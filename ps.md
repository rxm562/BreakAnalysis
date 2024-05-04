
--v5.001
--This script addresses consolidation of RR_ScenarioTargetBudgets and RR_ScenarioResultsSummary into RR_ScenarioYears
--Maintaining compatablity with RRPS v4 and v5
--v_14_ScenarioSummary:  Cast Total Cost as BigInt


--RR_ScenarioTargetBudgets and RR_ScenarioResultsSummary are consolidated into RR_ScenarioYears, data is copied in to RR_ScenarioYears below
--Foreign Keys are removed from RR_ScenarioTargetBudgets and RR_ScenarioResultsSummary below 
-- RR_ScenarioTargetBudgets is renamed so a view of the same name is created for v4 compatability.  The original table can be deleted after verification of proper operation


--v5.002 update for Cost Override

--v5.003
--v_PBI_ScenariosResultsSummary:  Fix to add Scenario ID Year

--v5.004
--v___QC_Results:  Corrected Rehab to include RR_RehabsAllowed criteria 
--p___QC_ResultsReview:  Added AgeOffset
--v_QC__Status:  Added Flag column and removed basic inventory stats from  
--v_14_Results_Summary:  
--v_10_a_ScenarioCurrentYearDetails;  Priorizize rehabs allowed and allow overlapping thresholds
--RR_ConfigTableLookup:  UPDATE Projects DisplayOrder and INSERT Projects Year1Pcnt, Year2Pcnt, Year3Pcnt, Year4Pcnt, OverrideCost
--RR_ScenarioYears:  Added LoF5Miles and Risk16Miles
--RR_Projects: Added StartYear
--p_02_AssignCohortsCosts:  REHAB based on RR_Diameter, REPLACE based on RR_ReplacementDiameter
--RR_ConfigTableLookup:  Updage bit fields to TrueFalse format
--p_50_UpdateProjectStats:  altered
--v_PBI_Projects:  altered
--v_PBI_ProjectYears:  Created
--v_QC_Projects:  Created
--v_40_FirstReplaceYear: altered
--v_40_FirstRehabYear: altered
--v_70_GraphScenarioResults:  Updated to include LoF5Miles and Risk16Miles
--v_00_02_ScenarioNames:  Added ReplacedWeight, RehabbedWeight
--v_10_a_ScenarioCurrentYearDetails:  Priorizize rehabs allowed and allow overlapping thresholds EXCEPT performance threshould
--p___QC_ListTables:  altered
--v_PBI_3DMatrix:  2023-04-22 tweak
--p___Alias_Views:  altered
--v__RuntimeResults:  altered
--v_00_11_Revisions:  altered
--p_90_AssignCoFLoF:  altered

--v5.005  2023-08-27
--v__InventoryWeight:  Added LoF raw, LoF, CoF and Risk
--v_QC_Loaded_ActiveAssets:  Added more stats including current LoF, CoF and Risk
--v_QC_Stats_Cohorts:  Added AvgDia
--RR_ScenarioTargetBudgets:  RENAMED to deleted and CREATED VIEW of same name for v4 compatability
--p_40_Update_Asset_Current_Results: Add Scenario ID parameter with default of -1 so it still works with v4
--v_14_ScenarioSummary:  Ensure the orignial with CostOfService>0 filter is being used
--RR_ScenarioYears:  Added LoF5Remaining and Risk16Remaining,  Copy values and drop LoF5Miles and Risk15Miles
--RR_Config:  Added WeightMultiplier adn set default to 1 (facilities),  Linear should be 0.00018393939
--v_70_GraphScenarioResults:  Updated for LoF5Remaining and Risk16Remaining
--v_14_Results_Summary:  Added LoF5Remaining and Risk16Remaining to use Weighting * WeightMultiplier
--p_14_Results_Summary_Update:  Updated to use LoF5Remaining and Risk16Remaining
--v_PBI_ScenariosResultsSummary:  Added LoF5Remaining and Risk16Remaining

--p_03_UpdateAssetCurves:  Set Rehabs Allowed to 0 if RR_ReplacementDiameter>RR_Diameter 2023-09-03


--v5.006
--Fucrum schema update - Not Yet Included in this script


--v5.007  2024-03-20
--Add Adjustment and Subcost to RR_Scenarios
--  Update v_00_02_ScenarioNames
--  Update p_14_Results_Summary_Update
--  Add Adjustment and Subcost to RR_ConfigTableLookup
--Move all scenario run functions to the new p_10_ProcessScenarioYear. 
--  Old scenario run procedures must be disabled so previous versions of the app only run the new proc even though they look for the old ones.
--  Updated v_10_01_ScenarioCurrentYear_RR_Projects to include ID and year fields
--  Create p_10a_ScenarioYearProjectsUpdate
--  Create p_10_ProcessScenarioYear and set RR_ConfigQueries.Category_ID  9 to use it
--  Disable old procedures by setting RR_ConfigQueries.Category_IDs (6, 7, 8, 10, 11, 12, 13, 21, 22, 23, 24, 25, 32, 33) to Category_ID = 0
--Update v_00_03_Config to include WeightMultiplier and Version 
--Add Configuration WeightMultiplier and Version to RR_ConfigTableLookup
--Updated p___QC_ResultsReview to include Scenario ID parameter


--v5.008  2024-04-13
--[p_03_UpdateAssetCurves]
--Limit RR_LoFInspection to values > 0


--v5.009  2024-04-26
--Add Improve and Inspect service types
--	Add ServiceType constriant
--  Added InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight to RR_Scenarios
--  Updated v_00_02_ScenarioNames to include InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight 
--	Updated v_14_ScenarioSummary to include InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight 
--	Updated p_14_Results_Summary_Update to set InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight
--	Updated v_10_01_ScenarioCurrentYear_RR_Projects to return specified ServiceType instead of defaulting to Rehab and default cost to 1 instead of RehabCost
--	Updated p_10_ProcessScenarioYear to set CurrentPerformance = 1 when ServiceType IN ('Replace', 'Improve')
--	Updated p_10a_ScenarioYearProjectsUpdate to set CurrentPerformance = 1 when ServiceType IN ('Replace', 'Improve')
--	Updated p_11_UpdateScenarioAsset to add Improve service type



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RR_ScenarioYears](
	[BudgetYear_ID] [int] IDENTITY(1,1) NOT NULL,
	[Scenario_ID] [int] NULL,
	[BudgetYear] [int] NULL,
	[Budget] [int] NULL,
	[AllocationToRisk] [real] NULL,
	[ConditionTarget] [real] NULL,
	[RiskTarget] [real] NULL,
	[UseProjectBudget] [bit] NOT NULL,
	[ActualBudget] [float] NULL,
	[OverallCount] [float] NULL,
	[OverallWeighting] [float] NULL,
	[OverallAgeWeighted] [float] NULL,
	[OverallAgeAvg] [float] NULL,
	[OverallPhysRawWeighted] [float] NULL,
	[OverallPhysRawAvg] [float] NULL,
	[OverallPhysScoreWeighted] [float] NULL,
	[OverallPhysScoreAvg] [float] NULL,
	[OverallPerfScoreWeighted] [float] NULL,
	[OverallPerfScoreAvg] [float] NULL,
	[OverallLoFRawWeighted] [float] NULL,
	[OverallLoFRawAvg] [float] NULL,
	[OverallLoFScoreWeighted] [float] NULL,
	[OverallLoFScoreScore] [float] NULL,
	[OverallRiskRawWeighted] [float] NULL,
	[OverallRiskRawAvg] [float] NULL,
	[OverallRiskScoreWeighted] [float] NULL,
	[OverallRiskScoreAvg] [float] NULL,
	[ServicedCount] [float] NULL,
	[ServicedWeighting] [float] NULL,
	[ServicedAgeWeighted] [float] NULL,
	[ServicedAgeAvg] [float] NULL,
	[ServicedPhysRawWeighted] [float] NULL,
	[ServicedPhysRawAvg] [float] NULL,
	[ServicedPhysScoreWeighted] [float] NULL,
	[ServicedPhysScoreAvg] [float] NULL,
	[ServicedPerfScoreWeighted] [float] NULL,
	[ServicedPerfScoreAvg] [float] NULL,
	[ServicedLoFRawWeighted] [float] NULL,
	[ServicedLoFRawAvg] [float] NULL,
	[ServicedLoFScoreWeighted] [float] NULL,
	[ServicedLoFScoreAvg] [float] NULL,
	[ServicedCoFWeighted] [float] NULL,
	[ServicedCoFAvg] [float] NULL,
	[ServicedRiskRawWeighted] [float] NULL,
	[ServicedRiskRawAvg] [float] NULL,
	[ServicedRiskScoreWeighted] [float] NULL,
	[ServicedRiskScoreAvg] [float] NULL,
 CONSTRAINT [PK_RR_ScenarioYears] PRIMARY KEY CLUSTERED 
(
	[BudgetYear_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

ALTER TABLE [dbo].[RR_ScenarioYears] ADD  CONSTRAINT [DF_RR_ScenarioYears_Budget]  DEFAULT ((0)) FOR [Budget];
GO
ALTER TABLE [dbo].[RR_ScenarioYears] ADD  CONSTRAINT [DF_RR_ScenarioYears_AllocationToRisk]  DEFAULT ((1)) FOR [AllocationToRisk];
GO
ALTER TABLE [dbo].[RR_ScenarioYears] ADD  CONSTRAINT [DF_RR_SScenarioYears_ConditionTarget]  DEFAULT ((0)) FOR [ConditionTarget];
GO
ALTER TABLE [dbo].[RR_ScenarioYears] ADD  CONSTRAINT [DF_RR_ScenarioYears_RiskTarget]  DEFAULT ((0)) FOR [RiskTarget];
GO
ALTER TABLE [dbo].[RR_ScenarioYears] ADD  CONSTRAINT [DF_RR_ScenarioYears_UseProjectBudget]  DEFAULT ((0)) FOR [UseProjectBudget];
GO
ALTER TABLE [dbo].[RR_ScenarioYears]  WITH CHECK ADD  CONSTRAINT [FK_RR_ScenarioYears_Scenarios] FOREIGN KEY([Scenario_ID])
REFERENCES [dbo].[RR_Scenarios] ([Scenario_ID]);
GO
ALTER TABLE [dbo].[RR_ScenarioYears] CHECK CONSTRAINT [FK_RR_ScenarioYears_Scenarios];
GO



ALTER TABLE dbo.RR_ScenarioTargetBudgets
DROP CONSTRAINT FK_RR_ScenarioTargetBudgets_Scenarios;
GO

ALTER TABLE dbo.RR_ScenarioResultsSummary
DROP CONSTRAINT FK_RR_ScenarioResultsSummary_Scenarios;
GO



--Summary info is added to RR_Scenarios
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [RR_Scenarios] ADD
	[TotalCost] [bigint] NULL,
	[ReplacedCost] [int] NULL,
	[RehabbedCost] [int] NULL,
	[TotalWeight] [bigint] NULL,
	[ReplacedWeight] [bigint] NULL,
	[RehabbedWeight] [bigint] NULL ;
GO


INSERT INTO RR_ScenarioYears
                         (Scenario_ID, BudgetYear, Budget, AllocationToRisk, ActualBudget, OverallCount, OverallWeighting, OverallAgeWeighted, OverallAgeAvg, OverallPhysRawWeighted, OverallPhysRawAvg, OverallPhysScoreWeighted, 
                         OverallPhysScoreAvg, OverallPerfScoreWeighted, OverallPerfScoreAvg, OverallLoFRawWeighted, OverallLoFRawAvg, OverallLoFScoreWeighted, OverallLoFScoreScore, OverallRiskRawWeighted, OverallRiskRawAvg, 
                         OverallRiskScoreWeighted, OverallRiskScoreAvg, ServicedCount, ServicedWeighting, ServicedAgeWeighted, ServicedAgeAvg, ServicedPhysRawWeighted, ServicedPhysRawAvg, ServicedPhysScoreWeighted, 
                         ServicedPhysScoreAvg, ServicedPerfScoreWeighted, ServicedPerfScoreAvg, ServicedLoFRawWeighted, ServicedLoFRawAvg, ServicedLoFScoreWeighted, ServicedLoFScoreAvg, ServicedCoFWeighted, ServicedCoFAvg, 
                         ServicedRiskRawWeighted, ServicedRiskRawAvg, ServicedRiskScoreWeighted, ServicedRiskScoreAvg)
SELECT        Scenario_ID, ScenarioYear, TargetBudget, TargetRiskAllocation, Budget, OverallCount, OverallWeighting, OverallAgeWeighted, OverallAgeAvg, OverallPhysRawWeighted, OverallPhysRawAvg, OverallPhysScoreWeighted, 
                         OverallPhysScoreAvg, OverallPerfScoreWeighted, OverallPerfScoreAvg, OverallLoFRawWeighted, OverallLoFRawAvg, OverallLoFScoreWeighted, OverallLoFScoreScore, OverallRiskRawWeighted, OverallRiskRawAvg, 
                         OverallRiskScoreWeighted, OverallRiskScoreAvg, ServicedCount, ServicedWeighting, ServicedAgeWeighted, ServicedAgeAvg, ServicedPhysRawWeighted, ServicedPhysRawAvg, ServicedPhysScoreWeighted, 
                         ServicedPhysScoreAvg, ServicedPerfScoreWeighted, ServicedPerfScoreAvg, ServicedLoFRawWeighted, ServicedLoFRawAvg, ServicedLoFScoreWeighted, ServicedLoFScoreAvg, ServicedCoFWeighted, ServicedCoFAvg, 
                         ServicedRiskRawWeighted, ServicedRiskRawAvg, ServicedRiskScoreWeighted, ServicedRiskScoreAvg
FROM            v_00_06_ScenarioResults_Detail;
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_06_ScenarioYears]
AS
SELECT	*
FROM	dbo.RR_ScenarioYears;
GO

--v_00_05_ScenarioBudgets must be update for v4 compatability
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_00_05_ScenarioBudgets]
AS
SELECT	BudgetYear_ID, Scenario_ID, BudgetYear, Budget, AllocationToRisk, ConditionTarget, RiskTarget, UseProjectBudget
FROM	dbo.RR_ScenarioYears;
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_07_01_ScenarioYears]
AS
SELECT	dbo.RR_ScenarioYears.Scenario_ID, dbo.RR_ScenarioYears.BudgetYear, dbo.RR_RuntimeAssets.RR_Asset_ID
FROM	dbo.RR_RuntimeAssets INNER JOIN
		dbo.RR_RuntimeConfig ON dbo.RR_RuntimeAssets.Config_ID = dbo.RR_RuntimeConfig.ID INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_RuntimeConfig.CurrentScenario_ID = dbo.RR_ScenarioYears.Scenario_ID;
GO

--Update to use new RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_10_a_ScenarioCurrentYearDetails]
AS
SELECT        dbo.v_10_b_ScenarioCurrentYearDetails.CurrentScenario_ID, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentBudget, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.RR_Asset_ID, dbo.v_10_b_ScenarioCurrentYearDetails.ProjectNumber, dbo.v_10_b_ScenarioCurrentYearDetails.ProjectYear, dbo.v_10_b_ScenarioCurrentYearDetails.InstallYear, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.CurrentInstallYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentAge, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentAgeOffset, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.CurrentFailurePhysOffset, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentEquationType, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentConstIntercept, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.CurrentExpSlope, dbo.v_10_b_ScenarioCurrentYearDetails.StatsCondition, dbo.v_10_b_ScenarioCurrentYearDetails.PrelimPhysRaw, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.ConditionLimit, dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw, dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw, dbo.v_10_b_ScenarioCurrentYearDetails.PerfScore, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.PhysScore, dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore, dbo.v_10_b_ScenarioCurrentYearDetails.RedundancyFactor, dbo.v_10_b_ScenarioCurrentYearDetails.CoF, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R, dbo.v_10_b_ScenarioCurrentYearDetails.CostRepair, dbo.v_10_b_ScenarioCurrentYearDetails.CostRehab, dbo.v_10_b_ScenarioCurrentYearDetails.CostReplace, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.BaseCostReplace, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceEquationType, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceConstIntercept, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceExpSlope, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceEUL, dbo.v_10_b_ScenarioCurrentYearDetails.RehabPercentEUL, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.RepairsRemaining, dbo.v_10_b_ScenarioCurrentYearDetails.RehabsRemaining, dbo.v_10_b_ScenarioCurrentYearDetails.LowRepair, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.HighRepair, dbo.v_10_b_ScenarioCurrentYearDetails.LowRehab, dbo.v_10_b_ScenarioCurrentYearDetails.HighRehab, dbo.v_10_b_ScenarioCurrentYearDetails.LowReplace, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.PerformanceReplace, dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS YearRiskRaw, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS YearRiskScore, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemPhysRaw, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemLoFRaw, 
                         CAST(dbo.v_10_b_ScenarioCurrentYearDetails.PhysScore AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemPhysScore, 
                         CAST(dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemLoFScore, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemCondition, 
                         CAST(dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS float) 
                         * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemRiskScore, 
                         dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemRiskRaw,
                          CASE WHEN [PerfScore] >= [PerformanceReplace] OR
                         [PhysRaw] >= [LowReplace] THEN 'Replace' WHEN [RehabsRemaining] > 0 AND PhysRaw >= [LowRehab] AND [PhysRaw] < [HighRehab] THEN 'Rehab' WHEN [RepairsRemaining] > 0 AND [PhysRaw] >= [LowRepair] AND 
                         [PhysRaw] < [HighRepair] THEN 'Repair' END AS ServiceType, CASE WHEN [PerfScore] >= [PerformanceReplace] OR
                         [PhysRaw] >= [LowReplace] THEN [CostReplace] WHEN [RehabsRemaining] > 0 AND [PhysRaw] >= [LowRehab] AND [PhysRaw] < [HighRehab] THEN [CostRehab] WHEN [RepairsRemaining] > 0 AND 
                         [PhysRaw] >= [LowRepair] AND [PhysRaw] < [HighRepair] THEN [CostRepair] END AS ServiceCost, dbo.RR_ScenarioYears.UseProjectBudget
FROM	dbo.v_10_b_ScenarioCurrentYearDetails INNER JOIN
		dbo.RR_ScenarioYears ON dbo.v_10_b_ScenarioCurrentYearDetails.CurrentScenario_ID = dbo.RR_ScenarioYears.Scenario_ID 
		AND dbo.v_10_b_ScenarioCurrentYearDetails.CurrentYear = dbo.RR_ScenarioYears.BudgetYear;
GO

--Update to use RR_ScenarioYear ActualBudget and maintain v4 compatability
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_70_GraphScenarioResults]
AS
SELECT        Scenario_ID, BudgetYear AS ScenarioYear, ActualBudget / 1000000 AS Budget, OverallLoFRawWeighted AS OverallCondition, OverallRiskScoreWeighted AS OverallRisk
FROM            dbo.RR_ScenarioYears
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_00_06_ScenarioResults_Detail]
AS
SELECT	dbo.RR_Scenarios.Scenario_ID, dbo.RR_Scenarios.ScenarioName, dbo.RR_ScenarioYears.BudgetYear AS ScenarioYear, dbo.RR_ScenarioYears.AllocationToRisk AS TargetRiskAllocation, 
		dbo.RR_ScenarioYears.Budget AS TargetBudget, dbo.RR_ScenarioYears.ActualBudget AS Budget, dbo.RR_ScenarioYears.OverallCount, dbo.RR_ScenarioYears.OverallWeighting / 5280 AS OverallMiles, 
		dbo.RR_ScenarioYears.OverallWeighting, dbo.RR_ScenarioYears.OverallAgeWeighted, dbo.RR_ScenarioYears.OverallAgeAvg, dbo.RR_ScenarioYears.OverallPhysRawWeighted, dbo.RR_ScenarioYears.OverallPhysRawAvg, 
		dbo.RR_ScenarioYears.OverallPhysScoreWeighted, dbo.RR_ScenarioYears.OverallPhysScoreAvg, dbo.RR_ScenarioYears.OverallPerfScoreWeighted, dbo.RR_ScenarioYears.OverallPerfScoreAvg, 
		dbo.RR_ScenarioYears.OverallLoFRawWeighted, dbo.RR_ScenarioYears.OverallLoFRawAvg, dbo.RR_ScenarioYears.OverallLoFScoreWeighted, dbo.RR_ScenarioYears.OverallLoFScoreScore, 
		dbo.RR_ScenarioYears.OverallRiskRawWeighted, dbo.RR_ScenarioYears.OverallRiskRawAvg, dbo.RR_ScenarioYears.OverallRiskScoreWeighted, dbo.RR_ScenarioYears.OverallRiskScoreAvg, 
		dbo.RR_ScenarioYears.ServicedCount, dbo.RR_ScenarioYears.ServicedWeighting / 5280 AS ServicedMiles, dbo.RR_ScenarioYears.ServicedWeighting, dbo.RR_ScenarioYears.ServicedAgeWeighted, 
		dbo.RR_ScenarioYears.ServicedAgeAvg, dbo.RR_ScenarioYears.ServicedPhysRawWeighted, dbo.RR_ScenarioYears.ServicedPhysRawAvg, dbo.RR_ScenarioYears.ServicedPhysScoreWeighted, 
		dbo.RR_ScenarioYears.ServicedPhysScoreAvg, dbo.RR_ScenarioYears.ServicedPerfScoreWeighted, dbo.RR_ScenarioYears.ServicedPerfScoreAvg, dbo.RR_ScenarioYears.ServicedLoFRawWeighted, 
		dbo.RR_ScenarioYears.ServicedLoFRawAvg, dbo.RR_ScenarioYears.ServicedLoFScoreWeighted, dbo.RR_ScenarioYears.ServicedLoFScoreAvg, dbo.RR_ScenarioYears.ServicedCoFWeighted, 
		dbo.RR_ScenarioYears.ServicedCoFAvg, dbo.RR_ScenarioYears.ServicedRiskRawWeighted, dbo.RR_ScenarioYears.ServicedRiskRawAvg, dbo.RR_ScenarioYears.ServicedRiskScoreWeighted, 
		dbo.RR_ScenarioYears.ServicedRiskScoreAvg, dbo.RR_ScenarioYears.BudgetYear AS SortOrder
FROM	dbo.RR_Scenarios INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioYears.Scenario_ID;
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_00_06_ScenarioResults_Totals]
AS
SELECT	dbo.RR_Scenarios.Scenario_ID, dbo.RR_Scenarios.ScenarioName, NULL AS ScenarioYear, 0 AS TargetRiskAllocation, 
		SUM(CAST(dbo.RR_ScenarioYears.Budget AS BIGINT)) AS SumOfTargetBudget, 
		SUM(CAST(dbo.RR_ScenarioYears.ActualBudget AS BIGINT)) AS SumOfBudget, AVG(dbo.RR_ScenarioYears.OverallCount) AS AvgOfOverallCount, 
		AVG(dbo.RR_ScenarioYears.OverallWeighting / 5280) AS AvgOfOverallMiles, 
		SUM(dbo.RR_ScenarioYears.OverallWeighting) AS SumOfOverallWeighting, AVG(dbo.RR_ScenarioYears.OverallAgeWeighted) AS AvgOfOverallAgeWeighted, 
		AVG(dbo.RR_ScenarioYears.OverallAgeAvg) AS AvgOfOverallAgeAvg, 
		AVG(dbo.RR_ScenarioYears.OverallPhysRawWeighted) AS AvgOfOverallPhysRawWeighted, AVG(dbo.RR_ScenarioYears.OverallPhysRawAvg) AS AvgOfOverallPhysRawAvg, 
		AVG(dbo.RR_ScenarioYears.OverallPhysScoreWeighted) AS AvgOfOverallPhysScoreWeighted, AVG(dbo.RR_ScenarioYears.OverallPhysScoreAvg) AS AvgOfOverallPhysScoreAvg, 
		AVG(dbo.RR_ScenarioYears.OverallPerfScoreWeighted) AS AvgOfOverallPerfScoreWeighted, AVG(dbo.RR_ScenarioYears.OverallPerfScoreAvg) AS AvgOfOverallPerfScoreAvg, 
		AVG(dbo.RR_ScenarioYears.OverallLoFRawWeighted) AS AvgOfOverallLoFRawWeighted, AVG(dbo.RR_ScenarioYears.OverallLoFRawAvg) AS AvgOfOverallLoFRawAvg, 
		AVG(dbo.RR_ScenarioYears.OverallLoFScoreWeighted) AS AvgOfOverallLoFScoreWeighted, AVG(dbo.RR_ScenarioYears.OverallLoFScoreScore) AS AvgOfOverallLoFScoreScore, 
		AVG(dbo.RR_ScenarioYears.OverallRiskRawWeighted) AS AvgOfOverallRiskRawWeighted, 
		AVG(dbo.RR_ScenarioYears.OverallRiskRawAvg) AS AvgOfOverallRiskRawAvg, AVG(dbo.RR_ScenarioYears.OverallRiskScoreWeighted) AS AvgOfOverallRiskScoreWeighted, 
		AVG(dbo.RR_ScenarioYears.OverallRiskScoreAvg) AS AvgOfOverallRiskScoreAvg, SUM(dbo.RR_ScenarioYears.ServicedCount) AS SumOfServicedCount, 
		SUM(dbo.RR_ScenarioYears.ServicedWeighting / 5280) AS SumOfServicedMiles, SUM(dbo.RR_ScenarioYears.ServicedWeighting) AS SumOfServicedWeighting, 
		AVG(dbo.RR_ScenarioYears.ServicedAgeWeighted) AS AvgOfServicedAgeWeighted, AVG(dbo.RR_ScenarioYears.ServicedAgeAvg) AS AvgOfServicedAgeAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedPhysRawWeighted) AS AvgOfServicedPhysRawWeighted, AVG(dbo.RR_ScenarioYears.ServicedPhysRawAvg) AS AvgOfServicedPhysRawAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedPhysScoreWeighted) AS AvgOfServicedPhysScoreWeighted, AVG(dbo.RR_ScenarioYears.ServicedPhysScoreAvg) AS AvgOfServicedPhysScoreAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedPerfScoreWeighted) AS AvgOfServicedPerfScoreWeighted, AVG(dbo.RR_ScenarioYears.ServicedPerfScoreAvg) AS AvgOfServicedPerfScoreAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedLoFRawWeighted) AS AvgOfServicedLoFRawWeighted, AVG(dbo.RR_ScenarioYears.ServicedLoFRawAvg) AS AvgOfServicedLoFRawAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedLoFScoreWeighted) AS AvgOfServicedLoFScoreWeighted, AVG(dbo.RR_ScenarioYears.ServicedLoFScoreAvg) AS AvgOfServicedLoFScoreAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedCoFWeighted) AS AvgOfServicedCoFWeighted, AVG(dbo.RR_ScenarioYears.ServicedCoFAvg) AS AvgOfServicedCoFAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedRiskRawWeighted) AS AvgOfServicedRiskRawWeighted, AVG(dbo.RR_ScenarioYears.ServicedRiskRawAvg) AS AvgOfServicedRiskRawAvg, 
		AVG(dbo.RR_ScenarioYears.ServicedRiskScoreWeighted) AS AvgOfServicedRiskScoreWeighted, AVG(dbo.RR_ScenarioYears.ServicedRiskScoreAvg) AS AvgOfServicedRiskScoreAvg, 
		9999 AS SortOrder
FROM	dbo.RR_Scenarios INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_ScenarioYears.Scenario_ID = dbo.RR_Scenarios.Scenario_ID
GROUP BY dbo.RR_Scenarios.Scenario_ID, dbo.RR_Scenarios.ScenarioName;
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_PBI_ScenariosResultsDetails]
AS
SELECT	Format(dbo.RR_ScenarioResults.Scenario_ID + CAST(dbo.RR_ScenarioResults.ScenarioYear AS FLOAT) / 10000, '00.0000') AS [Scenario ID Year], dbo.RR_ScenarioResults.Scenario_ID AS [Scenario ID], 
		dbo.RR_ScenarioResults.ScenarioYear AS [Scenario Year], dbo.RR_ScenarioYears.OverallWeighting AS [Total Weight], dbo.RR_ScenarioYears.OverallCount AS [Total Count], 
		dbo.RR_ScenarioResults.RR_Asset_ID AS [Asset ID], dbo.RR_ScenarioResults.Age, dbo.RR_ScenarioResults.PhysRaw AS [Phys Raw], dbo.RR_ScenarioResults.PhysScore AS [Phys Score], 
		dbo.RR_ScenarioResults.PerfScore AS Perf, dbo.RR_Assets.RR_RedundancyFactor AS [R-Factor], CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END AS LoF, dbo.RR_Assets.RR_CoF_R AS CoF, 
		CASE WHEN RR_ScenarioResults.Service = 'Rehab' THEN 2 WHEN RR_ScenarioResults.Service = 'Replace' THEN 1 ELSE CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END END AS [End LoF], 
		CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.RR_Assets.RR_CoF_R AS [Risk Score], 
		CASE WHEN RR_ScenarioResults.Service = 'Rehab' THEN 2 WHEN RR_ScenarioResults.Service = 'Replace' THEN 1 ELSE CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END END * dbo.RR_Assets.RR_CoF_R AS [End Risk Score], 
		dbo.RR_ScenarioResults.CostOfService AS Cost, dbo.RR_ScenarioResults.Service, dbo.RR_Assets.RR_Length / 5280 AS PipeMiles, dbo.RR_ScenarioResults.RR_Asset_ID AS RR_Pipe_ID, 
		dbo.RR_Assets.RR_Length AS Weight
FROM	dbo.RR_ScenarioResults INNER JOIN
		dbo.RR_Assets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.RR_Assets.RR_Asset_ID INNER JOIN
		dbo.RR_Scenarios ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_Scenarios.Scenario_ID INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_ScenarioYears.Scenario_ID AND dbo.RR_ScenarioResults.ScenarioYear = dbo.RR_ScenarioYears.BudgetYear
WHERE	(dbo.RR_Scenarios.PBI_Flag = 1);
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_PBI_ScenariosResultsSummary]
AS
SELECT	dbo.RR_ScenarioYears.Scenario_ID AS [Scenario ID], 
		dbo.RR_Scenarios.ScenarioName AS [Scenario Name], dbo.RR_Scenarios.Description AS [Scenario Description], dbo.RR_ScenarioYears.BudgetYear AS [Scenario Year], 
		dbo.RR_ScenarioYears.AllocationToRisk AS [Scenario Risk Allocation], dbo.RR_ScenarioYears.Budget AS [Scenario Target Budget], dbo.RR_ScenarioYears.ActualBudget AS [Overall Budget], 
		dbo.RR_ScenarioYears.OverallCount AS [Overall Asset Count], dbo.RR_ScenarioYears.OverallAgeWeighted AS [Ovarall Age], dbo.RR_ScenarioYears.OverallPhysRawWeighted AS [Overall Phys Raw], 
		dbo.RR_ScenarioYears.OverallPhysScoreWeighted AS [Overall Phys Score], dbo.RR_ScenarioYears.OverallPerfScoreWeighted AS [Overall Perf Score], dbo.RR_ScenarioYears.OverallLoFRawWeighted AS [Overall LoF Raw], 
		dbo.RR_ScenarioYears.OverallLoFScoreWeighted AS [Overall LoF Score], dbo.RR_ScenarioYears.OverallRiskRawWeighted AS [Overall Risk Raw], dbo.RR_ScenarioYears.OverallRiskScoreWeighted AS [Overall Risk Score], 
		dbo.RR_ScenarioYears.ServicedCount AS [Serviced Count], ROUND(dbo.RR_ScenarioYears.ServicedWeighting / 5280, 2) AS [Serviced Miles], dbo.RR_ScenarioYears.ServicedAgeWeighted AS [Serviced Age], 
		dbo.RR_ScenarioYears.ServicedPhysRawWeighted AS [Serviced Phys Raw], dbo.RR_ScenarioYears.ServicedPhysScoreWeighted AS [Serviced Phys Score], 
		dbo.RR_ScenarioYears.ServicedPerfScoreWeighted AS [Serviced Perf Score], dbo.RR_ScenarioYears.ServicedLoFRawWeighted AS [Serviced LoF Raw], 
		dbo.RR_ScenarioYears.ServicedLoFScoreWeighted AS [Serviced LoF Score], dbo.RR_ScenarioYears.ServicedCoFWeighted AS [Serviced CoF], dbo.RR_ScenarioYears.ServicedRiskRawWeighted AS [Serviced Risk Raw], 
		dbo.RR_ScenarioYears.ServicedRiskScoreWeighted AS [Serviced Risk Score]
FROM	dbo.RR_Scenarios INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioYears.Scenario_ID
WHERE	(dbo.RR_Scenarios.PBI_Flag = 1);
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_07_InitializeScenarioResultsForAllYears]
AS
BEGIN

	SET NOCOUNT ON;

	--Ensure UseProjectBudget is not null
	UPDATE	RR_ScenarioYears
	SET		UseProjectBudget = 0 
	WHERE	UseProjectBudget IS NULL;

	-- Delete all results for the current scenario
	DELETE FROM RR_ScenarioResults
	FROM	RR_ScenarioResults INNER JOIN RR_RuntimeConfig ON RR_ScenarioResults.Scenario_ID = RR_RuntimeConfig.CurrentScenario_ID;

END
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10_ScenarioYearLoF] 
AS
BEGIN

	DECLARE @iScenarioID int = 0  
	DECLARE @iCurrentYear int = 0  
	DECLARE @iAssetID int = 0  
	DECLARE @iServiceCost int = 0  
	DECLARE @sServiceType nvarchar(8) = ''  

	DECLARE @AllocationToRisk int = 0
	DECLARE @iBudget int = 0  
	DECLARE @fTargetCondition float = 0  
	DECLARE @fTargetRisk float = 0  
	DECLARE @fCurrentCondition float = 0  
	DECLARE @fCurrentRisk float = 0 
	DECLARE @iReducedBudget int = 0  
	DECLARE @fReducedCondition float = 0  
	DECLARE @fReducedRisk float = 0  
	DECLARE @i int = 0

	DECLARE @iRiskBudget int = 0  
	
	SET NOCOUNT ON;

	--Get scenario targets
	SELECT	@iScenarioID = RR_RuntimeConfig.CurrentScenario_ID,
			@iCurrentYear = RR_RuntimeConfig.CurrentYear, 
			@AllocationToRisk = RR_ScenarioYears.AllocationToRisk,
			@iBudget = RR_ScenarioYears.Budget, --* (1 - RR_ScenarioYears.AllocationToRisk), 
			@fTargetCondition = RR_ScenarioYears.ConditionTarget, 
			@fTargetRisk = RR_ScenarioYears.RiskTarget
	FROM	RR_ScenarioYears INNER JOIN RR_RuntimeConfig ON RR_ScenarioYears.Scenario_ID = RR_RuntimeConfig.CurrentScenario_ID AND RR_ScenarioYears.BudgetYear = RR_RuntimeConfig.CurrentYear;

	--Get budget previously spent on rsik
	SELECT	@iRiskBudget = Sum(CostOfService)
	FROM	RR_ScenarioResults
	WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @iCurrentYear;

	insert into rr_TraceX (trace_Step, trace_details) VALUES (-20, @iBudget);

	--Get the highest priority asset if budget has not already been spent on Risk
	IF @iRiskBudget = 0 
		SELECT	TOP (1)
				@iAssetID = RR_Asset_ID, 
				@iServiceCost = ServiceCost, 
				@sServiceType = ServiceType
		FROM	v_10_01_ScenarioCurrentYear_RR_Assets
		ORDER BY LoFScore DESC, LoFRaw DESC, SystemRiskScore DESC, RR_Asset_ID;
	ELSE 
		SELECT @iBudget = @iBudget - @iRiskBudget;

	--If the highest priority asset is more expensive than budget then perform the service on that asset only
	IF @iAssetID > 0 AND @iServiceCost >= @iBudget  BEGIN

		insert into rr_TraceX (trace_Step, trace_details) VALUES (-10, @iServiceCost);

		UPDATE	RR_ScenarioResults
		SET		CostOfService = @iServiceCost, 
				Service = @sServiceType
		WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @iCurrentYear AND  RR_Asset_ID = @iAssetID;

		UPDATE	v__RuntimeResults
		SET		CurrentInstallYear = CASE WHEN  @sServiceType = 'Replace' THEN  v__RuntimeResults.CurrentYear  ELSE CurrentInstallYear END   , 
				CurrentEquationType = CASE WHEN  @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceEquationType  ELSE CurrentEquationType END,  
				CurrentConstIntercept =  CASE WHEN  @sServiceType = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
				CurrentExpSlope = CASE WHEN  @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope   ELSE  CurrentExpSlope END, 
				CurrentFailurePhysOffset = CASE WHEN  @sServiceType = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
				CurrentAgeOffset = CASE WHEN  @sServiceType = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
				CurrentPerformance =  CASE WHEN  @sServiceType = 'Replace' THEN  1 ELSE  CurrentPerformance END, 
				RepairsRemaining =  CASE WHEN  @sServiceType = 'Repair' THEN  RepairsRemaining - 1    ELSE   v__RuntimeResults.RepairsAllowed END, 
				RehabsRemaining =  CASE WHEN  @sServiceType = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
		WHERE	RR_Asset_ID = @iAssetID ;

		SELECT @iBudget = 0; --This prevents more assets from being serviced
	END

	--If highest priority assets are within budget, process them
	IF @iBudget >0 BEGIN

		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, @iBudget);

		UPDATE RR_RuntimeConfig SET CurrentBudget = @iBudget;

		SELECT @fCurrentCondition = Cond, @fCurrentRisk = Risk FROM v_20_00_ScenerioYearConditionRisk;

		SELECT	@iReducedBudget = MAX(RunningCost), @fReducedRisk = MAX(RunningRisk), @fReducedCondition = MAX(RunningCondition)
		FROM	v_10_00_Running_LoF
		WHERE	RunningCost <= @iBudget AND 
				RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
				RunningCondition <=  @fCurrentCondition - @fTargetCondition  ;

		EXEC p_10a_ScenarioYearLoFUpdate @iBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

	    SELECT @iBudget = @iBudget - @iReducedBudget,  @fCurrentCondition = @fCurrentCondition - @fReducedCondition, @fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		--Continue to process remaining priority assets up to 10 iterations or with $1,000 of target budget
		WHILE @iBudget > 1000 AND @fCurrentCondition > @fTargetCondition AND @fCurrentRisk > @fTargetRisk AND @i < 10 BEGIN

			SELECT @i = @i + 1
			
			insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, @iBudget);

			UPDATE RR_RuntimeConfig SET CurrentBudget = @iBudget;

			SELECT	@iReducedBudget = MAX(RunningCost), @fReducedRisk = MAX(RunningRisk), @fReducedCondition = MAX(RunningCondition)
			FROM	v_10_00_Running_LoF
			WHERE	RunningCost <= @iBudget AND 
					RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
					RunningCondition <= @fCurrentCondition - @fTargetCondition 	;

			EXEC p_10a_ScenarioYearLoFUpdate @iBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

		    SELECT @iBudget = @iBudget - @iReducedBudget,  @fCurrentCondition = @fCurrentCondition - @fReducedCondition, @fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		END
	END
END
GO

--Update to use RR_ScenarioYear
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10_ScenarioYearRisk] 
AS
BEGIN

	DECLARE @iScenarioID int = 0  
	DECLARE @iCurrentYear int = 0  
	DECLARE @iAssetID int = 0  
	DECLARE @iServiceCost int = 0  
	DECLARE @sServiceType nvarchar(8) = ''  

	DECLARE @iBudget int = 0  
	DECLARE @fTargetCondition float = 0  
	DECLARE @fTargetRisk float = 0  
	DECLARE @fCurrentCondition float = 0  
	DECLARE @fCurrentRisk float = 0 
	DECLARE @iReducedBudget int = 0  
	DECLARE @fReducedCondition float = 0  
	DECLARE @fReducedRisk float = 0  
	DECLARE @i int = 0
	
	SET NOCOUNT ON;

	SELECT	@iBudget = RR_ScenarioYears.Budget * RR_ScenarioYears.AllocationToRisk, 
			@fTargetCondition = RR_ScenarioYears.ConditionTarget, 
			@fTargetRisk = RR_ScenarioYears.RiskTarget
	FROM	RR_ScenarioYears INNER JOIN RR_RuntimeConfig ON RR_ScenarioYears.Scenario_ID = RR_RuntimeConfig.CurrentScenario_ID AND RR_ScenarioYears.BudgetYear = RR_RuntimeConfig.CurrentYear;


	--Get the highest priority asset
	SELECT	TOP (1)
			@iScenarioID = CurrentScenario_ID,
			@iCurrentYear = CurrentYear, 
			@iAssetID = RR_Asset_ID, 
			@iServiceCost = ServiceCost, 
			@sServiceType = ServiceType
	FROM	v_10_01_ScenarioCurrentYear_RR_Assets
	ORDER BY YearRiskScore DESC, YearRiskRaw DESC, SystemRiskScore DESC, RR_Asset_ID;

	--If the highest priority asset is more expensive than budget then perform the service on that asset only
	IF @iAssetID > 0 AND @iServiceCost >= @iBudget  BEGIN

		insert into rr_TraceX (trace_Step, trace_details) VALUES (-10, @iServiceCost);

		UPDATE	RR_ScenarioResults
		SET		CostOfService = @iServiceCost, 
				Service = @sServiceType
		WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @iCurrentYear AND  RR_Asset_ID = @iAssetID;

		UPDATE	v__RuntimeResults
		SET		CurrentInstallYear = CASE WHEN  @sServiceType = 'Replace' THEN  v__RuntimeResults.CurrentYear  ELSE CurrentInstallYear END   , 
				CurrentEquationType = CASE WHEN  @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceEquationType  ELSE CurrentEquationType END,  
				CurrentConstIntercept =  CASE WHEN  @sServiceType = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
				CurrentExpSlope = CASE WHEN  @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope   ELSE  CurrentExpSlope END, 
				CurrentFailurePhysOffset = CASE WHEN  @sServiceType = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
				CurrentAgeOffset = CASE WHEN  @sServiceType = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
				CurrentPerformance =  CASE WHEN  @sServiceType = 'Replace' THEN  1 ELSE  CurrentPerformance END, 
				RepairsRemaining =  CASE WHEN  @sServiceType = 'Repair' THEN  RepairsRemaining - 1    ELSE   v__RuntimeResults.RepairsAllowed END, 
				RehabsRemaining =  CASE WHEN  @sServiceType = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
		WHERE	RR_Asset_ID = @iAssetID ;

		Select @iBudget = 0; --This prevents more assets from being serviced
	END

	--If highest priority assets are within budget, process them
	IF @iBudget >0 BEGIN

		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, @iBudget);

		UPDATE RR_RuntimeConfig SET CurrentBudget = @iBudget;

		SELECT @fCurrentCondition = Cond, @fCurrentRisk = Risk FROM v_20_00_ScenerioYearConditionRisk;

		SELECT	@iReducedBudget = MAX(RunningCost), @fReducedRisk = MAX(RunningRisk), @fReducedCondition = MAX(RunningCondition)
		FROM	v_10_00_Running_Risk
		WHERE	RunningCost <= @iBudget AND 
				RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
				RunningCondition <=  @fCurrentCondition - @fTargetCondition  ;

		EXEC p_10a_ScenarioYearRiskUpdate @iBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

	    SELECT @iBudget = @iBudget - @iReducedBudget,  @fCurrentCondition = @fCurrentCondition - @fReducedCondition, @fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		--Continue to process remaining priority assets up to 10 iterations or with $1,000 of target budget
		WHILE @iBudget > 1000 AND @fCurrentCondition > @fTargetCondition AND @fCurrentRisk > @fTargetRisk AND @i < 10 BEGIN

			SELECT @i = @i + 1
			
			insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, @iBudget);

			UPDATE RR_RuntimeConfig SET CurrentBudget = @iBudget;

			SELECT	@iReducedBudget = MAX(RunningCost), @fReducedRisk = MAX(RunningRisk), @fReducedCondition = MAX(RunningCondition)
			FROM	v_10_00_Running_Risk
			WHERE	RunningCost <= @iBudget AND 
					RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
					RunningCondition <= @fCurrentCondition - @fTargetCondition 	;

			EXEC p_10a_ScenarioYearRiskUpdate @iBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

		    SELECT @iBudget = @iBudget - @iReducedBudget,  @fCurrentCondition = @fCurrentCondition - @fReducedCondition, @fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		END
	END
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_14_ScenarioSummary]
AS
	SELECT	dbo.RR_Scenarios.Scenario_ID,
			SUM(CAST(dbo.RR_ScenarioResults.CostOfService AS bigint)) AS TotalCost, 
			SUM(dbo.v__ActiveAssets.Weighting) AS TotalWeight, 
			SUM(CASE WHEN service = 'Replace' THEN costofservice ELSE 0 END) AS TotalReplaceCost, 
			SUM(CASE WHEN service = 'Rehab' THEN costofservice ELSE 0 END) AS TotalRehabCost, 
			SUM(CASE WHEN service = 'Replace' THEN Weighting ELSE 0 END) AS TotalReplacedAssets, 
			SUM(CASE WHEN service = 'Rehab' THEN Weighting ELSE 0 END) AS TotalRehabbedAssets
	FROM	dbo.RR_Scenarios INNER JOIN
			dbo.RR_ScenarioResults ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioResults.Scenario_ID INNER JOIN
			dbo.v__ActiveAssets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID
	WHERE	(dbo.RR_ScenarioResults.CostOfService > 0)
	GROUP BY dbo.RR_Scenarios.Scenario_ID
GO

--Update to use RR_ScenarioYear adn additional RR_Scenario summary fields
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_14_Results_Summary_Update]
AS
BEGIN

	SET NOCOUNT ON;
	
	UPDATE	[RR_ScenarioYears]
	SET		[ActualBudget] = a.[Cost]
			, [OverallCount] = a.[TotalCount]
			, [OverallWeighting] = a.[TotalWeighting]
			, [OverallAgeWeighted] = a.[TotalAgeWeighted]/[TotalWeighting]
			, [OverallAgeAvg] = a.[TotalAgeAvg]
			, [OverallPhysRawWeighted] = a.[TotalPhysRawWeighted]/[TotalWeighting]
			, [OverallPhysRawAvg] = a.[TotalPhysRawAvg]
			, [OverallPhysScoreWeighted] = a.[TotalPhysScoreWeighted]/[TotalWeighting]
			, [OverallPhysScoreAvg] = a.[TotalPhysScoreAvg]
			, [OverallPerfScoreWeighted] = a.[TotalPerfScoreWeighted]/[TotalWeighting] 
			, [OverallPerfScoreAvg] = a.[TotalPerfScoreAvg]
			, [OverallLoFRawWeighted] = a.[TotalLoFRawWeighted]/[TotalWeighting]
			, [OverallLoFRawAvg] = a.[TotalLoFRawAvg]
			, [OverallLoFScoreWeighted] = a.[TotalLoFScoreWeighted]/[TotalWeighting]
			, [OverallLoFScoreScore] = a.[TotalLoFScoreAvg]
			, [OverallRiskRawWeighted] = a.[TotalRiskRawWeighted]/[TotalWeighting]
			, [OverallRiskRawAvg] = a.[TotalRiskRawAvg]
			, [OverallRiskScoreWeighted] = a.[TotalRiskScoreWeighted]/[TotalWeighting]
			, [OverallRiskScoreAvg] = a.[TotalRiskScoreAvg]
			, [ServicedCount] = a.[ReplacedCount]
			, [ServicedWeighting] = a.[ReplacedWeighting]
			, [ServicedAgeWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedAgeWeighted]/[ReplacedWeighting])
			, [ServicedAgeAvg] = a.[ReplacedAgeAvg]
			, [ServicedPhysRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysRawWeighted]/[ReplacedWeighting])
			, [ServicedPhysRawAvg] = a.[ReplacedPhysRawAvg]
			, [ServicedPhysScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysScoreWeighted]/[ReplacedWeighting])
			, [ServicedPhysScoreAvg] = a.[ReplacedPhysScoreAvg]
			, [ServicedPerfScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPerfScoreWeighted]/[ReplacedWeighting])
			, [ServicedPerfScoreAvg] = a.[ReplacedPerfScoreAvg]
			, [ServicedLoFRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFRawWeighted]/[ReplacedWeighting])
			, [ServicedLoFRawAvg] = a.[ReplacedLoFRawAvg]
			, [ServicedLoFScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFScoreWeighted]/[ReplacedWeighting])
			, [ServicedLoFScoreAvg] = a.[ReplacedLoFScoreAvg]
			, [ServicedCoFWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedCoFWeighted]/[ReplacedWeighting])
			, [ServicedCoFAvg] = a.[ReplacedCoFAvg]
			, [ServicedRiskRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskRawWeighted]/[ReplacedWeighting])
			, [ServicedRiskRawAvg] = a.[ReplacedRiskRawAvg]
			, [ServicedRiskScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskScoreWeighted]/[ReplacedWeighting])
			, [ServicedRiskScoreAvg] = a.[ReplacedRiskScoreAvg]
	FROM [v_14_Results_Summary] AS a
	INNER JOIN [RR_ScenarioYears] 
		ON ([a].[Scenario_ID] = [RR_ScenarioYears].[Scenario_ID]) 
		AND ([a].[ScenarioYear] = [RR_ScenarioYears].[BudgetYear]);

	UPDATE	RR_Scenarios
	SET		TotalCost = v_14_ScenarioSummary.TotalCost,
			ReplacedCost = v_14_ScenarioSummary.TotalReplaceCost, 
			RehabbedCost = v_14_ScenarioSummary.TotalRehabCost, 
			TotalWeight = v_14_ScenarioSummary.TotalWeight, 
			ReplacedWeight = v_14_ScenarioSummary.TotalReplacedAssets, 
			RehabbedWeight = v_14_ScenarioSummary.TotalRehabbedAssets
	FROM	v_14_ScenarioSummary INNER JOIN
			RR_Scenarios ON v_14_ScenarioSummary.Scenario_ID = RR_Scenarios.Scenario_ID;

	UPDATE RR_RuntimeConfig set StartedOn = NULL;

END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--New v5 procudeure to add scenarios
CREATE OR ALTER PROCEDURE [dbo].[p_00_06_Scenario]
	@Name nvarchar(64),
	@Year int
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO RR_Scenarios (ScenarioName, StartYear) VALUES (@Name, @Year);
END

--New v5 procudeure to add scenarios years
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[p_00_06_ScenarioYears]
	@ID Int,
	@Year int,
	@Budget int,
	@RiskAlloc float,
	@ConditionTarget float,
	@RiskTarget float,
	@ProjectBudget bit
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO RR_ScenarioYears (Scenario_ID, BudgetYear, Budget, AllocationToRisk, ConditionTarget, RiskTarget, UseProjectBudget)
	VALUES (@ID, @Year, @Budget, @RiskAlloc, @ConditionTarget, @RiskTarget, @ProjectBudget);
END
GO

--Update to use RR_ScenarioYear and additional RR_Scenario summary fields
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE p_19_DeleteScenario
	@ScenarioID int
AS
BEGIN

	SET NOCOUNT ON;

	DELETE FROM RR_ScenarioResults WHERE Scenario_ID = @ScenarioID;

	DELETE FROM RR_ScenarioYears WHERE Scenario_ID = @ScenarioID;

	UPDATE RR_Config SET CurrentScenario_ID = null;

	DELETE FROM RR_Scenarios WHERE Scenario_ID = @ScenarioID;

END
GO

--Update to hardcode 5 level hierarchy while maintaining application code compatability to 8 levels
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_00_07_HierarchyTree]
AS
SELECT	H1.RR_Hierarchy_ID AS ID1, H2.RR_Hierarchy_ID AS ID2, H3.RR_Hierarchy_ID AS ID3, H4.RR_Hierarchy_ID AS ID4, H5.RR_Hierarchy_ID AS ID5, NULL AS ID6, NULL AS ID7, NULL AS ID8, 
		H1.RR_Parent_ID AS P1, H2.RR_Parent_ID AS P2, H3.RR_Parent_ID AS P3, H4.RR_Parent_ID AS P4, H5.RR_Parent_ID AS P5, NULL AS P6, NULL AS P7, NULL AS P8, 
		H1.RR_HierarchyName AS Name1, H2.RR_HierarchyName AS Name2, H3.RR_HierarchyName AS Name3, H4.RR_HierarchyName AS Name4, H5.RR_HierarchyName AS Name5, NULL AS Name6, NULL AS Name7, NULL AS Name8, 
		COUNT(A1.RR_Asset_ID) AS AssetCount1, COUNT(A2.RR_Asset_ID) AS AssetCount2, COUNT(A3.RR_Asset_ID) AS AssetCount3, COUNT(A4.RR_Asset_ID) AS AssetCount4, COUNT(A5.RR_Asset_ID) AS AssetCount5, NULL AS AssetCount6, NULL AS AssetCount7, NULL AS AssetCount8
FROM	dbo.RR_Hierarchy AS H1 LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H2 ON H1.RR_Hierarchy_ID = H2.RR_Parent_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H3 ON H2.RR_Hierarchy_ID = H3.RR_Parent_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H4 ON H3.RR_Hierarchy_ID = H4.RR_Parent_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H5 ON H4.RR_Hierarchy_ID = H5.RR_Parent_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A1 ON H1.RR_Hierarchy_ID = A1.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A2 ON H2.RR_Hierarchy_ID = A2.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A3 ON H3.RR_Hierarchy_ID = A3.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A4 ON H4.RR_Hierarchy_ID = A4.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A5 ON H5.RR_Hierarchy_ID = A5.RR_Hierarchy_ID 
GROUP BY H1.RR_Hierarchy_ID, H2.RR_Hierarchy_ID, H3.RR_Hierarchy_ID, H4.RR_Hierarchy_ID, H5.RR_Hierarchy_ID, 
		H1.RR_Parent_ID, H2.RR_Parent_ID, H3.RR_Parent_ID, H4.RR_Parent_ID, H5.RR_Parent_ID, 
		H1.RR_HierarchyName, H2.RR_HierarchyName, H3.RR_HierarchyName, H4.RR_HierarchyName, H5.RR_HierarchyName
HAVING	(H1.RR_Parent_ID IS NULL)
GO

--New v5 view to support hierarchy and asset tree view
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_00_07_HierarchyAssetTree]
AS
	SELECT	DISTINCT 1 AS LEVEL, P1 AS PID, CONCAT(ID1, '') AS ID, CONCAT('H', ID1) AS Label, Name1 AS Name, AssetCount1 AS Cnt
	FROM	v_00_07_HierarchyTree
	WHERE	ID1 IS NOT NULL
	UNION ALL
	SELECT	DISTINCT 2 AS LEVEL, P2 AS PID, CONCAT(ID2, '') AS ID, CONCAT('H', ID2) AS Label, Name2 AS Name, AssetCount2 AS Cnt
	FROM	v_00_07_HierarchyTree
	WHERE	ID2 IS NOT NULL
	UNION ALL
	SELECT	DISTINCT 3 AS LEVEL, P3 AS PID, CONCAT(ID3, '') AS ID, CONCAT('H', ID3) AS Label, Name3 AS Name, AssetCount3 AS Cnt
	FROM	v_00_07_HierarchyTree
	WHERE	ID3 IS NOT NULL
	UNION ALL
	SELECT	DISTINCT 4 AS LEVEL, P4 AS PID, CONCAT(ID4, '') AS ID, CONCAT('H', ID4) AS Label, Name4 AS Name, AssetCount4 AS Cnt
	FROM	v_00_07_HierarchyTree
	WHERE	ID4 IS NOT NULL
	UNION ALL
	SELECT	DISTINCT 5 AS LEVEL, P5 AS PID, CONCAT(ID5, '') AS ID, CONCAT('H', ID5) AS Label, Name5 AS Name, AssetCount5 AS Cnt
	FROM	v_00_07_HierarchyTree
	WHERE	ID5 IS NOT NULL
	UNION ALL
	SELECT	6 AS LEVEL, RR_Hierarchy_ID AS PID, CONCAT('A', RR_Asset_ID) AS ID, CONCAT('A', RR_Asset_ID) AS Label, RR_AssetName AS Name, 0 AS Cnt
	FROM	v__ActiveAssets
GO


--Update to changed field names related to RR_ScenarioYears

UPDATE	RR_ConfigQueries
SET		QueryName = 'v_00_06_ScenarioYears',
		SortBy = 'BudgetYear'
WHERE	Category_ID = 106 AND QueryName = 'v_00_06_ScenarioResults';


UPDATE	RR_ConfigTableLookup
SET		ColumnName = 'BudgetYear'
WHERE	TableName = 'Results' AND ColumnName = 'ScenarioYear';

UPDATE	RR_ConfigTableLookup
SET		ColumnName = 'AllocationToRisk'
WHERE	TableName = 'Results' AND ColumnName = 'TargetRiskAllocation';

UPDATE	RR_ConfigTableLookup
SET		ColumnName = 'ActualBudget'
WHERE	TableName = 'Results' AND ColumnName = 'Budget';

UPDATE	RR_ConfigTableLookup
SET		ColumnName = 'Budget'
WHERE	TableName = 'Results' AND ColumnName = 'TargetBudget';


--Update for RR_ScenarioYears 

INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'Scenario_ID', N'ID', 1, -1, 32, N'#', 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'ScenarioName', N'Name', 2, 150, 16, NULL, 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'Description', N'Description', 3, 200, 16, NULL, 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'PBI_Flag', N'PBI', 4, 50, 32, N'TrueFalse', 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'LastRun', N'Last Run', 5, 120, 64, NULL, 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'TotalCost', N'Total Cost', 6, 80, 64, N'$#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'ReplacedCost', N'Replace Cost', 7, 80, 64, N'$#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'RehabbedCost', N'Rehab Cost', 8, 80, 64, N'$#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'TotalWeight', N'Total Length (ft)', 9, 75, 64, N'#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'ReplacedWeight', N'Replace Length (ft)', 10, 75, 64, N'#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'RehabbedWeight', N'Rehab Length (ft)', 11, 75, 64, N'#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'BudgetYear_ID', N'ID', 1, -1, 16, NULL, 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'Scenario_ID', N'SID', 2, 30, 32, NULL, 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'BudgetYear', N'Year', 3, 50, 32, NULL, 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'Budget', N'Budget Target', 4, 50, 64, N'$#,##0', 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'AllocationToRisk', N'Risk Allocation', 5, 50, 64, N'#%', 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ConditionTarget', N'Raw Phys Target', 6, 50, 64, NULL, 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'RiskTarget', N'Risk Target', 7, 50, 64, NULL, 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'UseProjectBudget', N'Use Projects', 8, 50, 32, N'TrueFalse', 1, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ActualBudget', N'Budget Used', 9, 75, 64, N'$#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallAgeWeighted', N'System Avg Age', 10, 60, 64, N'#,##0.0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallPhysRawWeighted', N'System Physical Raw', 11, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallPhysScoreWeighted', N'System Physical Score', 12, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallPerfScoreWeighted', N'System Perf Score', 13, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallLoFScoreWeighted', N'System LoF Score', 14, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallRiskRawWeighted', N'System Risk Raw', 15, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallRiskScoreWeighted', N'System Risk Score', 16, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'OverallCount', N'System Assets', 17, 60, 64, N'#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedCount', N'Serviced Assets', 18, 60, 64, N'#,##0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedAgeWeighted', N'Serviced Avg Age', 19, 60, 64, N'#,##0.0', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedPhysRawWeighted', N'Serviced Physical Raw', 20, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedPhysScoreWeighted', N'Serviced Physical Score', 21, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedPerfScoreWeighted', N'Serviced Perf Score', 22, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedLoFScoreWeighted', N'Serviced LoF Score', 23, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedCoFWeighted', N'Serviced CoF', 24, 60, 64, N'#,##0.00', 0, 0)
INSERT [dbo].[RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'ScenarioYears', N'ServicedRiskScoreWeighted', N'Serviced Risk Score', 25, 60, 64, N'#,##0.00', 0, 0)
GO

--SET IDENTITY_INSERT [dbo].[RR_ConfigTableLookup] OFF
--GO

INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (17, N'01. Report (Quality Control)', 1, N'v_QC__Status', 'sortOrder', N'RRPS Status', N'Failed to report RRPS status', N'Reports the RRPS configuration stats.', 0)
INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (17, N'01. Report (Quality Control)', 4, N'v_QC__DatabaseConnections', NULL, N'Current Database Connections', N'Failed to report current database connections', N'List of users currently connected to the database', 1)
UPDATE [RR_ConfigQueries] SET [RunOrder] = 2 WHERE [QueryName] = 'v_QC_Loaded_ActiveAssets'
UPDATE [RR_ConfigQueries] SET [RunOrder] = 3 WHERE [QueryName] = 'v_QC_Stats_Cohorts'

INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (40, N'40. Add scenario name (Add Scenario)', 1, N'p_00_06_Scenario', NULL, N'Adding scenario…', N'Failed to add scenario', N'Inserts into RR_Scenarios.', 0)
INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (41, N'41. Add scenario years (Add Scenario)', 1, N'p_00_06_ScenarioYears', NULL, N'Adding scenario years…', N'Failed to add scenario years', N'Inserts into RR_ScenarioYears.', 0)

INSERT [RR_ConfigCategories] ([Category_ID] ,[FunctionGroup] ,[Category] ,[MultipleRecords]) VALUES (300, 'Heierarchy Asset Tree', '00. Initialize', 'Only one record is allowed')
INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (300, N'00. Initialize (Heierarchy Asset Tree)', 1, N'v_00_07_HierarchyAssetTree', 'HName1, HName2, HName3, HName4, HName5, HName6, HName7', N'Populating Hierarchy Tree...', N'Failed to populate hierarchy tree', NULL, 0)

GO

UPDATE RR_CONFIG SET VERSION = 5.001;
GO







--v5.002 update for Cost Override

--Percentage of total budget fields are added to RR_Projects
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Projects] ADD
	[OverrideCost] [int] NULL,
	[Year1Pcnt] [float] NULL,
	[Year2Pcnt] [float] NULL,
	[Year3Pcnt] [float] NULL,
	[Year4Pcnt] [float] NULL,
	[RR_Year_Avg_Risk] [float] NULL,
	[RR_Year_Avg_LoF] [float] NULL,
	[RR_Year_Avg_LoF_PhysRaw] [float] NULL;
GO

UPDATE	RR_Projects
SET		[Year1Pcnt] = 1,
		[Year2Pcnt] = 0,
		[Year3Pcnt] = 0,
		[Year4Pcnt] = 0;
GO

ALTER TABLE [dbo].[RR_Projects] ADD  CONSTRAINT [DF_RR_Projects_Year1Pcnt]  DEFAULT ((1)) FOR [Year1Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects] ADD  CONSTRAINT [DF_RR_Projects_Year2Pcnt]  DEFAULT ((0)) FOR [Year2Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects] ADD  CONSTRAINT [DF_RR_Projects_Year3Pcnt]  DEFAULT ((0)) FOR [Year3Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects] ADD  CONSTRAINT [DF_RR_Projects_Year4Pcnt]  DEFAULT ((0)) FOR [Year4Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects]  WITH CHECK ADD  CONSTRAINT [CK_RR_Projects_Year1Pcnt] CHECK  (([Year1Pcnt]<=(1) AND [Year1Pcnt]>(0)))
GO
ALTER TABLE [dbo].[RR_Projects] CHECK CONSTRAINT [CK_RR_Projects_Year1Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects]  WITH CHECK ADD  CONSTRAINT [CK_RR_Projects_Year2Pcnt] CHECK  (([Year2Pcnt]<(1) AND [Year2Pcnt]>=(0)))
GO
ALTER TABLE [dbo].[RR_Projects] CHECK CONSTRAINT [CK_RR_Projects_Year2Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects]  WITH CHECK ADD  CONSTRAINT [CK_RR_Projects_Year3Pcnt] CHECK  (([Year3Pcnt]<(1) AND [Year3Pcnt]>=(0)))
GO
ALTER TABLE [dbo].[RR_Projects] CHECK CONSTRAINT [CK_RR_Projects_Year3Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects]  WITH CHECK ADD  CONSTRAINT [CK_RR_Projects_Year4Pcnt] CHECK  (([Year4Pcnt]<(1) AND [Year4Pcnt]>=(0)))
GO
ALTER TABLE [dbo].[RR_Projects] CHECK CONSTRAINT [CK_RR_Projects_Year4Pcnt]
GO
ALTER TABLE [dbo].[RR_Projects]  WITH CHECK ADD  CONSTRAINT [CK_RR_Projects_YearPcnt] CHECK  ((((([Year1Pcnt]+[Year2Pcnt])+[Year3Pcnt])+[Year4Pcnt])=(1)))
GO
ALTER TABLE [dbo].[RR_Projects] CHECK CONSTRAINT [CK_RR_Projects_YearPcnt]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Projects]
ALTER COLUMN [Year1Pcnt] [float] NOT NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Projects]
ALTER COLUMN [Year2Pcnt] [float] NOT NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Projects]
ALTER COLUMN [Year3Pcnt] [float] NOT NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Projects]
ALTER COLUMN [Year4Pcnt] [float] NOT NULL;
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_14_Results_Summary_ProjectOverrideCosts]
AS
SELECT	dbo.RR_ScenarioYears.Scenario_ID, dbo.RR_ScenarioYears.BudgetYear, 
		SUM(ISNULL(dbo.RR_Projects.OverrideCost, dbo.RR_Projects.ProjectCost) - ISNULL(dbo.RR_Projects.ProjectCost, 0)) AS CostDiff, 
		SUM(dbo.RR_Projects.ProjectCost) AS ProjectCost
FROM	dbo.RR_Projects INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_Projects.ProjectYear = dbo.RR_ScenarioYears.BudgetYear
WHERE	(dbo.RR_ScenarioYears.UseProjectBudget = 1) AND (dbo.RR_Projects.Active = 1)
GROUP BY dbo.RR_ScenarioYears.Scenario_ID, dbo.RR_ScenarioYears.BudgetYear
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_14_Results_Summary]
AS
SELECT	dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear, SUM(1) AS TotalCount, SUM(dbo.v__ActiveAssets.Weighting) AS TotalWeighting, 
		SUM(CAST(dbo.RR_ScenarioResults.Age * dbo.v__ActiveAssets.Weighting AS float)) AS TotalAgeWeighted, AVG(CAST(dbo.RR_ScenarioResults.Age AS FLOAT)) AS TotalAgeAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PhysRaw * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPhysRawWeighted, AVG(dbo.RR_ScenarioResults.PhysRaw) AS TotalPhysRawAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PhysScore * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPhysScoreWeighted, AVG(CAST(dbo.RR_ScenarioResults.PhysScore AS FLOAT)) AS TotalPhysScoreAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PerfScore * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPerfScoreWeighted, AVG(dbo.RR_ScenarioResults.PerfScore) AS TotalPerfScoreAvg, 
		SUM(CAST(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.Weighting AS float)) AS TotalLoFRawWeighted, 
		AVG(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END) AS TotalLoFRawAvg, 
		SUM(CAST(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.Weighting AS float)) AS TotalLoFScoreWeighted, 
		AVG(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END) AS TotalLoFScoreAvg, SUM(CAST(dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalCoFWeighted, 
		AVG(CAST(dbo.v__ActiveAssets.RR_CoF_R AS FLOAT)) AS TotalCoFAvg, 
		SUM(CAST(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalRiskRawWeighted, 
		AVG(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R) AS TotalRiskRawAvg, 
		SUM(CAST(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalRiskScoreWeighted, 
		AVG(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R) AS TotalRiskScoreAvg, SUM(dbo.RR_ScenarioResults.CostOfService) AS PreviousCost, 
		SUM(dbo.RR_ScenarioResults.CostOfService) + MIN(ISNULL(dbo.v_14_Results_Summary_ProjectOverrideCosts.CostDiff, 0)) AS Cost, SUM(CASE WHEN [CostOfService] > 0 THEN 1 ELSE 0 END) AS ReplacedCount, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN Weighting ELSE 0 END AS float)) AS ReplacedWeighting, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [Age] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedAgeWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CAST([Age] AS FLOAT) ELSE NULL END) AS ReplacedAgeAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PhysRaw] * Weighting ELSE 0 END AS float)) AS ReplacedPhysRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN [PhysRaw] ELSE NULL END) AS ReplacedPhysRawAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PerfScore] * Weighting ELSE 0 END AS float)) AS ReplacedPhysScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CAST([PerfScore] AS FLOAT) ELSE NULL END) AS ReplacedPhysScoreAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PerfScore] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedPerfScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN [PerfScore] ELSE NULL END) AS ReplacedPerfScoreAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedLoFRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END ELSE NULL END) AS ReplacedLoFRawAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedLoFScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END ELSE NULL END) AS ReplacedLoFScoreAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [RR_COF_R] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedCoFWeighted, AVG(CASE WHEN [CostOfService] > 0 THEN CAST([RR_COF_R] AS FLOAT) ELSE NULL END) AS ReplacedCoFAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * [RR_COF_R] * Weighting ELSE 0 END AS float)) AS ReplacedRiskRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * [RR_COF_R] ELSE NULL END) AS ReplacedRiskRawAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * RR_COF_R * Weighting ELSE 0 END AS float)) AS ReplacedRiskScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * [RR_COF_R] ELSE NULL END) AS ReplacedRiskScoreAvg, 
		MIN(dbo.v__ActiveAssets.RR_CoF_R) AS MinOfCoF, MAX(dbo.v__ActiveAssets.RR_CoF_R) AS MaxOfCoF
FROM	dbo.v_14_Results_Summary_ProjectOverrideCosts RIGHT OUTER JOIN
		dbo.RR_ScenarioResults INNER JOIN
		dbo.v__ActiveAssets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID INNER JOIN
		dbo.RR_RuntimeConfig ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_RuntimeConfig.CurrentScenario_ID ON dbo.v_14_Results_Summary_ProjectOverrideCosts.Scenario_ID = dbo.RR_ScenarioResults.Scenario_ID AND 
		dbo.v_14_Results_Summary_ProjectOverrideCosts.BudgetYear = dbo.RR_ScenarioResults.ScenarioYear
GROUP BY dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear
GO


DROP VIEW v___QC_DatabaseConnections
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_QC__DatabaseConnections]
AS
SELECT	MIN(sdes.login_time) AS LoginTime, sdes.host_name, sdes.program_name, sdes.login_name, sdes.status, sdest.DatabaseName, sdest.ObjName, COUNT(*) AS Connections
FROM	master.sys.dm_exec_sessions AS sdes INNER JOIN
		master.sys.dm_exec_connections AS sdec ON sdec.session_id = sdes.session_id CROSS APPLY
			(SELECT	DB_NAME(dbid) AS DatabaseName, OBJECT_NAME(objectid) AS ObjName, COALESCE
				((SELECT	TEXT AS [processing-instruction(definition)]
					FROM	master.sys.dm_exec_sql_text(sdec.most_recent_sql_handle) FOR XML PATH(''), TYPE), '') AS Query
			FROM master.sys.dm_exec_sql_text(sdec.most_recent_sql_handle)) sdest
WHERE	sdes.session_id <> @@SPID AND sdest.DatabaseName = DB_NAME()
GROUP BY sdes.host_name, sdes.program_name, sdes.login_name, sdes.status, sdest.DatabaseName, sdest.ObjName
GO


UPDATE RR_CONFIG SET VERSION = 5.002;
GO






--v5.003
--Fix to add Scenario ID Year
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_PBI_ScenariosResultsSummary]
AS
SELECT	Format(dbo.RR_Scenarios.Scenario_ID + CAST(dbo.RR_ScenarioYears.BudgetYear AS FLOAT) / 10000, '00.0000') AS [Scenario ID Year], dbo.RR_ScenarioYears.Scenario_ID AS [Scenario ID], 
		dbo.RR_Scenarios.ScenarioName AS [Scenario Name], dbo.RR_Scenarios.Description AS [Scenario Description], dbo.RR_ScenarioYears.BudgetYear AS [Scenario Year], 
		dbo.RR_ScenarioYears.AllocationToRisk AS [Scenario Risk Allocation], dbo.RR_ScenarioYears.Budget AS [Scenario Target Budget], dbo.RR_ScenarioYears.ActualBudget AS [Overall Budget], 
		dbo.RR_ScenarioYears.OverallCount AS [Overall Asset Count], dbo.RR_ScenarioYears.OverallAgeWeighted AS [Ovarall Age], dbo.RR_ScenarioYears.OverallPhysRawWeighted AS [Overall Phys Raw], 
		dbo.RR_ScenarioYears.OverallPhysScoreWeighted AS [Overall Phys Score], dbo.RR_ScenarioYears.OverallPerfScoreWeighted AS [Overall Perf Score], dbo.RR_ScenarioYears.OverallLoFRawWeighted AS [Overall LoF Raw], 
		dbo.RR_ScenarioYears.OverallLoFScoreWeighted AS [Overall LoF Score], dbo.RR_ScenarioYears.OverallRiskRawWeighted AS [Overall Risk Raw], dbo.RR_ScenarioYears.OverallRiskScoreWeighted AS [Overall Risk Score], 
		dbo.RR_ScenarioYears.ServicedCount AS [Serviced Count], ROUND(dbo.RR_ScenarioYears.ServicedWeighting / 5280, 2) AS [Serviced Miles], dbo.RR_ScenarioYears.ServicedAgeWeighted AS [Serviced Age], 
		dbo.RR_ScenarioYears.ServicedPhysRawWeighted AS [Serviced Phys Raw], dbo.RR_ScenarioYears.ServicedPhysScoreWeighted AS [Serviced Phys Score], 
		dbo.RR_ScenarioYears.ServicedPerfScoreWeighted AS [Serviced Perf Score], dbo.RR_ScenarioYears.ServicedLoFRawWeighted AS [Serviced LoF Raw], 
		dbo.RR_ScenarioYears.ServicedLoFScoreWeighted AS [Serviced LoF Score], dbo.RR_ScenarioYears.ServicedCoFWeighted AS [Serviced CoF], dbo.RR_ScenarioYears.ServicedRiskRawWeighted AS [Serviced Risk Raw], 
		dbo.RR_ScenarioYears.ServicedRiskScoreWeighted AS [Serviced Risk Score]
FROM	dbo.RR_Scenarios INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioYears.Scenario_ID
WHERE	(dbo.RR_Scenarios.PBI_Flag = 1);
GO


UPDATE RR_CONFIG SET VERSION = 5.003;
GO






--v5.004
--v___QC_Results:  Corrected Rehab to include RR_RehabsAllowed criteria 
--p___QC_ResultsReview:  Added AgeOffset
--v_QC__Status:  Added Flag column and removed basic inventory stats from  
--v_14_Results_Summary
--v_10_a_ScenarioCurrentYearDetails;  Priorizize rehabs allowed and allow overlapping thresholds
--RR_ConfigTableLookup:  UPDATE Projects DisplayOrder and INSERT Projects Year1Pcnt, Year2Pcnt, Year3Pcnt, Year4Pcnt, OverrideCost
--RR_ScenarioYears:  Added LoF5Miles and Risk16Miles
--RR_Projects: Added StartYear
--p_02_AssignCohortsCosts:  REHAB based on RR_Diameter, REPLACE based on RR_ReplacementDiameter
--RR_ConfigTableLookup:  Updage bit fields to TrueFalse format
--p_50_UpdateProjectStats:  altered
--v_PBI_Projects:  altered
--v_PBI_ProjectYears:  Created
--v_QC_Projects:  Created
--v_40_FirstReplaceYear: altered
--v_40_FirstRehabYear: altered
--v_70_GraphScenarioResults:  Updated to include LoF5Miles and Risk16Miles
--v_00_02_ScenarioNames:  Added ReplacedWeight, RehabbedWeight
--v_10_a_ScenarioCurrentYearDetails:  Priorizize rehabs allowed and allow overlapping thresholds EXCEPT performance threshould
--p___QC_ListTables:  altered
--v_PBI_3DMatrix:  2023-04-22 tweak
--p___Alias_Views:  altered
--v__RuntimeResults:  altered
--v_00_11_Revisions:  altered
--p_90_AssignCoFLoF:  altered



--2023-05-15 corrected Rehab to include RR_RehabsAllowed criteria and added AgeOffset
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v___QC_Results]
AS
SELECT	dbo.RR_Scenarios.Scenario_ID, dbo.RR_Scenarios.ScenarioName, dbo.RR_ScenarioResults.RR_Asset_ID, dbo.RR_Assets.RR_Facility, dbo.RR_Assets.RR_AssetType, dbo.RR_Assets.RR_AssetName, 
		dbo.RR_Assets.RR_EUL AS InitEUL, dbo.RR_ScenarioResults.ScenarioYear, dbo.RR_ScenarioResults.Age, dbo.RR_Assets.RR_AgeOffset AS AgeOffset, dbo.RR_ScenarioResults.PerfScore, 
		dbo.RR_CriticalityActionLimits.PerformanceReplace AS PerfReplace, dbo.RR_ScenarioResults.PhysScore, dbo.RR_ScenarioResults.PhysRaw, dbo.RR_CriticalityActionLimits.LowRehab, 
		dbo.RR_CriticalityActionLimits.HighRehab, dbo.RR_CriticalityActionLimits.LowReplace, 
		CASE 
			WHEN [PhysRaw] >= [LowRehab] AND [PhysRaw] < [HighRehab] AND [RR_CostRehab] > 0 AND [RR_RehabsAllowed] > 0 THEN 'Rehab' 
			WHEN [RR_CostReplace] > 0 AND [PhysRaw] >= [LowReplace] THEN 'Replace'
			WHEN [RR_CostReplace] > 0 AND [PerfScore] >= [PerformanceReplace] THEN 'ReplacePerf' 
			ELSE ''
		END AS EligableRR, 
		dbo.RR_ScenarioResults.Service, dbo.RR_ScenarioResults.CostOfService, dbo.RR_Assets.RR_CostRehab, 
		dbo.RR_Assets.RR_CostReplace, dbo.RR_Assets.RR_CoF_R, CASE WHEN [PhysScore] >= [PerfScore] THEN [PhysScore] ELSE [PerfScore] END AS LoFScore, dbo.RR_Config.CostMultiplier
FROM	dbo.RR_ScenarioResults INNER JOIN
		dbo.RR_Assets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.RR_Assets.RR_Asset_ID INNER JOIN
		dbo.RR_CriticalityActionLimits ON dbo.RR_Assets.RR_CoF_R = dbo.RR_CriticalityActionLimits.Criticality INNER JOIN
		dbo.RR_Cohorts ON dbo.RR_Assets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID INNER JOIN
		dbo.RR_Scenarios ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_Scenarios.Scenario_ID INNER JOIN
		dbo.RR_Config ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_Config.CurrentScenario_ID
GO

-- 2023-05-15 added AgeOffset
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p___QC_ResultsReview]
@ScenarioID as int
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE RR_Config
	SET CurrentScenario_ID = @ScenarioID;

	SELECT   'Total Asset Cost Summary' AS QCName, FORMAT(SUM(RR_CostRehab),'$#,##0') AS [Asset Rehab], FORMAT(SUM(CAST(RR_CostReplace AS bigint)),'$#,##0') AS [Asset Replace], 
			CostMultiplier, FORMAT(SUM(RR_CostRehab*CostMultiplier),'$#,##0') AS [Capital Rehab], FORMAT(SUM(RR_CostReplace*CostMultiplier),'$#,##0') AS [Capital Replace],
			FORMAT(COUNT(*),'#,##0')  AS Assets
	FROM	 RR_Assets INNER JOIN RR_Config on RR_Assets.RR_Config_ID =RR_Config.ID  WHERE RR_Status=1
	GROUP BY CostMultiplier;
	
	SELECT   'Scenario Cost Summary' AS QCName, [ScenarioName], FORMAT(SUM(CostOfService),'$#,##0') AS Cost, 
			FORMAT(SUM(RR_CostRehab*CostMultiplier),'$#,##0') AS [Capital Rehab], FORMAT(SUM(RR_CostReplace*CostMultiplier),'$#,##0') AS [Capital Replace], 
			FORMAT(COUNT(*),'#,##0') AS Assets
	FROM     v___QC_Results
	WHERE    (EligableRR <> N'') OR (Service <> 'Maintain')
	GROUP BY  [ScenarioName];

	SELECT   'Eligable-Actual Summary' AS QCName, ScenarioName, CASE WHEN EligableRR ='' THEN 'Maintain' ELSE EligableRR END AS Eligable, Service AS Actual, 
			 FORMAT(SUM(CostOfService),'$#,##0') AS [Actual Cost], FORMAT(SUM(RR_CostRehab*CostMultiplier),'$#,##0') AS [Capital Rehab], 
			 FORMAT(SUM(RR_CostReplace*CostMultiplier),'$#,##0')  AS [Capital Replace], FORMAT(COUNT(*),'#,##0') AS [Count]
	FROM     v___QC_Results
	GROUP BY ScenarioName, EligableRR, Service;

	SELECT 	 'Eligable-Actual Counts' AS QCName, [ScenarioName] ,[ScenarioYear] , COUNT(*) AS [Eligable Count], 
			SUM(CASE WHEN [CostOfService]>0 THEN 1 ELSE 0 END) AS [Actual Count], FORMAT(SUM([CostOfService]), '$#,##0') AS [Actual Cost], 
			FORMAT(SUM([RR_CostRehab]*[CostMultiplier]), '$#,##0') AS [Capital Rehab], FORMAT(SUM([RR_CostReplace]*[CostMultiplier]), '$#,##0') AS [Capital Replace]
	FROM	 v___QC_Results
	WHERE	 [EligableRR] <>'' or CostOfService>0
	GROUP BY [ScenarioName] ,[ScenarioYear]
	ORDER BY ScenarioYear;
	   	 
	SELECT  'Eligable-Actual Details' AS QCName,  RR_Asset_ID AS [Asset ID], ScenarioYear AS Year, RR_Facility, RR_AssetType, RR_AssetName, InitEUL AS EUL, Age, PerfScore, PerfReplace, PhysScore, 
			PhysRaw, LowRehab, HighRehab, EligableRR AS Eligable, Service AS Actual, CostOfService AS Cost, RR_CostRehab, RR_CostReplace, RR_CoF_R, LoFScore, CostMultiplier
	FROM    v___QC_Results
	WHERE  (EligableRR <> N'') OR (CostOfService > 0)
	ORDER BY ScenarioYear;
	
	SELECT  'Scenario Details' AS QCName, RR_Asset_ID AS [Asset ID], ScenarioYear AS Year, RR_Facility, RR_AssetType, RR_AssetName, InitEUL AS EUL, Age, AgeOffset, PerfScore, PerfReplace, PhysScore, 
			PhysRaw, LowRehab, HighRehab, EligableRR AS Eligable, Service AS Actual, CostOfService AS Cost, RR_CostRehab, RR_CostReplace, RR_CoF_R, LoFScore, CostMultiplier
	FROM    v___QC_Results
	ORDER BY RR_Asset_ID, ScenarioYear;
END
GO


--2023-05-18
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_QC__Status]
AS
--SELECT	'Active Assets' AS Description, '' AS Flag, FORMAT(ActiveAssets, '#,##0') AS Measure
--FROM	v__InventoryWeight
--UNION
--SELECT	'Active Miles' AS Description, '' AS Flag, FORMAT(Miles, '#,##0') AS Measure
--FROM	v__InventoryWeight
--UNION
--SELECT	'Capital Cost' AS Description, '' AS Flag, FORMAT(CapitalCost, '$#,##0') AS Measure
--FROM	v__InventoryWeight
--UNION
--SELECT	'Baseline Year' AS Description, '' AS Flag, FORMAT(BaselineYear, '0') AS Measure
--FROM	v__InventoryWeight
--UNION
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
SELECT	TOP 1 'Last Run Scenario' AS Description, '' AS Flag, ScenarioName + ' ' + FORMAT(LastRun, 'yyyy-MM-dd HH:mm:ss') AS Measure
FROM	RR_Scenarios
WHERE	LastRun IS NOT NULL
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   VIEW [dbo].[v_14_Results_Summary]
AS
SELECT	dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear, SUM(1) AS TotalCount, SUM(dbo.v__ActiveAssets.Weighting) AS TotalWeighting, 
		SUM(CAST(dbo.RR_ScenarioResults.Age * dbo.v__ActiveAssets.Weighting AS float)) AS TotalAgeWeighted, AVG(CAST(dbo.RR_ScenarioResults.Age AS FLOAT)) AS TotalAgeAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PhysRaw * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPhysRawWeighted, AVG(dbo.RR_ScenarioResults.PhysRaw) AS TotalPhysRawAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PhysScore * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPhysScoreWeighted, AVG(CAST(dbo.RR_ScenarioResults.PhysScore AS FLOAT)) AS TotalPhysScoreAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PerfScore * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPerfScoreWeighted, AVG(dbo.RR_ScenarioResults.PerfScore) AS TotalPerfScoreAvg, 
		SUM(CAST(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.Weighting AS float)) AS TotalLoFRawWeighted, 
		AVG(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END) AS TotalLoFRawAvg, 
		SUM(CAST(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.Weighting AS float)) AS TotalLoFScoreWeighted, 
		AVG(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END) AS TotalLoFScoreAvg, SUM(CAST(dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalCoFWeighted, 
		AVG(CAST(dbo.v__ActiveAssets.RR_CoF_R AS FLOAT)) AS TotalCoFAvg, 
		SUM(CAST(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalRiskRawWeighted, 
		AVG(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R) AS TotalRiskRawAvg, 
		SUM(CAST(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalRiskScoreWeighted, 
		AVG(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R) AS TotalRiskScoreAvg, SUM(dbo.RR_ScenarioResults.CostOfService) AS PreviousCost, 
		SUM(dbo.RR_ScenarioResults.CostOfService) + MIN(ISNULL(dbo.v_14_Results_Summary_ProjectOverrideCosts.CostDiff, 0)) AS Cost, SUM(CASE WHEN [CostOfService] > 0 THEN 1 ELSE 0 END) AS ReplacedCount, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN Weighting ELSE 0 END AS float)) AS ReplacedWeighting, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [Age] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedAgeWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CAST([Age] AS FLOAT) ELSE NULL END) AS ReplacedAgeAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PhysRaw] * Weighting ELSE 0 END AS float)) AS ReplacedPhysRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN [PhysRaw] ELSE NULL END) AS ReplacedPhysRawAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PerfScore] * Weighting ELSE 0 END AS float)) AS ReplacedPhysScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CAST([PerfScore] AS FLOAT) ELSE NULL END) AS ReplacedPhysScoreAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PerfScore] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedPerfScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN [PerfScore] ELSE NULL END) AS ReplacedPerfScoreAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedLoFRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END ELSE NULL END) AS ReplacedLoFRawAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedLoFScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END ELSE NULL END) AS ReplacedLoFScoreAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [RR_COF_R] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedCoFWeighted, AVG(CASE WHEN [CostOfService] > 0 THEN CAST([RR_COF_R] AS FLOAT) ELSE NULL END) AS ReplacedCoFAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * [RR_COF_R] * Weighting ELSE 0 END AS float)) AS ReplacedRiskRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * [RR_COF_R] ELSE NULL END) AS ReplacedRiskRawAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * RR_COF_R * Weighting ELSE 0 END AS float)) AS ReplacedRiskScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * [RR_COF_R] ELSE NULL END) AS ReplacedRiskScoreAvg, 
		MIN(dbo.v__ActiveAssets.RR_CoF_R) AS MinOfCoF, MAX(dbo.v__ActiveAssets.RR_CoF_R) AS MaxOfCoF
FROM	dbo.v_14_Results_Summary_ProjectOverrideCosts RIGHT OUTER JOIN
		dbo.RR_ScenarioResults INNER JOIN
		dbo.v__ActiveAssets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID INNER JOIN
		dbo.RR_RuntimeConfig ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_RuntimeConfig.CurrentScenario_ID ON dbo.v_14_Results_Summary_ProjectOverrideCosts.Scenario_ID = dbo.RR_ScenarioResults.Scenario_ID AND 
		dbo.v_14_Results_Summary_ProjectOverrideCosts.BudgetYear = dbo.RR_ScenarioResults.ScenarioYear
GROUP BY dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear
GO

-- 2023-05-18 priorizize rehabs allowed and allow overlapping thresholds
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_10_a_ScenarioCurrentYearDetails]
AS
SELECT	dbo.v_10_b_ScenarioCurrentYearDetails.CurrentScenario_ID, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentBudget, 
		dbo.v_10_b_ScenarioCurrentYearDetails.RR_Asset_ID, dbo.v_10_b_ScenarioCurrentYearDetails.ProjectNumber, dbo.v_10_b_ScenarioCurrentYearDetails.ProjectYear, 
		dbo.v_10_b_ScenarioCurrentYearDetails.InstallYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentInstallYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentAge, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CurrentAgeOffset, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentFailurePhysOffset, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CurrentEquationType, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentConstIntercept, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentExpSlope, 
		dbo.v_10_b_ScenarioCurrentYearDetails.StatsCondition, dbo.v_10_b_ScenarioCurrentYearDetails.PrelimPhysRaw, dbo.v_10_b_ScenarioCurrentYearDetails.ConditionLimit, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw, dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw, dbo.v_10_b_ScenarioCurrentYearDetails.PerfScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysScore, dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore, dbo.v_10_b_ScenarioCurrentYearDetails.RedundancyFactor, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CoF, dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R, dbo.v_10_b_ScenarioCurrentYearDetails.CostRepair, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CostRehab, dbo.v_10_b_ScenarioCurrentYearDetails.CostReplace, dbo.v_10_b_ScenarioCurrentYearDetails.BaseCostReplace, 
		dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceEquationType, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceConstIntercept, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceExpSlope, 
		dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceEUL, dbo.v_10_b_ScenarioCurrentYearDetails.RehabPercentEUL, dbo.v_10_b_ScenarioCurrentYearDetails.RepairsRemaining, 
		dbo.v_10_b_ScenarioCurrentYearDetails.RehabsRemaining, dbo.v_10_b_ScenarioCurrentYearDetails.LowRepair, dbo.v_10_b_ScenarioCurrentYearDetails.HighRepair, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LowRehab, dbo.v_10_b_ScenarioCurrentYearDetails.HighRehab, dbo.v_10_b_ScenarioCurrentYearDetails.LowReplace, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PerformanceReplace, dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS YearRiskRaw, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS YearRiskScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemPhysRaw, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemLoFRaw, 
		CAST(dbo.v_10_b_ScenarioCurrentYearDetails.PhysScore AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemPhysScore, 
		CAST(dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemLoFScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemCondition, 
		CAST(dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemRiskScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemRiskRaw,
		CASE 
			WHEN [CostRepair] > 0 AND [RepairsRemaining] > 0 AND [PhysRaw] >= [LowRepair] AND [PhysRaw] < [HighRepair] THEN 'Repair' 
			WHEN [CostRehab] > 0 AND [RehabsRemaining] > 0 AND PhysRaw >= [LowRehab] AND [PhysRaw] < [HighRehab] THEN 'Rehab' 
			WHEN [PerfScore] >= [PerformanceReplace] OR [PhysRaw] >= [LowReplace] THEN 'Replace' 
		END AS ServiceType,
		CASE 
			WHEN [CostRepair] > 0 AND [RepairsRemaining] > 0 AND [PhysRaw] >= [LowRepair] AND [PhysRaw] < [HighRepair] THEN [CostRepair] 
			WHEN [CostRehab] > 0 AND [RehabsRemaining] > 0 AND [PhysRaw] >= [LowRehab] AND [PhysRaw] < [HighRehab] THEN [CostRehab] 
			WHEN [PerfScore] >= [PerformanceReplace] OR [PhysRaw] >= [LowReplace] THEN [CostReplace] 
		END AS ServiceCost, 
		dbo.RR_ScenarioYears.UseProjectBudget
FROM	dbo.v_10_b_ScenarioCurrentYearDetails INNER JOIN
		dbo.RR_ScenarioYears ON dbo.v_10_b_ScenarioCurrentYearDetails.CurrentScenario_ID = dbo.RR_ScenarioYears.Scenario_ID 
		AND dbo.v_10_b_ScenarioCurrentYearDetails.CurrentYear = dbo.RR_ScenarioYears.BudgetYear;
GO



UPDATE [RR_ConfigTableLookup]
SET [DisplayOrder] = [DisplayOrder] + 5
WHERE [TableName] = 'Projects' AND [DisplayOrder] >=7;

INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Projects', N'Year1Pcnt', N'Year 1', 7, 75, 32, N'0%', 1, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Projects', N'Year2Pcnt', N'Year 2', 8, 75, 32, N'0%', 1, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Projects', N'Year3Pcnt', N'Year 3', 9, 75, 32, N'0%', 1, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Projects', N'Year4Pcnt', N'Year 4', 10, 75, 32, N'0%', 1, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Projects', N'OverrideCost', N'Override Cost', 11, 75, 32, N'$#,##0', 1, 0)






-- 2023-06-30 remaining risk and LoF 5   -v5.004
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [RR_ScenarioYears] ADD
	[LoF5Miles] [float] NULL,
	[Risk16Miles] [float] NULL  ;
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [RR_Projects] ADD
	[StartYear] [smallint] NULL;
GO

--Only run if no project data yet
--******************************************************
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--ALTER TABLE [dbo].[RR_Projects]
--ALTER COLUMN [ProjectYear]  AS ([StartYear] + CASE WHEN [Year4Pcnt]>0 THEN 3 WHEN [Year3Pcnt]>0 THEN 2 WHEN [Year2Pcnt]>0 THEN 1 ELSE 0 END) PERSISTED;
--GO




--REHAB based on RR_Diameter, REPLACE based on RR_ReplacementDiameter 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_02_AssignCohortsCosts]
AS
BEGIN

	SET NOCOUNT ON;

	-- Initialize values
	UPDATE	RR_Assets
	SET		RR_Cohort_ID = NULL,
			RR_CostRehab = 0, 
			RR_CostReplace = 0;

	-- Update Cohort ID
	UPDATE	RR_Assets
	SET		RR_Assets.RR_Cohort_ID = v_QC_Cohorts_Assignment.Cohort_ID
	FROM	RR_Assets INNER JOIN v_QC_Cohorts_Assignment ON v_QC_Cohorts_Assignment.RR_Asset_ID = RR_Assets.RR_Asset_ID;

	-- update asset replacement cost where inherit = 1 
	--REHAB based on RR_Diameter
	UPDATE	RR_Assets
	SET		RR_CostRehab = CASE WHEN RR_AssetCosts.CostRehab > 0 AND RR_AssetCosts.CostRehab * RR_Length < 1 THEN 1 ELSE RR_AssetCosts.CostRehab * RR_Length END
	FROM	RR_Assets INNER JOIN
			RR_AssetCosts ON RR_Assets.RR_Diameter > RR_AssetCosts.MinDia AND RR_Assets.RR_Diameter <= RR_AssetCosts.MaxDia
	WHERE	(RR_Assets.RR_InheritCost = 1) AND (ISNULL(RR_Assets.RR_AssetType, N'') = ISNULL(RR_AssetCosts.AssetType, N''));

	--REPLACE based on RR_ReplacementDiameter
	UPDATE	RR_Assets
	SET		RR_CostReplace = CASE WHEN RR_AssetCosts.CostReplacement > 0 AND RR_AssetCosts.CostReplacement * RR_Length < 1 THEN 1 ELSE RR_AssetCosts.CostReplacement * RR_Length END
	FROM	RR_Assets INNER JOIN
			RR_AssetCosts ON RR_Assets.RR_ReplacementDiameter > RR_AssetCosts.MinDia AND RR_Assets.RR_ReplacementDiameter <= RR_AssetCosts.MaxDia
	WHERE	(RR_Assets.RR_InheritCost = 1) AND (ISNULL(RR_Assets.RR_AssetType, N'') = ISNULL(RR_AssetCosts.AssetType, N''));


	-- update asset replacement cost where inherit = 0 
	UPDATE	RR_Assets
	SET		RR_CostRehab = RR_AssetCostRehab, 
			RR_CostReplace = RR_AssetCostReplace
	WHERE	RR_Assets.RR_InheritCost = 0;

END
GO

UPDATE [RR_ConfigTableLookup] SET [Format] = 'TrueFalse' WHERE [TableName] = 'Asset Attributes' AND [ColumnName] = 'RR_Status';
UPDATE [RR_ConfigTableLookup] SET [Format] = 'TrueFalse' WHERE [TableName] = 'CoFLoFAssignment' AND [ColumnName] = 'Active';
UPDATE [RR_ConfigTableLookup] SET [Format] = 'TrueFalse' WHERE [TableName] = 'Scenarios' AND [ColumnName] = 'PBI_Flag';
UPDATE [RR_ConfigTableLookup] SET [Format] = 'TrueFalse' WHERE [TableName] = 'ScenarioYears' AND [ColumnName] = 'UseProjectBudget';
UPDATE [RR_ConfigTableLookup] SET [Format] = 'TrueFalse' WHERE [TableName] = 'HierarchyAssets' AND [ColumnName] = 'RR_InheritCost';



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[p_50_UpdateProjectStats]
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO RR_Projects (ProjectNumber)
	SELECT DISTINCT RR_Assets.RR_ProjectNumber
	FROM	RR_Projects AS RR_Projects RIGHT OUTER JOIN
			RR_Assets ON RR_Projects.ProjectNumber = RR_Assets.RR_ProjectNumber
	WHERE (RR_Assets.RR_ProjectNumber IS NOT NULL) AND RR_Projects.ProjectNumber IS NULL;

	UPDATE	RR_Projects
	SET		ProjectCost = null, 
			Assets = null, 
			Length = null, 
			Min_Age = null, 
			Max_Age = null, 
			Avg_Age = null, 
			Min_Diameter = null, 
			Max_Diameter = null, 
			Avg_Diameter = null, 
			Max_LOF_Perf = null, 
			Avg_LOF_Perf = null, 
			Max_LOF_Phys = null, 
			Avg_LOF_Phys = null, 
			Max_LoF_EUL = null, 
			Avg_LoF_EUL = null, 
			Max_LoF = null, 
			Avg_LoF = null, 
			Max_CoF = null, 
			Avg_CoF = null, 
			Avg_Redundancy = null, 
			Max_CoF_R = null, 
			Avg_CoF_R = null, 
			Max_Risk = null, 
			Avg_Risk = null,
			SHAPE = null;

	UPDATE	RR_Projects
	SET		ProjectCost = v_50_ProjectStats.Cost, 
			Assets = v_50_ProjectStats.Assets, 
			Length = v_50_ProjectStats.Length, 
			Min_Age = v_50_ProjectStats.Min_Age, 
			Max_Age = v_50_ProjectStats.Max_Age, 
			Avg_Age = v_50_ProjectStats.Avg_Age, 
			Min_Diameter = v_50_ProjectStats.Min_Dia, 
			Max_Diameter = v_50_ProjectStats.Max_Dia, 
			Avg_Diameter = v_50_ProjectStats.Avg_Dia, 
			Max_LoF_Perf = v_50_ProjectStats.Max_LoF_Perf, 
			Avg_LoF_Perf = v_50_ProjectStats.Avg_LoF_Perf, 
			Max_LoF_Phys = v_50_ProjectStats.Max_LoF_Phys, 
			Avg_LoF_Phys = v_50_ProjectStats.Avg_LoF_Phys, 
			Max_LoF_EUL = v_50_ProjectStats.Max_LoF_EUL, 
			Avg_LoF_EUL = v_50_ProjectStats.Avg_LoF_EUL, 
			Max_LoF = v_50_ProjectStats.Max_LoF, 
			Avg_LoF = v_50_ProjectStats.Avg_LoF, 
			Max_CoF = v_50_ProjectStats.Max_CoF, 
			Avg_CoF = v_50_ProjectStats.Avg_CoF, 
			Avg_Redundancy = v_50_ProjectStats.Avg_Redundancy, 
			Max_CoF_R = v_50_ProjectStats.Max_CoF_R, 
			Avg_CoF_R = v_50_ProjectStats.Avg_CoF_R, 
			Max_Risk = v_50_ProjectStats.Max_Risk, 
			Avg_Risk = v_50_ProjectStats.Avg_Risk
	FROM	RR_Projects INNER JOIN
			v_50_ProjectStats ON v_50_ProjectStats.RR_ProjectNumber = RR_Projects.ProjectNumber;

	UPDATE	RR_Projects
	SET		SHAPE = v_50_ProjectGeo.AgLine.STBuffer(50)
	FROM	v_50_ProjectGeo INNER JOIN
			RR_Projects ON v_50_ProjectGeo.RR_ProjectNumber = RR_Projects.ProjectNumber;

END
GO

--2023-09-07
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_PBI_Projects]
AS
SELECT	ProjectNumber, ProjectName, ProjectDescription, ProjectGroup, ProjectYear, ServiceType, ISNULL(ProjectCost, 0) AS CalculatedCost, ISNULL(OverrideCost, 0) AS OverrideCost, 
		CASE WHEN overridecost IS NULL THEN ProjectCost ELSE OverrideCost END AS ProjectCost, Assets, Length, PreviousFailures, Min_Age, Max_Age, Avg_Age, Min_Diameter, Max_Diameter, Avg_Diameter, Max_LOF_Perf, Avg_LOF_Perf, Max_LOF_Phys, 
		Avg_LOF_Phys, Max_LoF_EUL, Avg_LoF_EUL, Max_LoF, Avg_LoF, Max_CoF, Avg_CoF, Avg_Redundancy, Avg_CoF_R, Max_CoF_R, Max_Risk, Avg_Risk, Active, SHAPE, 
		StartYear AS Year1, StartYear + 1 AS Year2, StartYear + 2 AS Year3, StartYear + 3 AS Year4, 
		FORMAT(Year1Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year1Cost, 
		FORMAT(Year2Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year2Cost, 
		FORMAT(Year3Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year3Cost, 
		FORMAT(Year4Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year4Cost, 
		FORMAT(CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS TotalCost
FROM	dbo.RR_Projects
WHERE	Active = 1;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_ProjectYears]
AS
SELECT	ProjectNumber, ProjectYear, 'Year 1' AS Schedule, CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END AS total, Year1Pcnt, Year2Pcnt, Year3Pcnt, Year4Pcnt,  
		StartYear  AS BudgetYear, ROUND(Year1Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, 0) AS Cost         
FROM	dbo.RR_Projects
WHERE	Active = 1 AND Year1Pcnt > 0
UNION ALL
SELECT	ProjectNumber, ProjectYear, 'Year 2' AS Schedule, CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END AS total, Year1Pcnt, Year2Pcnt, Year3Pcnt, Year4Pcnt,  
		StartYear +1  AS BudgetYear, ROUND(Year2Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, 0) AS Cost         FROM            dbo.RR_Projects
WHERE	Active = 1 AND Year2Pcnt > 0
UNION ALL
SELECT	ProjectNumber, ProjectYear, 'Year 3' AS Schedule, CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END AS total, Year1Pcnt, Year2Pcnt, Year3Pcnt, Year4Pcnt,  
		StartYear +2 AS BudgetYear, ROUND(Year3Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, 0) AS Cost
FROM	dbo.RR_Projects
WHERE	Active = 1 AND Year3Pcnt > 0
UNION ALL
SELECT	ProjectNumber, ProjectYear, 'Year 4' AS Schedule, CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END AS total, Year1Pcnt, Year2Pcnt, Year3Pcnt, Year4Pcnt,  
		StartYear +3 AS BudgetYear, ROUND(Year4Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, 0) AS Cost
FROM	dbo.RR_Projects
WHERE	Active = 1  AND Year4Pcnt > 0
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Projects]
AS
SELECT	p.ProjectNumber, p.ProjectName, p.ProjectDescription, p.ServiceType, p.ProjectGroup, p.StartYear, p.ProjectYear AS EndYear, p.StartYear AS Year1, p.StartYear + 1 AS Year2, p.StartYear + 2 AS Year3, p.StartYear + 3 AS Year4, 
		FORMAT(p.Year1Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year1Cost, 
		FORMAT(p.Year2Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year2Cost, 
		FORMAT(p.Year3Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year3Cost, 
		FORMAT(p.Year4Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS Year4Cost, 
		FORMAT(CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0') AS TotalCost, 
		p.Assets, p.PreviousFailures, 
		CASE WHEN p.Avg_LoF >= 4.3 THEN 5 WHEN p.Avg_LoF >= 3.6 THEN 4 WHEN p.Avg_LoF >= 2.4 THEN 3 WHEN p.Avg_LoF >= 1.6 THEN 2 ELSE 1 END AS LoF, 
		CASE WHEN p.Avg_Risk >= 20 THEN 5 WHEN p.Avg_Risk >= 16 THEN 4 WHEN p.Avg_Risk >= 12 THEN 3 WHEN p.Avg_Risk >= 8 THEN 2 ELSE 1 END AS Risk, 
		p.Min_Age, format(p.Avg_Age, '#.0') AS Avg_Age, p.Max_Age, Format(p.Avg_LOF_Phys, '#.0') AS Avg_LoF_Phys, p.Max_LOF_Phys, format(p.Avg_LOF_Perf, '#.0') AS Avg_LoF_Perf,
		p.Max_LOF_Perf, format(p.Avg_LoF_EUL, '#.0') AS Avg_LoF_Raw, p.Max_LoF_EUL AS Max_LoF_Raw, format(p.Avg_LoF, '#.0') AS Avg_LoF, p.Max_LoF, 
		format(p.Avg_CoF_R, '#.0') AS Avg_CoF_R, p.Max_CoF_R, format(p.Avg_Risk, '#.0') AS Avg_Risk, p.Max_Risk, p.ProjectCost, p.OverrideCost, 
		STRING_AGG(CAST(CONCAT_WS(CHAR(9), a.RR_Division, a.RR_Process, a.RR_AssetName, a.RR_Asset_ID) AS varchar(MAX)), CHAR(13)) AS AssetInfo, 
		p.Year1Pcnt, p.Year2Pcnt, p.Year3Pcnt, p.Year4Pcnt, p.ProjectYear
FROM	dbo.RR_Projects AS p LEFT OUTER JOIN
		dbo.v__ActiveAssets AS a ON p.ProjectNumber = a.RR_ProjectNumber
WHERE	(p.Active = 1)
GROUP BY p.StartYear, p.ProjectNumber, p.ProjectName, p.ProjectDescription, FORMAT(p.Year1Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0'), 
		FORMAT(p.Year2Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0'), FORMAT(p.Year3Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0'), 
		FORMAT(p.Year4Pcnt * CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0'), FORMAT(CASE WHEN OverrideCost > 0 THEN OverrideCost ELSE ProjectCost END, '$#,##0'), p.ProjectYear, 
		p.ServiceType, p.ProjectGroup, p.Assets, p.PreviousFailures, p.Min_Age, format(p.Avg_Age, '#.0'), p.Max_Age, 
		Format(p.Avg_LOF_Phys, '#.0'), p.Max_LOF_Phys, format(p.Avg_LOF_Perf, '#.0'), p.Max_LOF_Perf, format(p.Avg_LoF_EUL, '#.0'), p.Max_LoF_EUL, format(p.Avg_LoF, '#.0'), p.Max_LoF, format(p.Avg_CoF_R, '#.0'), p.Max_CoF_R, 
		format(p.Avg_Risk, '#.0'), p.Max_Risk, p.ProjectCost, p.OverrideCost, 
		CASE WHEN p.Avg_LoF >= 4.3 THEN 5 WHEN p.Avg_LoF >= 3.6 THEN 4 WHEN p.Avg_LoF >= 2.4 THEN 3 WHEN p.Avg_LoF >= 1.6 THEN 2 ELSE 1 END, 
		CASE WHEN p.Avg_Risk >= 20 THEN 5 WHEN p.Avg_Risk >= 16 THEN 4 WHEN p.Avg_Risk >= 12 THEN 3 WHEN p.Avg_Risk >= 8 THEN 2 ELSE 1 END, p.Year1Pcnt, p.Year2Pcnt, p.Year3Pcnt, p.Year4Pcnt
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_40_FirstRehabYear]
AS
SELECT	dbo.RR_ScenarioResults.RR_Asset_ID, dbo.RR_ScenarioResults.ScenarioYear AS RehabYear, dbo.RR_ScenarioResults.PhysRaw AS RehabPhysRaw, dbo.RR_ScenarioResults.PerfScore AS RehabPerfScore, 
		dbo.RR_ScenarioResults.PhysScore AS RehabPhysScore, CASE WHEN PerfScore > PhysScore THEN PerfScore ELSE PhysScore END AS RehabLoFScore, dbo.RR_ScenarioResults.Age AS RehabAge, 
		dbo.RR_ScenarioResults.CostOfService AS RehabCost, dbo.RR_ScenarioResults.Service
FROM	dbo.RR_ScenarioResults INNER JOIN
		dbo.RR_Config ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_Config.CurrentScenario_ID INNER JOIN
		(SELECT	Scenario_ID, MIN(ScenarioYear) AS ReplaceYear, RR_Asset_ID
		FROM	dbo.RR_ScenarioResults AS RR_ScenarioResults_1
		WHERE	(Service = 'Rehab')
		GROUP BY Scenario_ID, RR_Asset_ID) AS AssetMinYear 
		ON AssetMinYear.RR_Asset_ID = dbo.RR_ScenarioResults.RR_Asset_ID 
		AND AssetMinYear.ReplaceYear = dbo.RR_ScenarioResults.ScenarioYear 
		AND dbo.RR_ScenarioResults.Scenario_ID = AssetMinYear.Scenario_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_40_FirstReplaceYear]
AS
SELECT	dbo.RR_ScenarioResults.RR_Asset_ID, AssetMinYear.ReplaceYear, dbo.RR_ScenarioResults.PhysRaw AS ReplacePhysRaw, dbo.RR_ScenarioResults.PerfScore AS ReplacePerfScore, 
		dbo.RR_ScenarioResults.PhysScore AS ReplacePhysScore, CASE WHEN PerfScore > PhysScore THEN PerfScore ELSE PhysScore END AS ReplaceLoFScore, dbo.RR_ScenarioResults.Age AS ReplaceAge, 
		dbo.RR_ScenarioResults.CostOfService AS ReplaceCost, dbo.RR_ScenarioResults.Service
FROM	dbo.RR_ScenarioResults INNER JOIN
		dbo.RR_Config ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_Config.CurrentScenario_ID INNER JOIN
		(SELECT	Scenario_ID, MIN(ScenarioYear) AS ReplaceYear, RR_Asset_ID
		FROM	dbo.RR_ScenarioResults AS RR_ScenarioResults_1
		WHERE	(Service = 'Replace')
		GROUP BY Scenario_ID, RR_Asset_ID) AS AssetMinYear 
		ON AssetMinYear.RR_Asset_ID = dbo.RR_ScenarioResults.RR_Asset_ID 
		AND AssetMinYear.ReplaceYear = dbo.RR_ScenarioResults.ScenarioYear 
		AND dbo.RR_ScenarioResults.Scenario_ID = AssetMinYear.Scenario_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_70_GraphScenarioResults]
AS
SELECT	Scenario_ID, BudgetYear AS ScenarioYear, ActualBudget / 1000000 AS Budget, 
		OverallLoFRawWeighted AS OverallCondition, OverallRiskScoreWeighted AS OverallRisk, 
		LoF5Miles, Risk16Miles
FROM	dbo.RR_ScenarioYears
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW dbo.v_00_02_ScenarioNames
AS
SELECT	Scenario_ID, ScenarioName, 
		ScenarioName + CASE WHEN LastRun IS NOT NULL THEN CONCAT(' ', DATEPART(MONTH, LastRun), '/', DATEPART(DAY, LastRun), '/' ,DATEPART(YEAR, LastRun), ' ', DATEPART(HOUR, LastRun), ':', DATEPART(MINUTE, LastRun), ':', DATEPART(SECOND, LastRun) ) ELSE '' END AS NameLastRun2,
		Description, LastRun, PBI_Flag, TotalCost, ReplacedCost, RehabbedCost, TotalWeight, ReplacedWeight, RehabbedWeight
FROM	dbo.RR_Scenarios
GO


-- 2023-07-02
--priorizize rehabs allowed and allow overlapping thresholds except performance threshould
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_10_a_ScenarioCurrentYearDetails]
AS
SELECT	dbo.v_10_b_ScenarioCurrentYearDetails.CurrentScenario_ID, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentBudget, 
		dbo.v_10_b_ScenarioCurrentYearDetails.RR_Asset_ID, dbo.v_10_b_ScenarioCurrentYearDetails.ProjectNumber, dbo.v_10_b_ScenarioCurrentYearDetails.ProjectYear, dbo.v_10_b_ScenarioCurrentYearDetails.InstallYear, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CurrentInstallYear, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentAge, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentAgeOffset, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CurrentFailurePhysOffset, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentEquationType, dbo.v_10_b_ScenarioCurrentYearDetails.CurrentConstIntercept, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CurrentExpSlope, dbo.v_10_b_ScenarioCurrentYearDetails.StatsCondition, dbo.v_10_b_ScenarioCurrentYearDetails.PrelimPhysRaw, 
		dbo.v_10_b_ScenarioCurrentYearDetails.ConditionLimit, dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw, dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw, dbo.v_10_b_ScenarioCurrentYearDetails.PerfScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysScore, dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore, dbo.v_10_b_ScenarioCurrentYearDetails.RedundancyFactor, dbo.v_10_b_ScenarioCurrentYearDetails.CoF, 
		dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R, dbo.v_10_b_ScenarioCurrentYearDetails.CostRepair, dbo.v_10_b_ScenarioCurrentYearDetails.CostRehab, dbo.v_10_b_ScenarioCurrentYearDetails.CostReplace, 
		dbo.v_10_b_ScenarioCurrentYearDetails.BaseCostReplace, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceEquationType, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceConstIntercept, 
		dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceExpSlope, dbo.v_10_b_ScenarioCurrentYearDetails.ReplaceEUL, dbo.v_10_b_ScenarioCurrentYearDetails.RehabPercentEUL, 
		dbo.v_10_b_ScenarioCurrentYearDetails.RepairsRemaining, dbo.v_10_b_ScenarioCurrentYearDetails.RehabsRemaining, dbo.v_10_b_ScenarioCurrentYearDetails.LowRepair, 
		dbo.v_10_b_ScenarioCurrentYearDetails.HighRepair, dbo.v_10_b_ScenarioCurrentYearDetails.LowRehab, dbo.v_10_b_ScenarioCurrentYearDetails.HighRehab, dbo.v_10_b_ScenarioCurrentYearDetails.LowReplace, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PerformanceReplace, dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS YearRiskRaw, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS YearRiskScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemPhysRaw, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemLoFRaw, 
		CAST(dbo.v_10_b_ScenarioCurrentYearDetails.PhysScore AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemPhysScore, 
		CAST(dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemLoFScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.PhysRaw * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemCondition, 
		CAST(dbo.v_10_b_ScenarioCurrentYearDetails.LoFScore * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R AS float) * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemRiskScore, 
		dbo.v_10_b_ScenarioCurrentYearDetails.LoFRaw * dbo.v_10_b_ScenarioCurrentYearDetails.CoF_R * dbo.v_10_b_ScenarioCurrentYearDetails.AssetWeight / dbo.v_10_b_ScenarioCurrentYearDetails.TotalWeight AS SystemRiskRaw,
		CASE 
			WHEN [CostRepair] > 0 AND [RepairsRemaining] > 0 AND [PhysRaw] >= [LowRepair] AND [PhysRaw] < [HighRepair] AND [PerfScore] < [PerformanceReplace] THEN 'Repair' 
			WHEN [CostRehab] > 0 AND [RehabsRemaining] > 0 AND PhysRaw >= [LowRehab] AND [PhysRaw] < [HighRehab] AND [PerfScore] < [PerformanceReplace] THEN 'Rehab' 
			WHEN [PerfScore] >= [PerformanceReplace] OR [PhysRaw] >= [LowReplace] THEN 'Replace' 
		END AS ServiceType, 
		CASE 
			WHEN [CostRepair] > 0 AND [RepairsRemaining] > 0 AND [PhysRaw] >= [LowRepair] AND [PhysRaw] < [HighRepair] AND [PerfScore] < [PerformanceReplace] THEN [CostRepair] 
			WHEN [CostRehab] > 0 AND [RehabsRemaining] > 0 AND [PhysRaw] >= [LowRehab] AND [PhysRaw] < [HighRehab] AND [PerfScore] < [PerformanceReplace] THEN [CostRehab] 
			WHEN [PerfScore] >= [PerformanceReplace] OR [PhysRaw] >= [LowReplace] THEN [CostReplace] 
		END AS ServiceCost, 
		dbo.RR_ScenarioYears.UseProjectBudget
FROM	dbo.v_10_b_ScenarioCurrentYearDetails INNER JOIN
		dbo.RR_ScenarioYears ON dbo.v_10_b_ScenarioCurrentYearDetails.CurrentScenario_ID = dbo.RR_ScenarioYears.Scenario_ID 
		AND dbo.v_10_b_ScenarioCurrentYearDetails.CurrentYear = dbo.RR_ScenarioYears.BudgetYear
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [p___QC_ListTables] 
	@tablename nvarchar(64) = '%'
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @column nvarchar(64)
	DECLARE @type nvarchar(32)
	DECLARE @rows integer
	DECLARE @empty integer 
	DECLARE @zero integer 
	DECLARE @negative integer 
	DECLARE @sql nvarchar(MAX)

	CREATE TABLE #tempTables (TableName nvarchar(64), Records int)
	CREATE TABLE #tempColumns (ColumnName nvarchar(64), DataType nvarchar(32))
	CREATE TABLE #tempColumnDetails (TableName nvarchar(64), ColumnName nvarchar(64), DataType nvarchar(32), MinVal int, MaxVal Int, ZeroVals int, NegativeVals int, TotalRows int, DistinctVals int, Populated int)

	SET @sql = 'INSERT INTO #tempTables '
				+ 'SELECT sOBJ.name AS TableName, SUM(sPTN.Rows) AS Records '
				+ 'FROM sys.objects AS sOBJ INNER JOIN sys.partitions AS sPTN ON sOBJ.object_id = sPTN.object_id '
				+ 'WHERE sOBJ.type = ''U'' AND sOBJ.is_ms_shipped = 0x0 AND index_id < 2 '
				+ 'AND sOBJ.name LIKE ''' + @tablename + ''''
				+ 'GROUP BY sOBJ.name '
				+ 'HAVING SUM(sPTN.Rows) >0'
	--PRINT @sql;
	EXEC sp_executesql @sql;

	SELECT * FROM #tempTables ORDER BY TableName

	DECLARE c0 CURSOR
	FOR	SELECT TableName, Records FROM #tempTables WHERE Records > 0 ORDER BY TableName 
	OPEN c0
	FETCH NEXT FROM c0 INTO @tablename, @rows;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
	
	--PRINT @tablename;

		SET @sql = 'INSERT INTO #tempColumns '
					+ 'SELECT COLUMN_NAME, DATA_TYPE FROM ' + DB_NAME() + '.information_schema.columns '
					+ 'WHERE TABLE_NAME = ''' + @tablename + ''' ' 
					+ 'AND DATA_TYPE <> ''geometry'' '
					+ 'ORDER BY COLUMN_NAME'
		
		--PRINT @sql;
		exec sp_executesql @sql

		DECLARE c1 CURSOR
		FOR	SELECT ColumnName, DataType FROM #tempColumns ORDER BY ColumnName 
		OPEN c1
		FETCH NEXT FROM c1 INTO @column, @type;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			IF @type LIKE '%char%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(LEN(' + @column + ')) AS mn, MAX(LEN(' + @column + ')) AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ISNULL(' + @column + ', '''') = '''' THEN 0 ELSE 1 END) AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%smalldate%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(YEAR(' + @column + ')) AS mn, MAX(YEAR(' + @column + ')) AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL THEN 0 ELSE 1 END) AS Populated  FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%date%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(YEAR(' + @column + ')) AS mn, MAX(YEAR(' + @column + ')) AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL OR ' + @column + ' < ''1800-01-01'' THEN 0 ELSE 1 END) AS Populated  FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%bit%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, NULL AS mn, NULL AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, NULL AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%geometry%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, NULL AS mn, NULL AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(' + @column + ') AS mn, MAX(' + @column + ') AS mx, SUM(CASE WHEN ' + @column + ' = 0 THEN 1 ELSE 0 END) AS Zeros, SUM(CASE WHEN ' + @column + ' < 0 THEN 1 ELSE 0 END) AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL THEN 0 ELSE 1 END) AS Populated  FROM ' + QUOTENAME(@tablename)

			--PRINT @sql;
			exec sp_executesql @sql

			FETCH NEXT FROM c1 INTO @column, @type;
		END
		CLOSE c1;  
		DEALLOCATE c1;

		SELECT *, Format(ISNULL(CAST(Populated as real), 0.0) / @rows, '0.00%') AS PercentPopulated FROM #tempColumnDetails;
		DELETE FROM #tempColumnDetails;
		DELETE FROM #tempColumns;

		FETCH NEXT FROM c0 INTO @tablename, @rows;
	END
	CLOSE c0;  
	DEALLOCATE c0;

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_40_Update_Asset_Current_Results]
	--@ScenarioID int = -1  -- I dont think this was implemented until v5.005, not sure if this is any different from v5.001
AS
BEGIN

	SET NOCOUNT ON;

	--IF (@ScenarioID <> -1)
	--	BEGIN
	--		UPDATE RR_Config SET CurrentScenario_ID = @ScenarioID;
	--	END

	UPDATE	RR_Assets 
	SET		RR_Assets.RR_ReplaceYear = Null,
			RR_Assets.RR_ReplaceYearCost = Null,
			RR_Assets.RR_ReplaceYearLoFRaw = Null,
			RR_Assets.RR_ReplaceYearLoFScore = Null,
			RR_Assets.RR_RehabYear = Null,
			RR_Assets.RR_RehabYearCost = Null,
			RR_Assets.RR_RehabYearLoFRaw = Null,
			RR_Assets.RR_RehabYearLoFScore = Null;

	UPDATE	RR_Assets
	SET		RR_Assets.RR_ReplaceYear = v_40_FirstReplaceYear.ReplaceYear,
			RR_Assets.RR_ReplaceYearCost = v_40_FirstReplaceYear.ReplaceCost,
			RR_Assets.RR_ReplaceYearLoFRaw = v_40_FirstReplaceYear.ReplacePhysRaw,
			RR_Assets.RR_ReplaceYearLoFScore = v_40_FirstReplaceYear.ReplaceLoFScore,
			RR_Assets.RR_RehabYear = v_40_FirstRehabYear.RehabYear,
			RR_Assets.RR_RehabYearCost = v_40_FirstRehabYear.RehabCost,
			RR_Assets.RR_RehabYearLoFRaw = v_40_FirstRehabYear.RehabPhysRaw,
			RR_Assets.RR_RehabYearLoFScore = v_40_FirstRehabYear.RehabLoFScore			
	FROM	RR_Assets
			LEFT JOIN [dbo].[v_40_FirstRehabYear] ON [v_40_FirstRehabYear].[RR_Asset_ID] = RR_Assets.[RR_Asset_ID]
			LEFT JOIN [dbo].[v_40_FirstReplaceYear] ON [v_40_FirstReplaceYear].[RR_Asset_ID] = RR_Assets.[RR_Asset_ID]
	WHERE	([v_40_FirstReplaceYear].[ReplaceYear] IS NOT NULL) OR ([v_40_FirstRehabYear].[RehabYear] IS NOT NULL)

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_CriticalCustomers]
ALTER COLUMN [CustomerType] [nvarchar](64) NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_CriticalCustomers]
ALTER COLUMN [Category] [nvarchar](64) NULL;
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_00_07_HierarchyTree]
AS
SELECT	H1.RR_Hierarchy_ID AS ID1, H2.RR_Hierarchy_ID AS ID2, H3.RR_Hierarchy_ID AS ID3, H4.RR_Hierarchy_ID AS ID4, H5.RR_Hierarchy_ID AS ID5, NULL AS ID6, NULL AS ID7, NULL AS ID8, 
		H1.RR_Parent_ID AS P1, H2.RR_Parent_ID AS P2, H3.RR_Parent_ID AS P3, H4.RR_Parent_ID AS P4, H5.RR_Parent_ID AS P5, NULL AS P6, NULL AS P7, NULL AS P8, 
		H1.RR_HierarchyName AS Name1, H2.RR_HierarchyName AS Name2, H3.RR_HierarchyName AS Name3, H4.RR_HierarchyName AS Name4, H5.RR_HierarchyName AS Name5, NULL AS Name6, NULL AS Name7, NULL AS Name8, 
		COUNT(A1.RR_Asset_ID) AS AssetCount1, COUNT(A2.RR_Asset_ID) AS AssetCount2, COUNT(A3.RR_Asset_ID) AS AssetCount3, COUNT(A4.RR_Asset_ID) AS AssetCount4, COUNT(A5.RR_Asset_ID) AS AssetCount5, NULL AS AssetCount6, NULL AS AssetCount7, NULL AS AssetCount8
FROM	dbo.RR_Hierarchy AS H1 LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H2 ON H1.RR_Hierarchy_ID = H2.RR_Parent_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H3 ON H2.RR_Hierarchy_ID = H3.RR_Parent_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H4 ON H3.RR_Hierarchy_ID = H4.RR_Parent_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy AS H5 ON H4.RR_Hierarchy_ID = H5.RR_Parent_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A1 ON H1.RR_Hierarchy_ID = A1.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A2 ON H2.RR_Hierarchy_ID = A2.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A3 ON H3.RR_Hierarchy_ID = A3.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A4 ON H4.RR_Hierarchy_ID = A4.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.v__ActiveAssets AS A5 ON H5.RR_Hierarchy_ID = A5.RR_Hierarchy_ID 
GROUP BY H1.RR_Hierarchy_ID, H2.RR_Hierarchy_ID, H3.RR_Hierarchy_ID, H4.RR_Hierarchy_ID, H5.RR_Hierarchy_ID, 
		H1.RR_Parent_ID, H2.RR_Parent_ID, H3.RR_Parent_ID, H4.RR_Parent_ID, H5.RR_Parent_ID, 
		H1.RR_HierarchyName, H2.RR_HierarchyName, H3.RR_HierarchyName, H4.RR_HierarchyName, H5.RR_HierarchyName
HAVING	(H1.RR_Parent_ID IS NULL)
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [p___QC_ListTables] 
	@tablename nvarchar(64) = '%'
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @column nvarchar(64)
	DECLARE @type nvarchar(32)
	DECLARE @rows integer
	DECLARE @empty integer 
	DECLARE @zero integer 
	DECLARE @negative integer 
	DECLARE @sql nvarchar(MAX)

	CREATE TABLE #tempTables (TableName nvarchar(64), Records int)
	CREATE TABLE #tempColumns (ColumnName nvarchar(64), DataType nvarchar(32))
	CREATE TABLE #tempColumnDetails (TableName nvarchar(64), ColumnName nvarchar(64), DataType nvarchar(32), MinVal int, MaxVal Int, ZeroVals int, NegativeVals int, TotalRows int, DistinctVals int, Populated int)

	SET @sql = 'INSERT INTO #tempTables '
				+ 'SELECT sOBJ.name AS TableName, SUM(sPTN.Rows) AS Records '
				+ 'FROM sys.objects AS sOBJ INNER JOIN sys.partitions AS sPTN ON sOBJ.object_id = sPTN.object_id '
				+ 'WHERE sOBJ.type = ''U'' AND sOBJ.is_ms_shipped = 0x0 AND index_id < 2 '
				+ 'AND sOBJ.name LIKE ''' + @tablename + ''''
				+ 'GROUP BY sOBJ.name '
				+ 'HAVING SUM(sPTN.Rows) >0'
	--PRINT @sql;
	EXEC sp_executesql @sql;

	SELECT * FROM #tempTables ORDER BY TableName

	DECLARE c0 CURSOR
	FOR	SELECT TableName, Records FROM #tempTables WHERE Records > 0 ORDER BY TableName 
	OPEN c0
	FETCH NEXT FROM c0 INTO @tablename, @rows;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
	
	--PRINT @tablename;

		SET @sql = 'INSERT INTO #tempColumns '
					+ 'SELECT COLUMN_NAME, DATA_TYPE FROM ' + DB_NAME() + '.information_schema.columns '
					+ 'WHERE TABLE_NAME = ''' + @tablename + ''' ' 
					+ 'AND DATA_TYPE <> ''geometry'' '
					+ 'ORDER BY COLUMN_NAME'
		
		--PRINT @sql;
		exec sp_executesql @sql

		DECLARE c1 CURSOR
		FOR	SELECT ColumnName, DataType FROM #tempColumns ORDER BY ColumnName 
		OPEN c1
		FETCH NEXT FROM c1 INTO @column, @type;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			IF @type LIKE '%char%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(LEN(' + @column + ')) AS mn, MAX(LEN(' + @column + ')) AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ISNULL(' + @column + ', '''') = '''' THEN 0 ELSE 1 END) AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%smalldate%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(YEAR(' + @column + ')) AS mn, MAX(YEAR(' + @column + ')) AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL THEN 0 ELSE 1 END) AS Populated  FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%date%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(YEAR(' + @column + ')) AS mn, MAX(YEAR(' + @column + ')) AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL OR ' + @column + ' < ''1800-01-01'' THEN 0 ELSE 1 END) AS Populated  FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%bit%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, NULL AS mn, NULL AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, NULL AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%geometry%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, NULL AS mn, NULL AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, MIN(' + @column + ') AS mn, MAX(' + @column + ') AS mx, SUM(CASE WHEN ' + @column + ' = 0 THEN 1 ELSE 0 END) AS Zeros, SUM(CASE WHEN ' + @column + ' < 0 THEN 1 ELSE 0 END) AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL THEN 0 ELSE 1 END) AS Populated  FROM ' + QUOTENAME(@tablename)

			--PRINT @sql;
			exec sp_executesql @sql

			FETCH NEXT FROM c1 INTO @column, @type;
		END
		CLOSE c1;  
		DEALLOCATE c1;

		SELECT *, Format(ISNULL(CAST(Populated as real), 0.0) / @rows, '0.00%') AS PercentPopulated FROM #tempColumnDetails;
		DELETE FROM #tempColumnDetails;
		DELETE FROM #tempColumns;

		FETCH NEXT FROM c0 INTO @tablename, @rows;
	END
	CLOSE c0;  
	DEALLOCATE c0;

END



-- 2023-04-22 tweak
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_PBI_3DMatrix]
AS
SELECT	[Scenario ID], [Scenario Year] AS Year, [End LoF] AS [LoF End], LoF AS [LoF Start], CoF, [Risk Score] AS [Risk Start], [End Risk Score] AS [Risk End], ROUND(100 * SUM(Weight) / [Total Weight], 2) AS prcnt, 
		ROUND(SUM(PipeMiles), 2) AS mi, [Total Weight] / 5280 AS TotalMi, 
		CASE WHEN [End Risk Score] <= 5 THEN 1 WHEN [End Risk Score] <= 10 THEN 2 WHEN [End Risk Score] <= 15 THEN 3 WHEN [End Risk Score] <= 20 THEN 4 ELSE 5 END AS RiskGroup, 
		CASE WHEN SUM(Weight) / ([Total Weight]) < 0.01 THEN 1 WHEN SUM(Weight) / ([Total Weight]) < 0.02 THEN 2 WHEN SUM(Weight) / ([Total Weight]) < 0.04 THEN 3 
			WHEN SUM(Weight) / ([Total Weight]) < 0.08 THEN 4 WHEN SUM(Weight) / ([Total Weight]) < 0.16 THEN 5 WHEN SUM(Weight) / ([Total Weight]) < 0.32 THEN 6 ELSE 7 END AS Sz, 
		CASE WHEN [End Risk Score] <= 5 THEN '#00C8C8' WHEN [End Risk Score] <= 10 THEN '#009600' WHEN [End Risk Score] <= 15 THEN '#DCDC00' WHEN [End Risk Score] <= 20 THEN '#FF9600' ELSE '#C80000' END AS RiskColor
FROM	dbo.v_PBI_ScenariosResultsDetails
GROUP BY 
		CASE WHEN [End Risk Score] <= 5 THEN 1 WHEN [End Risk Score] <= 10 THEN 2 WHEN [End Risk Score] <= 15 THEN 3 WHEN [End Risk Score] <= 20 THEN 4 ELSE 5 END, 
		[Risk Score], LoF, CoF, [Scenario Year], [Scenario ID], [End LoF], [End Risk Score], [Total Weight]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [p___Alias_Views] 

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @viewtext NVARCHAR(MAX)
	DECLARE @ObjectName nvarchar(200)
	DECLARE @ObjectType nvarchar(2)
	DECLARE @NumRows integer
	DECLARE @ID integer = 0
	DECLARE @ColumnName nvarchar(64) 
	DECLARE @SearchText nvarchar(64) 
	DECLARE @ReplaceText nvarchar(64)
	DECLARE @Usage nvarchar(16)
	DECLARE @SQLtext NVARCHAR(MAX)
	
	-- Select the view and procedure definitions that need to be altered
	DECLARE c0 CURSOR
	FOR	SELECT DISTINCT 
		sysobjects.xtype AS [Object Type],
		sysobjects.name AS [Object Name]
		FROM sysobjects,syscomments
		WHERE sysobjects.id = syscomments.id
		AND sysobjects.type in ('P','V')
		AND sysobjects.category = 0
		AND sysobjects.name IN ('v__ActiveAssets', 'v__Inspections', 'p_04_Update_CoF_LoF_Risk', 'v_PBI_CoF_ByCat', 'v_PBI_Perf_ByCat', 'v_PBI_Physical_ByCat', 'v_PBI_OM_ByCat', 'v_QC_AssetPhysCond', 'v_QC_HierarchyPerfCondCoF');

	OPEN c0
	FETCH NEXT FROM c0 INTO @ObjectType, @ObjectName ;

	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		-- Each view and procedure could be defined across multiple records, so they need to be concatinated
		DECLARE c1 CURSOR
		FOR	SELECT syscomments.text AS NEWTEXT, row_number() OVER (ORDER BY syscomments.text ) as Rownum
			FROM sysobjects,syscomments
			WHERE sysobjects.id = syscomments.id
			AND sysobjects.name = @ObjectName
			ORDER BY colid;
		OPEN c1
		FETCH NEXT FROM c1 INTO  @viewtext, @NumRows ;

		WHILE @@FETCH_STATUS = 0  
		BEGIN -- Insert and upadate of current view/proc in rr_UpdateAlias  

			IF @ID = 0 
				BEGIN
					INSERT INTO rr_UpdateAlias (SQLText) VALUES ('');
					SELECT @ID = @@IDENTITY  --Get row ID of the view/proc being saved in rr_UpdateAlias
				END

			IF @ObjectType = 'V' 
				BEGIN
					UPDATE rr_UpdateAlias SET SQLText = SQLText +  REPLACE(@viewtext,'CREATE VIEW','ALTER VIEW') WHERE ID = @ID;
				END
			ELSE IF  @ObjectType = 'P'   
				BEGIN
					UPDATE rr_UpdateAlias SET SQLText = SQLText +  REPLACE(@viewtext,'CREATE PROCEDURE','ALTER PROCEDURE') WHERE ID = @ID;
				END
			
			FETCH NEXT FROM c1 INTO  @viewtext, @NumRows ;
		END -- Insert and upadate of current view/proc in rr_UpdateAlias
		CLOSE c1;  
		DEALLOCATE c1; 

			
		DECLARE c2 CURSOR
		FOR	SELECT ColumnName, SearchText, ReplaceText, Usage FROM RR_ConfigAliases;
		OPEN c2
		FETCH NEXT FROM c2 INTO  @ColumnName, @SearchText, @ReplaceText, @Usage;
		WHILE @@FETCH_STATUS = 0  
		BEGIN  -- search and replace of current view/proc in rr_UpdateAlias  
			IF @Usage <> 'NA' --Update aliases
				UPDATE rr_UpdateAlias SET SQLText = REPLACE(SQLText, @SearchText, @ReplaceText) WHERE ID = @ID;

			IF LOWER(@ObjectName) = 'p_04_update_cof_lof_risk'
				BEGIN
					IF @Usage = 'NA' 
						BEGIN  -- Make sure Usage NA null values are set to 0 
							UPDATE	rr_UpdateAlias 
							SET		SQLText = REPLACE(SQLText, 
													'[' + @ColumnName + '] = CASE WHEN ISNULL([' + @ColumnName + '], 0) = 0 THEN 1 ELSE [' + @ColumnName + '] END', 
													'[' + @ColumnName + '] = CASE WHEN ISNULL([' + @ColumnName + '], 0) = 0 THEN 0 ELSE [' + @ColumnName + '] END') 
							WHERE	ID = @ID;
						END
					ELSE 
						BEGIN  -- Usage Hierarchy or Attribute

							-- Make sure Usage Hierarchy and Attribute null values are set to 1 
							UPDATE	rr_UpdateAlias 
							SET		SQLText = REPLACE(SQLText, 
													'[' + @ColumnName + '] = CASE WHEN ISNULL([' + @ColumnName + '], 0) = 0 THEN 0 ELSE [' + @ColumnName + '] END', 
													'[' + @ColumnName + '] = CASE WHEN ISNULL([' + @ColumnName + '], 0) = 0 THEN 1 ELSE [' + @ColumnName + '] END') 
							WHERE	ID = @ID;
						END

					IF @Usage = 'NA' OR @Usage = 'Attribute'
						BEGIN  -- Make sure Usage NA or Attribute have hierarchy assignment commented out 
							UPDATE	rr_UpdateAlias 
							SET		SQLText = REPLACE(SQLText, 
													',[RR_Assets].[' + @ColumnName + '] = CASE WHEN ISNULL([RR_Hierarchy].[' + @ColumnName + '], 0)', 
													' --,[RR_Assets].[' + @ColumnName + '] = CASE WHEN ISNULL([RR_Hierarchy].[' + @ColumnName + '], 0)' )
							WHERE	ID = @ID 
									AND SQLText NOT LIKE '% --,[[]RR_Assets].[[]' + @ColumnName + '] = CASE WHEN ISNULL([[]RR_Hierarchy].[[]' + @ColumnName + '], 0)%';
						END
					ELSE 
						BEGIN -- Make sure Usage Hierarchy does NOT have hierarchy assignment commented out
							UPDATE	rr_UpdateAlias 
							SET		SQLText = REPLACE(SQLText, 
													' --,[RR_Assets].[' + @ColumnName + '] = CASE WHEN ISNULL([RR_Hierarchy].[' + @ColumnName + '], 0)', 
													',[RR_Assets].[' + @ColumnName + '] = CASE WHEN ISNULL([RR_Hierarchy].[' + @ColumnName + '], 0)' )
							WHERE	ID = @ID;
						END
				END -- p_04_Update_CoF_LoF_Risk

			FETCH NEXT FROM c2 INTO  @ColumnName, @SearchText, @ReplaceText, @Usage ;
		END  -- search and replace of current view/proc in rr_UpdateAlias
		CLOSE c2;  
		DEALLOCATE c2;

		SELECT @SQLtext = (SELECT SQLText FROM rr_UpdateAlias WHERE ID = @ID);
		EXEC (@SQLtext);

		SELECT @ID = 0; -- reset to trigger new record on next loop


		FETCH NEXT FROM c0 INTO @ObjectType, @ObjectName ;
	END  -- selection of current view/proc
	CLOSE c0;  
	DEALLOCATE c0; 

	--Update to ConfigTableLookup for NA Usage
	DECLARE c2 CURSOR
	FOR	SELECT ColumnName, SearchText, ReplaceText FROM RR_ConfigAliases; -- WHERE Usage = 'NA';
	OPEN c2
	FETCH NEXT FROM c2 INTO @ColumnName, @SearchText, @ReplaceText ;
	WHILE @@FETCH_STATUS = 0  
	BEGIN    
		
		UPDATE	RR_ConfigTableLookup 
		SET		ColumnWidth = -1  --Hide column
		WHERE	ColumnName = @ColumnName AND TableName IN ('Asset Attributes', 'HierarchyAssets', 'Hierarchy', 'Inspections');
			
		FETCH NEXT FROM c2 INTO @ColumnName, @SearchText, @ReplaceText ;
	END  
	CLOSE c2;  
	DEALLOCATE c2;

	--Update to ConfigTableLookup for Attribute Usage
	DECLARE c2 CURSOR
	FOR	SELECT ColumnName, SearchText, ReplaceText FROM RR_ConfigAliases WHERE Usage = 'Attribute';
	OPEN c2
	FETCH NEXT FROM c2 INTO @ColumnName, @SearchText, @ReplaceText ;
	WHILE @@FETCH_STATUS = 0  
	BEGIN    
		
		UPDATE	RR_ConfigTableLookup 
		SET		ColumnAlias = @ReplaceText,
				ColumnWidth = 60
		WHERE	ColumnName = @ColumnName AND TableName IN ('Asset Attributes', 'Inspections');
			
		FETCH NEXT FROM c2 INTO @ColumnName, @SearchText, @ReplaceText ;
	END  
	CLOSE c2;  
	DEALLOCATE c2;

		--Update to ConfigTableLookup for Hierarchy Usage
	DECLARE c2 CURSOR
	FOR	SELECT ColumnName, SearchText, ReplaceText FROM RR_ConfigAliases WHERE Usage = 'Hierarchy';
	OPEN c2
	FETCH NEXT FROM c2 INTO @ColumnName, @SearchText, @ReplaceText ;
	WHILE @@FETCH_STATUS = 0  
	BEGIN    
		
		UPDATE	RR_ConfigTableLookup 
		SET		ColumnAlias = @ReplaceText,
				ColumnWidth = 60
		WHERE	ColumnName = @ColumnName AND TableName IN ('Asset Attributes', 'HierarchyAssets', 'Hierarchy');
			
		FETCH NEXT FROM c2 INTO @ColumnName, @SearchText, @ReplaceText ;
	END  
	CLOSE c2;  
	DEALLOCATE c2;

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v__RuntimeResults]
AS
SELECT	dbo.RR_RuntimeAssets.Config_ID, dbo.RR_RuntimeConfig.CurrentScenario_ID, dbo.RR_RuntimeConfig.CurrentYear, dbo.RR_RuntimeConfig.CurrentBudget, dbo.v__ActiveAssets.RR_Asset_ID, 
		dbo.v__ActiveAssets.RR_Cohort_ID, dbo.RR_DegradationPoints.Condition AS StatsCondition, dbo.v__InventoryWeight.ConditionLimit, 
		dbo.RR_RuntimeConfig.CurrentYear - dbo.RR_RuntimeAssets.CurrentInstallYear AS CurrentAge, 
		ROUND(CASE WHEN RR_DegradationPoints.Condition IS NOT NULL THEN RR_DegradationPoints.Condition ELSE CurrentFailurePhysOffset + dbo.f_RR_CurveCondition(CurrentEquationType, CurrentConstIntercept, CurrentYear - CurrentInstallYear + CurrentAgeOffset, CurrentExpSlope) END, 2) AS PrelimCondition, 
		ROUND(CASE WHEN RR_DegradationPoints.Condition IS NOT NULL THEN RR_DegradationPoints.Condition ELSE CurrentFailurePhysOffset + dbo.f_RR_CurveCondition(CurrentEquationType, CurrentConstIntercept, CurrentYear - CurrentInstallYear + CurrentAgeOffset, CurrentExpSlope) END, 2) AS PrelimPhysRaw, 
		dbo.v__ActiveAssets.RR_LoFPerf, dbo.v__ActiveAssets.RR_LoFPhys, dbo.v__ActiveAssets.RR_RedundancyFactor, dbo.v__ActiveAssets.RR_CoF, 
		dbo.v__ActiveAssets.RR_CoF_R, dbo.v__ActiveAssets.RR_InstallYear, dbo.v__ActiveAssets.RR_ProjectNumber, 0 AS CostRepair, 
		ROUND(dbo.v__ActiveAssets.RR_CostRehab * dbo.v__InventoryWeight.CostMultiplier, 0) AS CostRehab, 
		ROUND( dbo.v__ActiveAssets.RR_CostReplace * dbo.v__InventoryWeight.CostMultiplier, 0) AS CostReplace, 
		dbo.v__ActiveAssets.RR_CostReplace AS BaseCostReplace, dbo.RR_RuntimeAssets.CurrentInstallYear, 
		dbo.RR_RuntimeAssets.CurrentEquationType, dbo.RR_RuntimeAssets.CurrentConstIntercept, dbo.RR_RuntimeAssets.CurrentExpSlope, dbo.RR_RuntimeAssets.CurrentFailurePhysOffset, 
		dbo.RR_RuntimeAssets.CurrentAgeOffset, dbo.RR_RuntimeAssets.CurrentPerformance, dbo.v__ActiveAssets.RR_Length AS PipeFeet, dbo.v__ActiveAssets.RR_Length / 5280 AS PipeMiles, 
		dbo.v__ActiveAssets.RR_Length * 0.3048 AS PipeMeters, dbo.RR_Cohorts.ReplaceEquationType, dbo.RR_Cohorts.ReplaceConstIntercept, dbo.RR_Cohorts.ReplaceExpSlope, dbo.RR_Cohorts.ReplaceEUL, 
		 dbo.v__InventoryWeight.RehabPercentEUL, dbo.v__ActiveAssets.RR_EUL AS InitEUL, dbo.RR_RuntimeAssets.RepairsRemaining, dbo.RR_RuntimeAssets.RehabsRemaining, dbo.RR_Cohorts.RepairsAllowed, 
		dbo.RR_Cohorts.RehabsAllowed, dbo.RR_CriticalityActionLimits.LowRepair, dbo.RR_CriticalityActionLimits.HighRepair, dbo.RR_CriticalityActionLimits.LowRehab, dbo.RR_CriticalityActionLimits.HighRehab, 
		dbo.RR_CriticalityActionLimits.LowReplace, dbo.RR_CriticalityActionLimits.PerformanceReplace, dbo.v__ActiveAssets.Weighting AS AssetWeight, dbo.v__InventoryWeight.Weight AS TotalWeight, 
		dbo.v__InventoryWeight.ActiveAssets AS Assets, dbo.v__InventoryWeight.Feet AS TotalLength, dbo.v__InventoryWeight.CostMultiplier
FROM	dbo.v__InventoryWeight INNER JOIN
		dbo.v__ActiveAssets INNER JOIN
		dbo.RR_RuntimeAssets ON dbo.RR_RuntimeAssets.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID INNER JOIN
		dbo.RR_Cohorts ON dbo.v__ActiveAssets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID INNER JOIN
		dbo.RR_CriticalityActionLimits ON dbo.v__ActiveAssets.RR_CoF_R = dbo.RR_CriticalityActionLimits.Criticality INNER JOIN
		dbo.RR_RuntimeConfig ON dbo.RR_RuntimeAssets.Config_ID = dbo.RR_RuntimeConfig.ID ON dbo.v__InventoryWeight.Config_ID = dbo.RR_RuntimeAssets.Config_ID LEFT OUTER JOIN
		dbo.RR_DegradationPoints ON dbo.RR_RuntimeConfig.CurrentYear = dbo.RR_DegradationPoints.ConditionYear AND dbo.RR_RuntimeAssets.RR_Asset_ID = dbo.RR_DegradationPoints.Asset_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_00_11_Revisions]
AS
SELECT	ID, Notes, CreatedOn, CreatedBy, LastEditedOn, LastEditedBy
FROM	dbo.RR_Revisions
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_90_AssignCoFLoF]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Fld nvarchar(64), @Descript nvarchar(32), @NoteField nvarchar(32), @SQL nvarchar(MAX), @ID INT, @StartDT datetime,
	@sRefTable nvarchar(64), @RefGeoField nvarchar(32);
	
	-- Initialize CoF or LoF to 1 where not negative and Field is active in RR_ConfigCoFLoF
	DECLARE c0 CURSOR
	FOR SELECT  Attribute, RefTable, ISNULL(RefGeoField, '') AS RefGeoField FROM RR_ConfigCoFLoF WHERE Active = 1 GROUP BY Attribute, RefTable, ISNULL(RefGeoField, '');
	OPEN c0
	FETCH NEXT FROM c0 INTO @Fld, @sRefTable, @RefGeoField

	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		IF @RefGeoField <> ''  SELECT @sRefTable = 'v__ActiveAssets'  
		
		SELECT	@SQL = 'UPDATE ' + @sRefTable + ' SET [' + @Fld + '] = CASE WHEN ISNULL([' + @Fld + '], 0) >= 0 THEN 1 ELSE [' + @Fld + '] END;'  -- WHERE RR_Status = 1;'
		EXEC	(@SQL);

		--Remove existing comments
		DECLARE c1 CURSOR
		FOR SELECT DISTINCT Description, NoteField FROM RR_ConfigCoFLoF WHERE Active = 1 AND Attribute = @Fld;
		OPEN c1
		FETCH NEXT FROM c1 INTO @Descript, @NoteField
		WHILE @@FETCH_STATUS = 0  
			BEGIN  

			SELECT	@SQL = 'UPDATE ' + @sRefTable + ' SET [' + @NoteField + '] = REPLACE(REPLACE(REPLACE([' + @NoteField + '], ''' + @Descript + ', '', ''''), '', ' + @Descript + ''', ''''), ''' + @Descript + ''', '''') WHERE [' + @NoteField + '] LIKE ''%' + @Descript + '%'';' 
			EXEC	(@SQL);
			--PRINT @SQL;

			FETCH NEXT FROM c1 INTO @Descript, @NoteField
		END
		CLOSE c1;  
		DEALLOCATE c1;

		FETCH NEXT FROM c0 INTO @Fld, @sRefTable, @RefGeoField
	END   
	CLOSE c0;  
	DEALLOCATE c0; 

	-- Apply CoF or LoF criteria where active in RR_ConfigCoFLoF
	DECLARE c0 CURSOR
	FOR SELECT ConfigCoFLoF_ID, SQL FROM v_90_CoF_LoF ORDER by Attribute, AttributeValue DESC, OrderNum;
	OPEN c0
	FETCH NEXT FROM c0 INTO @ID, @SQL

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
	
		SELECT  @StartDT = Getdate();
		EXEC	(@SQL);

		UPDATE	RR_ConfigCoFLoF
		SET		Records = @@RowCount,
				Duration = DATEDIFF(ms, @StartDT, Getdate()) * 0.001,
				LastRun = Getdate()
		WHERE	ConfigCoFLoF_ID = @ID;
		
		FETCH NEXT FROM c0 INTO @ID, @SQL
	END   
	CLOSE c0;  
	DEALLOCATE c0;  

END
GO


ALTER TABLE [RR_Config] DROP  CONSTRAINT [DF_RR_Config_Version] ;
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_Version]  DEFAULT (5.004) FOR [Version];
GO


UPDATE RR_CONFIG SET VERSION = 5.004;
GO






--v5.005
--v__InventoryWeight:  Added LoF raw, LoF, CoF and Risk
--v_QC_Loaded_ActiveAssets:  Added more stats including current LoF, CoF and Risk
--v_QC_Stats_Cohorts:  Added AvgDia
--Temp v5.005a
--RR_ScenarioTargetBudgets:  RENAMED to deleted and CREATED VIEW of same name for v4 compatability
--p_40_Update_Asset_Current_Results: Add Scenario ID parameter with default of -1 so it still works with v4
--Temp v5.005b
--v_14_ScenarioSummary:  Ensure the orignial with CostOfService>0 filter is being used
--Temp v5.005c
--RR_ScenarioYears:  Added LoF5Remaining and Risk16Remaining,  Copy values and drop LoF5Miles and Risk15Miles
--RR_Config:  Added WeightMultiplier adn set default to 1 (facilities),  Linear should be 0.00018393939
--v_70_GraphScenarioResults:  Updated for LoF5Remaining and Risk16Remaining
--v_14_Results_Summary:  Added LoF5Remaining and Risk16Remaining to use Weighting * WeightMultiplier
--p_14_Results_Summary_Update:  Updated to use LoF5Remaining and Risk16Remaining
--v_PBI_ScenariosResultsSummary:  Added LoF5Remaining and Risk16Remaining

--p_03_UpdateAssetCurves:  Set Rehabs Allowed to 0 if RR_ReplacementDiameter>RR_Diameter 2023-09-03

--RR_Config:  Added Initialized  2023-09-08
--v_00_03_Config:  Added Initialized
--p_04_Update_CoF_LoF_Risk:  Updated to set Initialized

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v__InventoryWeight]
AS
SELECT	1 AS Config_ID, SUM(1) AS ActiveAssets, SUM(dbo.v__ActiveAssets.RR_Length) AS Feet, SUM(dbo.v__ActiveAssets.RR_Length / 5280) AS Miles, 
		SUM(dbo.v__ActiveAssets.RR_Length / 3308) AS Km, SUM(CAST(dbo.v__ActiveAssets.RR_CostRehab AS float)) AS RehabCost, 
		SUM(CAST(dbo.v__ActiveAssets.RR_CostReplace AS float)) AS AssetCost, SUM(dbo.v__ActiveAssets.RR_CostReplace * dbo.RR_Config.CostMultiplier) AS CapitalCost, 
		SUM(dbo.v__ActiveAssets.Weighting) AS Weight, dbo.RR_Config.CostMultiplier, dbo.RR_Config.ConditionLimit, dbo.RR_Config.ConditionFailureFactor, 
		dbo.RR_Config.RehabPercentEUL, dbo.RR_Config.BaselineYear, 
		SUM(dbo.v__ActiveAssets.RR_LoFEUL * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting) AS AvgLoFRaw, 
		SUM(dbo.v__ActiveAssets.RR_LoF * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting) AS AvgLoFScore, 
		SUM(dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting) AS AvgCoFScore, 
		SUM(dbo.v__ActiveAssets.RR_Risk * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting) AS AvgRiskScore
FROM	dbo.v__ActiveAssets INNER JOIN
		dbo.RR_Config ON dbo.v__ActiveAssets.RR_Config_ID = dbo.RR_Config.ID
GROUP BY dbo.RR_Config.CostMultiplier, dbo.RR_Config.ConditionLimit, dbo.RR_Config.ConditionFailureFactor, dbo.RR_Config.RehabPercentEUL, dbo.RR_Config.BaselineYear
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_QC_Loaded_ActiveAssets]
AS
SELECT	FORMAT(ActiveAssets, '#,##0') AS [Active Assets], FORMAT(Feet, '#,##0') AS Feet, FORMAT(Miles, '#,##0.##') AS Miles, 
		FORMAT(Km, '#,##0.##') AS Km, FORMAT(RehabCost, '$#,##0') AS [Rehab Cost], FORMAT(AssetCost, '$#,##0') AS [Asset Cost], 
		CostMultiplier AS [Multiplier], FORMAT(CapitalCost, '$#,##0') AS [Capital Cost], BaselineYear AS [Year], 
		ROUND(AvgLoFRaw, 2) AS [LoF Raw], ROUND(AvgLoFScore, 2) AS [LoF], ROUND(AvgCoFScore, 2) AS [CoF], ROUND(AvgRiskScore, 2) AS [Risk], 
		ConditionLimit AS [Condition Limit], ConditionFailureFactor AS [Failure Factor], RehabPercentEUL AS [Rehab EUL %]
FROM	dbo.v__InventoryWeight
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_QC_Stats_Cohorts]
AS
SELECT	dbo.RR_Cohorts.CohortName, dbo.RR_Cohorts.InitEUL AS EUL, MIN(dbo.v__ActiveAssets.RR_Diameter) AS MinDia,	
		ROUND(SUM(dbo.v__ActiveAssets.RR_Diameter * dbo.v__ActiveAssets.RR_Length) / SUM(dbo.v__ActiveAssets.RR_Length), 1) AS AvgDia, 
		MAX(dbo.v__ActiveAssets.RR_Diameter) AS MaxDia, MIN(dbo.v__ActiveAssets.RR_InstallYear) AS MinYear, MAX(dbo.v__ActiveAssets.RR_InstallYear) AS MaxYear, 
		ROUND(SUM((dbo.v__InventoryWeight.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear) * dbo.v__ActiveAssets.RR_Length) / SUM(dbo.v__ActiveAssets.RR_Length), 1) AS AvgAge, 
		SUM(dbo.v__ActiveAssets.RR_PreviousFailures) AS Failures, ROUND(SUM(dbo.v__ActiveAssets.RR_Length / 5280), 2) AS Miles,
		FORMAT(SUM(1), '##,##0') AS Assets, 
		FORMAT(SUM(CAST(dbo.v__ActiveAssets.Weighting AS float) / dbo.v__InventoryWeight.Weight), '0.00%') AS [Percent], 
		FORMAT(SUM(dbo.v__ActiveAssets.RR_CostReplace), '$#,##0') AS [Asset Cost]
FROM	dbo.v__ActiveAssets INNER JOIN
		dbo.v__InventoryWeight ON dbo.v__ActiveAssets.RR_Config_ID = dbo.v__InventoryWeight.Config_ID INNER JOIN
		dbo.RR_Cohorts ON dbo.v__ActiveAssets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID
GROUP BY dbo.RR_Cohorts.CohortName, dbo.RR_Cohorts.InitEUL
GO

--Temp v5.005a
exec sp_rename 'dbo.RR_ScenarioTargetBudgets', 'dbo.RR_ScenarioTargetBudgets_DELETE'

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[RR_ScenarioTargetBudgets]
AS
SELECT        BudgetYear_ID, Scenario_ID, BudgetYear, Budget, AllocationToRisk, ConditionTarget, RiskTarget, UseProjectBudget
FROM            dbo.RR_ScenarioYears
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_40_Update_Asset_Current_Results]
	@ScenarioID int = -1
AS
BEGIN

	SET NOCOUNT ON;

	IF (@ScenarioID <> -1)
		BEGIN
			UPDATE RR_Config SET CurrentScenario_ID = @ScenarioID;
		END

	UPDATE	RR_Assets 
	SET		RR_Assets.RR_ReplaceYear = Null,
			RR_Assets.RR_ReplaceYearCost = Null,
			RR_Assets.RR_ReplaceYearLoFRaw = Null,
			RR_Assets.RR_ReplaceYearLoFScore = Null,
			RR_Assets.RR_RehabYear = Null,
			RR_Assets.RR_RehabYearCost = Null,
			RR_Assets.RR_RehabYearLoFRaw = Null,
			RR_Assets.RR_RehabYearLoFScore = Null;

	UPDATE	RR_Assets
	SET		RR_Assets.RR_ReplaceYear = v_40_FirstReplaceYear.ReplaceYear,
			RR_Assets.RR_ReplaceYearCost = v_40_FirstReplaceYear.ReplaceCost,
			RR_Assets.RR_ReplaceYearLoFRaw = v_40_FirstReplaceYear.ReplacePhysRaw,
			RR_Assets.RR_ReplaceYearLoFScore = v_40_FirstReplaceYear.ReplaceLoFScore,
			RR_Assets.RR_RehabYear = v_40_FirstRehabYear.RehabYear,
			RR_Assets.RR_RehabYearCost = v_40_FirstRehabYear.RehabCost,
			RR_Assets.RR_RehabYearLoFRaw = v_40_FirstRehabYear.RehabPhysRaw,
			RR_Assets.RR_RehabYearLoFScore = v_40_FirstRehabYear.RehabLoFScore			
	FROM	RR_Assets
			LEFT JOIN [dbo].[v_40_FirstRehabYear] ON [v_40_FirstRehabYear].[RR_Asset_ID] = RR_Assets.[RR_Asset_ID]
			LEFT JOIN [dbo].[v_40_FirstReplaceYear] ON [v_40_FirstReplaceYear].[RR_Asset_ID] = RR_Assets.[RR_Asset_ID]
	WHERE	([v_40_FirstReplaceYear].[ReplaceYear] IS NOT NULL) OR ([v_40_FirstRehabYear].[RehabYear] IS NOT NULL)

END
GO


--Temp v5.005b
--Ensure the orignial with CostOfService>0 filter is being used
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_14_ScenarioSummary]
AS
	SELECT	dbo.RR_Scenarios.Scenario_ID,
			SUM(CAST(dbo.RR_ScenarioResults.CostOfService AS bigint)) AS TotalCost, 
			SUM(dbo.v__ActiveAssets.Weighting) AS TotalWeight, 
			SUM(CASE WHEN Service = 'Replace' THEN CostOfService ELSE 0 END) AS TotalReplaceCost, 
			SUM(CASE WHEN Service = 'Rehab' THEN CostOfService ELSE 0 END) AS TotalRehabCost, 
			SUM(CASE WHEN Service = 'Replace' THEN Weighting ELSE 0 END) AS TotalReplacedAssets, 
			SUM(CASE WHEN Service = 'Rehab' THEN Weighting ELSE 0 END) AS TotalRehabbedAssets
	FROM	dbo.RR_Scenarios INNER JOIN
			dbo.RR_ScenarioResults ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioResults.Scenario_ID INNER JOIN
			dbo.v__ActiveAssets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID
	WHERE	(dbo.RR_ScenarioResults.CostOfService > 0)
	GROUP BY dbo.RR_Scenarios.Scenario_ID
GO


--Temp v5.005c
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [RR_ScenarioYears] ADD
	[LoF5Remaining] [float] NULL,
	[Risk16Remaining] [float] NULL;
GO

UPDATE	[RR_ScenarioYears]
SET		LoF5Remaining = Lof5Miles,
		Risk16Remaining = Risk16Miles;
GO

ALTER TABLE [RR_ScenarioYears] DROP COLUMN 
	LoF5Miles,
	Risk16Miles;
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [RR_Config] ADD
	[WeightMultiplier] [float] NULL;
GO

UPDATE RR_Config 
SET WeightMultiplier = 0.000893939;  --Linear specific , must be changed to 1 for facilities
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_70_GraphScenarioResults]
AS
SELECT	Scenario_ID, BudgetYear AS ScenarioYear, ActualBudget / 1000000 AS Budget, 
		OverallLoFRawWeighted AS OverallCondition, OverallRiskScoreWeighted AS OverallRisk, 
		LoF5Remaining, Risk16Remaining
FROM	dbo.RR_ScenarioYears
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_14_Results_Summary]
AS
SELECT	dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear, SUM(1) AS TotalCount, SUM(dbo.v__ActiveAssets.Weighting) AS TotalWeighting, 
		SUM(CAST(dbo.RR_ScenarioResults.Age * dbo.v__ActiveAssets.Weighting AS float)) AS TotalAgeWeighted, AVG(CAST(dbo.RR_ScenarioResults.Age AS FLOAT)) AS TotalAgeAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PhysRaw * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPhysRawWeighted, AVG(dbo.RR_ScenarioResults.PhysRaw) AS TotalPhysRawAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PhysScore * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPhysScoreWeighted, AVG(CAST(dbo.RR_ScenarioResults.PhysScore AS FLOAT)) AS TotalPhysScoreAvg, 
		SUM(CAST(dbo.RR_ScenarioResults.PerfScore * dbo.v__ActiveAssets.Weighting AS float)) AS TotalPerfScoreWeighted, AVG(dbo.RR_ScenarioResults.PerfScore) AS TotalPerfScoreAvg, 
		SUM(CAST(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.Weighting AS float)) AS TotalLoFRawWeighted, 
		AVG(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END) AS TotalLoFRawAvg, 
		SUM(CAST(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.Weighting AS float)) AS TotalLoFScoreWeighted, 
		AVG(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END) AS TotalLoFScoreAvg, SUM(CAST(dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalCoFWeighted, 
		AVG(CAST(dbo.v__ActiveAssets.RR_CoF_R AS FLOAT)) AS TotalCoFAvg, 
		SUM(CAST(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalRiskRawWeighted, 
		AVG(CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R) AS TotalRiskRawAvg, 
		SUM(CAST(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R * dbo.v__ActiveAssets.Weighting AS float)) AS TotalRiskScoreWeighted, 
		AVG(CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * dbo.v__ActiveAssets.RR_CoF_R) AS TotalRiskScoreAvg, SUM(dbo.RR_ScenarioResults.CostOfService) AS PreviousCost, 
		SUM(dbo.RR_ScenarioResults.CostOfService) + MIN(ISNULL(dbo.v_14_Results_Summary_ProjectOverrideCosts.CostDiff, 0)) AS Cost, SUM(CASE WHEN [CostOfService] > 0 THEN 1 ELSE 0 END) AS ReplacedCount, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN Weighting ELSE 0 END AS float)) AS ReplacedWeighting, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [Age] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedAgeWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CAST([Age] AS FLOAT) ELSE NULL END) AS ReplacedAgeAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PhysRaw] * Weighting ELSE 0 END AS float)) AS ReplacedPhysRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN [PhysRaw] ELSE NULL END) AS ReplacedPhysRawAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PerfScore] * Weighting ELSE 0 END AS float)) AS ReplacedPhysScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CAST([PerfScore] AS FLOAT) ELSE NULL END) AS ReplacedPhysScoreAvg, SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [PerfScore] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedPerfScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN [PerfScore] ELSE NULL END) AS ReplacedPerfScoreAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedLoFRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END ELSE NULL END) AS ReplacedLoFRawAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedLoFScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END ELSE NULL END) AS ReplacedLoFScoreAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN [RR_COF_R] ELSE 0 END * dbo.v__ActiveAssets.Weighting AS float)) AS ReplacedCoFWeighted, AVG(CASE WHEN [CostOfService] > 0 THEN CAST([RR_COF_R] AS FLOAT) ELSE NULL END) AS ReplacedCoFAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * [RR_COF_R] * Weighting ELSE 0 END AS float)) AS ReplacedRiskRawWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysRaw] > [PerfScore] THEN [PhysRaw] ELSE [PerfScore] END * [RR_COF_R] ELSE NULL END) AS ReplacedRiskRawAvg, 
		SUM(CAST(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * RR_COF_R * Weighting ELSE 0 END AS float)) AS ReplacedRiskScoreWeighted, 
		AVG(CASE WHEN [CostOfService] > 0 THEN CASE WHEN [PhysScore] > [PerfScore] THEN [PhysScore] ELSE [PerfScore] END * [RR_COF_R] ELSE NULL END) AS ReplacedRiskScoreAvg, 
		MIN(dbo.v__ActiveAssets.RR_CoF_R) AS MinOfCoF, MAX(dbo.v__ActiveAssets.RR_CoF_R) AS MaxOfCoF,
		SUM(CASE WHEN Service = 'Maintain' AND CASE WHEN PhysScore > PerfScore THEN PhysScore ELSE PerfScore END = 5 THEN Weighting * WeightMultiplier ELSE 0 END) AS LoF5Remaining, 
		SUM(CASE WHEN Service = 'Maintain' AND CASE WHEN PhysScore > PerfScore THEN PhysScore ELSE PerfScore END * RR_CoF_R >= 16 THEN Weighting * WeightMultiplier ELSE 0 END) AS Risk16Remaining
FROM	dbo.RR_Config INNER JOIN
		dbo.RR_ScenarioResults INNER JOIN
		dbo.v__ActiveAssets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID INNER JOIN
		dbo.RR_RuntimeConfig ON dbo.RR_ScenarioResults.Scenario_ID = dbo.RR_RuntimeConfig.CurrentScenario_ID ON dbo.RR_Config.ID = dbo.RR_RuntimeConfig.ID LEFT OUTER JOIN
		dbo.v_14_Results_Summary_ProjectOverrideCosts ON dbo.RR_ScenarioResults.Scenario_ID = dbo.v_14_Results_Summary_ProjectOverrideCosts.Scenario_ID AND 
		dbo.RR_ScenarioResults.ScenarioYear = dbo.v_14_Results_Summary_ProjectOverrideCosts.BudgetYear
GROUP BY dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_14_Results_Summary_Update]
AS
BEGIN

	SET NOCOUNT ON;
	
	UPDATE	[RR_ScenarioYears]
	SET		[ActualBudget] = a.[Cost]
			, [OverallCount] = a.[TotalCount]
			, [OverallWeighting] = a.[TotalWeighting]
			, [OverallAgeWeighted] = a.[TotalAgeWeighted]/[TotalWeighting]
			, [OverallAgeAvg] = a.[TotalAgeAvg]
			, [OverallPhysRawWeighted] = a.[TotalPhysRawWeighted]/[TotalWeighting]
			, [OverallPhysRawAvg] = a.[TotalPhysRawAvg]
			, [OverallPhysScoreWeighted] = a.[TotalPhysScoreWeighted]/[TotalWeighting]
			, [OverallPhysScoreAvg] = a.[TotalPhysScoreAvg]
			, [OverallPerfScoreWeighted] = a.[TotalPerfScoreWeighted]/[TotalWeighting] 
			, [OverallPerfScoreAvg] = a.[TotalPerfScoreAvg]
			, [OverallLoFRawWeighted] = a.[TotalLoFRawWeighted]/[TotalWeighting]
			, [OverallLoFRawAvg] = a.[TotalLoFRawAvg]
			, [OverallLoFScoreWeighted] = a.[TotalLoFScoreWeighted]/[TotalWeighting]
			, [OverallLoFScoreScore] = a.[TotalLoFScoreAvg]
			, [OverallRiskRawWeighted] = a.[TotalRiskRawWeighted]/[TotalWeighting]
			, [OverallRiskRawAvg] = a.[TotalRiskRawAvg]
			, [OverallRiskScoreWeighted] = a.[TotalRiskScoreWeighted]/[TotalWeighting]
			, [OverallRiskScoreAvg] = a.[TotalRiskScoreAvg]
			, [ServicedCount] = a.[ReplacedCount]
			, [ServicedWeighting] = a.[ReplacedWeighting]
			, [ServicedAgeWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedAgeWeighted]/[ReplacedWeighting])
			, [ServicedAgeAvg] = a.[ReplacedAgeAvg]
			, [ServicedPhysRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysRawWeighted]/[ReplacedWeighting])
			, [ServicedPhysRawAvg] = a.[ReplacedPhysRawAvg]
			, [ServicedPhysScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysScoreWeighted]/[ReplacedWeighting])
			, [ServicedPhysScoreAvg] = a.[ReplacedPhysScoreAvg]
			, [ServicedPerfScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPerfScoreWeighted]/[ReplacedWeighting])
			, [ServicedPerfScoreAvg] = a.[ReplacedPerfScoreAvg]
			, [ServicedLoFRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFRawWeighted]/[ReplacedWeighting])
			, [ServicedLoFRawAvg] = a.[ReplacedLoFRawAvg]
			, [ServicedLoFScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFScoreWeighted]/[ReplacedWeighting])
			, [ServicedLoFScoreAvg] = a.[ReplacedLoFScoreAvg]
			, [ServicedCoFWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedCoFWeighted]/[ReplacedWeighting])
			, [ServicedCoFAvg] = a.[ReplacedCoFAvg]
			, [ServicedRiskRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskRawWeighted]/[ReplacedWeighting])
			, [ServicedRiskRawAvg] = a.[ReplacedRiskRawAvg]
			, [ServicedRiskScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskScoreWeighted]/[ReplacedWeighting])
			, [ServicedRiskScoreAvg] = a.[ReplacedRiskScoreAvg]
			, [LoF5Remaining] = a.LoF5Remaining
			, [Risk16Remaining] = a.Risk16Remaining
	FROM [v_14_Results_Summary] AS a
	INNER JOIN [RR_ScenarioYears] 
		ON ([a].[Scenario_ID] = [RR_ScenarioYears].[Scenario_ID]) 
		AND ([a].[ScenarioYear] = [RR_ScenarioYears].[BudgetYear]);

	UPDATE	RR_Scenarios
	SET		TotalCost = v_14_ScenarioSummary.TotalCost,
			ReplacedCost = v_14_ScenarioSummary.TotalReplaceCost, 
			RehabbedCost = v_14_ScenarioSummary.TotalRehabCost, 
			TotalWeight = v_14_ScenarioSummary.TotalWeight, 
			ReplacedWeight = v_14_ScenarioSummary.TotalReplacedAssets, 
			RehabbedWeight = v_14_ScenarioSummary.TotalRehabbedAssets
	FROM	v_14_ScenarioSummary INNER JOIN
			RR_Scenarios ON v_14_ScenarioSummary.Scenario_ID = RR_Scenarios.Scenario_ID;

	UPDATE RR_RuntimeConfig set StartedOn = NULL;

END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_PBI_ScenariosResultsSummary]
AS
SELECT	Format(dbo.RR_Scenarios.Scenario_ID + CAST(dbo.RR_ScenarioYears.BudgetYear AS FLOAT) / 10000, '00.0000') AS [Scenario ID Year], dbo.RR_ScenarioYears.Scenario_ID AS [Scenario ID], 
		dbo.RR_Scenarios.ScenarioName AS [Scenario Name], dbo.RR_Scenarios.Description AS [Scenario Description], dbo.RR_ScenarioYears.BudgetYear AS [Scenario Year], 
		dbo.RR_ScenarioYears.AllocationToRisk AS [Scenario Risk Allocation], dbo.RR_ScenarioYears.Budget AS [Scenario Target Budget], dbo.RR_ScenarioYears.ActualBudget AS [Overall Budget], 
		dbo.RR_ScenarioYears.OverallCount AS [Overall Asset Count], dbo.RR_ScenarioYears.OverallAgeWeighted AS [Ovarall Age], dbo.RR_ScenarioYears.OverallPhysRawWeighted AS [Overall Phys Raw], 
		dbo.RR_ScenarioYears.OverallPhysScoreWeighted AS [Overall Phys Score], dbo.RR_ScenarioYears.OverallPerfScoreWeighted AS [Overall Perf Score], dbo.RR_ScenarioYears.OverallLoFRawWeighted AS [Overall LoF Raw], 
		dbo.RR_ScenarioYears.OverallLoFScoreWeighted AS [Overall LoF Score], dbo.RR_ScenarioYears.OverallRiskRawWeighted AS [Overall Risk Raw], dbo.RR_ScenarioYears.OverallRiskScoreWeighted AS [Overall Risk Score], 
		dbo.RR_ScenarioYears.ServicedCount AS [Serviced Count], ROUND(dbo.RR_ScenarioYears.ServicedWeighting / 5280, 2) AS [Serviced Miles], dbo.RR_ScenarioYears.ServicedAgeWeighted AS [Serviced Age], 
		dbo.RR_ScenarioYears.ServicedPhysRawWeighted AS [Serviced Phys Raw], dbo.RR_ScenarioYears.ServicedPhysScoreWeighted AS [Serviced Phys Score], 
		dbo.RR_ScenarioYears.ServicedPerfScoreWeighted AS [Serviced Perf Score], dbo.RR_ScenarioYears.ServicedLoFRawWeighted AS [Serviced LoF Raw], 
		dbo.RR_ScenarioYears.ServicedLoFScoreWeighted AS [Serviced LoF Score], dbo.RR_ScenarioYears.ServicedCoFWeighted AS [Serviced CoF], dbo.RR_ScenarioYears.ServicedRiskRawWeighted AS [Serviced Risk Raw], 
		dbo.RR_ScenarioYears.ServicedRiskScoreWeighted AS [Serviced Risk Score],
		dbo.RR_ScenarioYears.LoF5Remaining AS [LoF 5 Remaining], dbo.RR_ScenarioYears.Risk16Remaining AS [Risk 16 Remaining]
FROM	dbo.RR_Scenarios INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioYears.Scenario_ID
WHERE	(dbo.RR_Scenarios.PBI_Flag = 1);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Initializes RR_Assets curve type, intercept and slope, EUL, offsets for failures and age (based on inspection or rehab), and allowed rehabs and repairs and OM score
--This proc adjusts from cohort setting based on inspections, stats model, previous failures and previous rehabs
--Curve settings and EUL based on cohort unless stats model results exist and no inspection has been performed
--If stats model results exist, age and failure offsets are set to 0 (not used)
--LoF Inspection and age offset is set if one was performed
--If a previous rehab exists the age offset is overriden to a condition of 2 at the rehab date, if no newer inspection was performed
--p_04_Update_CoF_LoF_Risk must be run to set LoF EUL, Phys, Perf and CoF and Risk

CREATE OR ALTER PROCEDURE [dbo].[p_03_UpdateAssetCurves]
AS
BEGIN

	SET NOCOUNT ON;

	-- Initialize
	UPDATE	RR_Assets 
	SET		RR_CurveType = NULL,
			RR_CurveIntercept = NULL,
			RR_CurveSlope = NULL,
			RR_EUL = 0,
			RR_FailurePhysOffset = 0,
			RR_AgeOffset = 0,
			RR_RehabsAllowed = 0,
			RR_RepairsAllowed = 0,
			RR_LoFInspection = NULL,
			RR_LastInspection = NULL,
			RR_OM = NULL;

	-- Update curve, allowed R&R and EUL values based on cohorts
	UPDATE	RR_Assets
	SET		RR_CurveType = RR_Cohorts.InitEquationType, 
			RR_CurveIntercept = RR_Cohorts.InitConstIntercept, 
			RR_CurveSlope = RR_Cohorts.InitExpSlope,
			RR_EUL = RR_Cohorts.InitEUL,
			RR_FailurePhysOffset = ConditionFailureFactor * RR_PreviousFailures,
			RR_RehabsAllowed = ISNULL(RR_Cohorts.RehabsAllowed, 0) - CASE WHEN RR_PreviousRehabYear IS NULL THEN 0 ELSE 1 END, 
			RR_RepairsAllowed = ISNULL(RR_Cohorts.RepairsAllowed, 0)
	FROM	RR_Assets INNER JOIN
			RR_Cohorts ON RR_Cohorts.Cohort_ID = RR_Assets.RR_Cohort_ID INNER JOIN
            RR_Config ON RR_Assets.RR_Config_ID = RR_Config.ID;

	-- Update rehabs allowed to 0 if Replace Diameter is larger than Diameter 2023-09-03
	UPDATE	RR_Assets
	SET		RR_RehabsAllowed = 0
	FROM	RR_Assets
	WHERE	RR_ReplacementDiameter > RR_Diameter;

	-- Update inspection attributes
	UPDATE	RR_Assets
	SET		RR_LoFInspection = v_00_07c_MaxPhysOM.MaxPhys,
			RR_LastInspection = v_00_07c_MaxPhysOM.RR_InspectionDate,
			RR_OM = v_00_07c_MaxPhysOM.MaxOM
	FROM	RR_Assets INNER JOIN
			v_00_07c_MaxPhysOM ON v_00_07c_MaxPhysOM.RR_Asset_ID = RR_Assets.RR_Asset_ID;

	-- Set currentageoffset based on physical score
	-- Heltzel Modified 2022-01-21 to include RR_Conditions to account for break rate
	-- If Inspect LoF > Age LoF, then age offset at start of inspection LoF (original method)
	-- If Inspect LoF < Age LoF, then age offset at end of inspection LoF 
	-- If Inspect LoF = Age LoF, no age offset
	UPDATE RR_Assets 
	SET 
		RR_Assets.RR_AgeOffset = 
			(CASE
				WHEN MinRawCondition > CAST(dbo.f_RR_CurveCondition(RR_CurveType, RR_CurveIntercept, (YEAR(RR_LastInspection) - RR_InstallYear), RR_CurveSlope) AS Int)     -- Min Inspect Lof > Age LoF
					THEN dbo.f_RR_CurveAge(RR_CurveType, RR_CurveIntercept, MinRawCondition, RR_CurveSlope) - (YEAR(RR_LastInspection) - RR_InstallYear) + (0.05 * RR_EUL)	-- Positive age offset based on Min Inspect + 5% of EUL
				WHEN MaxRawCondition <= CAST(dbo.f_RR_CurveCondition(RR_CurveType, RR_CurveIntercept, (YEAR(RR_LastInspection) - RR_InstallYear), RR_CurveSlope) AS Int)    -- Max Inspect Lof < Age LoF (2022-03-18 MaxCondition must be <=)
					THEN dbo.f_RR_CurveAge(RR_CurveType, RR_CurveIntercept, MaxRawCondition , RR_CurveSlope) - (YEAR(RR_LastInspection) - RR_InstallYear) - (0.05 * RR_EUL) -- Negative age offset based on Max Inspect - 5% of EUL
				ELSE 0  -- no offset because Inspect LoF is within Age LoF range
			END)
	FROM	RR_Assets INNER JOIN
			RR_Conditions ON RR_Assets.RR_LoFInspection = RR_Conditions.Condition_Score
	WHERE	RR_Assets.RR_LoFInspection > 0;

	-- Set current age offset based on LoF Phys of 2 at the last rehab year if no more recent inspection exists
	-- ISNULL OF RR_PreviousRehabYear MUST BE LESS THAN ISNULL OF RR_LastInspection
	UPDATE	RR_Assets
	SET		RR_AgeOffset = dbo.f_RR_CurveAge(RR_CurveType, RR_CurveIntercept, 2, RR_CurveSlope) - (RR_Assets.RR_PreviousRehabYear - RR_Assets.RR_InstallYear)
	WHERE	ISNULL(RR_PreviousRehabYear, 0) >= ISNULL(YEAR(RR_LastInspection), 1);

	-- Update curve values based on statistical model results if they exist and a physical condition assessment score does not exist
	UPDATE	RR_Assets
	SET		RR_CurveType = 'E', 
			RR_CurveIntercept = v_03a_CurveCalc.InterceptConst, 
			RR_CurveSlope = CASE WHEN SlopeExponent < 0.0001 THEN 0.0001 ELSE SlopeExponent END, 
			RR_EUL = ROUND(dbo.f_RR_CurveAge('E', v_03a_CurveCalc.InterceptConst, RR_Cohorts.ConditionAtEUL, CASE WHEN SlopeExponent < 0.0001 THEN 0.0001 ELSE SlopeExponent END), 0), 
			RR_AgeOffset = 0, 
			RR_FailurePhysOffset = 0
	FROM	RR_Cohorts INNER JOIN
			RR_Assets INNER JOIN
			v_03a_CurveCalc ON v_03a_CurveCalc.RR_Asset_ID = RR_Assets.RR_Asset_ID ON RR_Cohorts.Cohort_ID = RR_Assets.RR_Cohort_ID
	WHERE	(ISNULL(RR_Assets.RR_LoFInspection, 0) = 0);

END


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[p_03a_ClientUpdate]
AS
BEGIN
--Client Specific updates required after p_03 is run

	SET NOCOUNT ON;

END
GO

UPDATE [RR_ConfigQueries]
SET RunOrder = RunOrder + 1
WHERE Category_ID = 16 AND RunOrder >= 6;
GO

INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (16, N'00. Initialize (Quality Control)', 6, N'p_03a_ClientUpdate', NULL, N'Initializing client specific asset attributes…', N'Failed to initialize asset attributes', N'Inserts missing records from v__AssetInventory into RR_AssetAttributes with default values.', 0);
GO

--2023-09-08
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [RR_Config] ADD
	[Initialized] [datetime2](7) NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_00_03_Config]
AS
SELECT	ID, Version, ConditionLimit, ConditionFailureFactor, CostMultiplier, BaselineYear, ProjectName, ProjectVersion, 
		ConfigNotes, CommandTimeout, RepairsAllowed, RehabsAllowed, RehabPercentEUL, Initialized
FROM	dbo.RR_Config;
GO

INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Configuration', N'Initialized', N'Initialized', 10, 150, 64, NULL, 1, 0)
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Initialize RR_Hierarchy CoF and LoF Perf
--Initialize RR_Assets CoF, LoF Perf and redundany based on hierarchy, cost, diameter and critical customers
--Initialize RR_Assets LoFPerf, LoFPhys, LoFEUL, LoF, CoF, CoF_R, RUL and Risk
--p_03_UpdateAssetCurves should have been run to set CurveType, CurveIntercept, CurveSlope, EUL, FailurePhysOffset, RehabsAllowed, RepairsAllowed, LoFInspection, LastInspection and OM
ALTER PROCEDURE [p_04_Update_CoF_LoF_Risk]
AS
BEGIN

	SET NOCOUNT ON;

-- Update FIRST level hierarchical  
	UPDATE [RR_Hierarchy]
	SET [RR_HierarchyLevel] = 1
	WHERE [RR_Parent_ID] IS NULL

-- Update SECOND level hierarchical based on view of dbo.RR_Hierarchy with alias columns 
	UPDATE [H1]
	SET [H1].[RR_HierarchyLevel] = 2
		, [H1].[RF] = IIf([H2].[RF]>0,[H2].[RF],[H1].[RF])
		, [H1].[CoF1] = IIf([H2].[CoF1]>0,[H2].[CoF1],[H1].[CoF1])
		, [H1].[CoF2] = IIf([H2].[CoF2]>0,[H2].[CoF2],[H1].[CoF2])
		, [H1].[CoF3] = IIf([H2].[CoF3]>0,[H2].[CoF3],[H1].[CoF3])
		, [H1].[CoF4] = IIf([H2].[CoF4]>0,[H2].[CoF4],[H1].[CoF4])
		, [H1].[CoF5] = IIf([H2].[CoF5]>0,[H2].[CoF5],[H1].[CoF5])
		, [H1].[CoF6] = IIf([H2].[CoF6]>0,[H2].[CoF6],[H1].[CoF6])
		, [H1].[CoF7] = IIf([H2].[CoF7]>0,[H2].[CoF7],[H1].[CoF7])
		, [H1].[CoF8] = IIf([H2].[CoF8]>0,[H2].[CoF8],[H1].[CoF8])
		, [H1].[CoF9] = IIf([H2].[CoF9]>0,[H2].[CoF9],[H1].[CoF9])
		, [H1].[CoF10] = IIf([H2].[CoF10]>0,[H2].[CoF10],[H1].[CoF10])
		, [H1].[CoF11] = IIf([H2].[CoF11]>0,[H2].[CoF11],[H1].[CoF11])
		, [H1].[CoF12] = IIf([H2].[CoF12]>0,[H2].[CoF12],[H1].[CoF12])
		, [H1].[CoF13] = IIf([H2].[CoF13]>0,[H2].[CoF13],[H1].[CoF13])
		, [H1].[CoF14] = IIf([H2].[CoF14]>0,[H2].[CoF14],[H1].[CoF14])
		, [H1].[CoF15] = IIf([H2].[CoF15]>0,[H2].[CoF15],[H1].[CoF15])
		, [H1].[CoF16] = IIf([H2].[CoF16]>0,[H2].[CoF16],[H1].[CoF16])
		, [H1].[CoF17] = IIf([H2].[CoF17]>0,[H2].[CoF17],[H1].[CoF17])
		, [H1].[CoF18] = IIf([H2].[CoF18]>0,[H2].[CoF18],[H1].[CoF18])
		, [H1].[CoF19] = IIf([H2].[CoF19]>0,[H2].[CoF19],[H1].[CoF19])
		, [H1].[CoF20] = IIf([H2].[CoF20]>0,[H2].[CoF20],[H1].[CoF20])
		, [H1].[LoF1] = IIf([H2].[LoF1]>0,[H2].[LoF1],[H1].[LoF1])
		, [H1].[LoF2] = IIf([H2].[LoF2]>0,[H2].[LoF2],[H1].[LoF2])
		, [H1].[LoF3] = IIf([H2].[LoF3]>0,[H2].[LoF3],[H1].[LoF3])
		, [H1].[LoF4] = IIf([H2].[LoF4]>0,[H2].[LoF4],[H1].[LoF4])
		, [H1].[LoF5] = IIf([H2].[LoF5]>0,[H2].[LoF5],[H1].[LoF5])
		, [H1].[LoF7] = IIf([H2].[LoF7]>0,[H2].[LoF7],[H1].[LoF7])
		, [H1].[LoF8] = IIf([H2].[LoF8]>0,[H2].[LoF8],[H1].[LoF8])
		, [H1].[LoF9] = IIf([H2].[LoF9]>0,[H2].[LoF9],[H1].[LoF9])
		, [H1].[LoF10] = IIf([H2].[LoF10]>0,[H2].[LoF10],[H1].[LoF10])
	FROM [dbo].[v_00_07_Hierarchy] [H1]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H2] ON [H2].[Hierarchy_ID] = [H1].[Parent_ID]
	WHERE [H2].[Parent_ID] IS NULL

-- Update THIRD level hierarchical based on view of dbo.RR_Hierarchy with alias columns 
	UPDATE [H1]
	SET  [H1].[RR_HierarchyLevel] = 3
		, [H1].[RF] = IIf([H2].[RF]>0,[H2].[RF],[H1].[RF])
		, [H1].[CoF1] = IIf([H2].[CoF1]>0,[H2].[CoF1],[H1].[CoF1])
		, [H1].[CoF2] = IIf([H2].[CoF2]>0,[H2].[CoF2],[H1].[CoF2])
		, [H1].[CoF3] = IIf([H2].[CoF3]>0,[H2].[CoF3],[H1].[CoF3])
		, [H1].[CoF4] = IIf([H2].[CoF4]>0,[H2].[CoF4],[H1].[CoF4])
		, [H1].[CoF5] = IIf([H2].[CoF5]>0,[H2].[CoF5],[H1].[CoF5])
		, [H1].[CoF6] = IIf([H2].[CoF6]>0,[H2].[CoF6],[H1].[CoF6])
		, [H1].[CoF7] = IIf([H2].[CoF7]>0,[H2].[CoF7],[H1].[CoF7])
		, [H1].[CoF8] = IIf([H2].[CoF8]>0,[H2].[CoF8],[H1].[CoF8])
		, [H1].[CoF9] = IIf([H2].[CoF9]>0,[H2].[CoF9],[H1].[CoF9])
		, [H1].[CoF10] = IIf([H2].[CoF10]>0,[H2].[CoF10],[H1].[CoF10])
		, [H1].[CoF11] = IIf([H2].[CoF11]>0,[H2].[CoF11],[H1].[CoF11])
		, [H1].[CoF12] = IIf([H2].[CoF12]>0,[H2].[CoF12],[H1].[CoF12])
		, [H1].[CoF13] = IIf([H2].[CoF13]>0,[H2].[CoF13],[H1].[CoF13])
		, [H1].[CoF14] = IIf([H2].[CoF14]>0,[H2].[CoF14],[H1].[CoF14])
		, [H1].[CoF15] = IIf([H2].[CoF15]>0,[H2].[CoF15],[H1].[CoF15])
		, [H1].[CoF16] = IIf([H2].[CoF16]>0,[H2].[CoF16],[H1].[CoF16])
		, [H1].[CoF17] = IIf([H2].[CoF17]>0,[H2].[CoF17],[H1].[CoF17])
		, [H1].[CoF18] = IIf([H2].[CoF18]>0,[H2].[CoF18],[H1].[CoF18])
		, [H1].[CoF19] = IIf([H2].[CoF19]>0,[H2].[CoF19],[H1].[CoF19])
		, [H1].[CoF20] = IIf([H2].[CoF20]>0,[H2].[CoF20],[H1].[CoF20])
		, [H1].[LoF1] = IIf([H2].[LoF1]>0,[H2].[LoF1],[H1].[LoF1])
		, [H1].[LoF2] = IIf([H2].[LoF2]>0,[H2].[LoF2],[H1].[LoF2])
		, [H1].[LoF3] = IIf([H2].[LoF3]>0,[H2].[LoF3],[H1].[LoF3])
		, [H1].[LoF4] = IIf([H2].[LoF4]>0,[H2].[LoF4],[H1].[LoF4])
		, [H1].[LoF5] = IIf([H2].[LoF5]>0,[H2].[LoF5],[H1].[LoF5])
		, [H1].[LoF7] = IIf([H2].[LoF7]>0,[H2].[LoF7],[H1].[LoF7])
		, [H1].[LoF8] = IIf([H2].[LoF8]>0,[H2].[LoF8],[H1].[LoF8])
		, [H1].[LoF9] = IIf([H2].[LoF9]>0,[H2].[LoF9],[H1].[LoF9])
		, [H1].[LoF10] = IIf([H2].[LoF10]>0,[H2].[LoF10],[H1].[LoF10])
	FROM [dbo].[v_00_07_Hierarchy] AS [H1]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H2] ON [H2].[Hierarchy_ID] = [H1].[Parent_ID]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H3] ON [H3].[Hierarchy_ID] = [H2].[Parent_ID]
	WHERE [H3].[Parent_ID] IS NULL

-- Update FOURTH level hierarchical based on view of dbo.RR_Hierarchy with alias columns 
	UPDATE [H1]
	SET  [H1].[RR_HierarchyLevel] = 4
		, [H1].[RF] = IIf([H2].[RF]>0,[H2].[RF],[H1].[RF])
		, [H1].[CoF1] = IIf([H2].[CoF1]>0,[H2].[CoF1],[H1].[CoF1])
		, [H1].[CoF2] = IIf([H2].[CoF2]>0,[H2].[CoF2],[H1].[CoF2])
		, [H1].[CoF3] = IIf([H2].[CoF3]>0,[H2].[CoF3],[H1].[CoF3])
		, [H1].[CoF4] = IIf([H2].[CoF4]>0,[H2].[CoF4],[H1].[CoF4])
		, [H1].[CoF5] = IIf([H2].[CoF5]>0,[H2].[CoF5],[H1].[CoF5])
		, [H1].[CoF6] = IIf([H2].[CoF6]>0,[H2].[CoF6],[H1].[CoF6])
		, [H1].[CoF7] = IIf([H2].[CoF7]>0,[H2].[CoF7],[H1].[CoF7])
		, [H1].[CoF8] = IIf([H2].[CoF8]>0,[H2].[CoF8],[H1].[CoF8])
		, [H1].[CoF9] = IIf([H2].[CoF9]>0,[H2].[CoF9],[H1].[CoF9])
		, [H1].[CoF10] = IIf([H2].[CoF10]>0,[H2].[CoF10],[H1].[CoF10])
		, [H1].[CoF11] = IIf([H2].[CoF11]>0,[H2].[CoF11],[H1].[CoF11])
		, [H1].[CoF12] = IIf([H2].[CoF12]>0,[H2].[CoF12],[H1].[CoF12])
		, [H1].[CoF13] = IIf([H2].[CoF13]>0,[H2].[CoF13],[H1].[CoF13])
		, [H1].[CoF14] = IIf([H2].[CoF14]>0,[H2].[CoF14],[H1].[CoF14])
		, [H1].[CoF15] = IIf([H2].[CoF15]>0,[H2].[CoF15],[H1].[CoF15])
		, [H1].[CoF16] = IIf([H2].[CoF16]>0,[H2].[CoF16],[H1].[CoF16])
		, [H1].[CoF17] = IIf([H2].[CoF17]>0,[H2].[CoF17],[H1].[CoF17])
		, [H1].[CoF18] = IIf([H2].[CoF18]>0,[H2].[CoF18],[H1].[CoF18])
		, [H1].[CoF19] = IIf([H2].[CoF19]>0,[H2].[CoF19],[H1].[CoF19])
		, [H1].[CoF20] = IIf([H2].[CoF20]>0,[H2].[CoF20],[H1].[CoF20])
		, [H1].[LoF1] = IIf([H2].[LoF1]>0,[H2].[LoF1],[H1].[LoF1])
		, [H1].[LoF2] = IIf([H2].[LoF2]>0,[H2].[LoF2],[H1].[LoF2])
		, [H1].[LoF3] = IIf([H2].[LoF3]>0,[H2].[LoF3],[H1].[LoF3])
		, [H1].[LoF4] = IIf([H2].[LoF4]>0,[H2].[LoF4],[H1].[LoF4])
		, [H1].[LoF5] = IIf([H2].[LoF5]>0,[H2].[LoF5],[H1].[LoF5])
		, [H1].[LoF7] = IIf([H2].[LoF7]>0,[H2].[LoF7],[H1].[LoF7])
		, [H1].[LoF8] = IIf([H2].[LoF8]>0,[H2].[LoF8],[H1].[LoF8])
		, [H1].[LoF9] = IIf([H2].[LoF9]>0,[H2].[LoF9],[H1].[LoF9])
		, [H1].[LoF10] = IIf([H2].[LoF10]>0,[H2].[LoF10],[H1].[LoF10])
	FROM [dbo].[v_00_07_Hierarchy] AS [H1]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H2] ON [H2].[Hierarchy_ID] = [H1].[Parent_ID]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H3] ON [H3].[Hierarchy_ID] = [H2].[Parent_ID]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H4] ON [H4].[Hierarchy_ID] = [H3].[Parent_ID]
	WHERE [H4].[Parent_ID] IS NULL

-- Update FIFTH level hierarchical based on view of dbo.RR_Hierarchy with alias columns 
	UPDATE [H1]
	SET   [H1].[RR_HierarchyLevel] = 5
		, [H1].[RF] = IIf([H2].[RF]>0,[H2].[RF],[H1].[RF])
		, [H1].[CoF1] = IIf([H2].[CoF1]>0,[H2].[CoF1],[H1].[CoF1])
		, [H1].[CoF2] = IIf([H2].[CoF2]>0,[H2].[CoF2],[H1].[CoF2])
		, [H1].[CoF3] = IIf([H2].[CoF3]>0,[H2].[CoF3],[H1].[CoF3])
		, [H1].[CoF4] = IIf([H2].[CoF4]>0,[H2].[CoF4],[H1].[CoF4])
		, [H1].[CoF5] = IIf([H2].[CoF5]>0,[H2].[CoF5],[H1].[CoF5])
		, [H1].[CoF6] = IIf([H2].[CoF6]>0,[H2].[CoF6],[H1].[CoF6])
		, [H1].[CoF7] = IIf([H2].[CoF7]>0,[H2].[CoF7],[H1].[CoF7])
		, [H1].[CoF8] = IIf([H2].[CoF8]>0,[H2].[CoF8],[H1].[CoF8])
		, [H1].[CoF9] = IIf([H2].[CoF9]>0,[H2].[CoF9],[H1].[CoF9])
		, [H1].[CoF10] = IIf([H2].[CoF10]>0,[H2].[CoF10],[H1].[CoF10])
		, [H1].[CoF11] = IIf([H2].[CoF11]>0,[H2].[CoF11],[H1].[CoF11])
		, [H1].[CoF12] = IIf([H2].[CoF12]>0,[H2].[CoF12],[H1].[CoF12])
		, [H1].[CoF13] = IIf([H2].[CoF13]>0,[H2].[CoF13],[H1].[CoF13])
		, [H1].[CoF14] = IIf([H2].[CoF14]>0,[H2].[CoF14],[H1].[CoF14])
		, [H1].[CoF15] = IIf([H2].[CoF15]>0,[H2].[CoF15],[H1].[CoF15])
		, [H1].[CoF16] = IIf([H2].[CoF16]>0,[H2].[CoF16],[H1].[CoF16])
		, [H1].[CoF17] = IIf([H2].[CoF17]>0,[H2].[CoF17],[H1].[CoF17])
		, [H1].[CoF18] = IIf([H2].[CoF18]>0,[H2].[CoF18],[H1].[CoF18])
		, [H1].[CoF19] = IIf([H2].[CoF19]>0,[H2].[CoF19],[H1].[CoF19])
		, [H1].[CoF20] = IIf([H2].[CoF20]>0,[H2].[CoF20],[H1].[CoF20])
		, [H1].[LoF1] = IIf([H2].[LoF1]>0,[H2].[LoF1],[H1].[LoF1])
		, [H1].[LoF2] = IIf([H2].[LoF2]>0,[H2].[LoF2],[H1].[LoF2])
		, [H1].[LoF3] = IIf([H2].[LoF3]>0,[H2].[LoF3],[H1].[LoF3])
		, [H1].[LoF4] = IIf([H2].[LoF4]>0,[H2].[LoF4],[H1].[LoF4])
		, [H1].[LoF5] = IIf([H2].[LoF5]>0,[H2].[LoF5],[H1].[LoF5])
		, [H1].[LoF7] = IIf([H2].[LoF7]>0,[H2].[LoF7],[H1].[LoF7])
		, [H1].[LoF8] = IIf([H2].[LoF8]>0,[H2].[LoF8],[H1].[LoF8])
		, [H1].[LoF9] = IIf([H2].[LoF9]>0,[H2].[LoF9],[H1].[LoF9])
		, [H1].[LoF10] = IIf([H2].[LoF10]>0,[H2].[LoF10],[H1].[LoF10])
	FROM [dbo].[v_00_07_Hierarchy] AS [H1]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H2] ON [H2].[Hierarchy_ID] = [H1].[Parent_ID]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H3] ON [H3].[Hierarchy_ID] = [H2].[Parent_ID]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H4] ON [H4].[Hierarchy_ID] = [H3].[Parent_ID]
	INNER JOIN [dbo].[v_00_07_Hierarchy] AS [H5] ON [H5].[Hierarchy_ID] = [H4].[Parent_ID]
	WHERE [H5].[Parent_ID] IS NULL

-- Initialize CoF by attributes and buffers	(not hierarchy) 
	EXEC p_90_AssignCoFLof;

-- Update RR_Assets CoF, LoF and redundancy factors from RR_Hierarchy where direct parent > 0 RR_Asset is not negative
	UPDATE	[RR_Assets]
	SET		 [RR_Assets].[RR_CoFComment] = [RR_Assets].[RR_CoFComment]  --This line is needed so p___Alias_Views always starts a comment with a comma ' --,'
			,[RR_Assets].[RR_CoF01] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF01], 0) > 0 AND [RR_Assets].[RR_CoF01] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF01], 0) ELSE [RR_Assets].[RR_CoF01] END
			,[RR_Assets].[RR_CoF02] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF02], 0) > 0 AND [RR_Assets].[RR_CoF02] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF02], 0) ELSE [RR_Assets].[RR_CoF02] END
			,[RR_Assets].[RR_CoF03] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF03], 0) > 0 AND [RR_Assets].[RR_CoF03] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF03], 0) ELSE [RR_Assets].[RR_CoF03] END
			,[RR_Assets].[RR_CoF04] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF04], 0) > 0 AND [RR_Assets].[RR_CoF04] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF04], 0) ELSE [RR_Assets].[RR_CoF04] END
			,[RR_Assets].[RR_CoF05] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF05], 0) > 0 AND [RR_Assets].[RR_CoF05] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF05], 0) ELSE [RR_Assets].[RR_CoF05] END
			,[RR_Assets].[RR_CoF06] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF06], 0) > 0 AND [RR_Assets].[RR_CoF06] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF06], 0) ELSE [RR_Assets].[RR_CoF06] END
			,[RR_Assets].[RR_CoF07] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF07], 0) > 0 AND [RR_Assets].[RR_CoF07] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF07], 0) ELSE [RR_Assets].[RR_CoF07] END
			,[RR_Assets].[RR_CoF08] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF08], 0) > 0 AND [RR_Assets].[RR_CoF08] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF08], 0) ELSE [RR_Assets].[RR_CoF08] END
			,[RR_Assets].[RR_CoF09] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF09], 0) > 0 AND [RR_Assets].[RR_CoF09] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF09], 0) ELSE [RR_Assets].[RR_CoF09] END
			,[RR_Assets].[RR_CoF10] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF10], 0) > 0 AND [RR_Assets].[RR_CoF10] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF10], 0) ELSE [RR_Assets].[RR_CoF10] END
			,[RR_Assets].[RR_CoF11] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF11], 0) > 0 AND [RR_Assets].[RR_CoF11] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF11], 0) ELSE [RR_Assets].[RR_CoF11] END
			,[RR_Assets].[RR_CoF12] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF12], 0) > 0 AND [RR_Assets].[RR_CoF12] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF12], 0) ELSE [RR_Assets].[RR_CoF12] END
			,[RR_Assets].[RR_CoF13] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF13], 0) > 0 AND [RR_Assets].[RR_CoF13] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF13], 0) ELSE [RR_Assets].[RR_CoF13] END
			,[RR_Assets].[RR_CoF14] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF14], 0) > 0 AND [RR_Assets].[RR_CoF14] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF14], 0) ELSE [RR_Assets].[RR_CoF14] END
			,[RR_Assets].[RR_CoF15] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF15], 0) > 0 AND [RR_Assets].[RR_CoF15] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF15], 0) ELSE [RR_Assets].[RR_CoF15] END
			,[RR_Assets].[RR_CoF16] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF16], 0) > 0 AND [RR_Assets].[RR_CoF16] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF16], 0) ELSE [RR_Assets].[RR_CoF16] END
			,[RR_Assets].[RR_CoF17] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF17], 0) > 0 AND [RR_Assets].[RR_CoF17] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF17], 0) ELSE [RR_Assets].[RR_CoF17] END
			,[RR_Assets].[RR_CoF18] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF18], 0) > 0 AND [RR_Assets].[RR_CoF18] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF18], 0) ELSE [RR_Assets].[RR_CoF18] END
			,[RR_Assets].[RR_CoF19] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF19], 0) > 0 AND [RR_Assets].[RR_CoF19] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF19], 0) ELSE [RR_Assets].[RR_CoF19] END
			,[RR_Assets].[RR_CoF20] = CASE WHEN ISNULL([RR_Hierarchy].[RR_CoF20], 0) > 0 AND [RR_Assets].[RR_CoF20] >= 0 THEN ISNULL([RR_Hierarchy].[RR_CoF20], 0) ELSE [RR_Assets].[RR_CoF20] END

			,[RR_Assets].[RR_LoFPerf01] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf01], 0) > 0 AND [RR_Assets].[RR_LoFPerf01] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf01], 0) ELSE [RR_Assets].[RR_LoFPerf01] END
			,[RR_Assets].[RR_LoFPerf02] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf02], 0) > 0 AND [RR_Assets].[RR_LoFPerf02] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf02], 0) ELSE [RR_Assets].[RR_LoFPerf02] END
			,[RR_Assets].[RR_LoFPerf03] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf03], 0) > 0 AND [RR_Assets].[RR_LoFPerf03] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf03], 0) ELSE [RR_Assets].[RR_LoFPerf03] END
			,[RR_Assets].[RR_LoFPerf04] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf04], 0) > 0 AND [RR_Assets].[RR_LoFPerf04] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf04], 0) ELSE [RR_Assets].[RR_LoFPerf04] END
			,[RR_Assets].[RR_LoFPerf05] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf05], 0) > 0 AND [RR_Assets].[RR_LoFPerf05] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf05], 0) ELSE [RR_Assets].[RR_LoFPerf05] END
			,[RR_Assets].[RR_LoFPerf06] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf06], 0) > 0 AND [RR_Assets].[RR_LoFPerf06] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf06], 0) ELSE [RR_Assets].[RR_LoFPerf06] END
			,[RR_Assets].[RR_LoFPerf07] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf07], 0) > 0 AND [RR_Assets].[RR_LoFPerf07] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf07], 0) ELSE [RR_Assets].[RR_LoFPerf07] END
			,[RR_Assets].[RR_LoFPerf08] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf08], 0) > 0 AND [RR_Assets].[RR_LoFPerf08] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf08], 0) ELSE [RR_Assets].[RR_LoFPerf08] END
			,[RR_Assets].[RR_LoFPerf09] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf09], 0) > 0 AND [RR_Assets].[RR_LoFPerf09] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf09], 0) ELSE [RR_Assets].[RR_LoFPerf09] END
			,[RR_Assets].[RR_LoFPerf10] = CASE WHEN ISNULL([RR_Hierarchy].[RR_LoFPerf10], 0) > 0 AND [RR_Assets].[RR_LoFPerf10] >= 0 THEN ISNULL([RR_Hierarchy].[RR_LoFPerf10], 0) ELSE [RR_Assets].[RR_LoFPerf10] END

			,[RR_Assets].[RR_RedundancyFactor] = CASE WHEN ISNULL([RR_Hierarchy].[RR_RedundancyFactor], 0) >0 THEN [RR_Hierarchy].[RR_RedundancyFactor] ELSE [RR_Assets].[RR_RedundancyFactor] END
	FROM	[dbo].[RR_Assets]
	INNER JOIN [dbo].[RR_Hierarchy] ON [RR_Hierarchy].[RR_Hierarchy_ID]  = [RR_Assets].[RR_Hierarchy_ID]

--This UPDATE is modified by p___Alias_Views to set unused values to 0 otherwise null or 0 are set to 1
	UPDATE	[RR_Assets]
	SET		 [RR_CoF01] = CASE WHEN ISNULL([RR_CoF01], 0) = 0 THEN 1 ELSE [RR_CoF01] END
			,[RR_CoF02] = CASE WHEN ISNULL([RR_CoF02], 0) = 0 THEN 1 ELSE [RR_CoF02] END
			,[RR_CoF03] = CASE WHEN ISNULL([RR_CoF03], 0) = 0 THEN 1 ELSE [RR_CoF03] END
			,[RR_CoF04] = CASE WHEN ISNULL([RR_CoF04], 0) = 0 THEN 1 ELSE [RR_CoF04] END
			,[RR_CoF05] = CASE WHEN ISNULL([RR_CoF05], 0) = 0 THEN 1 ELSE [RR_CoF05] END
			,[RR_CoF06] = CASE WHEN ISNULL([RR_CoF06], 0) = 0 THEN 1 ELSE [RR_CoF06] END
			,[RR_CoF07] = CASE WHEN ISNULL([RR_CoF07], 0) = 0 THEN 1 ELSE [RR_CoF07] END
			,[RR_CoF08] = CASE WHEN ISNULL([RR_CoF08], 0) = 0 THEN 1 ELSE [RR_CoF08] END
			,[RR_CoF09] = CASE WHEN ISNULL([RR_CoF09], 0) = 0 THEN 1 ELSE [RR_CoF09] END
			,[RR_CoF10] = CASE WHEN ISNULL([RR_CoF10], 0) = 0 THEN 1 ELSE [RR_CoF10] END
			,[RR_CoF11] = CASE WHEN ISNULL([RR_CoF11], 0) = 0 THEN 1 ELSE [RR_CoF11] END
			,[RR_CoF12] = CASE WHEN ISNULL([RR_CoF12], 0) = 0 THEN 1 ELSE [RR_CoF12] END
			,[RR_CoF13] = CASE WHEN ISNULL([RR_CoF13], 0) = 0 THEN 1 ELSE [RR_CoF13] END
			,[RR_CoF14] = CASE WHEN ISNULL([RR_CoF14], 0) = 0 THEN 1 ELSE [RR_CoF14] END
			,[RR_CoF15] = CASE WHEN ISNULL([RR_CoF15], 0) = 0 THEN 1 ELSE [RR_CoF15] END
			,[RR_CoF16] = CASE WHEN ISNULL([RR_CoF16], 0) = 0 THEN 1 ELSE [RR_CoF16] END
			,[RR_CoF17] = CASE WHEN ISNULL([RR_CoF17], 0) = 0 THEN 1 ELSE [RR_CoF17] END
			,[RR_CoF18] = CASE WHEN ISNULL([RR_CoF18], 0) = 0 THEN 1 ELSE [RR_CoF18] END
			,[RR_CoF19] = CASE WHEN ISNULL([RR_CoF19], 0) = 0 THEN 1 ELSE [RR_CoF19] END
			,[RR_CoF20] = CASE WHEN ISNULL([RR_CoF20], 0) = 0 THEN 1 ELSE [RR_CoF20] END

			,[RR_LoFPerf01] = CASE WHEN ISNULL([RR_LoFPerf01], 0) = 0 THEN 1 ELSE [RR_LoFPerf01] END
			,[RR_LoFPerf02] = CASE WHEN ISNULL([RR_LoFPerf02], 0) = 0 THEN 1 ELSE [RR_LoFPerf02] END
			,[RR_LoFPerf03] = CASE WHEN ISNULL([RR_LoFPerf03], 0) = 0 THEN 1 ELSE [RR_LoFPerf03] END
			,[RR_LoFPerf04] = CASE WHEN ISNULL([RR_LoFPerf04], 0) = 0 THEN 1 ELSE [RR_LoFPerf04] END
			,[RR_LoFPerf05] = CASE WHEN ISNULL([RR_LoFPerf05], 0) = 0 THEN 1 ELSE [RR_LoFPerf05] END
			,[RR_LoFPerf06] = CASE WHEN ISNULL([RR_LoFPerf06], 0) = 0 THEN 1 ELSE [RR_LoFPerf06] END
			,[RR_LoFPerf07] = CASE WHEN ISNULL([RR_LoFPerf07], 0) = 0 THEN 1 ELSE [RR_LoFPerf07] END
			,[RR_LoFPerf08] = CASE WHEN ISNULL([RR_LoFPerf08], 0) = 0 THEN 1 ELSE [RR_LoFPerf08] END
			,[RR_LoFPerf09] = CASE WHEN ISNULL([RR_LoFPerf09], 0) = 0 THEN 1 ELSE [RR_LoFPerf09] END
			,[RR_LoFPerf10] = CASE WHEN ISNULL([RR_LoFPerf10], 0) = 0 THEN 1 ELSE [RR_LoFPerf10] END
	FROM	[dbo].[RR_Assets] 

-- Update RR_Assets overall LoF, CoF and Risk scores
	UPDATE	RR_Assets
	SET		[RR_LoFEUL] = [v_00_07a_CoFLoFRisk].[EULPhysRaw],
			[RR_LoFPhys] = [v_00_07a_CoFLoFRisk].[EULPhysScore],
			[RR_LoFPerf] = [v_00_07a_CoFLoFRisk].[MaxPerf],
			[RR_LoF] = [v_00_07a_CoFLoFRisk].[LoF],
			[RR_CoF] = [v_00_07a_CoFLoFRisk].[CoF],
			[RR_CoF_R] = [v_00_07a_CoFLoFRisk].[CoF_R],
			[RR_RUL] = CASE WHEN [RUL] > 300 THEN 300 ELSE [RUL] END, --max of 300 year RUL, should put this in RR_Config
			[RR_Risk] = CASE WHEN [v_00_07a_CoFLoFRisk].[Risk] < 0.5 THEN 1 ELSE ROUND([v_00_07a_CoFLoFRisk].[Risk], 0) END,
			[RR_CoFMaxCriteria] = '',
			[RR_LoFPerfMaxCriteria] = '',
			[RR_LoFPhysMaxCriteria] = '',
			[RR_OMMaxCriteria] = ''
	FROM [RR_Assets]
	INNER JOIN [v_00_07a_CoFLoFRisk] ON [v_00_07a_CoFLoFRisk].[RR_Asset_ID] = [RR_Assets].[RR_Asset_ID]

	-- SUBSTRING is used to remove the leading ', '
	-- REPLACE is used to trim the extra 'Cof ' or 'LoFPerf ' from each criteria
	UPDATE	[RR_Assets]
	SET		[RR_CoFMaxCriteria] = CASE WHEN [RR_CoF] > 1 THEN SUBSTRING(REPLACE(
				CASE WHEN ABS([RR_CoF01]) = [RR_CoF] THEN ', CoF 01 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF02]) = [RR_CoF] THEN ', CoF 02 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF03]) = [RR_CoF] THEN ', CoF 03 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF04]) = [RR_CoF] THEN ', CoF 04 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF05]) = [RR_CoF] THEN ', CoF 05 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF06]) = [RR_CoF] THEN ', CoF 06 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF07]) = [RR_CoF] THEN ', CoF 07 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF08]) = [RR_CoF] THEN ', CoF 08 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF09]) = [RR_CoF] THEN ', CoF 09 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF10]) = [RR_CoF] THEN ', CoF 10 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF11]) = [RR_CoF] THEN ', CoF 11 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF12]) = [RR_CoF] THEN ', CoF 12 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF13]) = [RR_CoF] THEN ', CoF 13 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF14]) = [RR_CoF] THEN ', CoF 14 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_CoF15]) = [RR_CoF] THEN ', CoF 15 Alias' ELSE '' END +
				CASE WHEN ABS([RR_CoF16]) = [RR_CoF] THEN ', CoF 16 Alias' ELSE '' END +
				CASE WHEN ABS([RR_CoF17]) = [RR_CoF] THEN ', CoF 17 Alias' ELSE '' END +
				CASE WHEN ABS([RR_CoF18]) = [RR_CoF] THEN ', CoF 18 Alias' ELSE '' END +
				CASE WHEN ABS([RR_CoF19]) = [RR_CoF] THEN ', CoF 19 Alias' ELSE '' END +
				CASE WHEN ABS([RR_CoF20]) = [RR_CoF] THEN ', CoF 20 Alias' ELSE '' END
			, ', CoF ', ', '), 3 , 100) ELSE '' END,

			[RR_LoFPerfMaxCriteria] = CASE WHEN [RR_LoFPerf] > 1 THEN SUBSTRING(REPLACE(
				CASE WHEN ABS([RR_LoFPerf01]) = [RR_LoFPerf] THEN ', LoFPerf 01 Alias' ELSE '' END +
				CASE WHEN ABS([RR_LoFPerf02]) = [RR_LoFPerf] THEN ', LoFPerf 02 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_LoFPerf03]) = [RR_LoFPerf] THEN ', LoFPerf 03 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_LoFPerf04]) = [RR_LoFPerf] THEN ', LoFPerf 04 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_LoFPerf05]) = [RR_LoFPerf] THEN ', LoFPerf 05 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_LoFPerf06]) = [RR_LoFPerf] THEN ', LoFPerf 06 Alias' ELSE '' END + 
				CASE WHEN ABS([RR_LoFPerf07]) = [RR_LoFPerf] THEN ', LoFPerf 07 Alias' ELSE '' END +
				CASE WHEN ABS([RR_LoFPerf08]) = [RR_LoFPerf] THEN ', LoFPerf 08 Alias' ELSE '' END +
				CASE WHEN ABS([RR_LoFPerf09]) = [RR_LoFPerf] THEN ', LoFPerf 09 Alias' ELSE '' END +
				CASE WHEN ABS([RR_LoFPerf10]) = [RR_LoFPerf] THEN ', LoFPerf 10 Alias' ELSE '' END
			, ', LoFPerf ', ', '), 3, 100) ELSE '' END
	FROM	[dbo].[RR_Assets] ;

	-- SUBSTRING is used to remove the leading ', '
	-- REPLACE is used to trim the extra 'LoFPhys ' from each criteria
	UPDATE	v__Inspections
	SET		RR_LoFPhysMaxCriteria = CASE WHEN [RR_LoFInspection] > 1 THEN SUBSTRING(REPLACE(
				CASE WHEN [RR_LoFPhys01] = [RR_LoFInspection] THEN ', LoFPhys 01 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys02] = [RR_LoFInspection] THEN ', LoFPhys 02 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys03] = [RR_LoFInspection] THEN ', LoFPhys 03 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys04] = [RR_LoFInspection] THEN ', LoFPhys 04 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys05] = [RR_LoFInspection] THEN ', LoFPhys 05 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys06] = [RR_LoFInspection] THEN ', LoFPhys 06 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys07] = [RR_LoFInspection] THEN ', LoFPhys 07 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys08] = [RR_LoFInspection] THEN ', LoFPhys 08 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys09] = [RR_LoFInspection] THEN ', LoFPhys 09 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys10] = [RR_LoFInspection] THEN ', LoFPhys 10 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys11] = [RR_LoFInspection] THEN ', LoFPhys 11 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys12] = [RR_LoFInspection] THEN ', LoFPhys 12 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys13] = [RR_LoFInspection] THEN ', LoFPhys 13 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys14] = [RR_LoFInspection] THEN ', LoFPhys 14 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys15] = [RR_LoFInspection] THEN ', LoFPhys 15 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys16] = [RR_LoFInspection] THEN ', LoFPhys 16 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys17] = [RR_LoFInspection] THEN ', LoFPhys 17 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys18] = [RR_LoFInspection] THEN ', LoFPhys 18 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys19] = [RR_LoFInspection] THEN ', LoFPhys 19 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys20] = [RR_LoFInspection] THEN ', LoFPhys 20 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys21] = [RR_LoFInspection] THEN ', LoFPhys 21 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys22] = [RR_LoFInspection] THEN ', LoFPhys 22 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys23] = [RR_LoFInspection] THEN ', LoFPhys 23 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys24] = [RR_LoFInspection] THEN ', LoFPhys 24 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys25] = [RR_LoFInspection] THEN ', LoFPhys 25 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys26] = [RR_LoFInspection] THEN ', LoFPhys 26 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys27] = [RR_LoFInspection] THEN ', LoFPhys 27 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys28] = [RR_LoFInspection] THEN ', LoFPhys 28 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys29] = [RR_LoFInspection] THEN ', LoFPhys 29 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys30] = [RR_LoFInspection] THEN ', LoFPhys 30 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys31] = [RR_LoFInspection] THEN ', LoFPhys 31 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys32] = [RR_LoFInspection] THEN ', LoFPhys 32 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys33] = [RR_LoFInspection] THEN ', LoFPhys 33 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys34] = [RR_LoFInspection] THEN ', LoFPhys 34 Alias' ELSE '' END + 
				CASE WHEN [RR_LoFPhys35] = [RR_LoFInspection] THEN ', LoFPhys 35 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys36] = [RR_LoFInspection] THEN ', LoFPhys 36 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys37] = [RR_LoFInspection] THEN ', LoFPhys 37 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys38] = [RR_LoFInspection] THEN ', LoFPhys 38 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys39] = [RR_LoFInspection] THEN ', LoFPhys 39 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys40] = [RR_LoFInspection] THEN ', LoFPhys 40 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys41] = [RR_LoFInspection] THEN ', LoFPhys 41 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys42] = [RR_LoFInspection] THEN ', LoFPhys 42 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys43] = [RR_LoFInspection] THEN ', LoFPhys 43 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys44] = [RR_LoFInspection] THEN ', LoFPhys 44 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys45] = [RR_LoFInspection] THEN ', LoFPhys 45 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys46] = [RR_LoFInspection] THEN ', LoFPhys 46 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys47] = [RR_LoFInspection] THEN ', LoFPhys 47 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys48] = [RR_LoFInspection] THEN ', LoFPhys 48 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys49] = [RR_LoFInspection] THEN ', LoFPhys 49 Alias' ELSE '' END +
				CASE WHEN [RR_LoFPhys50] = [RR_LoFInspection] THEN ', LoFPhys 50 Alias' ELSE '' END
			, ', LoFPhys ', ', '), 3, 100) ELSE '' END;


	--2023-12-26
	UPDATE	v__ActiveAssets
	SET		RR_LoFPhysMaxCriteria = 'Age'
	WHERE	RR_LoFPhysMaxCriteria = '' AND RR_LoF > 1; 


	-- SUBSTRING is used to remove the leading ', '
	-- REPLACE is used to trim the extra 'OM ' from each criteria
	UPDATE	v__Inspections 
	SET		RR_OMMaxCriteria = CASE WHEN [RR_OM] > 1 THEN SUBSTRING(REPLACE(
				CASE WHEN [RR_OM01] = [RR_OM] THEN ', OM 01 Alias' ELSE '' END +  
				CASE WHEN [RR_OM02] = [RR_OM] THEN ', OM 02 Alias' ELSE '' END +  
				CASE WHEN [RR_OM03] = [RR_OM] THEN ', OM 03 Alias' ELSE '' END +  
				CASE WHEN [RR_OM04] = [RR_OM] THEN ', OM 04 Alias' ELSE '' END +  
				CASE WHEN [RR_OM05] = [RR_OM] THEN ', OM 05 Alias' ELSE '' END +  
				CASE WHEN [RR_OM06] = [RR_OM] THEN ', OM 06 Alias' ELSE '' END +  
				CASE WHEN [RR_OM07] = [RR_OM] THEN ', OM 07 Alias' ELSE '' END +  
				CASE WHEN [RR_OM08] = [RR_OM] THEN ', OM 08 Alias' ELSE '' END +  
				CASE WHEN [RR_OM09] = [RR_OM] THEN ', OM 09 Alias' ELSE '' END +  
				CASE WHEN [RR_OM10] = [RR_OM] THEN ', OM 10 Alias' ELSE '' END +  
				CASE WHEN [RR_OM11] = [RR_OM] THEN ', OM 11 Alias' ELSE '' END +  
				CASE WHEN [RR_OM12] = [RR_OM] THEN ', OM 12 Alias' ELSE '' END +  
				CASE WHEN [RR_OM13] = [RR_OM] THEN ', OM 13 Alias' ELSE '' END + 
				CASE WHEN [RR_OM14] = [RR_OM] THEN ', OM 14 Alias' ELSE '' END +  
				CASE WHEN [RR_OM15] = [RR_OM] THEN ', OM 15 Alias' ELSE '' END +  
				CASE WHEN [RR_OM16] = [RR_OM] THEN ', OM 16 Alias' ELSE '' END +  
				CASE WHEN [RR_OM17] = [RR_OM] THEN ', OM 17 Alias' ELSE '' END +  
				CASE WHEN [RR_OM18] = [RR_OM] THEN ', OM 18 Alias' ELSE '' END +  
				CASE WHEN [RR_OM19] = [RR_OM] THEN ', OM 19 Alias' ELSE '' END +  
				CASE WHEN [RR_OM20] = [RR_OM] THEN ', OM 20 Alias' ELSE '' END +  
				CASE WHEN [RR_OM21] = [RR_OM] THEN ', OM 21 Alias' ELSE '' END +  
				CASE WHEN [RR_OM22] = [RR_OM] THEN ', OM 22 Alias' ELSE '' END +  
				CASE WHEN [RR_OM23] = [RR_OM] THEN ', OM 23 Alias' ELSE '' END +  
				CASE WHEN [RR_OM24] = [RR_OM] THEN ', OM 24 Alias' ELSE '' END +  
				CASE WHEN [RR_OM25] = [RR_OM] THEN ', OM 25 Alias' ELSE '' END +  
				CASE WHEN [RR_OM30] = [RR_OM] THEN ', OM 30 Alias' ELSE '' END +  
				CASE WHEN [RR_OM31] = [RR_OM] THEN ', OM 31 Alias' ELSE '' END +  
				CASE WHEN [RR_OM32] = [RR_OM] THEN ', OM 32 Alias' ELSE '' END +  
				CASE WHEN [RR_OM33] = [RR_OM] THEN ', OM 33 Alias' ELSE '' END +  
				CASE WHEN [RR_OM34] = [RR_OM] THEN ', OM 34 Alias' ELSE '' END +  
				CASE WHEN [RR_OM35] = [RR_OM] THEN ', OM 35 Alias' ELSE '' END + 
				CASE WHEN [RR_OM36] = [RR_OM] THEN ', OM 36 Alias' ELSE '' END + 
				CASE WHEN [RR_OM37] = [RR_OM] THEN ', OM 37 Alias' ELSE '' END + 
				CASE WHEN [RR_OM38] = [RR_OM] THEN ', OM 38 Alias' ELSE '' END + 
				CASE WHEN [RR_OM39] = [RR_OM] THEN ', OM 39 Alias' ELSE '' END + 
				CASE WHEN [RR_OM40] = [RR_OM] THEN ', OM 40 Alias' ELSE '' END + 
				CASE WHEN [RR_OM41] = [RR_OM] THEN ', OM 41 Alias' ELSE '' END + 
				CASE WHEN [RR_OM42] = [RR_OM] THEN ', OM 42 Alias' ELSE '' END + 
				CASE WHEN [RR_OM43] = [RR_OM] THEN ', OM 43 Alias' ELSE '' END + 
				CASE WHEN [RR_OM44] = [RR_OM] THEN ', OM 44 Alias' ELSE '' END + 
				CASE WHEN [RR_OM45] = [RR_OM] THEN ', OM 45 Alias' ELSE '' END + 
				CASE WHEN [RR_OM46] = [RR_OM] THEN ', OM 46 Alias' ELSE '' END + 
				CASE WHEN [RR_OM47] = [RR_OM] THEN ', OM 47 Alias' ELSE '' END + 
				CASE WHEN [RR_OM48] = [RR_OM] THEN ', OM 48 Alias' ELSE '' END + 
				CASE WHEN [RR_OM49] = [RR_OM] THEN ', OM 49 Alias' ELSE '' END + 
				CASE WHEN [RR_OM50] = [RR_OM] THEN ', OM 50 Alias' ELSE '' END 
			, ', OM ', ', '), 3, 250) ELSE '' END; 

	UPDATE	RR_Config
	SET		Initialized = getdate();

END
GO

INSERT [dbo].[RR_ConfigCategories] ([Category_ID], [FunctionGroup], [Category], [MultipleRecords]) VALUES (19, N'Delete Scenario', N'19. Scenarios', N'Zero or more records are allowed')
INSERT [RR_ConfigQueries] ([Category_ID], [Category], [RunOrder], [QueryName], [SortBy], [ProcessingLabel], [FailedLabel], [Description], [AllowQCEdits]) VALUES (19, N'19. Scenarios (Delete Scenario)', 1, N'p_19_DeleteScenario', NULL, N'Deleting scenario…', N'Failed to delete scenario', N'Delete all related records for a scenario.', 0)


ALTER TABLE [RR_Config] DROP  CONSTRAINT [DF_RR_Config_Version] ;
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_Version]  DEFAULT (5.005) FOR [Version];
GO


UPDATE RR_CONFIG SET VERSION = 5.005;
GO







--v5.006
--Fucrum schema update
--Not Yet Included in this script






--v5.007  2024-03-20
--Add Adjustment and Subcost to RR_Scenarios
--  Update v_00_02_ScenarioNames
--  Update p_14_Results_Summary_Update
--  Add Scenarios Adjustment and Subcost to RR_ConfigTableLookup

--Move all scenario run functions to the new p_10_ProcessScenarioYear. 
--  Old scenario run procedures must be disabled so previous versions of the app only run the new proc even though they look for the old ones.
--  Updated v_10_01_ScenarioCurrentYear_RR_Projects to includ ID and year fields
--  Create p_10a_ScenarioYearProjectsUpdate
--  Create p_10_ProcessScenarioYear and set RR_ConfigQueries.Category_ID  9 to use it
--  Disable old procedures by setting RR_ConfigQueries.Category_IDs (6, 7, 8, 10, 11, 12, 13, 21, 22, 23, 24, 25, 32, 33) to Category_ID = 0

--Update v_00_03_Config to include WeightMultiplier and Version 
--Add Configuration WeightMultiplier and Version to RR_ConfigTableLookup

--Updated p___QC_ResultsReview to include Scenario ID parameter

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Scenarios] ADD
	[SubCost] [bigint] NULL,
	[Adjustment] [bigint] NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_00_02_ScenarioNames]
AS
SELECT	Scenario_ID, ScenarioName, CONCAT(ScenarioName, ' ',  + FORMAT(LastRun, 'yyy-MM-yy'), ' ',  + FORMAT(LastRun, 'hh:mm:ss')) AS NameLastRun2, Description, 
		LastRun, PBI_Flag, RehabbedCost, ReplacedCost, SubCost, Adjustment, TotalCost, TotalWeight, ReplacedWeight, RehabbedWeight
FROM	dbo.RR_Scenarios
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_10_01_ScenarioCurrentYear_RR_Projects]
AS
SELECT	dbo.v_10_a_ScenarioCurrentYearDetails.CurrentScenario_ID, dbo.v_10_a_ScenarioCurrentYearDetails.CurrentYear, dbo.v_10_a_ScenarioCurrentYearDetails.RR_Asset_ID, dbo.RR_Projects.ProjectYear, 
		CASE WHEN RR_Projects.ServiceType = 'Replace' THEN 'Replace' ELSE 'Rehab' END AS ServiceType, CASE WHEN RR_Projects.ServiceType = 'Replace' THEN CostReplace ELSE CostRehab END AS ServiceCost, 
		dbo.v_10_a_ScenarioCurrentYearDetails.SystemCondition, dbo.v_10_a_ScenarioCurrentYearDetails.SystemRiskScore, dbo.v_10_a_ScenarioCurrentYearDetails.SystemRiskRaw, 
		dbo.v_10_a_ScenarioCurrentYearDetails.ProjectNumber, dbo.v_10_a_ScenarioCurrentYearDetails.CurrentAge, dbo.v_10_a_ScenarioCurrentYearDetails.PhysRaw, dbo.v_10_a_ScenarioCurrentYearDetails.LoFRaw, 
		dbo.v_10_a_ScenarioCurrentYearDetails.PhysScore, dbo.v_10_a_ScenarioCurrentYearDetails.PerfScore, dbo.v_10_a_ScenarioCurrentYearDetails.LoFScore, dbo.v_10_a_ScenarioCurrentYearDetails.RedundancyFactor, 
		dbo.v_10_a_ScenarioCurrentYearDetails.CoF_R, dbo.v_10_a_ScenarioCurrentYearDetails.CostReplace, dbo.v_10_a_ScenarioCurrentYearDetails.CostRehab, dbo.v_10_a_ScenarioCurrentYearDetails.CostRepair, 
		dbo.v_10_a_ScenarioCurrentYearDetails.YearRiskRaw, dbo.v_10_a_ScenarioCurrentYearDetails.YearRiskScore
FROM	dbo.v_10_a_ScenarioCurrentYearDetails INNER JOIN
		dbo.RR_Projects ON dbo.v_10_a_ScenarioCurrentYearDetails.ProjectNumber = dbo.RR_Projects.ProjectNumber AND dbo.v_10_a_ScenarioCurrentYearDetails.CurrentYear = dbo.RR_Projects.ProjectYear
WHERE	(dbo.v_10_a_ScenarioCurrentYearDetails.UseProjectBudget = 1)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_10a_ScenarioYearProjectsUpdate]
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE	RR_ScenarioResults
	SET		CostOfService = [ServiceCost], Service = [ServiceType]
	FROM	RR_ScenarioResults INNER JOIN
			v_10_01_ScenarioCurrentYear_RR_Projects AS p ON RR_ScenarioResults.RR_Asset_ID = p.RR_Asset_ID AND RR_ScenarioResults.Scenario_ID = p.CurrentScenario_ID AND 
			RR_ScenarioResults.ScenarioYear = p.CurrentYear ;

	UPDATE	v__RuntimeResults
	SET		CurrentInstallYear = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.CurrentYear  ELSE CurrentInstallYear END   , 
			CurrentEquationType = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceEquationType  ELSE CurrentEquationType END,  
			CurrentConstIntercept = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
			CurrentExpSlope = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope   ELSE  CurrentExpSlope END, 
			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentPerformance = CASE WHEN  [ServiceType] = 'Replace' THEN  1 ELSE  CurrentPerformance END, 
			RepairsRemaining = CASE WHEN  [ServiceType] = 'Repair' THEN  RepairsRemaining - 1    ELSE   v__RuntimeResults.RepairsAllowed END, 
			RehabsRemaining = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
	FROM	v__RuntimeResults INNER JOIN
			v_10_01_ScenarioCurrentYear_RR_Projects AS p ON v__RuntimeResults.RR_Asset_ID = p.RR_Asset_ID;

END --p_10a_ScenarioYearProjectsUpdate


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_10_ProcessScenarioYear] 
AS
BEGIN

	DECLARE @iScenarioID int = 0  
	DECLARE @iCurrentYear int = 0  
	DECLARE @iTargetBudget int = 0  
	DECLARE @fTargetCondition float = 0  
	DECLARE @fTargetRisk float = 0  
	DECLARE @fRiskAllocation float = 1
	DECLARE @iProjectsCost int = 0

	DECLARE @iRemainingBudget int = 0  
	DECLARE @iRiskBudget int = 0  
	DECLARE @iConditionBudget int = 0  

	DECLARE @iRiskBudgetStart int = 0  
	DECLARE @iConditionBudgetStart int = 0  

	DECLARE @iTempBudget int = 0  

	DECLARE @iAssetID int = 0  
	DECLARE @iServiceCost int = 0  
	DECLARE @sServiceType nvarchar(8) = ''  
	DECLARE @iOverallReducedBudget int = 0  
	DECLARE @fCurrentCondition float = 0  
	DECLARE @fCurrentRisk float = 0 
	DECLARE @iReducedBudget int = 0  
	DECLARE @fReducedCondition float = 0  
	DECLARE @fReducedRisk float = 0  
	DECLARE @i int = 0
	
	SET NOCOUNT ON;

	SELECT	@iScenarioID = RR_RuntimeConfig.CurrentScenario_ID,
			@iCurrentYear = RR_RuntimeConfig.CurrentYear,
			@iTargetBudget = RR_ScenarioYears.Budget,
			@fTargetCondition = RR_ScenarioYears.ConditionTarget, 
			@fTargetRisk = RR_ScenarioYears.RiskTarget,
			@fRiskAllocation = RR_ScenarioYears.AllocationToRisk
	FROM	RR_ScenarioYears INNER JOIN RR_RuntimeConfig 
			ON RR_ScenarioYears.Scenario_ID = RR_RuntimeConfig.CurrentScenario_ID AND RR_ScenarioYears.BudgetYear = RR_RuntimeConfig.CurrentYear;

-- next two statement are from p_09_UpdateScenarioResultsForAYear
	-- Create RR_ScenarioYears records for the current year
	INSERT INTO RR_ScenarioResults (Scenario_ID, ScenarioYear, RR_Asset_ID, Age, PhysRaw, PhysScore, PerfScore, CostOfService, [Service])
	SELECT	CurrentScenario_ID, CurrentYear, RR_Asset_ID, CurrentAge, PhysRaw, PhysScore, PerfScore, 0, 'Maintain'
	FROM	v_10_a_ScenarioCurrentYearDetails;

	-- Initialize RR_RuntimeConfig
	UPDATE	RR_RuntimeConfig
	SET		CurrentBudget = NULL;

	-- Apply project assets for the current year
	EXEC p_10a_ScenarioYearProjectsUpdate; 

	-- Determine the cost of the projects (some may have override costs and some may use the asset calculated cost. This needs to be subtracted from the overall yearly budget
	SELECT	@iProjectsCost = ISNULL(SUM(OverrideCost), 0)
	FROM	RR_ScenarioYears INNER JOIN RR_Projects ON RR_ScenarioYears.BudgetYear = RR_Projects.ProjectYear 
	WHERE	UseProjectBudget = 1 AND Scenario_ID = @iScenarioID AND BudgetYear = @iCurrentYear;

	SELECT	@iRemainingBudget = @iTargetBudget - @iProjectsCost;  
	SELECT	@iOverallReducedBudget = @iProjectsCost;
	SELECT	@iRiskBudget = @iRemainingBudget * @fRiskAllocation;
	SELECT	@iConditionBudget = @iRemainingBudget * (1 - @fRiskAllocation);

	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,' Start'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Target: ', format(@iTargetBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Projects: ', format(@iProjectsCost, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Remaining: ', format(@iRemainingBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Risk Percent: ', format(@fRiskAllocation, '#0%')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Risk Budget: ', format(@iRiskBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Condition Budget: ', format(@iConditionBudget, '$#,##0')));

	--Get the highest priority asset
	IF @fRiskAllocation = 0  --All budget is for condition
		BEGIN --Use condition sorting
			SELECT	TOP (1)
					@iAssetID = RR_Asset_ID, 
					@iServiceCost = ServiceCost, 
					@sServiceType = ServiceType
			FROM	v_10_01_ScenarioCurrentYear_RR_Assets
			ORDER BY LoFScore DESC, LoFRaw DESC, SystemRiskScore DESC, RR_Asset_ID;

			SELECT	@iTempBudget =  @iConditionBudget;
		END
	ELSE  --Some or all budget is for risk
		BEGIN --Use risk sorting
			SELECT	TOP (1)
					@iAssetID = RR_Asset_ID, 
					@iServiceCost = ServiceCost, 
					@sServiceType = ServiceType
			FROM	v_10_01_ScenarioCurrentYear_RR_Assets
			ORDER BY YearRiskScore DESC, YearRiskRaw DESC, SystemRiskScore DESC, RR_Asset_ID;

			SELECT	@iTempBudget =  @iRiskBudget;
		END

	--If the highest priority asset is more expensive than budget then perform the service on that asset only
	IF @iAssetID > 0 AND @iTempBudget > 0 AND @iServiceCost >= @iTempBudget 
		BEGIN

			UPDATE	RR_ScenarioResults
			SET		CostOfService = @iServiceCost, 
					Service = @sServiceType
			WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @iCurrentYear AND  RR_Asset_ID = @iAssetID;

			UPDATE	v__RuntimeResults
			SET		CurrentInstallYear = CASE WHEN @sServiceType = 'Replace' THEN  v__RuntimeResults.CurrentYear ELSE CurrentInstallYear END, 
					CurrentEquationType = CASE WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceEquationType ELSE CurrentEquationType END,  
					CurrentConstIntercept =  CASE WHEN @sServiceType = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
					CurrentExpSlope = CASE WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope ELSE  CurrentExpSlope END, 
					CurrentFailurePhysOffset = CASE WHEN @sServiceType = 'Repair' THEN CurrentFailurePhysOffset ELSE 0 END, 
					CurrentAgeOffset = CASE WHEN @sServiceType = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
					CurrentPerformance =  CASE WHEN @sServiceType = 'Replace' THEN 1 ELSE CurrentPerformance END, 
					RepairsRemaining =  CASE WHEN @sServiceType = 'Repair' THEN RepairsRemaining - 1 ELSE v__RuntimeResults.RepairsAllowed END, 
					RehabsRemaining =  CASE WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining  END
			WHERE	RR_Asset_ID = @iAssetID ;

			-- Budget should be negative and prevents more assets from being serviced, this amount will be used to calc and store remaining target for next proc
 			SELECT	@iOverallReducedBudget = @iOverallReducedBudget + @iServiceCost,
					@iRemainingBudget = @iRemainingBudget - @iServiceCost;
		
			IF @fRiskAllocation = 0												--All budget is for condition
				SELECT	@iConditionBudget = @iConditionBudget - @iServiceCost;	--Should be negative
			ELSE																--Some or all budget is for risk
				SELECT	@iRiskBudget = @iRiskBudget - @iServiceCost,			--Should be negative
						@iConditionBudget = @iConditionBudget + (@iRiskBudget - @iServiceCost);	--May or maynot be negative
		
			insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '   Single Asset: ', format(@iServiceCost, '$#,##0')));
			insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '    Spend: ', format(@iOverallReducedBudget, '$#,##0')));
			insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '    Remaining: ', format(@iRemainingBudget, '$#,##0')));

		END

	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '  Start Risk'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '   Risk Budget: ', format(@iRiskBudget, '$#,##0')));

	SELECT @fCurrentCondition = Cond, @fCurrentRisk = Risk, @i = 0 FROM v_20_00_ScenerioYearConditionRisk;

	--Pocess risk priority assets up to 10 iterations or within $1,000 of risk budget

	SELECT @iRiskBudgetStart = @iRiskBudget;

	WHILE @iRiskBudget > 1000 AND @fCurrentCondition > @fTargetCondition AND @fCurrentRisk > @fTargetRisk AND @i < 10 BEGIN

		SELECT @i = @i + 1

		UPDATE RR_RuntimeConfig SET CurrentBudget = @iRiskBudget;  --CHECK TO SEE IF CurrentBudget IS ACTUALLY BEIG USED BY ANYTHING ELSE

		SELECT	@iReducedBudget = ISNULL(MAX(RunningCost), 0), @fReducedRisk = ISNULL(MAX(RunningRisk), 0), @fReducedCondition = ISNULL(MAX(RunningCondition), 0)
		FROM	v_10_00_Running_Risk
		WHERE	RunningCost <= @iRiskBudget AND 
				RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
				RunningCondition <= @fCurrentCondition - @fTargetCondition 	;

		EXEC p_10a_ScenarioYearRiskUpdate @iRiskBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

		SELECT	@iRiskBudget = @iRiskBudget - @iReducedBudget,  
				@iOverallReducedBudget = @iOverallReducedBudget + @iReducedBudget, 
				@fCurrentCondition = @fCurrentCondition - @fReducedCondition, 
				@fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		IF @iReducedBudget = 0 
			SELECT @i = 10;

		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Reduced Risk: ', format(@iReducedBudget, '$#,##0')));
		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining Risk: ', format(@iRiskBudget, '$#,##0')));

	END

	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Risk Spend: ', format(@iRiskBudgetStart - @iRiskBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining: ', format(@iTargetBudget - @iOverallReducedBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '  End Risk'));

	SELECT	@fCurrentCondition = Cond, @fCurrentRisk = Risk, @i = 0 FROM v_20_00_ScenerioYearConditionRisk;
	SELECT	@iConditionBudget = @iTargetBudget - @iOverallReducedBudget;
	SELECT	@iConditionBudgetStart = @iConditionBudget;

	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '  Start Cond'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '   Condition Budget: ', format(@iConditionBudget, '$#,##0')));

	WHILE @iConditionBudget > 1000 AND @fCurrentCondition > @fTargetCondition AND @fCurrentRisk > @fTargetRisk AND @i < 10 BEGIN

		SELECT @i = @i + 1
			
		UPDATE RR_RuntimeConfig SET CurrentBudget = @iConditionBudget;

		SELECT	@iReducedBudget = ISNULL(MAX(RunningCost), 0), @fReducedRisk = ISNULL(MAX(RunningRisk), 0), @fReducedCondition = ISNULL(MAX(RunningCondition), 0)
		FROM	v_10_00_Running_LoF
		WHERE	RunningCost <= @iConditionBudget AND 
				RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
				RunningCondition <= @fCurrentCondition - @fTargetCondition 	;

		EXEC p_10a_ScenarioYearLoFUpdate @iConditionBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

		SELECT	@iConditionBudget = @iConditionBudget - @iReducedBudget,  
				@iOverallReducedBudget = @iOverallReducedBudget + @iReducedBudget, 
				@fCurrentCondition = @fCurrentCondition - @fReducedCondition, 
				@fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		IF @iReducedBudget = 0 
			SELECT @i = 10;

		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Reduced Cond: ', format(@iReducedBudget, '$#,##0')));
		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining Cond: ', format(@iConditionBudget, '$#,##0')));

	END

	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Cond Spend: ', format(@iConditionBudgetStart - @iConditionBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining: ', format(@iTargetBudget - @iOverallReducedBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear,'  End Cond'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear,' End'));

END  --p_10_ProcessScenarioYear

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_14_Results_Summary_Update]
AS
BEGIN

	SET NOCOUNT ON;
	
	UPDATE	[RR_ScenarioYears]
	SET		[ActualBudget] = a.[Cost]
			, [OverallCount] = a.[TotalCount]
			, [OverallWeighting] = a.[TotalWeighting]
			, [OverallAgeWeighted] = a.[TotalAgeWeighted]/[TotalWeighting]
			, [OverallAgeAvg] = a.[TotalAgeAvg]
			, [OverallPhysRawWeighted] = a.[TotalPhysRawWeighted]/[TotalWeighting]
			, [OverallPhysRawAvg] = a.[TotalPhysRawAvg]
			, [OverallPhysScoreWeighted] = a.[TotalPhysScoreWeighted]/[TotalWeighting]
			, [OverallPhysScoreAvg] = a.[TotalPhysScoreAvg]
			, [OverallPerfScoreWeighted] = a.[TotalPerfScoreWeighted]/[TotalWeighting] 
			, [OverallPerfScoreAvg] = a.[TotalPerfScoreAvg]
			, [OverallLoFRawWeighted] = a.[TotalLoFRawWeighted]/[TotalWeighting]
			, [OverallLoFRawAvg] = a.[TotalLoFRawAvg]
			, [OverallLoFScoreWeighted] = a.[TotalLoFScoreWeighted]/[TotalWeighting]
			, [OverallLoFScoreScore] = a.[TotalLoFScoreAvg]
			, [OverallRiskRawWeighted] = a.[TotalRiskRawWeighted]/[TotalWeighting]
			, [OverallRiskRawAvg] = a.[TotalRiskRawAvg]
			, [OverallRiskScoreWeighted] = a.[TotalRiskScoreWeighted]/[TotalWeighting]
			, [OverallRiskScoreAvg] = a.[TotalRiskScoreAvg]
			, [ServicedCount] = a.[ReplacedCount]
			, [ServicedWeighting] = a.[ReplacedWeighting]
			, [ServicedAgeWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedAgeWeighted]/[ReplacedWeighting])
			, [ServicedAgeAvg] = a.[ReplacedAgeAvg]
			, [ServicedPhysRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysRawWeighted]/[ReplacedWeighting])
			, [ServicedPhysRawAvg] = a.[ReplacedPhysRawAvg]
			, [ServicedPhysScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysScoreWeighted]/[ReplacedWeighting])
			, [ServicedPhysScoreAvg] = a.[ReplacedPhysScoreAvg]
			, [ServicedPerfScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPerfScoreWeighted]/[ReplacedWeighting])
			, [ServicedPerfScoreAvg] = a.[ReplacedPerfScoreAvg]
			, [ServicedLoFRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFRawWeighted]/[ReplacedWeighting])
			, [ServicedLoFRawAvg] = a.[ReplacedLoFRawAvg]
			, [ServicedLoFScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFScoreWeighted]/[ReplacedWeighting])
			, [ServicedLoFScoreAvg] = a.[ReplacedLoFScoreAvg]
			, [ServicedCoFWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedCoFWeighted]/[ReplacedWeighting])
			, [ServicedCoFAvg] = a.[ReplacedCoFAvg]
			, [ServicedRiskRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskRawWeighted]/[ReplacedWeighting])
			, [ServicedRiskRawAvg] = a.[ReplacedRiskRawAvg]
			, [ServicedRiskScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskScoreWeighted]/[ReplacedWeighting])
			, [ServicedRiskScoreAvg] = a.[ReplacedRiskScoreAvg]
			, [LoF5Remaining] = a.LoF5Remaining
			, [Risk16Remaining] = a.Risk16Remaining
	FROM [v_14_Results_Summary] AS a
	INNER JOIN [RR_ScenarioYears] 
		ON ([a].[Scenario_ID] = [RR_ScenarioYears].[Scenario_ID]) 
		AND ([a].[ScenarioYear] = [RR_ScenarioYears].[BudgetYear]);

	UPDATE	RR_Scenarios
	SET		SubCost = v_14_ScenarioSummary.TotalCost,
			ReplacedCost = v_14_ScenarioSummary.TotalReplaceCost, 
			RehabbedCost = v_14_ScenarioSummary.TotalRehabCost, 
			TotalWeight = v_14_ScenarioSummary.TotalWeight, 
			ReplacedWeight = v_14_ScenarioSummary.TotalReplacedAssets, 
			RehabbedWeight = v_14_ScenarioSummary.TotalRehabbedAssets
	FROM	v_14_ScenarioSummary INNER JOIN
			RR_Scenarios ON v_14_ScenarioSummary.Scenario_ID = RR_Scenarios.Scenario_ID;

	UPDATE	RR_Scenarios
	SET		Adjustment = t2.TotalCosts - RR_Scenarios.SubCost ,
			TotalCost = t2.TotalCosts
	FROM	RR_Scenarios
			INNER JOIN (SELECT Scenario_ID, SUM(RR_ScenarioYears.ActualBudget) as TotalCosts
						FROM RR_ScenarioYears
						GROUP BY Scenario_ID) as t2
			ON t2.Scenario_ID = RR_Scenarios.Scenario_ID;

	UPDATE RR_RuntimeConfig set StartedOn = NULL;

END   --p_14_Results_Summary_Update
GO


UPDATE	RR_ConfigQueries
SET		QueryName = 'p_10_ProcessScenarioYear'
WHERE	Category_ID = 9
GO

UPDATE	RR_ConfigQueries
SET		Category_ID = 0,
		Description = concat('was ID ', Category_ID, ' ', Description)
WHERE	Category_ID IN (6, 7, 8, 10, 11, 12, 13, 21, 22, 23, 24, 25, 32, 33)
GO


INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'Adjustment', N'Adjustment', 8, 100, 32, N'$#,##0', 0, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'SubCost', N'Sub Cost', 8, 100, 32, N'$#,##0', 0, 0)
GO

INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Configuration', N'WeightMultiplier', N'Asset Weight', 11, 75, 64, NULL, 1, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Configuration', N'Version', N'DB Ver', 12, 60, 75, NULL, 1, 0)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   VIEW [dbo].[v_00_03_Config]
AS
SELECT	ID, Version, ConditionLimit, ConditionFailureFactor, CostMultiplier, BaselineYear, ProjectName, ProjectVersion, 
		ConfigNotes, CommandTimeout, RepairsAllowed, RehabsAllowed, RehabPercentEUL, Initialized, WeightMultiplier
FROM	dbo.RR_Config;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p___QC_ResultsReview]
@ScenarioID as int
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE RR_Config
	SET CurrentScenario_ID = @ScenarioID;

	SELECT   'Total Asset Cost Summary' AS QCName, FORMAT(SUM(RR_CostRehab),'$#,##0') AS [Asset Rehab], FORMAT(SUM(CAST(RR_CostReplace AS bigint)),'$#,##0') AS [Asset Replace], 
			CostMultiplier, FORMAT(SUM(RR_CostRehab*CostMultiplier),'$#,##0') AS [Capital Rehab], FORMAT(SUM(RR_CostReplace*CostMultiplier),'$#,##0') AS [Capital Replace],
			FORMAT(COUNT(*),'#,##0')  AS Assets
	FROM	 RR_Assets INNER JOIN RR_Config on RR_Assets.RR_Config_ID =RR_Config.ID  WHERE RR_Status=1
	GROUP BY CostMultiplier;
	
	SELECT   'Scenario Cost Summary' AS QCName, [ScenarioName], FORMAT(SUM(CostOfService),'$#,##0') AS Cost, 
			FORMAT(SUM(RR_CostRehab*CostMultiplier),'$#,##0') AS [Capital Rehab], FORMAT(SUM(RR_CostReplace*CostMultiplier),'$#,##0') AS [Capital Replace], 
			FORMAT(COUNT(*),'#,##0') AS Assets
	FROM     v___QC_Results
	WHERE    (EligableRR <> N'') OR (Service <> 'Maintain')
	GROUP BY  [ScenarioName];

	SELECT   'Eligable-Actual Summary' AS QCName, ScenarioName, CASE WHEN EligableRR ='' THEN 'Maintain' ELSE EligableRR END AS Eligable, Service AS Actual, 
			 FORMAT(SUM(CostOfService),'$#,##0') AS [Actual Cost], FORMAT(SUM(RR_CostRehab*CostMultiplier),'$#,##0') AS [Capital Rehab], 
			 FORMAT(SUM(RR_CostReplace*CostMultiplier),'$#,##0')  AS [Capital Replace], FORMAT(COUNT(*),'#,##0') AS [Count]
	FROM     v___QC_Results
	GROUP BY ScenarioName, EligableRR, Service;

	SELECT 	 'Eligable-Actual Counts' AS QCName, [ScenarioName] ,[ScenarioYear] , COUNT(*) AS [Eligable Count], 
			SUM(CASE WHEN [CostOfService]>0 THEN 1 ELSE 0 END) AS [Actual Count], FORMAT(SUM([CostOfService]), '$#,##0') AS [Actual Cost], 
			FORMAT(SUM([RR_CostRehab]*[CostMultiplier]), '$#,##0') AS [Capital Rehab], FORMAT(SUM([RR_CostReplace]*[CostMultiplier]), '$#,##0') AS [Capital Replace]
	FROM	 v___QC_Results
	WHERE	 [EligableRR] <>'' or CostOfService>0
	GROUP BY [ScenarioName] ,[ScenarioYear]
	ORDER BY ScenarioYear;
	   	 
	SELECT  'Eligable-Actual Details' AS QCName,  RR_Asset_ID AS [Asset ID], ScenarioYear AS Year, RR_Facility, RR_AssetType, RR_AssetName, InitEUL AS EUL, Age, PerfScore, PerfReplace, PhysScore, 
			PhysRaw, LowRehab, HighRehab, EligableRR AS Eligable, Service AS Actual, CostOfService AS Cost, RR_CostRehab, RR_CostReplace, RR_CoF_R, LoFScore, CostMultiplier
	FROM    v___QC_Results
	WHERE  (EligableRR <> N'') OR (CostOfService > 0)
	ORDER BY ScenarioYear;
	
	SELECT  'Scenario Details' AS QCName, RR_Asset_ID AS [Asset ID], ScenarioYear AS Year, RR_Facility, RR_AssetType, RR_AssetName, InitEUL AS EUL, Age, AgeOffset, PerfScore, PerfReplace, PhysScore, 
			PhysRaw, LowRehab, HighRehab, EligableRR AS Eligable, Service AS Actual, CostOfService AS Cost, RR_CostRehab, RR_CostReplace, RR_CoF_R, LoFScore, CostMultiplier
	FROM    v___QC_Results
	ORDER BY RR_Asset_ID, ScenarioYear;
END
GO

UPDATE RR_CONFIG SET VERSION = 5.007;
GO






--v5.008 2024-04-13
--Limit RR_LoFInspection to values > 0
--This is critically important to avoid and inspection date LoF that overrides a rehab age offset

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Initializes RR_Assets curve type, intercept and slope, EUL, offsets for failures and age (based on inspection or rehab), and allowed rehabs and repairs and OM score
--This proc adjusts from cohort setting based on inspections, stats model, previous failures and previous rehabs
--Curve settings and EUL based on cohort unless stats model results exist and no inspection has been performed
--If stats model results exist, age and failure offsets are set to 0 (not used)
--LoF Inspection and age offset is set if one was performed
--If a previous rehab exists the age offset is overriden to a condition of 2 at the rehab date, if no newer inspection was performed
--p_04_Update_CoF_LoF_Risk must be run to set LoF EUL, Phys, Perf and CoF and Risk
ALTER PROCEDURE [dbo].[p_03_UpdateAssetCurves]
AS
BEGIN

	SET NOCOUNT ON;

	-- Initialize
	UPDATE	RR_Assets 
	SET		RR_CurveType = NULL,
			RR_CurveIntercept = NULL,
			RR_CurveSlope = NULL,
			RR_EUL = 0,
			RR_FailurePhysOffset = 0,
			RR_AgeOffset = 0,
			RR_RehabsAllowed = 0,
			RR_RepairsAllowed = 0,
			RR_LoFInspection = NULL,
			RR_LastInspection = NULL,
			RR_OM = NULL;

	-- Update curve, allowed R&R and EUL values based on cohorts
	UPDATE	RR_Assets
	SET		RR_CurveType = RR_Cohorts.InitEquationType, 
			RR_CurveIntercept = RR_Cohorts.InitConstIntercept, 
			RR_CurveSlope = RR_Cohorts.InitExpSlope,
			RR_EUL = RR_Cohorts.InitEUL,
			RR_FailurePhysOffset = ConditionFailureFactor * RR_PreviousFailures,
			RR_RehabsAllowed = ISNULL(RR_Cohorts.RehabsAllowed, 0) - CASE WHEN RR_PreviousRehabYear IS NULL THEN 0 ELSE 1 END, 
			RR_RepairsAllowed = ISNULL(RR_Cohorts.RepairsAllowed, 0)
	FROM	RR_Assets INNER JOIN
			RR_Cohorts ON RR_Cohorts.Cohort_ID = RR_Assets.RR_Cohort_ID INNER JOIN
            RR_Config ON RR_Assets.RR_Config_ID = RR_Config.ID

	-- Update inspection attributes if asset has a physical score
	UPDATE	RR_Assets
	SET		RR_LoFInspection = v_00_07c_MaxPhysOM.MaxPhys,
			RR_LastInspection = v_00_07c_MaxPhysOM.RR_InspectionDate,
			RR_OM = v_00_07c_MaxPhysOM.MaxOM
	FROM	RR_Assets INNER JOIN
			v_00_07c_MaxPhysOM ON v_00_07c_MaxPhysOM.RR_Asset_ID = RR_Assets.RR_Asset_ID
	WHERE	v_00_07c_MaxPhysOM.MaxPhys > 0;

	-- Set currentageoffset based on physical score
	-- Heltzel Modified 2022-01-21 to include RR_Conditions to account for break rate
	-- If Inspect LoF > Age LoF, then age offset at start of inspection LoF (original method)
	-- If Inspect LoF < Age LoF, then age offset at end of inspection LoF 
	-- If Inspect LoF = Age LoF, no age offset
	UPDATE RR_Assets 
	SET 
		RR_Assets.RR_AgeOffset = 
			(CASE
				WHEN MinRawCondition > CAST(dbo.f_RR_CurveCondition(RR_CurveType, RR_CurveIntercept, (YEAR(RR_LastInspection) - RR_InstallYear), RR_CurveSlope) AS Int)     -- Min Inspect Lof > Age LoF
					THEN dbo.f_RR_CurveAge(RR_CurveType, RR_CurveIntercept, MinRawCondition, RR_CurveSlope) - (YEAR(RR_LastInspection) - RR_InstallYear) + (0.05 * RR_EUL)	-- Positive age offset based on Min Inspect + 5% of EUL
				WHEN MaxRawCondition <= CAST(dbo.f_RR_CurveCondition(RR_CurveType, RR_CurveIntercept, (YEAR(RR_LastInspection) - RR_InstallYear), RR_CurveSlope) AS Int)    -- Max Inspect Lof < Age LoF (2022-03-18 MaxCondition must be <=)
					THEN dbo.f_RR_CurveAge(RR_CurveType, RR_CurveIntercept, MaxRawCondition , RR_CurveSlope) - (YEAR(RR_LastInspection) - RR_InstallYear) - (0.05 * RR_EUL) -- Negative age offset based on Max Inspect - 5% of EUL
				ELSE 0  -- no offset because Inspect LoF is within Age LoF range
			END)
	FROM	RR_Assets INNER JOIN
			RR_Conditions ON RR_Assets.RR_LoFInspection = RR_Conditions.Condition_Score
	WHERE	RR_Assets.RR_LoFInspection > 0;

	-- Set current age offset based on LoF Phys of 2 at the last rehab year if no more recent inspection exists
	-- ISNULL OF RR_PreviousRehabYear MUST BE GREATER THAN ISNULL OF RR_LastInspection
	UPDATE	RR_Assets
	SET		RR_AgeOffset = dbo.f_RR_CurveAge(RR_CurveType, RR_CurveIntercept, 2, RR_CurveSlope) - (RR_Assets.RR_PreviousRehabYear - RR_Assets.RR_InstallYear)
	WHERE	ISNULL(RR_PreviousRehabYear, 0) >= ISNULL(YEAR(RR_LastInspection), 1);

	-- Update curve values based on statistical model results if they exist and a physical condition assessment score does not exist
	UPDATE	RR_Assets
	SET		RR_CurveType = 'E', 
			RR_CurveIntercept = v_03a_CurveCalc.InterceptConst, 
			RR_CurveSlope = CASE WHEN SlopeExponent < 0.0001 THEN 0.0001 ELSE SlopeExponent END, 
			RR_EUL = ROUND(dbo.f_RR_CurveAge('E', v_03a_CurveCalc.InterceptConst, RR_Cohorts.ConditionAtEUL, CASE WHEN SlopeExponent < 0.0001 THEN 0.0001 ELSE SlopeExponent END), 0), 
			RR_AgeOffset = 0, 
			RR_FailurePhysOffset = 0
	FROM	RR_Cohorts INNER JOIN
			RR_Assets INNER JOIN
			v_03a_CurveCalc ON v_03a_CurveCalc.RR_Asset_ID = RR_Assets.RR_Asset_ID ON RR_Cohorts.Cohort_ID = RR_Assets.RR_Cohort_ID
	WHERE	(ISNULL(RR_Assets.RR_LoFInspection, 0) = 0);

END --p_03_UpdateAssetCurves
GO

UPDATE RR_CONFIG SET VERSION = 5.008;
GO







--v5.009
--Add Improve and Inspect service types
--	Add ServiceType constriant
--  Added InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight to RR_Scenarios
--  Updated v_00_02_ScenarioNames to include InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight 
--	Updated v_14_ScenarioSummary to include InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight 
--	Updated p_14_Results_Summary_Update to set InspectedCost, ImprovedCost, InspectedWeight and ImprovedWeight
--  Inserted fields into Scenarios RR_ConfigTableLookup
--	Updated v_10_01_ScenarioCurrentYear_RR_Projects to return specified ServiceType instead of defaulting to Rehab and default cost to 1 instead of RehabCost
--	Updated p_10_ProcessScenarioYear to set CurrentPerformance = 1 when ServiceType IN ('Replace', 'Improve')
--	Updated p_10a_ScenarioYearProjectsUpdate to set CurrentPerformance = 1 when ServiceType IN ('Replace', 'Improve')
--	Updated p_11_UpdateScenarioAsset to add Improve service type

ALTER TABLE [dbo].[RR_Projects]  WITH CHECK ADD  CONSTRAINT [CK_RR_Projects_ServiceType] CHECK  (([ServiceType]='Improve' OR [ServiceType]='Inspect' OR [ServiceType]='Replace' OR [ServiceType]='Rehab' OR [ServiceType]='Repair'))
GO
ALTER TABLE [dbo].[RR_Projects] CHECK CONSTRAINT [CK_RR_Projects_ServiceType]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TABLE [dbo].[RR_Scenarios] ADD
	[InspectedWeight] [bigint] NULL,
	[ImprovedWeight] [bigint] NULL,
	[InspectedCost] [bigint] NULL,
	[ImprovedCost] [bigint] NULL;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_00_02_ScenarioNames]
AS
SELECT	Scenario_ID, ScenarioName, CONCAT(ScenarioName, ' ',  + FORMAT(LastRun, 'yyy-MM-yy'), ' ',  + FORMAT(LastRun, 'hh:mm:ss')) AS NameLastRun2, Description, 
		LastRun, PBI_Flag, InspectedCost, ImprovedCost, RehabbedCost, ReplacedCost, SubCost, Adjustment, TotalCost, InspectedWeight, ImprovedWeight, ReplacedWeight, RehabbedWeight, TotalWeight
FROM	dbo.RR_Scenarios
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_14_ScenarioSummary]
AS
	SELECT	dbo.RR_Scenarios.Scenario_ID,
			SUM(CAST(dbo.RR_ScenarioResults.CostOfService AS bigint)) AS TotalCost, 
			SUM(dbo.v__ActiveAssets.Weighting) AS TotalWeight, 
			SUM(CASE WHEN Service = 'Inspect' THEN CostOfService ELSE 0 END) AS TotalInspectedCost, 
			SUM(CASE WHEN Service = 'Improve' THEN CostOfService ELSE 0 END) AS TotalImprovedCost, 
			SUM(CASE WHEN Service = 'Replace' THEN CostOfService ELSE 0 END) AS TotalReplaceCost, 
			SUM(CASE WHEN Service = 'Rehab' THEN CostOfService ELSE 0 END) AS TotalRehabCost, 
			SUM(CASE WHEN Service = 'Inspect' THEN Weighting ELSE 0 END) AS TotalInspectedAssets, 
			SUM(CASE WHEN Service = 'Improve' THEN Weighting ELSE 0 END) AS TotalImprovedAssets, 
			SUM(CASE WHEN Service = 'Replace' THEN Weighting ELSE 0 END) AS TotalReplacedAssets, 
			SUM(CASE WHEN Service = 'Rehab' THEN Weighting ELSE 0 END) AS TotalRehabbedAssets
	FROM	dbo.RR_Scenarios INNER JOIN
			dbo.RR_ScenarioResults ON dbo.RR_Scenarios.Scenario_ID = dbo.RR_ScenarioResults.Scenario_ID INNER JOIN
			dbo.v__ActiveAssets ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID
	WHERE	(dbo.RR_ScenarioResults.CostOfService > 0)
	GROUP BY dbo.RR_Scenarios.Scenario_ID
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_14_Results_Summary_Update]
AS
BEGIN

	SET NOCOUNT ON;
	
	UPDATE	[RR_ScenarioYears]
	SET		[ActualBudget] = a.[Cost]
			, [OverallCount] = a.[TotalCount]
			, [OverallWeighting] = a.[TotalWeighting]
			, [OverallAgeWeighted] = a.[TotalAgeWeighted]/[TotalWeighting]
			, [OverallAgeAvg] = a.[TotalAgeAvg]
			, [OverallPhysRawWeighted] = a.[TotalPhysRawWeighted]/[TotalWeighting]
			, [OverallPhysRawAvg] = a.[TotalPhysRawAvg]
			, [OverallPhysScoreWeighted] = a.[TotalPhysScoreWeighted]/[TotalWeighting]
			, [OverallPhysScoreAvg] = a.[TotalPhysScoreAvg]
			, [OverallPerfScoreWeighted] = a.[TotalPerfScoreWeighted]/[TotalWeighting] 
			, [OverallPerfScoreAvg] = a.[TotalPerfScoreAvg]
			, [OverallLoFRawWeighted] = a.[TotalLoFRawWeighted]/[TotalWeighting]
			, [OverallLoFRawAvg] = a.[TotalLoFRawAvg]
			, [OverallLoFScoreWeighted] = a.[TotalLoFScoreWeighted]/[TotalWeighting]
			, [OverallLoFScoreScore] = a.[TotalLoFScoreAvg]
			, [OverallRiskRawWeighted] = a.[TotalRiskRawWeighted]/[TotalWeighting]
			, [OverallRiskRawAvg] = a.[TotalRiskRawAvg]
			, [OverallRiskScoreWeighted] = a.[TotalRiskScoreWeighted]/[TotalWeighting]
			, [OverallRiskScoreAvg] = a.[TotalRiskScoreAvg]
			, [ServicedCount] = a.[ReplacedCount]
			, [ServicedWeighting] = a.[ReplacedWeighting]
			, [ServicedAgeWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedAgeWeighted]/[ReplacedWeighting])
			, [ServicedAgeAvg] = a.[ReplacedAgeAvg]
			, [ServicedPhysRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysRawWeighted]/[ReplacedWeighting])
			, [ServicedPhysRawAvg] = a.[ReplacedPhysRawAvg]
			, [ServicedPhysScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPhysScoreWeighted]/[ReplacedWeighting])
			, [ServicedPhysScoreAvg] = a.[ReplacedPhysScoreAvg]
			, [ServicedPerfScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedPerfScoreWeighted]/[ReplacedWeighting])
			, [ServicedPerfScoreAvg] = a.[ReplacedPerfScoreAvg]
			, [ServicedLoFRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFRawWeighted]/[ReplacedWeighting])
			, [ServicedLoFRawAvg] = a.[ReplacedLoFRawAvg]
			, [ServicedLoFScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedLoFScoreWeighted]/[ReplacedWeighting])
			, [ServicedLoFScoreAvg] = a.[ReplacedLoFScoreAvg]
			, [ServicedCoFWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedCoFWeighted]/[ReplacedWeighting])
			, [ServicedCoFAvg] = a.[ReplacedCoFAvg]
			, [ServicedRiskRawWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskRawWeighted]/[ReplacedWeighting])
			, [ServicedRiskRawAvg] = a.[ReplacedRiskRawAvg]
			, [ServicedRiskScoreWeighted] = IIf([ReplacedWeighting]=0,Null,[ReplacedRiskScoreWeighted]/[ReplacedWeighting])
			, [ServicedRiskScoreAvg] = a.[ReplacedRiskScoreAvg]
			, [LoF5Remaining] = a.LoF5Remaining
			, [Risk16Remaining] = a.Risk16Remaining
	FROM [v_14_Results_Summary] AS a
	INNER JOIN [RR_ScenarioYears] 
		ON ([a].[Scenario_ID] = [RR_ScenarioYears].[Scenario_ID]) 
		AND ([a].[ScenarioYear] = [RR_ScenarioYears].[BudgetYear]);

	UPDATE	RR_Scenarios
	SET		SubCost = v_14_ScenarioSummary.TotalCost,
			InspectedCost = v_14_ScenarioSummary.TotalInspectedCost,
			ImprovedCost = v_14_ScenarioSummary.TotalImprovedCost,
			ReplacedCost = v_14_ScenarioSummary.TotalReplaceCost, 
			RehabbedCost = v_14_ScenarioSummary.TotalRehabCost, 
			TotalWeight = v_14_ScenarioSummary.TotalWeight, 
			InspectedWeight = v_14_ScenarioSummary.TotalInspectedAssets,
			ImprovedWeight = v_14_ScenarioSummary.TotalImprovedAssets,
			ReplacedWeight = v_14_ScenarioSummary.TotalReplacedAssets, 
			RehabbedWeight = v_14_ScenarioSummary.TotalRehabbedAssets
	FROM	v_14_ScenarioSummary INNER JOIN
			RR_Scenarios ON v_14_ScenarioSummary.Scenario_ID = RR_Scenarios.Scenario_ID;

	UPDATE	RR_Scenarios
	SET		Adjustment = t2.TotalCosts - RR_Scenarios.SubCost ,
			TotalCost = t2.TotalCosts
	FROM	RR_Scenarios
			INNER JOIN (SELECT Scenario_ID, SUM(RR_ScenarioYears.ActualBudget) as TotalCosts
						FROM RR_ScenarioYears
						GROUP BY Scenario_ID) as t2
			ON t2.Scenario_ID = RR_Scenarios.Scenario_ID;

	UPDATE RR_RuntimeConfig set StartedOn = NULL;

END   --p_14_Results_Summary_Update
GO


INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'InspectedCost', N'Inspected Cost', 6, 100, 32, N'$#,##0', 0, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'ImprovedCost', N'Improved Cost', 6, 100, 32, N'$#,##0', 0, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'InspectedWeight', N'Inspected', 11, 100, 32, N'#,##0', 0, 0)
INSERT [RR_ConfigTableLookup] ([TableName], [ColumnName], [ColumnAlias], [DisplayOrder], [ColumnWidth], [Alignment], [Format], [AllowEdit], [FreezeColumn]) VALUES (N'Scenarios', N'ImprovedWeight', N'Improved', 11, 100, 32, N'#,##0', 0, 0)
GO




SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[v_10_01_ScenarioCurrentYear_RR_Projects]
AS
SELECT	v_10_a_ScenarioCurrentYearDetails.CurrentScenario_ID, v_10_a_ScenarioCurrentYearDetails.CurrentYear, v_10_a_ScenarioCurrentYearDetails.RR_Asset_ID, RR_Projects.ProjectYear, RR_Projects.ServiceType, 
		CASE WHEN RR_Projects.ServiceType = 'Replace' THEN CostReplace WHEN RR_Projects.ServiceType = 'Rehab' THEN CostRehab WHEN RR_Projects.ServiceType = 'Repair' THEN CostRepair ELSE 1 END AS ServiceCost, 
		v_10_a_ScenarioCurrentYearDetails.SystemCondition, v_10_a_ScenarioCurrentYearDetails.SystemRiskScore, v_10_a_ScenarioCurrentYearDetails.SystemRiskRaw, 
		v_10_a_ScenarioCurrentYearDetails.ProjectNumber, v_10_a_ScenarioCurrentYearDetails.CurrentAge, v_10_a_ScenarioCurrentYearDetails.PhysRaw, v_10_a_ScenarioCurrentYearDetails.LoFRaw, 
		v_10_a_ScenarioCurrentYearDetails.PhysScore, v_10_a_ScenarioCurrentYearDetails.PerfScore, v_10_a_ScenarioCurrentYearDetails.LoFScore, v_10_a_ScenarioCurrentYearDetails.RedundancyFactor, 
		v_10_a_ScenarioCurrentYearDetails.CoF_R, v_10_a_ScenarioCurrentYearDetails.CostReplace, v_10_a_ScenarioCurrentYearDetails.CostRehab, v_10_a_ScenarioCurrentYearDetails.CostRepair, 
		v_10_a_ScenarioCurrentYearDetails.YearRiskRaw, v_10_a_ScenarioCurrentYearDetails.YearRiskScore
FROM	v_10_a_ScenarioCurrentYearDetails INNER JOIN
		RR_Projects ON v_10_a_ScenarioCurrentYearDetails.ProjectNumber = RR_Projects.ProjectNumber AND v_10_a_ScenarioCurrentYearDetails.CurrentYear = RR_Projects.ProjectYear
WHERE	(v_10_a_ScenarioCurrentYearDetails.UseProjectBudget = 1);
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10a_ScenarioYearProjectsUpdate]
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE	RR_ScenarioResults
	SET		CostOfService = [ServiceCost], Service = [ServiceType]
	FROM	RR_ScenarioResults INNER JOIN
			v_10_01_ScenarioCurrentYear_RR_Projects AS p ON RR_ScenarioResults.RR_Asset_ID = p.RR_Asset_ID AND RR_ScenarioResults.Scenario_ID = p.CurrentScenario_ID AND 
			RR_ScenarioResults.ScenarioYear = p.CurrentYear ;

	UPDATE	v__RuntimeResults
	SET		CurrentInstallYear = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.CurrentYear ELSE CurrentInstallYear END, 
			CurrentEquationType = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceEquationType ELSE CurrentEquationType END,  
			CurrentConstIntercept = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
			CurrentExpSlope = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope ELSE CurrentExpSlope END, 
			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentPerformance = CASE WHEN  [ServiceType] IN ('Replace', 'Improve') THEN  1 ELSE CurrentPerformance END, 
			RepairsRemaining = CASE WHEN  [ServiceType] = 'Repair' THEN  RepairsRemaining - 1 ELSE v__RuntimeResults.RepairsAllowed END, 
			RehabsRemaining = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining END
	FROM	v__RuntimeResults INNER JOIN
			v_10_01_ScenarioCurrentYear_RR_Projects AS p ON v__RuntimeResults.RR_Asset_ID = p.RR_Asset_ID;

END  --p_10a_ScenarioYearProjectsUpdate
GO




SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10a_ScenarioYearRiskUpdate]
	@iBudget int = 0 , 
	@fCurrentCondition float = 0,
	@fCurrentRisk float = 0, 
	@fTargetCondition float = 0,  
	@fTargetRisk float = 0  
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE	RR_ScenarioResults
	SET		CostOfService = [ServiceCost], Service = [ServiceType]
	FROM	RR_ScenarioResults INNER JOIN
			v_10_00_Running_Risk ON RR_ScenarioResults.RR_Asset_ID = v_10_00_Running_Risk.RR_Asset_ID AND RR_ScenarioResults.Scenario_ID = v_10_00_Running_Risk.CurrentScenario_ID AND 
			RR_ScenarioResults.ScenarioYear = v_10_00_Running_Risk.CurrentYear
	WHERE	[ServiceCost] < =  @iBudget AND
			RunningCost <= @iBudget AND 
			RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
			RunningCondition <= @fCurrentCondition - @fTargetCondition ;

	UPDATE	v__RuntimeResults
	SET		CurrentInstallYear = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.CurrentYear  ELSE CurrentInstallYear END   , 
			CurrentEquationType = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceEquationType  ELSE CurrentEquationType END,  
			CurrentConstIntercept =  CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
			CurrentExpSlope = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope   ELSE  CurrentExpSlope END, 
--			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
--			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN [ServiceType] = 'Replace' THEN 0 
									WHEN [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) 
									ELSE CurrentAgeOffset END, 
			CurrentFailurePhysOffset = CASE WHEN [ServiceType] IN ('Replace', 'Rehab') THEN 0 ELSE CurrentFailurePhysOffset END, 
			CurrentPerformance = CASE WHEN [ServiceType]IN ('Replace', 'Improve') THEN  1 ELSE CurrentPerformance END, 
			RepairsRemaining = CASE WHEN [ServiceType] = 'Repair' THEN  RepairsRemaining - 1 ELSE v__RuntimeResults.RepairsAllowed END, 
--			RehabsRemaining = CASE WHEN [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
			RehabsRemaining = CASE WHEN  [ServiceType] = 'Rehab' THEN RehabsRemaining - 1 WHEN [ServiceType] = 'Replace' THEN v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining END
	FROM	v__RuntimeResults INNER JOIN
			v_10_00_Running_Risk ON v__RuntimeResults.RR_Asset_ID = v_10_00_Running_Risk.RR_Asset_ID
	WHERE	[ServiceCost] < =  @iBudget AND
			RunningCost <= @iBudget AND 
			RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
			RunningCondition <= @fCurrentCondition - @fTargetCondition ;

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10a_ScenarioYearLoFUpdate]
	@iBudget int = 0 , 
	@fCurrentCondition float = 0,
	@fCurrentRisk float = 0, 
	@fTargetCondition float = 0,  
	@fTargetRisk float = 0  
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE	RR_ScenarioResults
	SET		CostOfService = [ServiceCost], Service = [ServiceType]
	FROM	RR_ScenarioResults INNER JOIN
			v_10_00_Running_LoF ON RR_ScenarioResults.RR_Asset_ID = v_10_00_Running_LoF.RR_Asset_ID AND RR_ScenarioResults.Scenario_ID = v_10_00_Running_LoF.CurrentScenario_ID AND 
			RR_ScenarioResults.ScenarioYear = v_10_00_Running_LoF.CurrentYear
	WHERE	[ServiceCost] < =  @iBudget AND
			RunningCost <= @iBudget AND 
			RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
			RunningCondition <= @fCurrentCondition - @fTargetCondition ;

	UPDATE	v__RuntimeResults
	SET		CurrentInstallYear = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.CurrentYear ELSE CurrentInstallYear END, 
			CurrentEquationType = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceEquationType ELSE CurrentEquationType END,  
			CurrentConstIntercept = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
			CurrentExpSlope = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope ELSE CurrentExpSlope END, 
--			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
--			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN [ServiceType] = 'Replace' THEN 0 
									WHEN [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) 
									ELSE CurrentAgeOffset END, 
			CurrentFailurePhysOffset = CASE WHEN [ServiceType] IN ('Replace', 'Rehab') THEN 0 ELSE CurrentFailurePhysOffset END, 
			CurrentPerformance = CASE WHEN [ServiceType]IN ('Replace', 'Improve') THEN  1 ELSE CurrentPerformance END, 
			RepairsRemaining = CASE WHEN [ServiceType] = 'Repair' THEN  RepairsRemaining - 1 ELSE v__RuntimeResults.RepairsAllowed END, 
--			RehabsRemaining = CASE WHEN [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
			RehabsRemaining = CASE WHEN  [ServiceType] = 'Rehab' THEN RehabsRemaining - 1 WHEN [ServiceType] = 'Replace' THEN v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining END
	FROM	v__RuntimeResults INNER JOIN
			v_10_00_Running_LoF ON v__RuntimeResults.RR_Asset_ID = v_10_00_Running_LoF.RR_Asset_ID
	WHERE	[ServiceCost] < =  @iBudget AND
			RunningCost <= @iBudget AND 
			RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
			RunningCondition <= @fCurrentCondition - @fTargetCondition ;

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10a_ScenarioYearProjectsUpdate]
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE	RR_ScenarioResults
	SET		CostOfService = [ServiceCost], Service = [ServiceType]
	FROM	RR_ScenarioResults INNER JOIN
			v_10_01_ScenarioCurrentYear_RR_Projects AS p ON RR_ScenarioResults.RR_Asset_ID = p.RR_Asset_ID AND RR_ScenarioResults.Scenario_ID = p.CurrentScenario_ID AND 
			RR_ScenarioResults.ScenarioYear = p.CurrentYear ;

	UPDATE	v__RuntimeResults
	SET		CurrentInstallYear = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.CurrentYear ELSE CurrentInstallYear END, 
			CurrentEquationType = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceEquationType ELSE CurrentEquationType END,  
			CurrentConstIntercept = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
			CurrentExpSlope = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope ELSE CurrentExpSlope END, 
--			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
--			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN [ServiceType] = 'Replace' THEN 0 
									WHEN [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) 
									ELSE CurrentAgeOffset END, 
			CurrentFailurePhysOffset = CASE WHEN [ServiceType] IN ('Replace', 'Rehab') THEN 0 ELSE CurrentFailurePhysOffset END, 
			CurrentPerformance = CASE WHEN [ServiceType]IN ('Replace', 'Improve') THEN  1 ELSE CurrentPerformance END, 
			RepairsRemaining = CASE WHEN [ServiceType] = 'Repair' THEN  RepairsRemaining - 1 ELSE v__RuntimeResults.RepairsAllowed END, 
--			RehabsRemaining = CASE WHEN [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
			RehabsRemaining = CASE WHEN  [ServiceType] = 'Rehab' THEN RehabsRemaining - 1 WHEN [ServiceType] = 'Replace' THEN v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining END
	FROM	v__RuntimeResults INNER JOIN
			v_10_01_ScenarioCurrentYear_RR_Projects AS p ON v__RuntimeResults.RR_Asset_ID = p.RR_Asset_ID;

END  --p_10a_ScenarioYearProjectsUpdate
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_10_ProcessScenarioYear] 
AS
BEGIN

	DECLARE @iScenarioID int = 0  
	DECLARE @iCurrentYear int = 0  
	DECLARE @iTargetBudget int = 0  
	DECLARE @fTargetCondition float = 0  
	DECLARE @fTargetRisk float = 0  
	DECLARE @fRiskAllocation float = 1
	DECLARE @iProjectsCost int = 0

	DECLARE @iRemainingBudget int = 0  
	DECLARE @iRiskBudget int = 0  
	DECLARE @iConditionBudget int = 0  

	DECLARE @iRiskBudgetStart int = 0  
	DECLARE @iConditionBudgetStart int = 0  

	DECLARE @iTempBudget int = 0  

	DECLARE @iAssetID int = 0  
	DECLARE @iServiceCost int = 0  
	DECLARE @sServiceType nvarchar(8) = ''  
	DECLARE @iOverallReducedBudget int = 0  
	DECLARE @fCurrentCondition float = 0  
	DECLARE @fCurrentRisk float = 0 
	DECLARE @iReducedBudget int = 0  
	DECLARE @fReducedCondition float = 0  
	DECLARE @fReducedRisk float = 0  
	DECLARE @i int = 0
	
	SET NOCOUNT ON;

	SELECT	@iScenarioID = RR_RuntimeConfig.CurrentScenario_ID,
			@iCurrentYear = RR_RuntimeConfig.CurrentYear,
			@iTargetBudget = RR_ScenarioYears.Budget,
			@fTargetCondition = RR_ScenarioYears.ConditionTarget, 
			@fTargetRisk = RR_ScenarioYears.RiskTarget,
			@fRiskAllocation = RR_ScenarioYears.AllocationToRisk
	FROM	RR_ScenarioYears INNER JOIN RR_RuntimeConfig 
			ON RR_ScenarioYears.Scenario_ID = RR_RuntimeConfig.CurrentScenario_ID AND RR_ScenarioYears.BudgetYear = RR_RuntimeConfig.CurrentYear;

-- next two statement are from p_09_UpdateScenarioResultsForAYear
	-- Create RR_ScenarioYears records for the current year
	INSERT INTO RR_ScenarioResults (Scenario_ID, ScenarioYear, RR_Asset_ID, Age, PhysRaw, PhysScore, PerfScore, CostOfService, [Service])
	SELECT	CurrentScenario_ID, CurrentYear, RR_Asset_ID, CurrentAge, PhysRaw, PhysScore, PerfScore, 0, 'Maintain'
	FROM	v_10_a_ScenarioCurrentYearDetails;

	-- Initialize RR_RuntimeConfig
	UPDATE	RR_RuntimeConfig
	SET		CurrentBudget = NULL;

	-- Apply project assets for the current year
	EXEC p_10a_ScenarioYearProjectsUpdate; 

	-- Determine the cost of the projects (some may have override costs and some may use the asset calculated cost. This needs to be subtracted from the overall yearly budget
	SELECT	@iProjectsCost = ISNULL(SUM(OverrideCost), 0)
	FROM	RR_ScenarioYears INNER JOIN RR_Projects ON RR_ScenarioYears.BudgetYear = RR_Projects.ProjectYear 
	WHERE	UseProjectBudget = 1 AND Scenario_ID = @iScenarioID AND BudgetYear = @iCurrentYear;

	SELECT	@iRemainingBudget = @iTargetBudget - @iProjectsCost;  
	SELECT	@iOverallReducedBudget = @iProjectsCost;
	SELECT	@iRiskBudget = @iRemainingBudget * @fRiskAllocation;
	SELECT	@iConditionBudget = @iRemainingBudget * (1 - @fRiskAllocation);

	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,' Start'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Target: ', format(@iTargetBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Projects: ', format(@iProjectsCost, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Remaining: ', format(@iRemainingBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Risk Percent: ', format(@fRiskAllocation, '#0%')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Risk Budget: ', format(@iRiskBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear,'  Condition Budget: ', format(@iConditionBudget, '$#,##0')));

	--Get the highest priority asset
	IF @fRiskAllocation = 0  --All budget is for condition
		BEGIN --Use condition sorting
			SELECT	TOP (1)
					@iAssetID = RR_Asset_ID, 
					@iServiceCost = ServiceCost, 
					@sServiceType = ServiceType
			FROM	v_10_01_ScenarioCurrentYear_RR_Assets
			ORDER BY LoFScore DESC, LoFRaw DESC, SystemRiskScore DESC, RR_Asset_ID;

			SELECT	@iTempBudget =  @iConditionBudget;
		END
	ELSE  --Some or all budget is for risk
		BEGIN --Use risk sorting
			SELECT	TOP (1)
					@iAssetID = RR_Asset_ID, 
					@iServiceCost = ServiceCost, 
					@sServiceType = ServiceType
			FROM	v_10_01_ScenarioCurrentYear_RR_Assets
			ORDER BY YearRiskScore DESC, YearRiskRaw DESC, SystemRiskScore DESC, RR_Asset_ID;

			SELECT	@iTempBudget =  @iRiskBudget;
		END

	--If the highest priority asset is more expensive than budget then perform the service on that asset only
	IF @iAssetID > 0 AND @iTempBudget > 0 AND @iServiceCost >= @iTempBudget 
		BEGIN

			UPDATE	RR_ScenarioResults
			SET		CostOfService = @iServiceCost, 
					Service = @sServiceType
			WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @iCurrentYear AND  RR_Asset_ID = @iAssetID;

			UPDATE	v__RuntimeResults
			SET		CurrentInstallYear = CASE WHEN @sServiceType = 'Replace' THEN  v__RuntimeResults.CurrentYear ELSE CurrentInstallYear END, 
					CurrentEquationType = CASE WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceEquationType ELSE CurrentEquationType END,  
					CurrentConstIntercept =  CASE WHEN @sServiceType = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
					CurrentExpSlope = CASE WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope ELSE  CurrentExpSlope END, 
--					CurrentFailurePhysOffset = CASE WHEN @sServiceType = 'Repair' THEN CurrentFailurePhysOffset ELSE 0 END, 
--					CurrentAgeOffset = CASE WHEN @sServiceType = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
					CurrentAgeOffset = CASE WHEN @sServiceType = 'Replace' THEN 0 
											WHEN @sServiceType = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) 
											ELSE CurrentAgeOffset END, 
					CurrentFailurePhysOffset = CASE WHEN @sServiceType IN ('Replace', 'Rehab') THEN 0 ELSE CurrentFailurePhysOffset END, 
					CurrentPerformance = CASE WHEN @sServiceType IN ('Replace', 'Improve') THEN  1 ELSE CurrentPerformance END, 
					RepairsRemaining =  CASE WHEN @sServiceType = 'Repair' THEN RepairsRemaining - 1 ELSE v__RuntimeResults.RepairsAllowed END, 
--					RehabsRemaining =  CASE WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining  END
					RehabsRemaining = CASE WHEN  @sServiceType = 'Rehab' THEN RehabsRemaining - 1 WHEN @sServiceType = 'Replace' THEN v__RuntimeResults.RehabsAllowed ELSE RehabsRemaining END
			WHERE	RR_Asset_ID = @iAssetID ;

			-- Budget should be negative and prevents more assets from being serviced, this amount will be used to calc and store remaining target for next proc
 			SELECT	@iOverallReducedBudget = @iOverallReducedBudget + @iServiceCost,
					@iRemainingBudget = @iRemainingBudget - @iServiceCost;
		
			IF @fRiskAllocation = 0												--All budget is for condition
				SELECT	@iConditionBudget = @iConditionBudget - @iServiceCost;	--Should be negative
			ELSE																--Some or all budget is for risk
				SELECT	@iRiskBudget = @iRiskBudget - @iServiceCost,			--Should be negative
						@iConditionBudget = @iConditionBudget + (@iRiskBudget - @iServiceCost);	--May or maynot be negative
		
			insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '   Single Asset: ', format(@iServiceCost, '$#,##0')));
			insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '    Spend: ', format(@iOverallReducedBudget, '$#,##0')));
			insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '    Remaining: ', format(@iRemainingBudget, '$#,##0')));

		END

	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '  Start Risk'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '   Risk Budget: ', format(@iRiskBudget, '$#,##0')));

	SELECT @fCurrentCondition = Cond, @fCurrentRisk = Risk, @i = 0 FROM v_20_00_ScenerioYearConditionRisk;

	--Pocess risk priority assets up to 10 iterations or within $1,000 of risk budget

	SELECT @iRiskBudgetStart = @iRiskBudget;

	WHILE @iRiskBudget > 1000 AND @fCurrentCondition > @fTargetCondition AND @fCurrentRisk > @fTargetRisk AND @i < 10 BEGIN

		SELECT @i = @i + 1

		UPDATE RR_RuntimeConfig SET CurrentBudget = @iRiskBudget;  --CHECK TO SEE IF CurrentBudget IS ACTUALLY BEIG USED BY ANYTHING ELSE

		SELECT	@iReducedBudget = ISNULL(MAX(RunningCost), 0), @fReducedRisk = ISNULL(MAX(RunningRisk), 0), @fReducedCondition = ISNULL(MAX(RunningCondition), 0)
		FROM	v_10_00_Running_Risk
		WHERE	RunningCost <= @iRiskBudget AND 
				RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
				RunningCondition <= @fCurrentCondition - @fTargetCondition 	;

		EXEC p_10a_ScenarioYearRiskUpdate @iRiskBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

		SELECT	@iRiskBudget = @iRiskBudget - @iReducedBudget,  
				@iOverallReducedBudget = @iOverallReducedBudget + @iReducedBudget, 
				@fCurrentCondition = @fCurrentCondition - @fReducedCondition, 
				@fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		IF @iReducedBudget = 0 
			SELECT @i = 10;

		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Reduced Risk: ', format(@iReducedBudget, '$#,##0')));
		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining Risk: ', format(@iRiskBudget, '$#,##0')));

	END

	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Risk Spend: ', format(@iRiskBudgetStart - @iRiskBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining: ', format(@iTargetBudget - @iOverallReducedBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '  End Risk'));

	SELECT	@fCurrentCondition = Cond, @fCurrentRisk = Risk, @i = 0 FROM v_20_00_ScenerioYearConditionRisk;
	SELECT	@iConditionBudget = @iTargetBudget - @iOverallReducedBudget;
	SELECT	@iConditionBudgetStart = @iConditionBudget;

	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '  Start Cond'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (0, concat(@iCurrentYear, '   Condition Budget: ', format(@iConditionBudget, '$#,##0')));

	WHILE @iConditionBudget > 1000 AND @fCurrentCondition > @fTargetCondition AND @fCurrentRisk > @fTargetRisk AND @i < 10 BEGIN

		SELECT @i = @i + 1
			
		UPDATE RR_RuntimeConfig SET CurrentBudget = @iConditionBudget;

		SELECT	@iReducedBudget = ISNULL(MAX(RunningCost), 0), @fReducedRisk = ISNULL(MAX(RunningRisk), 0), @fReducedCondition = ISNULL(MAX(RunningCondition), 0)
		FROM	v_10_00_Running_LoF
		WHERE	RunningCost <= @iConditionBudget AND 
				RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
				RunningCondition <= @fCurrentCondition - @fTargetCondition 	;

		EXEC p_10a_ScenarioYearLoFUpdate @iConditionBudget, @fCurrentCondition, @fCurrentRisk, @fTargetCondition, @fTargetRisk;

		SELECT	@iConditionBudget = @iConditionBudget - @iReducedBudget,  
				@iOverallReducedBudget = @iOverallReducedBudget + @iReducedBudget, 
				@fCurrentCondition = @fCurrentCondition - @fReducedCondition, 
				@fCurrentRisk =  @fCurrentRisk - @fReducedRisk ;

		IF @iReducedBudget = 0 
			SELECT @i = 10;

		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Reduced Cond: ', format(@iReducedBudget, '$#,##0')));
		insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining Cond: ', format(@iConditionBudget, '$#,##0')));

	END

	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Cond Spend: ', format(@iConditionBudgetStart - @iConditionBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear, '   Remaining: ', format(@iTargetBudget - @iOverallReducedBudget, '$#,##0')));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear,'  End Cond'));
	insert into rr_TraceX (trace_Step, trace_details) VALUES (@i, concat(@iCurrentYear,' End'));

END  --p_10_ProcessScenarioYear
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_11_UpdateScenarioAsset]
	@iAssetID int, @sServiceType nvarchar(8), @iServiceCost int, @iScenarioID int, @ScenarioYear smallint
AS
BEGIN
	SET NOCOUNT ON;

	IF @sServiceType = 'Repair' 
	BEGIN
		UPDATE	RR_RuntimeAssets
		SET		CurrentAgeOffset = 0, 
				RepairsRemaining = RepairsRemaining - 1
		FROM	RR_RuntimeAssets WHERE RR_Asset_ID = @iAssetID;
	END

	IF @sServiceType = 'Rehab' 
	BEGIN
		UPDATE	v__RuntimeResults
		SET		CurrentAgeOffset = v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (@ScenarioYear - v__RuntimeResults.CurrentInstallYear), 
				CurrentFailurePhysOffset = 0,
				RehabsRemaining = v__RuntimeResults.RehabsRemaining - 1
		FROM	v__RuntimeResults 
		WHERE v__RuntimeResults.RR_Asset_ID = @iAssetID;
	END

	IF @sServiceType = 'Replace' 
	BEGIN
		UPDATE	v__RuntimeResults
		SET		CurrentInstallYear = @ScenarioYear, 
				CurrentEquationType = v__RuntimeResults.ReplaceEquationType, 
				CurrentConstIntercept = v__RuntimeResults.ReplaceConstIntercept, 
				CurrentExpSlope = v__RuntimeResults.ReplaceExpSlope, 
				CurrentAgeOffset = 0, 
				CurrentFailurePhysOffset = 0,
				CurrentPerformance = 1, 
				RepairsRemaining = v__RuntimeResults.RepairsAllowed, 
				RehabsRemaining = v__RuntimeResults.RehabsAllowed
		FROM   v__RuntimeResults 
		WHERE v__RuntimeResults.RR_Asset_ID = @iAssetID;
	END

	IF @sServiceType = 'Improve' 
	BEGIN
		UPDATE	v__RuntimeResults
		SET		CurrentPerformance = 1
		FROM   v__RuntimeResults 
		WHERE v__RuntimeResults.RR_Asset_ID = @iAssetID;
	END

	UPDATE	RR_ScenarioResults 
	SET		CostOfService = @iServiceCost, Service = @sServiceType 
	WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @ScenarioYear AND RR_Asset_ID = @iAssetID;

END  --p_11_UpdateScenarioAsset
GO


UPDATE RR_CONFIG SET VERSION = 5.009;
GO
