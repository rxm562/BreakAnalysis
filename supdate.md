-- LAST UPDATED 2023-04-22
-- Update configuration for sewer collection

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Cohort Defaults

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_InitEUL] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitEUL]  DEFAULT ((100)) FOR [InitEUL];
GO

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_InitEquationType] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitEquationType]  DEFAULT (N'E') FOR [InitEquationType];
GO

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_InitExpSlope] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitExpSlope]  DEFAULT ((0.0438)) FOR [InitExpSlope];
GO

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_ReplaceEUL] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceEUL]  DEFAULT ((100)) FOR [ReplaceEUL];
GO

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_ReplaceEquationType] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceEquationType]  DEFAULT (N'E') FOR [ReplaceEquationType];
GO

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_ReplaceExpSlope] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceExpSlope]  DEFAULT ((0.0438)) FOR [ReplaceExpSlope];
GO


CREATE OR ALTER VIEW [dbo].[v_QC_Stats_MtlYearDiaIssues]
AS
SELECT	Assets.MATERIAL, dbo.ref_MaterialYearDiameters.Material AS Description, dbo.ref_MaterialYearDiameters.Notes,
		MIN(Try_Convert(date, Assets.INSTALLDATE)) AS ActualMinDate, MAX(Try_Convert(date, Assets.INSTALLDATE)) AS ActualMaxDate, 
		dbo.ref_MaterialYearDiameters.MinYear AS StandardMinYear, dbo.ref_MaterialYearDiameters.MaxYear AS StandardMaxYear, 
		SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 0) < 1800 THEN 1 ELSE 0 END) AS UnknownInstallCount, 
		ROUND(SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 0) < 1800 THEN RR_Length / 5280 ELSE 0 END), 2) AS UnknownInstallMiles, 
		SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) < ISNULL(MinYear, 1800) THEN 1 ELSE 0 END) AS EarlierInstallCount, 
		ROUND(SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) < ISNULL(MinYear, 1800) THEN RR_Length / 5280 ELSE 0 END), 2) AS EarlierInstallMiles, 
		SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) > ISNULL(MaxYear, 2022) THEN 1 ELSE 0 END) AS LaterInstallCount, 
		ROUND(SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) > ISNULL(MaxYear, 2022) THEN RR_Length / 5280 ELSE 0 END), 2) AS LaterInstallMiles, 
		MIN(Assets.DIAMETER) AS ActualMinDia, MAX(Assets.DIAMETER) AS ActualMaxDia, 
		dbo.ref_MaterialYearDiameters.MinDia AS StandardMinDia, dbo.ref_MaterialYearDiameters.MaxDia AS StandardMaxDia, 
		SUM(CASE WHEN ISNULL(DIAMETER, 0) <= 0 THEN 1 ELSE 0 END) AS UnknownDiaCount, 
		ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 0) <= 0 THEN RR_Length / 5280 ELSE 0 END), 2) AS UnknownDiaMiles, 
		SUM(CASE WHEN ISNULL(DIAMETER, 1000) < ISNULL(MinDia, 1) THEN 1 ELSE 0 END) AS SmallerDiaCount, 
		ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 1000) < ISNULL(MinDia, 1) THEN RR_Length / 5280 ELSE 0 END), 2) AS SmallerDiaMiles, 
		SUM(CASE WHEN ISNULL(DIAMETER, 0) > ISNULL(MaxDia, 1000) THEN 1 ELSE 0 END) AS LargerDiaCount, 
		ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 0) > ISNULL(MaxDia, 1000) THEN RR_Length / 5280 ELSE 0 END), 2) AS LargerDiaMiles
FROM	dbo.v__ActiveAssets AS Assets INNER JOIN
		dbo.ref_MaterialYearDiameters ON Assets.RR_Material = dbo.ref_MaterialYearDiameters.RRPS_Material
WHERE	(dbo.ref_MaterialYearDiameters.System LIKE N'%Sewer%')
GROUP BY dbo.ref_MaterialYearDiameters.Notes, dbo.ref_MaterialYearDiameters.MinYear, dbo.ref_MaterialYearDiameters.MaxYear, 
		dbo.ref_MaterialYearDiameters.MinDia, dbo.ref_MaterialYearDiameters.MaxDia, Assets.MATERIAL, dbo.ref_MaterialYearDiameters.Material
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Assumed_Diameter_Details]
AS
SELECT        RR_Asset_ID, RR_Config_ID, RR_Diameter, 'UPDATE TO CLIENT SPECIFIC FIELD' AS Diameter, RR_Material, RR_InstallYear, RR_Length
FROM            dbo.v__ActiveAssets
WHERE        (ISNULL('UPDATE TO CLIENT SPECIFIC FIELD', 0) <> RR_Diameter)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Assumed_Diameter_Summary]
AS
SELECT	dbo.v_QC_Assumed_Diameter_Details.RR_Diameter, dbo.v_QC_Assumed_Diameter_Details.Diameter, dbo.v_QC_Assumed_Diameter_Details.RR_Material, 
		MIN(dbo.v_QC_Assumed_Diameter_Details.RR_InstallYear) AS MinYear, MAX(dbo.v_QC_Assumed_Diameter_Details.RR_InstallYear) AS MaxYear, SUM(1) AS Cnt, 
		ROUND(SUM(dbo.v_QC_Assumed_Diameter_Details.RR_Length / 5280), 2) AS Miles, FORMAT(SUM(dbo.v_QC_Assumed_Diameter_Details.RR_Length / dbo.v__InventoryWeight.Weight), '0.0%') AS Prcnt
FROM	dbo.v_QC_Assumed_Diameter_Details INNER JOIN
		dbo.v__InventoryWeight ON dbo.v_QC_Assumed_Diameter_Details.RR_Config_ID = dbo.v__InventoryWeight.Config_ID
GROUP BY dbo.v_QC_Assumed_Diameter_Details.RR_Diameter, dbo.v_QC_Assumed_Diameter_Details.Diameter, dbo.v_QC_Assumed_Diameter_Details.RR_Material
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Assumed_InstallYear_Details]
AS
SELECT	RR_Asset_ID, RR_Config_ID, 'UPDATE TO CLIENT SPECIFIC FIELD' AS InstallYear, RR_InstallYear, RR_Diameter, RR_Material, RR_Length
FROM	dbo.v__ActiveAssets
WHERE	(ISNULL('UPDATE TO CLIENT SPECIFIC FIELD', '0') <> RR_InstallYear)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Assumed_InstallYear_Summary]
AS
SELECT	dbo.v_QC_Assumed_InstallYear_Details.RR_InstallYear, dbo.v_QC_Assumed_InstallYear_Details.InstallYear, MIN(dbo.v_QC_Assumed_InstallYear_Details.RR_Diameter) AS MinDia, 
		MAX(dbo.v_QC_Assumed_InstallYear_Details.RR_Diameter) AS MaxDia, dbo.v_QC_Assumed_InstallYear_Details.RR_Material, SUM(1) AS Cnt, 
		ROUND(SUM(dbo.v_QC_Assumed_InstallYear_Details.RR_Length / 5280), 2) AS Miles, FORMAT(SUM(dbo.v_QC_Assumed_InstallYear_Details.RR_Length / dbo.v__InventoryWeight.Weight), '0.00%') AS Prcnt
FROM	dbo.v_QC_Assumed_InstallYear_Details INNER JOIN
	dbo.v__InventoryWeight ON dbo.v_QC_Assumed_InstallYear_Details.RR_Config_ID = dbo.v__InventoryWeight.Config_ID
GROUP BY dbo.v_QC_Assumed_InstallYear_Details.InstallYear, dbo.v_QC_Assumed_InstallYear_Details.RR_InstallYear, dbo.v_QC_Assumed_InstallYear_Details.RR_Material
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Assumed_Material_Details]
AS
SELECT	RR_Asset_ID, RR_Config_ID, RR_Material, 'UPDATE TO CLIENT SPECIFIC FIELD' AS Material, RR_Diameter, RR_InstallYear, RR_Length
FROM	dbo.v__ActiveAssets
WHERE	(ISNULL('UPDATE TO CLIENT SPECIFIC FIELD', '') <> RR_Material)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Assumed_Material_Summary]
AS
SELECT	dbo.v_QC_Assumed_Material_Details.RR_Material, dbo.v_QC_Assumed_Material_Details.Material, MIN(dbo.v_QC_Assumed_Material_Details.RR_InstallYear) AS MinYear, 
		MAX(dbo.v_QC_Assumed_Material_Details.RR_InstallYear) AS MaxYear, MIN(dbo.v_QC_Assumed_Material_Details.RR_Diameter) AS MinDia, MAX(dbo.v_QC_Assumed_Material_Details.RR_Diameter) AS MaxDia, 
		SUM(1) AS Cnt, ROUND(SUM(dbo.v_QC_Assumed_Material_Details.RR_Length / 5280), 2) AS Miles, FORMAT(SUM(dbo.v_QC_Assumed_Material_Details.RR_Length / dbo.v__InventoryWeight.Weight), '0.00%') AS Prcnt
FROM	dbo.v_QC_Assumed_Material_Details INNER JOIN
		dbo.v__InventoryWeight ON dbo.v_QC_Assumed_Material_Details.RR_Config_ID = dbo.v__InventoryWeight.Config_ID
GROUP BY dbo.v_QC_Assumed_Material_Details.RR_Material, dbo.v_QC_Assumed_Material_Details.Material
GO


INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (17, N'01. Report (Quality Control)', 10, N'v_QC_Assumed_Diameter_Summary', NULL, N'Assumed Diameter Summary', N'Failed to report Assumed Diameter Summary', N'Reports the quantity of asset assumed diameter records.', 0)
INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (17, N'01. Report (Quality Control)', 11, N'v_QC_Assumed_Material_Summary', NULL, N'Assumed Material Summary', N'Failed to report Assumed Material Summary', N'Reports the quantity of asset assumed material records.', 0)
INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (17, N'01. Report (Quality Control)', 12, N'v_QC_Assumed_InstallYear_Summary', NULL, N'Assumed Install Year Summary', N'Failed to report Assumed Install Year Summary', N'Reports the quantity of asset assumed install year records.', 0)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_QC__Status]
AS
SELECT	'Duplicate Source IDs' AS Description, CASE WHEN COUNT(*) >0 THEN '~' ELSE '' END  AS Flag, FORMAT(COUNT(*), '#,##0') AS Measure
FROM	v_QC_DuplicateFacilityIDs
UNION
SELECT	'Invalid Values' AS Description, CASE WHEN COUNT(*) >0 THEN 'X' ELSE '' END  AS Flag, FORMAT(COUNT(*), '#,##0') AS Measure
FROM	v_QC_InvalidValues
UNION
SELECT	'Defined Aliases' AS Description, '' AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	RR_ConfigAliases
WHERE	Usage <> 'NA'
UNION
SELECT	'Defined CoF LoF' AS Description, '' AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	RR_ConfigCoFLoF
UNION
SELECT	'Run CoF LoF' AS Description, '' AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	RR_ConfigCoFLoF
WHERE	LastRun IS NOT NULL
UNION
SELECT	'Hierarchy Level 1 Records' AS Description, '' AS Flag, FORMAT(COUNT(DISTINCT Hierarchy_ID), '0') AS Measure
FROM	v_00_07_Hierarchy
WHERE	RR_HierarchyLevel = 1
UNION
SELECT	'Hierarchy Level 2 Records' AS Description, '' AS Flag, FORMAT(COUNT(DISTINCT Hierarchy_ID), '0') AS Measure
FROM	v_00_07_Hierarchy
WHERE	RR_HierarchyLevel = 2
UNION
SELECT	'Hierarchy Level 3 Records' AS Description, '' AS Flag, FORMAT(COUNT(DISTINCT Hierarchy_ID), '0') AS Measure
FROM	v_00_07_Hierarchy
WHERE	RR_HierarchyLevel = 3
UNION
SELECT	'Hierarchy Level 4 Records' AS Description, '' AS Flag, FORMAT(COUNT(DISTINCT Hierarchy_ID), '0') AS Measure
FROM	v_00_07_Hierarchy
WHERE	RR_HierarchyLevel = 4
UNION
SELECT	'Hierarchy Level 5 Records' AS Description, '' AS Flag, FORMAT(COUNT(DISTINCT Hierarchy_ID), '0') AS Measure
FROM	v_00_07_Hierarchy
WHERE	RR_HierarchyLevel = 5
UNION
SELECT	'Hierarchy Asset Records' AS Description, '' AS Flag, FORMAT(COUNT(DISTINCT RR_Hierarchy_ID), '0') AS Measure
FROM	RR_Assets
UNION
SELECT	'Defined Cohorts' AS Description, '' AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	v_00_01_Cohorts
UNION
SELECT	'Missing Cohorts' AS Description, CASE WHEN COUNT(*) >0 THEN 'X' ELSE '' END AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	v_QC_Cohorts_Missing
UNION
SELECT	'Duplicate Cohorts' AS Description, CASE WHEN COUNT(*) >0 THEN 'X' ELSE '' END  AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	v_QC_Cohorts_Duplicate
UNION
SELECT	'Unused Cohorts' AS Description, CASE WHEN COUNT(*) >0 THEN '~' ELSE '' END  AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	v_QC_Cohorts_Unused
UNION
--SELECT	'Assumed Diameters' AS Description, FORMAT(COUNT(*), '#,##0') AS Measure
--FROM	v_QC_Assumed_Diameter_Details
--UNION
--SELECT	'Assumed Install Years' AS Description, FORMAT(COUNT(*), '#,##0') AS Measure
--FROM	v_QC_Assumed_InstallYear_Details
--UNION
--SELECT	'Assumed Materials' AS Description, FORMAT(COUNT(*), '#,##0') AS Measure
--FROM	v_QC_Assumed_Material_Details
--UNION
SELECT	'Scenarios' AS Description, '' AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	RR_Scenarios
WHERE	LastRun IS NOT NULL
UNION
SELECT	TOP 1 'Last Run Scenario' AS Description, '' AS Flag, ScenarioName + ' ' + FORMAT(LastRun, 'yyyy-MM-dd HH:mm:ss') AS Measure
FROM	RR_Scenarios
WHERE	LastRun IS NOT NULL
GO

