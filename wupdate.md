-- LAST UPDATED 2023-04-22
-- Update configuration for water distribution LoF range (1 to 100).  Default is set to range of 1 to 5.

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Cohort Defaults

ALTER TABLE [RR_Cohorts] DROP CONSTRAINT [DF_RR_Cohorts_ConditionAtEUL] ;
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ConditionAtEUL]  DEFAULT ((80)) FOR [ConditionAtEUL];
GO

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



--v_70_GraphCohortCurve
ALTER VIEW [v_70_GraphCohortCurve]
AS
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, 0 AS X, [InitConstIntercept] AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 10, [InitExpSlope]) AS x, 10 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 20, [InitExpSlope]) AS x, 20 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 30, [InitExpSlope]) AS x, 30 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 40, [InitExpSlope]) AS x, 40 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 50, [InitExpSlope]) AS x, 50 AS Y
FROM	RR_Cohorts;
GO

CREATE VIEW [dbo].[v__Source]
AS
SELECT        RR_Asset_ID, 0 AS Diameter, 'UNK' AS Material, 1800 AS InstallYear, '' AS Source_ID, shape
FROM            dbo.RR_Assets
GO

ALTER VIEW [dbo].[v_QC_Stats_MtlYearDiaIssues]
AS
SELECT	Assets.MATERIAL, dbo.ref_MaterialYearDiameters.Material AS Description, dbo.ref_MaterialYearDiameters.Notes,
		MIN(InstallYear) AS ActualMinDate, MAX(InstallYear) AS ActualMaxDate, 
		dbo.ref_MaterialYearDiameters.MinYear AS StandardMinYear, dbo.ref_MaterialYearDiameters.MaxYear AS StandardMaxYear, 
		SUM(CASE WHEN ISNULL(InstallYear, 0) < 1800 THEN 1 ELSE 0 END) AS UnknownInstallCount, 
		ROUND(SUM(CASE WHEN ISNULL(InstallYear, 0) < 1800 THEN shape.STLength() / 5280 ELSE 0 END), 2) AS UnknownInstallMiles, 
		SUM(CASE WHEN ISNULL(InstallYear, 1800) < ISNULL(MinYear, 1800) THEN 1 ELSE 0 END) AS EarlierInstallCount, 
		ROUND(SUM(CASE WHEN ISNULL(InstallYear, 1800) < ISNULL(MinYear, 1800) THEN shape.STLength() / 5280 ELSE 0 END), 2) AS EarlierInstallMiles, 
		SUM(CASE WHEN ISNULL(InstallYear, 1800) > ISNULL(MaxYear, 2022) THEN 1 ELSE 0 END) AS LaterInstallCount, 
		ROUND(SUM(CASE WHEN ISNULL(InstallYear, 1800) > ISNULL(MaxYear, 2022) THEN shape.STLength() / 5280 ELSE 0 END), 2) AS LaterInstallMiles, 
		MIN(Assets.DIAMETER) AS ActualMinDia, MAX(Assets.DIAMETER) AS ActualMaxDia, 
		dbo.ref_MaterialYearDiameters.MinDia AS StandardMinDia, dbo.ref_MaterialYearDiameters.MaxDia AS StandardMaxDia, 
		SUM(CASE WHEN ISNULL(DIAMETER, 0) <= 0 THEN 1 ELSE 0 END) AS UnknownDiaCount, 
		ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 0) <= 0 THEN shape.STLength() / 5280 ELSE 0 END), 2) AS UnknownDiaMiles, 
		SUM(CASE WHEN ISNULL(DIAMETER, 1000) < ISNULL(MinDia, 1) THEN 1 ELSE 0 END) AS SmallerDiaCount, 
		ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 1000) < ISNULL(MinDia, 1) THEN shape.STLength() / 5280 ELSE 0 END), 2) AS SmallerDiaMiles, 
		SUM(CASE WHEN ISNULL(DIAMETER, 0) > ISNULL(MaxDia, 1000) THEN 1 ELSE 0 END) AS LargerDiaCount, 
		ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 0) > ISNULL(MaxDia, 1000) THEN shape.STLength() / 5280 ELSE 0 END), 2) AS LargerDiaMiles
FROM	dbo.v__Source AS Assets INNER JOIN
		dbo.ref_MaterialYearDiameters ON Assets.Material = dbo.ref_MaterialYearDiameters.RRPS_Material
WHERE	(dbo.ref_MaterialYearDiameters.System LIKE N'%Water%')
GROUP BY dbo.ref_MaterialYearDiameters.Notes, dbo.ref_MaterialYearDiameters.MinYear, dbo.ref_MaterialYearDiameters.MaxYear, 
		dbo.ref_MaterialYearDiameters.MinDia, dbo.ref_MaterialYearDiameters.MaxDia, Assets.MATERIAL, dbo.ref_MaterialYearDiameters.Material
GO

-- RR_Config
UPDATE [dbo].[RR_Config] 
SET	[ConditionLimit] = 300,
		[ConditionFailureFactor] = 10
WHERE	[ID] = 1;
GO

--[RR_Conditions]
UPDATE	[dbo].[RR_Conditions] 
SET		[MinRawCondition] = 0, 
		[MaxRawCondition] = 20
WHERE [Condition_Score] = 1;
GO

UPDATE	[dbo].[RR_Conditions] 
SET		[MinRawCondition] = 20, 
		[MaxRawCondition] = 40
WHERE [Condition_Score] = 2;
GO

UPDATE	[dbo].[RR_Conditions] 
SET		[MinRawCondition] = 40, 
		[MaxRawCondition] = 60
WHERE [Condition_Score] = 3;
GO

UPDATE	[dbo].[RR_Conditions] 
SET		[MinRawCondition] = 60, 
		[MaxRawCondition] = 80
WHERE [Condition_Score] = 4;
GO

UPDATE	[dbo].[RR_Conditions] 
SET		[MinRawCondition] = 80, 
		[MaxRawCondition] = NULL
WHERE [Condition_Score] = 5;
GO

--[RR_CriticalityActionLimits]
UPDATE	[dbo].[RR_CriticalityActionLimits] 
SET		[LowReplace] = 80
WHERE	[Criticality] = 1;
GO

UPDATE	[dbo].[RR_CriticalityActionLimits] 
SET		[LowReplace] = 70
WHERE	[Criticality] = 2;
GO

UPDATE	[dbo].[RR_CriticalityActionLimits] 
SET		[LowReplace] = 60
WHERE	[Criticality] = 3;
GO

UPDATE	[dbo].[RR_CriticalityActionLimits] 
SET		[LowReplace] = 50
WHERE	[Criticality] = 4;
GO

UPDATE	[dbo].[RR_CriticalityActionLimits] 
SET		[LowReplace] = 40
WHERE	[Criticality] = 5;
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

CREATE OR ALTER   VIEW [dbo].[v_QC__Status]
AS
SELECT	'Active Assets' AS Description, '' AS Flag, FORMAT(ActiveAssets, '#,##0') AS Measure
FROM	v__InventoryWeight
UNION
SELECT	'Active Miles' AS Description, '' AS Flag, FORMAT(Miles, '#,##0') AS Measure
FROM	v__InventoryWeight
UNION
SELECT	'Capital Cost' AS Description, '' AS Flag, FORMAT(CapitalCost, '$#,##0') AS Measure
FROM	v__InventoryWeight
UNION
SELECT	'Baseline Year' AS Description, '' AS Flag, FORMAT(BaselineYear, '0') AS Measure
FROM	v__InventoryWeight
UNION
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
SELECT	'Scenarios' AS Description, '' AS Flag, FORMAT(COUNT(*), '0') AS Measure
FROM	RR_Scenarios
WHERE	LastRun IS NOT NULL
UNION
SELECT	'Projection' AS Descripton, '' AS Flag, STRING_AGG(CONCAT(WKID, ' (', cnt, ')') , ', ') AS comma_separated FROM (SELECT shape.STSrid AS WKID, count(*) as cnt FROM v__ActiveAssets group by shape.STSrid) AS T1
UNION
SELECT	TOP 1 'Last Run Scenario' AS Description, '' AS Flag, ScenarioName + ' ' + FORMAT(LastRun, 'yyyy-MM-dd HH:mm:ss') AS Measure
FROM	RR_Scenarios
WHERE	LastRun IS NOT NULL
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[v_QC_RiskMatrix]
AS
SELECT        '5' AS CoF, ROUND(SUM(CASE WHEN RR_LoF = 1 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF1, ROUND(SUM(CASE WHEN RR_LoF = 2 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF2, 
                         ROUND(SUM(CASE WHEN RR_LoF = 3 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF3, ROUND(SUM(CASE WHEN RR_LoF = 4 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF4, 
                         ROUND(SUM(CASE WHEN RR_LoF = 5 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF5, ROUND(SUM(RR_Length / 5280), 2) AS Total
FROM            dbo.v__ActiveAssets
WHERE        (RR_CoF_R = 5)

UNION ALL

SELECT        '4' AS CoF, ROUND(SUM(CASE WHEN RR_LoF = 1 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF1, ROUND(SUM(CASE WHEN RR_LoF = 2 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF2, 
                         ROUND(SUM(CASE WHEN RR_LoF = 3 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF3, ROUND(SUM(CASE WHEN RR_LoF = 4 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF4, 
                         ROUND(SUM(CASE WHEN RR_LoF = 5 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF5, ROUND(SUM(RR_Length / 5280), 2) AS Total
FROM            dbo.v__ActiveAssets
WHERE        (RR_CoF_R = 4)
UNION ALL

SELECT        '3' AS CoF, ROUND(SUM(CASE WHEN RR_LoF = 1 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF1, ROUND(SUM(CASE WHEN RR_LoF = 2 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF2, 
                         ROUND(SUM(CASE WHEN RR_LoF = 3 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF3, ROUND(SUM(CASE WHEN RR_LoF = 4 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF4, 
                         ROUND(SUM(CASE WHEN RR_LoF = 5 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF5, ROUND(SUM(RR_Length / 5280), 2) AS Total
FROM            dbo.v__ActiveAssets
WHERE        (RR_CoF_R = 3)
UNION ALL

SELECT        '2' AS CoF, ROUND(SUM(CASE WHEN RR_LoF = 1 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF1, ROUND(SUM(CASE WHEN RR_LoF = 2 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF2, 
                         ROUND(SUM(CASE WHEN RR_LoF = 3 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF3, ROUND(SUM(CASE WHEN RR_LoF = 4 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF4, 
                         ROUND(SUM(CASE WHEN RR_LoF = 5 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF5, ROUND(SUM(RR_Length / 5280), 2) AS Total
FROM            dbo.v__ActiveAssets
WHERE        (RR_CoF_R = 2)
UNION ALL

SELECT       '1' AS CoF, ROUND(SUM(CASE WHEN RR_LoF = 1 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF1, ROUND(SUM(CASE WHEN RR_LoF = 2 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF2, 
                         ROUND(SUM(CASE WHEN RR_LoF = 3 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF3, ROUND(SUM(CASE WHEN RR_LoF = 4 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF4, 
                         ROUND(SUM(CASE WHEN RR_LoF = 5 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF5, ROUND(SUM(RR_Length / 5280), 2) AS Total
FROM            dbo.v__ActiveAssets
WHERE        (RR_CoF_R = 1)
UNION ALL

SELECT       'Total' AS CoF, ROUND(SUM(CASE WHEN RR_LoF = 1 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF1, ROUND(SUM(CASE WHEN RR_LoF = 2 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF2, 
                         ROUND(SUM(CASE WHEN RR_LoF = 3 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF3, ROUND(SUM(CASE WHEN RR_LoF = 4 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF4, 
                         ROUND(SUM(CASE WHEN RR_LoF = 5 THEN RR_Length / 5280 ELSE 0 END), 2) AS LoF5, ROUND(SUM(RR_Length / 5280), 2) AS Total
FROM            dbo.v__ActiveAssets

GO

