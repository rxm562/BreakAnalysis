USE 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[p_01_UpdateAssetInfo]
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Update dbo.RR_Assets hierarchy data from dbo.RR_Hierarchy 
	UPDATE	RR_Assets
	SET		RR_Division = RR_Hierarchy_1.RR_HierarchyName, RR_Facility = RR_Hierarchy_2.RR_HierarchyName, RR_Process = RR_Hierarchy_3.RR_HierarchyName, RR_Group = RR_Hierarchy_4.RR_HierarchyName
	FROM	RR_Assets LEFT OUTER JOIN
			RR_Hierarchy AS RR_Hierarchy_4 ON RR_Assets.RR_Hierarchy_ID = RR_Hierarchy_4.RR_Hierarchy_ID RIGHT OUTER JOIN
			RR_Hierarchy AS RR_Hierarchy_1 RIGHT OUTER JOIN
			RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_1.RR_Hierarchy_ID = RR_Hierarchy_2.RR_Parent_ID RIGHT OUTER JOIN
			RR_Hierarchy AS RR_Hierarchy_3 ON RR_Hierarchy_2.RR_Hierarchy_ID = RR_Hierarchy_3.RR_Parent_ID ON RR_Hierarchy_4.RR_Parent_ID = RR_Hierarchy_3.RR_Hierarchy_ID;


	UPDATE RR_ASSETS
	SET 
		RR_Diameter = ISNULL(DIAMETER, 7), --assume 7 if gis data is null initially
		RR_ReplacementDiameter = ISNULL(DIAMETER, 7), --assume 7 if gis data is null initially
		RR_Material =	CASE 
							WHEN UPPER(MATERIAL) IS NULL THEN 'UNK' -- assume unknown initially if null
							WHEN UPPER(MATERIAL) = 'OTH' THEN 'UNK' -- swap other to unknown
							ELSE UPPER(MATERIAL) --make all uppercase for consistency
						END,
		RR_InstallYear = ISNULL(YEAR(InstallDate), 1888), -- one year before earliest
		RR_AssetType = CASE WHEN RR_Fulcrum_ID IS NULL THEN 'Linear' ELSE RR_AssetType END, --all are linear
		RR_Length = ISNULL(shape.STLength(), 1); --calc to geometry length
	
		
	--fixing materials, chris
	UPDATE RR_Assets
	SET RR_Material = 'AC'
	WHERE RR_Material = 'TRANS';

	--fixing years
	UPDATE RR_ASSETS
	SET RR_InstallYear =	
		CASE
			WHEN RR_Material = 'CI' THEN 1914 -- besides very small amount of 1889 the next earliest is 1915
			WHEN RR_Material = 'DI' THEN 1965 --1953 --EWSU seems to have quite a few starting in 1954, so maybe an early adopter? 
			WHEN RR_Material = 'CON' THEN 1953 -- 1954 is earliest known
			WHEN RR_Material = 'PE' THEN 1995 --1994 --can clearly seem install years pick up in 1995, early ones probably wrong
			WHEN RR_Material = 'CU' THEN 1922 -- 1923 earliest
			WHEN RR_Material = 'ST' THEN 1934 -- 1935 earliest
			WHEN RR_Material = 'GAL' THEN 1922 --1923 earliest
			WHEN RR_Material = 'AC' THEN 1934 --1954 is earliest known besides 1935
			WHEN RR_Material = 'PVC' THEN 1980 --1974 --EWSU seems to have quite a few starting in 1975, so maybe an early adopter?
			WHEN RR_Material = 'PCCP' THEN 1942  --earliest available
			ELSE RR_InstallYear
		END
	WHERE RR_InstallYear = 1888 ;

	--fixing materials
	UPDATE RR_Assets
	SET RR_Material =
		CASE
			WHEN RR_Material = 'DI' AND RR_InstallYear < 1965 THEN 'CI' --1954 THEN 'CI' --DI seems to pick up around 1954, assuming material was wrong
			WHEN RR_Material = 'AC' AND RR_InstallYear > 1975 THEN 'CON' --seems the last legitimate AC was in 1975
			WHEN RR_Material = 'CI' AND RR_InstallYear > 1970 THEN 'DI'
			WHEN RR_Material IN ('PVC', 'PE') AND RR_InstallYear < 1965 THEN 'CI'
			WHEN RR_Material IN ('PVC', 'PE') AND RR_InstallYear < 1980 THEN 'DI'
			WHEN RR_Material = 'PE' AND RR_InstallYear < 1995 THEN 'PVC'
			ELSE RR_Material
		END
	WHERE RR_InstallYear != 1888; --ignore unknown dates

	UPDATE RR_Assets
	SET RR_Material =
		CASE
			WHEN RR_InstallYear > 1980 THEN 'PVC'
			WHEN RR_InstallYear < 1914 THEN 'CI'
			ELSE RR_Material
		END
	WHERE RR_Material = 'UNK'

	UPDATE	RR_Assets
	SET		RR_InstallYear = 2022
	WHERE	RR_InstallYear > 2022;

	UPDATE	RR_ASSETS 
	SET		RR_Status = 
			CASE 
				WHEN LIFECYCLESTATUS IN ('Active') AND SUBTYPECD <=5 AND RR_Diameter >2 AND ISNULL(RR_Notes, '') NOT LIKE '%yard piping%' THEN 1 -- ignore hydrant tap, unkonwn and the single transmission and small dia per workshopp feedback
				ELSE 0 
			END;

	UPDATE	RR_ASSETS 
	SET		RR_CohortAnalysis = 
			CASE 
				WHEN LIFECYCLESTATUS IN ('Active', 'Abandoned') AND SUBTYPECD <=5 AND RR_Diameter >2  AND ISNULL(RR_Notes, '') NOT LIKE '%yard piping%' THEN 1 
				ELSE 0 
			END;


	UPDATE	RR_Assets
	SET		RR_PreviousFailures = ISNULL(v_00_08_FailureCount.FailureCount, 0)
	FROM	RR_Assets LEFT OUTER JOIN
			v_00_08_FailureCount ON RR_Assets.RR_Asset_ID = v_00_08_FailureCount.Asset_ID;


	UPDATE	v_00_08_FailurePredicted  -- Added base on top 20% of ML prediction of failure in pipes that do not already have breaks
	SET		RR_PreviousFailures = 1,
			RR_Notes = case when RR_Notes LIKE '%Predicted Break%' then RR_Notes ELSE CONCAT(RR_Notes, ', Predicted Break') END;

			/*
			No Nulls
			1 air release (110)
			2 blowoff (1,093)
			3 bypass (0)
			4 chemical injection (0)
			5 distribution (31,045)
			6 drain (0)
			7 interconnect (0)
			8 pipe bridge (0)
			10 sampling station (0)
			11 sprinkler (0)
			12 transmission (1)
			13 unknown (4)
			14 hydrant tap (12,591)
			*/



END
