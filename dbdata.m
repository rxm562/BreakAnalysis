
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[p__SpatialIndex]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MinX bigint, @MinY bigint, @MaxX bigint, @MaxY bigint, @sTable as nvarchar(64);
	DECLARE @sql NVARCHAR(1024);

	SELECT
			@MinX = MIN(Shape.STEnvelope().STPointN(1).STX),
			@MinY = MIN(Shape.STEnvelope().STPointN(1).STY),
			@MaxX = MAX(Shape.STEnvelope().STPointN(3).STX) + 1,
			@MaxY = MAX(Shape.STEnvelope().STPointN(3).STY) + 1,
			@sTable =	'RR_Assets'  --Enter table name
	FROM				RR_Assets;   --Enter table name

	--IF	EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(@sTable) AND name = @sTable + '_Shape_IDX')
	--	DROP INDEX [RR_Assets_Shape_IDX] ON [RR_Assets];  --Enter table names

	SET @sql = 'IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @sTable + ''') AND name = ''' +  @sTable + '_Shape_IDX'')'
	SET @sql = @sql + ' DROP INDEX [' + @sTable + '_Shape_IDX] ON [' + @sTable + ']'

	Print @sql;

	EXEC sp_executesql @sql;

	SET ARITHABORT ON
	SET CONCAT_NULL_YIELDS_NULL ON
	SET QUOTED_IDENTIFIER ON
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON
	SET ANSI_WARNINGS ON
	SET NUMERIC_ROUNDABORT OFF

	SET @sql = 'CREATE SPATIAL INDEX [' + @sTable + '_Shape_IDX] ON [dbo].[' + @sTable + '] ([Shape]) USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX =('
	SET @sql = @sql + CAST(@MinX AS nvarchar(10)) + ', ' + CAST( @MinY AS nvarchar(10)) + ', ' + CAST(@MaxX AS nvarchar(10)) + ', ' + CAST(@MaxY AS nvarchar(10)) + '), '
	SET @sql = @sql + 'CELLS_PER_OBJECT = 8, PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]';

	Print @sql;
	
	EXEC sp_executesql @sql;
       
END

USE [RRPS_]
GO
/****** Object:  StoredProcedure [dbo].[p_01_UpdateAssetInfo]    Script Date: 4/29/2024 11:45:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[p_01_UpdateAssetInfo]
AS
BEGIN
	
	SET NOCOUNT ON;

	UPDATE	RR_Assets
	SET		RR_Material = CASE WHEN MATERIAL = 'Cast Iron' THEN 'CAS' 
					WHEN MATERIAL = 'Ductile Iron' THEN 'DIP'
					ELSE MATERIAL
					END
			, RR_InstallYear = CASE WHEN INSTALLDATE is NULL THEN 0 ELSE Year(INSTALLDATE) END
			, RR_Diameter = ISNULL(DIAMETER, 0)
			, RR_Length = Shape.STLength()
			, RR_SourceTxt_ID = FACILITYID
			, RR_Status = 1
			 ,RR_PreviousFailures = 0
			, RR_FailurePhysOffset = 0
			, RR_AgeOffset = 0
			, RR_Config_ID = 1;
	
	--exclude inactive
	UPDATE RR_Assets
	SET RR_Status = 0,  RR_Notes = CASE WHEN RR_Notes like '%Inactive%' THEN RR_Notes ELSE 'Inactive,' + ISNULL(rr_notes,'') END
	WHERE  ACTIVEFLAG = 0; 

	--exclude not owned by Goshen
	UPDATE RR_Assets
		SET RR_Status = 0, RR_Notes = CASE WHEN RR_Notes like '%Not City owned%' THEN RR_Notes ELSE 'Not City owned,' + ISNULL(rr_notes,'') END
	WHERE OWNEDBY <> 1 ;

	--exclude known diameters <2 
	UPDATE RR_Assets
		SET RR_Status = 0, RR_Notes = CASE WHEN RR_Notes like '%Diameter <2%' THEN RR_Notes ELSE 'Diameter <2",' + ISNULL(rr_notes,'') END
	WHERE RR_Diameter > 0 AND RR_Diameter < 2;

	--exclude private copper that is private
	UPDATE RR_Assets
		SET RR_Status = 0, RR_Notes = CASE WHEN RR_Notes like '%Private copper%' THEN RR_Notes ELSE 'Private copper,' + ISNULL(rr_notes,'') END
	WHERE RR_Material = 'COP';

	--exclude private Galvanized that is private
	UPDATE RR_Assets
		SET RR_Status = 0, RR_Notes = CASE WHEN RR_Notes like '%Private galvanized%' THEN RR_Notes ELSE 'Private galvanized,' + ISNULL(rr_notes,'') END
	WHERE RR_Material = 'GP';

	--Change materials based on known install years
	UPDATE RR_Assets
		SET RR_Material = 'CAS'
	WHERE RR_Material IN ('PVC', 'HDPE', 'DIP') AND RR_InstallYear > 0 AND RR_InstallYear < 1980

	UPDATE RR_Assets
		SET RR_Material = 'DIP'
	WHERE RR_Material = 'CAS' AND RR_InstallYear >= 1980

	UPDATE RR_Assets
		SET RR_Material = 'CAS'
	WHERE RR_Material = 'UNK' AND RR_InstallYear > 0 AND RR_InstallYear < 1980;

	UPDATE RR_Assets
		SET RR_Material = 'DIP'  --Maybe this should be PVC
	WHERE RR_Material = 'UNK' AND RR_InstallYear >= 1980;

	UPDATE RR_Assets
		SET RR_InstallYear = 1980
	WHERE RR_InstallYear = 0 AND RR_Material IN ('DIP','PVC', 'HDPE')  ;

	UPDATE RR_Assets
		SET RR_InstallYear = 1885
	WHERE RR_InstallYear <= 0 

	--Apply assumed diameter to unknown 
	UPDATE RR_Assets
		SET RR_Diameter = 7
	WHERE RR_Diameter <= 0 ;

	UPDATE RR_Assets
		SET RR_AssetName = CAST(RR_InstallYear AS varchar(4)) + ' ' + RR_Material + ' ' + CAST(ROUND(RR_Diameter,0) AS varchar(2)) + '"' ;

	UPDATE RR_Assets
	  SET  RR_LOFPerfCapacity = 1
		 , RR_LOFPerfOM = 1
		 , RR_COFServiceImpact = 1;

	--apply hydraulic model factors
 	UPDATE RR_Assets
	  SET  RR_LOFPerfCapacity = CASE WHEN rr_HydraulicModel.HeadLoss_Max > 10 THEN -5 WHEN rr_HydraulicModel.HeadLoss_Max > 4 THEN -4 WHEN rr_HydraulicModel.HeadLoss_Max > 1 THEN -3 WHEN rr_HydraulicModel.HeadLoss_Max > 0.1 THEN -2 ELSE -1 END 
		 , RR_LOFPerfOM = CASE WHEN rr_HydraulicModel.C_Factor <= 15 THEN -5 WHEN rr_HydraulicModel.C_Factor <= 30 THEN -4 WHEN rr_HydraulicModel.C_Factor <= 50 THEN -3 WHEN rr_HydraulicModel.C_Factor< = 100 THEN -2 ELSE -1 END 
		 , RR_COFServiceImpact = CASE WHEN rr_HydraulicModel.DemandShortfall_Pcnt >= 2 THEN -4 WHEN rr_HydraulicModel.DemandShortfall_Pcnt >= 1 THEN -3 WHEN rr_HydraulicModel.DemandShortfall_Pcnt > 0 THEN -2 ELSE -1 END
	FROM rr_HydraulicModel join  RR_Assets on rr_HydraulicModel.FacilityID = RR_Assets.RR_SourceTxt_ID;

	-- Override facility yeard piping
	UPDATE RR_Assets
	  SET  RR_LOFPerfCapacity = 1, RR_Status = 0, RR_Notes = CASE WHEN RR_Notes like '%Yard piping%' THEN RR_Notes ELSE 'Yard piping,' + ISNULL(rr_notes,'') END
	FROM rr_HydraulicModel join  RR_Assets on rr_HydraulicModel.FacilityID = RR_Assets.RR_SourceTxt_ID
	WHERE Zone = 'Facility';

	--set previous breaks
	UPDATE	RR_Assets
	SET	RR_PreviousFailures = BreakCount
	FROM	RR_Assets INNER JOIN  v_00_08_BreakCount ON RR_Assets.RR_Asset_ID = v_00_08_BreakCount.Asset_ID

	UPDATE	RR_Assets
	SET		RR_ReplacementDiameter = CASE WHEN RR_ReplacementDiameter IS NULL THEN RR_Diameter ELSE RR_ReplacementDiameter END
			, RR_AssetName = CAST(RR_InstallYear AS varchar(4)) + ' ' + RR_Material + ' ' + CAST(ROUND(RR_Diameter,0) AS varchar(2));


END





