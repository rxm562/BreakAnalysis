--USE XXXXX  --MAKE SURE TO USE THE CORRECT NEW DATATBASE
--GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_Config](
	[ID] [smallint] NOT NULL,
	[Version] [float] NULL,
	[ConditionLimit] [float] NULL,
	[ConditionFailureFactor] [float] NULL,
	[CostMultiplier] [float] NULL,
	[RepairsAllowed] [smallint] NULL,
	[RehabsAllowed] [smallint] NULL,
	[RehabPercentEUL] [float] NULL,
	[BaselineYear] [smallint] NULL,
	[StatModel_Name] [nvarchar](16) NULL,
	[StatModel_Start_Row] [smallint] NULL,
	[StatModel_PipeID_Column] [smallint] NULL,
	[StatModel_Year_Column] [smallint] NULL,
	[StatModel_Cond_Column] [smallint] NULL,
	[StatModel_Year_Row] [smallint] NULL,
	[StatModel_Delimiter] [nvarchar](1) NULL,
	[HyperlinkFolder] [nvarchar](255) NULL,
	[BIDocument] [nvarchar](255) NULL,
	[MapDocument] [nvarchar](255) NULL,
	[ProjectName] [nvarchar](64) NULL,
	[ProjectVersion] [nvarchar](16) NULL,
	[ConfigNotes] [nvarchar](max) NULL,
	[CommandTimeout] [smallint] NULL,
	[CurrentScenario_ID] [int] NULL,
	[WeightMultiplier] [float] NOT NULL,
	[Initialized] [datetime2](7) NULL,
 CONSTRAINT [PK_RR_Config] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

--SET THESE PROJECT SPECIFIC VALUES 
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_Version]  DEFAULT (5.008) FOR [Version]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_ProjectName]  DEFAULT (N'RRPS') FOR [ProjectName]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_BaselineYear]  DEFAULT (datepart(year,getdate())) FOR [BaselineYear]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_ConditionLimit]  DEFAULT ((10)) FOR [ConditionLimit]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_ConditionFailureFactor]  DEFAULT ((0.5)) FOR [ConditionFailureFactor]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_CostMultiplier]  DEFAULT ((1)) FOR [CostMultiplier]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_RepairsAllowed]  DEFAULT ((0)) FOR [RepairsAllowed]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_RehabsAllowed]  DEFAULT ((1)) FOR [RehabsAllowed]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_RehabPercentEUL]  DEFAULT ((0.25)) FOR [RehabPercentEUL]
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_CommandTimeout]  DEFAULT ((600)) FOR [CommandTimeout]
GO
ALTER TABLE [RR_Config]  ADD  CONSTRAINT [RR_Config_ID_validation_rule] CHECK  (([ID]=(1)))
GO
ALTER TABLE [RR_Config]  ADD  CONSTRAINT [RR_Config_RehabPercentEUL_validation_rule] CHECK  (([RehabPercentEUL]>=(0) AND [RehabPercentEUL]<(1)))
GO
ALTER TABLE [RR_Config] ADD  CONSTRAINT [DF_RR_Config_WeightMultiplier]  DEFAULT ((1.0)) FOR [WeightMultiplier]
GO


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_RR_ConditionLimit]
(@RawCond real, @CondLimit real)
RETURNS real
AS
BEGIN
	DECLARE @ret real;

	IF @RawCond>@CondLimit 
	  SET @ret =  @CondLimit
	ELSE
	  SET @ret = @RawCond

	RETURN @ret;
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_RR_CurveAge]
(@EQType char(1), @Intercept real, @Cond real, @Slope real)
RETURNS real
AS
BEGIN
	DECLARE @ret real;

	IF @EQType = 'E' SET @ret =  	Log(@Cond/@Intercept)/@Slope
	ELSE
	SET @ret = (@Cond-@Intercept)/@Slope

	RETURN @ret;
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_RR_CurveCondition]
(@EQType char(1), @Intercept real, @Age real, @Slope real)
RETURNS real
AS
BEGIN
	DECLARE @ret real;

	IF @EQType = 'E' SET @ret =  @Intercept*Exp(@Slope*@Age)
	ELSE
	SET @ret = (@Age*@Slope)+@Intercept

	RETURN @ret;

END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_RR_CurveSlope]
(@EQType char(1), @Intercept float, @Cond float, @EUL float)
RETURNS float
AS
BEGIN
	DECLARE @ret float;

	IF @EQType = 'E' SET @ret =  Log(@Cond/@Intercept)/@EUL;
	ELSE
	SET @ret = (@Cond-@Intercept)/@EUL

	RETURN @ret;

END
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_ConfigAliases](
	[Alias_ID] [int] IDENTITY(1,1) NOT NULL,
	[ColumnName] [nvarchar](64) NULL,
	[SearchText] [nvarchar](64) NULL,
	[ReplaceText] [nvarchar](64) NULL,
	[FulcrumName] [nvarchar](64) NULL,
	[Usage] [nvarchar](16)  NOT NULL,
 CONSTRAINT [PK_RR_Config_Aliases] PRIMARY KEY CLUSTERED 
(
	[Alias_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_RR_ConfigAliases_ColumnName] ON [RR_ConfigAliases]
(
	[ColumnName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [RR_ConfigAliases] ADD  CONSTRAINT [DF_RR_ConfigAliases_Usage]  DEFAULT (N'NA') FOR [Usage]
GO

ALTER TABLE [RR_ConfigAliases]  WITH CHECK ADD  CONSTRAINT [CK_RR_ConfigAliases_Usage] CHECK  (([Usage]='Attribute' OR [Usage]='Hierarchy' OR [Usage]='NA'))
GO

ALTER TABLE [RR_ConfigAliases] CHECK CONSTRAINT [CK_RR_ConfigAliases_Usage]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [rr_UpdateAlias](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SQLText] [nvarchar](max) NULL,
	[CreateDate] [smalldatetime] NULL,
 CONSTRAINT [PK_rr_UpdateAlias] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [rr_UpdateAlias] ADD  CONSTRAINT [DF_r_UpdateAlias_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO


--v5.006
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ref_Fulcrum](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[_record_id] [nvarchar](255) NULL,
	[_server_updated_at] [date] NULL,
	[rr_hierarchylevel] [nvarchar](255) NULL,
	[rr_asset_name] [nvarchar](255) NULL,
	[rr_cmms_id] [nvarchar](255) NULL,
	[rr_cmms_id_field] [nvarchar](255) NULL,
	[rr_asset_group] [nvarchar](255) NULL,
	[rr_asset_number] [nvarchar](255) NULL,
	[rr_inspection_type] [nvarchar](255) NULL,
	[rr_asset_type] [nvarchar](255) NULL,
	[rr_is_the_motor_its_own_asset] [nvarchar](255) NULL,
	[rr_is_the_roof_its_own_asset] [nvarchar](255) NULL,
	[rr_photos] [nvarchar](max) NULL,
	[rr_install_year] [nvarchar](255) NULL,
	[rr_manufacturer] [nvarchar](255) NULL,
	[rr_model_number] [nvarchar](255) NULL,
	[rr_serial_number] [nvarchar](255) NULL,
	[rr_tag_number] [nvarchar](255) NULL,
	[rr_motor_manufacturer] [nvarchar](255) NULL,
	[rr_gpm] [nvarchar](255) NULL,
	[rr_head] [nvarchar](255) NULL,
	[rr_cfm] [nvarchar](255) NULL,
	[rr_filtration_rate] [nvarchar](255) NULL,
	[rr_tons] [nvarchar](255) NULL,
	[rr_diameter] [nvarchar](255) NULL,
	[rr_hp] [nvarchar](255) NULL,
	[rr_voltage] [nvarchar](255) NULL,
	[rr_fla] [nvarchar](255) NULL,
	[rr_phase] [nvarchar](255) NULL,
	[rr_rpm] [nvarchar](255) NULL,
	[rr_sqft] [nvarchar](255) NULL,
	[rr_gallons] [nvarchar](255) NULL,
	[rr_max_fill_height] [nvarchar](255) NULL,
	[rr_capacity_other] [nvarchar](255) NULL,
	[rr_motor_hertz] [nvarchar](255) NULL,
	[rr_construction_type] [nvarchar](255) NULL,
	[rr_field_code] [nvarchar](255) NULL,
	[rr_field_code_comment] [nvarchar](255) NULL,
	[rr_duplicate_cmms_id] [nvarchar](255) NULL,
	[rr_corrosionsurface] [nvarchar](255) NULL,
	[rr_corrosionstructural] [nvarchar](255) NULL,
	[corrosion_comments] [nvarchar](255) NULL,
	[rr_transformercoolantleakconnections] [nvarchar](255) NULL,
	[transformer_coolant_comments] [nvarchar](255) NULL,
	[rr_leakageconnections] [nvarchar](255) NULL,
	[rr_leakagefailures] [nvarchar](255) NULL,
	[rr_leakagecracksjoints] [nvarchar](255) NULL,
	[leakage_comments] [nvarchar](255) NULL,
	[rr_vibrationnoise] [nvarchar](255) NULL,
	[rr_vibrationnonstructural] [nvarchar](255) NULL,
	[rr_vibrationstructural] [nvarchar](255) NULL,
	[vibration_comments] [nvarchar](255) NULL,
	[rr_steelcorrosion] [nvarchar](255) NULL,
	[rr_steelcracking] [nvarchar](255) NULL,
	[rr_steelfatigueconnections] [nvarchar](255) NULL,
	[rr_steeldeformation] [nvarchar](255) NULL,
	[rr_steellosssection] [nvarchar](255) NULL,
	[steel_damage_comments] [nvarchar](255) NULL,
	[rr_electricaloverheating] [nvarchar](255) NULL,
	[rr_electricalwater] [nvarchar](255) NULL,
	[rr_electricalgrounding] [nvarchar](255) NULL,
	[rr_electricalinsulation] [nvarchar](255) NULL,
	[rr_electricalcoolingsystem] [nvarchar](255) NULL,
	[electrical_damage_comments] [nvarchar](255) NULL,
	[rr_motorssurfacecorrosion] [nvarchar](255) NULL,
	[rr_motorssurface] [nvarchar](255) NULL,
	[rr_motorsdevice] [nvarchar](255) NULL,
	[motors_core_comments] [nvarchar](255) NULL,
	[rr_roofleakscracks] [nvarchar](255) NULL,
	[rr_roofleakspenetrations] [nvarchar](255) NULL,
	[rr_roofsagging] [nvarchar](255) NULL,
	[rr_roofsupport] [nvarchar](255) NULL,
	[roof_core_comments] [nvarchar](255) NULL,
	[rr_masonryreinforcement] [nvarchar](255) NULL,
	[rr_masonrycracking] [nvarchar](255) NULL,
	[rr_masonrysurface] [nvarchar](255) NULL,
	[concrete_masonry_damage_comments] [nvarchar](255) NULL,
	[rr_jointdamage] [nvarchar](255) NULL,
	[joint_damage_comments] [nvarchar](255) NULL,
	[rr_settling] [nvarchar](255) NULL,
	[settling_comments] [nvarchar](255) NULL,
	[rr_wooddryrot] [nvarchar](255) NULL,
	[rr_woodwarping] [nvarchar](255) NULL,
	[rr_woodconnections] [nvarchar](255) NULL,
	[rr_woodsectionloss] [nvarchar](255) NULL,
	[wood_damage_comments] [nvarchar](255) NULL,
	[rr_general_score] [nvarchar](255) NULL,
	[general_comments] [nvarchar](255) NULL,
	[om_concretepedestalssurfacecracking] [nvarchar](255) NULL,
	[om_concretepedestalsthroughcracks] [nvarchar](255) NULL,
	[om_concretepedestalsmissingpieces] [nvarchar](255) NULL,
	[concrete_pedestals_comments] [nvarchar](255) NULL,
	[om_steelsupportssurfacecorrosion] [nvarchar](255) NULL,
	[om_steelsupportsstructuralcorrosion] [nvarchar](255) NULL,
	[om_steelsupportsmissinganchors] [nvarchar](255) NULL,
	[steel_supports_comments] [nvarchar](255) NULL,
	[om_supportbaseloosegrout] [nvarchar](255) NULL,
	[om_supportbasethroughcracks] [nvarchar](255) NULL,
	[om_supportbasemissingpieces] [nvarchar](255) NULL,
	[om_supportbasesurfacecorrosion] [nvarchar](255) NULL,
	[om_supportbasestructuralcorrosion] [nvarchar](255) NULL,
	[om_supportbasemissinganchors] [nvarchar](255) NULL,
	[support_base_comments] [nvarchar](255) NULL,
	[om_pipingvalvesleakageconnections] [nvarchar](255) NULL,
	[om_pipingvalvesleakagefailures] [nvarchar](255) NULL,
	[om_pipingvalvessurfacecorrosion] [nvarchar](255) NULL,
	[om_pipingvalvesstructuralcorrosion] [nvarchar](255) NULL,
	[om_pipingvalvesdamage] [nvarchar](255) NULL,
	[piping_valves_comments] [nvarchar](255) NULL,
	[om_localpanelssurfacecorrosion] [nvarchar](255) NULL,
	[om_localpanelsstructuralcorrosion] [nvarchar](255) NULL,
	[om_localpanelsleakage] [nvarchar](255) NULL,
	[om_localpanelsinstruments] [nvarchar](255) NULL,
	[local_panels_comments] [nvarchar](255) NULL,
	[om_fieldinstrumentsdamage] [nvarchar](255) NULL,
	[om_fieldinstrumentsleakage] [nvarchar](255) NULL,
	[field_instruments_comments] [nvarchar](255) NULL,
	[om_electricalconnectionscorrosion] [nvarchar](255) NULL,
	[om_electricalconnectionsdamage] [nvarchar](255) NULL,
	[om_electricalconnectionswiring] [nvarchar](255) NULL,
	[electrical_connections_comments] [nvarchar](255) NULL,
	[om_roofleakscracks] [nvarchar](255) NULL,
	[om_roofleakspenetrations] [nvarchar](255) NULL,
	[om_roofsagging] [nvarchar](255) NULL,
	[om_roofsupport] [nvarchar](255) NULL,
	[roof_comments] [nvarchar](255) NULL,
	[om_walkwayssurfacecorrosion] [nvarchar](255) NULL,
	[om_walkwaysstructural] [nvarchar](255) NULL,
	[om_walkwayssectionloss] [nvarchar](255) NULL,
	[om_walkwaysdeflection] [nvarchar](255) NULL,
	[walkways_comments] [nvarchar](255) NULL,
	[om_doorsleaks] [nvarchar](255) NULL,
	[om_doorssurfacecorrosion] [nvarchar](255) NULL,
	[om_doorsstructural] [nvarchar](255) NULL,
	[doors_comments] [nvarchar](255) NULL,
	[om_ductworkdamage] [nvarchar](255) NULL,
	[om_ductworksurfacecorrosion] [nvarchar](255) NULL,
	[om_ductworkstructuralcorrosion] [nvarchar](255) NULL,
	[om_ductworksupportdamage] [nvarchar](255) NULL,
	[ductwork_comments] [nvarchar](255) NULL,
	[om_filterstrapsdamage] [nvarchar](255) NULL,
	[om_filterstrapssurfacecorrosion] [nvarchar](255) NULL,
	[om_filterstrapsclogging] [nvarchar](255) NULL,
	[filters_traps_comments] [nvarchar](255) NULL,
	[om_motorssurfacecorrosion] [nvarchar](255) NULL,
	[om_motorssurface] [nvarchar](255) NULL,
	[om_motorsdevice] [nvarchar](255) NULL,
	[motors_comments] [nvarchar](255) NULL,
	[om_insulationholes] [nvarchar](255) NULL,
	[om_insulationdamage] [nvarchar](255) NULL,
	[insulation_comments] [nvarchar](255) NULL,
	[performance_comments] [nvarchar](255) NULL
 CONSTRAINT [PK_ref_Fulcrum] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_AssetCosts](
	[AssetCost_ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](64) NULL,
	[AssetType] [nvarchar](64) NULL,
	[MinDia] [smallint] NULL,
	[MaxDia] [smallint] NULL,
	[CostRepair] [float] NULL,
	[CostRehab] [float] NULL,
	[CostReplacement] [float] NULL,
 CONSTRAINT [PK_RR_AssetCosts] PRIMARY KEY CLUSTERED 
(
	[AssetCost_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_Assets]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_Assets](
	[RR_Asset_ID] [int] IDENTITY(1,1) NOT NULL,
	[RR_SourceTxt_ID] [nvarchar](64) NULL,
	[RR_SourceNum_ID] [float] NULL,
	[RR_Source] [nvarchar](64) NULL,
	[RR_Hierarchy_ID] [int] NULL,
	[RR_Config_ID] [smallint] NULL,
	[RR_Status] [bit] NULL,
	[RR_Division] [nvarchar](64) NULL,
	[RR_Facility] [nvarchar](64) NULL,
	[RR_Process] [nvarchar](64) NULL,
	[RR_Group] [nvarchar](64) NULL,
	[RR_Cohort_ID] [int] NULL,
	[RR_AssetType] [nvarchar](64) NULL,
	[RR_AssetName] [nvarchar](64) NULL,
	[RR_InstallYear] [smallint] NULL,
	[RR_Decommissioned] [smallint] NULL,
	[RR_Material] [nvarchar](64) NULL,
	[RR_Diameter] [float] NULL,
	[RR_Length] [float] NULL,
	[RR_PreviousFailures] [smallint] NULL,
	[RR_PreviousRehabYear] [smallint] NULL,
	[RR_ReplacementDiameter] [float] NULL,
	[RR_ProjectNumber] [nvarchar](64) NULL,
	[RR_CurveType] [nvarchar](1) NULL,
	[RR_CurveIntercept] [float] NULL,
	[RR_CurveSlope] [float] NULL,
	[RR_FailurePhysOffset] [float] NULL,
	[RR_AgeOffset] [float] NULL,
	[RR_EUL] [float] NULL,
	[RR_RUL] [smallint] NULL,
	[RR_LastInspection] [smalldatetime] NULL,
	[RR_LoFInspection] [smallint] NULL,
	[RR_LoFEUL] [float] NULL,
	[RR_LoFPhys] [smallint] NULL,
	[RR_LoFPerf] [smallint] NULL,
	[RR_LoF] [smallint] NULL,
	[RR_RedundancyFactor] [float] NULL,
	[RR_CoF] [smallint] NULL,
	[RR_CoF_R] [smallint] NULL,
	[RR_Risk] [smallint] NULL,
	[RR_CoFMaxCriteria] [nvarchar](500) NULL,
    [RR_LoFPhysMaxCriteria] [nvarchar](500) NULL,
    [RR_LoFPerfMaxCriteria] [nvarchar](500) NULL,
    [RR_OMMaxCriteria] [nvarchar](500) NULL,
	[RR_RepairsAllowed] [smallint] NULL,
	[RR_RehabsAllowed] [smallint] NULL,
	[RR_RehabYear] [smallint] NULL,
	[RR_ReplaceYear] [smallint] NULL,
	[RR_RehabYearCost] [int] NULL,
	[RR_RehabYearLoFRaw] [float] NULL,
	[RR_RehabYearLoFScore] [smallint] NULL,
	[RR_ReplaceYearCost] [int] NULL,
	[RR_ReplaceYearLoFRaw] [float] NULL,
	[RR_ReplaceYearLoFScore] [smallint] NULL,
	[RR_CostRehab] [int] NULL,
	[RR_CostReplace] [int] NULL,
	[RR_InheritCost] [smallint] NULL,
	[RR_AssetCostRehab] [int] NULL,
	[RR_AssetCostReplace] [int] NULL,
	[RR_CoF01] [smallint] NULL,
	[RR_CoF02] [smallint] NULL,
	[RR_CoF03] [smallint] NULL,
	[RR_CoF04] [smallint] NULL,
	[RR_CoF05] [smallint] NULL,
	[RR_CoF06] [smallint] NULL,
	[RR_CoF07] [smallint] NULL,
	[RR_CoF08] [smallint] NULL,
	[RR_CoF09] [smallint] NULL,
	[RR_CoF10] [smallint] NULL,
	[RR_CoF11] [smallint] NULL,
	[RR_CoF12] [smallint] NULL,
	[RR_CoF13] [smallint] NULL,
	[RR_CoF14] [smallint] NULL,
	[RR_CoF15] [smallint] NULL,
	[RR_CoF16] [smallint] NULL,
	[RR_CoF17] [smallint] NULL,
	[RR_CoF18] [smallint] NULL,
	[RR_CoF19] [smallint] NULL,
	[RR_CoF20] [smallint] NULL,
	[RR_CoFComment] [nvarchar](500) NULL,
	[RR_LoFPerf01] [smallint] NULL,
	[RR_LoFPerf02] [smallint] NULL,
	[RR_LoFPerf03] [smallint] NULL,
	[RR_LoFPerf04] [smallint] NULL,
	[RR_LoFPerf05] [smallint] NULL,
	[RR_LoFPerf06] [smallint] NULL,
	[RR_LoFPerf07] [smallint] NULL,
	[RR_LoFPerf08] [smallint] NULL,
	[RR_LoFPerf09] [smallint] NULL,
	[RR_LoFPerf10] [smallint] NULL,
	[RR_LoFPerfComment] [nvarchar](500) NULL,
	[RR_OM] [smallint] NULL,
	[RR_Fulcrum_ID] [nvarchar](38) NULL,
	[RR_InspectionType] [nvarchar](16) NULL,
	[RR_Width] [float] NULL,
	[RR_Height] [float] NULL,
	[RR_Manufacturer] [nvarchar](64) NULL,
	[RR_ModelNumber] [nvarchar](64) NULL,
	[RR_SerialNumber] [nvarchar](64) NULL,
	[RR_TagNumber] [nvarchar](64) NULL,
	[RR_MotorManufacturer] [nvarchar](64) NULL,
	[RR_GPM] [nvarchar](32) NULL,
	[RR_Head] [nvarchar](32) NULL,
	[RR_CFM] [nvarchar](32) NULL,
	[RR_FiltrationRate] [nvarchar](32) NULL,
	[RR_Tons] [nvarchar](32) NULL,
	[RR_CapacityDiameter] [nvarchar](32) NULL,
	[RR_HP] [nvarchar](32) NULL,
	[RR_Voltage] [nvarchar](50) NULL,
	[RR_FLA] [nvarchar](50) NULL,
	[RR_Phase] [nvarchar](50) NULL,
	[RR_RPM] [nvarchar](50) NULL,
	[RR_SQFT] [nvarchar](50) NULL,
	[RR_Gallons] [nvarchar](50) NULL,
	[RR_MaxFillHeight] [nvarchar](50) NULL,
	[RR_CapacityOther] [nvarchar](255) NULL,
	[RR_MotorHertz] [nvarchar](50) NULL,
	[RR_ConstructionType] [nvarchar](255) NULL,
	[RR_Purpose] [nvarchar](255) NULL,
	[RR_FieldCode] [nvarchar](64) NULL,
	[RR_Barcode] [nchar](32) NULL,
	[RR_CohortAnalysis] [bit] NULL,
	[RR_Notes] [nvarchar](255) NULL,
	[RR_Start_ID] [int] NULL,
	[RR_End_ID] [int] NULL,
	[RR_CreatedOn] [smalldatetime] NULL,
	[RR_CreatedBy] [nvarchar](64) NULL,
	[RR_EditedOn] [smalldatetime] NULL,
	[RR_EditedBy] [nvarchar](64) NULL,
	[shape] [geometry] NULL,
 CONSTRAINT [PK_RR_Asset_ID] PRIMARY KEY CLUSTERED 
(
	[RR_Asset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TRIGGER [dbo].[trg_RR_Assets_Updated]
ON RR_Assets
AFTER UPDATE
AS

	SET NOCOUNT ON

	UPDATE RR_Assets
    SET RR_EditedOn = GETDATE(),
	 RR_EditedBy = SYSTEM_USER
	 FROM RR_Assets
    WHERE RR_Asset_ID IN (SELECT DISTINCT RR_Asset_ID FROM Inserted)
GO
ALTER TABLE RR_Assets ENABLE TRIGGER [trg_RR_Assets_Updated]
GO

CREATE TRIGGER [dbo].[trg_RR_Assets_Inserted]
ON RR_Assets
AFTER INSERT
AS

	SET NOCOUNT ON

    UPDATE RR_Assets
    SET RR_CreatedOn = GETDATE(),
	 RR_CreatedBy = SYSTEM_USER
	 FROM RR_Assets
    WHERE RR_Asset_ID IN (SELECT DISTINCT RR_Asset_ID FROM Inserted)
GO
ALTER TABLE RR_Assets ENABLE TRIGGER [trg_RR_Assets_Inserted]
GO


/****** Object:  Table [RR_Cohorts]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_Cohorts](
	[Cohort_ID] [int] IDENTITY(1,1) NOT NULL,
	[CohortName] [nvarchar](64) NULL,
	[AssetType] [nvarchar](255) NULL,
	[Materials] [nvarchar](255) NULL,
	[MinDia] [int] NULL,
	[MaxDia] [int] NULL,
	[MinYear] [int] NULL,
	[MaxYear] [int] NULL,
	[ConditionAtEUL] [float] NULL,
	[InitEUL] [int] NULL,
	[InitEquationType] [nvarchar](1) NULL,
	[InitConstIntercept] [float] NULL,
	[InitExpSlope] [float] NULL,
	[ReplaceEquationType] [nvarchar](1) NULL,
	[ReplaceConstIntercept] [float] NULL,
	[ReplaceExpSlope] [float] NULL,
	[ReplaceEUL] [int] NULL,
	[RepairsAllowed] [smallint] NULL,
	[RehabsAllowed] [smallint] NULL,
	[Comment] [nvarchar](255) NULL,
 	[CreatedOn] [smalldatetime] NULL,
	[CreatedBy] [nvarchar](64) NULL,
	[EditedOn] [smalldatetime] NULL,
	[EditedBy] [nvarchar](64) NULL,
CONSTRAINT [PK_RR_Cohorts] PRIMARY KEY CLUSTERED 
(
	[Cohort_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ConditionAtEUL]  DEFAULT ((5)) FOR [ConditionAtEUL];
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitEUL]  DEFAULT ((25)) FOR [InitEUL]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitEquationType]  DEFAULT (N'L') FOR [InitEquationType]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitConstIntercept]  DEFAULT ((1)) FOR [InitConstIntercept]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_InitExpSlope]  DEFAULT ((0.16)) FOR [InitExpSlope]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceEquationType]  DEFAULT (N'L') FOR [ReplaceEquationType]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceConstIntercept]  DEFAULT ((1)) FOR [ReplaceConstIntercept]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceExpSlope]  DEFAULT ((0.16)) FOR [ReplaceExpSlope]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_ReplaceEUL]  DEFAULT ((25)) FOR [ReplaceEUL]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_RepairsAllowed]  DEFAULT ((0)) FOR [RepairsAllowed]
GO
ALTER TABLE [RR_Cohorts] ADD  CONSTRAINT [DF_RR_Cohorts_RehabsAllowed]  DEFAULT ((0)) FOR [RehabsAllowed]
GO

CREATE TRIGGER [dbo].[trg_RR_Cohorts_Updated]
ON RR_Cohorts
AFTER UPDATE
AS

	SET NOCOUNT ON

    UPDATE RR_Cohorts
    SET EditedOn = GETDATE(),
	 EditedBy = SYSTEM_USER
	 FROM RR_Assets
    WHERE Cohort_ID IN (SELECT DISTINCT RR_Asset_ID FROM Inserted)
GO
ALTER TABLE RR_Cohorts ENABLE TRIGGER [trg_RR_Cohorts_Updated]
GO

CREATE TRIGGER [dbo].[trg_RR_Cohorts_Inserted]
ON RR_Cohorts
AFTER INSERT
AS

	SET NOCOUNT ON

    UPDATE RR_Cohorts
    SET CreatedOn = GETDATE(),
	 CreatedBy = SYSTEM_USER
	 FROM RR_Cohorts
    WHERE Cohort_ID IN (SELECT DISTINCT Cohort_ID FROM Inserted)
GO
ALTER TABLE RR_Cohorts ENABLE TRIGGER [trg_RR_Cohorts_Inserted]
GO


/****** Object:  Table [RR_Conditions]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_Conditions](
	[Condition_Score] [int] NOT NULL,
	[PACP_Score] [float] NULL,
	[PACP_Condition] [nvarchar](32) NULL,
	[PACP_Description] [nvarchar](128) NULL,
	[MinRawCondition] [float] NULL,
	[MaxRawCondition] [float] NULL,
 CONSTRAINT [PK_RR_Conditions] PRIMARY KEY CLUSTERED 
(
	[Condition_Score] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_ConfigCategories](
	[Category_ID] [smallint] NOT NULL,
	[FunctionGroup] [nvarchar](54) NULL,
	[Category] [nvarchar](64) NULL,
	[MultipleRecords] [nvarchar](255) NULL,
 CONSTRAINT [PK_RR_ConfigCategories] PRIMARY KEY CLUSTERED 
(
	[Category_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_ConfigCoFLoF](
	[ConfigCoFLoF_ID] [int] IDENTITY(1,1) NOT NULL,
	[Active] [bit] NULL,
	[Attribute] [nvarchar](32) NULL,
	[AttributeValue] [nvarchar](1) NULL,
	[RefTable] [nvarchar](64) NULL,
	[RefFilter] [nvarchar](255) NULL,
	[RefGeoField] [nvarchar](32) NULL,
	[RefBuffer] [nvarchar](4) NULL,
	[NoteField] [nvarchar](32) NULL,
	[Description] [nvarchar](32) NULL,
	[OrderNum] [smallint] NULL,
	[Duration] [float] NULL,
	[Records] [int] NULL,
	[LastRun] [smalldatetime] NULL,
 CONSTRAINT [PK_RR_ConfigCoFLoF] PRIMARY KEY CLUSTERED 
(
	[ConfigCoFLoF_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [RR_ConfigQueries]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_ConfigQueries](
	[Query_ID] [int] IDENTITY(1,1) NOT NULL,
	[Category_ID] [smallint] NULL,
	[Category] [nvarchar](128) NULL,
	[RunOrder] [smallint] NULL,
	[QueryName] [nvarchar](128) NULL,
	[SortBy] [nvarchar](128) NULL,
	[ProcessingLabel] [nvarchar](64) NULL,
	[FailedLabel] [nvarchar](64) NULL,
	[Description] [nvarchar](max) NULL,
	[AllowQCEdits] [bit] NOT NULL,
 CONSTRAINT [PK_RR_ConfigQueries] PRIMARY KEY CLUSTERED 
(
	[Query_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [RR_ConfigTableLookup]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_ConfigTableLookup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [nvarchar](64) NULL,
	[ColumnName] [nvarchar](64) NULL,
	[ColumnAlias] [nvarchar](64) NULL,
	[DisplayOrder] [int] NULL,
	[ColumnWidth] [smallint] NULL,
	[Alignment] [smallint] NULL,
	[Format] [nvarchar](16) NULL,
	[AllowEdit] [bit] NULL,
	[FreezeColumn] [bit] NULL,
 CONSTRAINT [PK_RR_ConfigTableLookup] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [RR_CriticalCustomers]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_CriticalCustomers](
	[Customer_ID] [int] IDENTITY(1,1) NOT NULL,
	[SourceTxt_ID] [nvarchar](64) NULL,
	[Customer] [nvarchar](64) NULL,
	[CustomerType] [nvarchar](64) NULL,
	[Category] [nvarchar](64) NULL,
	[CoF] [smallint] NULL,
 CONSTRAINT [PK_RR_CriticalCustomers] PRIMARY KEY CLUSTERED 
(
	[Customer_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_CriticalityActionLimits]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_CriticalityActionLimits](
	[Criticality] [int] NOT NULL,
	[Description] [nvarchar](255) NULL,
	[LowRepair] [float] NULL,
	[HighRepair] [float] NULL,
	[LowRehab] [float] NULL,
	[HighRehab] [float] NULL,
	[LowReplace] [float] NULL,
	[HighReplace] [float] NULL,
	[PerformanceReplace] [float] NULL,
 CONSTRAINT [PK_RR_CriticalityActionLimits] PRIMARY KEY CLUSTERED 
(
	[Criticality] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_DegradationPoints]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_DegradationPoints](
	[Asset_ID] [int] NOT NULL,
	[ConditionYear] [smallint] NOT NULL,
	[Condition] [float] NULL,
	[InputFile_ID] [int] NULL,
 CONSTRAINT [PK_RR_DegredationPoints] PRIMARY KEY CLUSTERED 
(
	[Asset_ID] ASC,
	[ConditionYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_Failures]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_Failures](
	[Failure_ID] [int]  IDENTITY(1,1) NOT NULL,
	[Asset_ID] [int] NULL,
	[BreakDate] [datetime] NULL,
	[SourceTxt_ID] [nvarchar](64) NULL,
	[SourceWOTxt_ID] [nvarchar](64) NULL,
	[shape] [geometry] NULL
 CONSTRAINT [PK_RR_Failures] PRIMARY KEY CLUSTERED 
(
	[Failure_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_Hierarchy]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_Hierarchy](
	[RR_Hierarchy_ID] [int] IDENTITY(1,1) NOT NULL,
	[RR_Parent_ID] [int] NULL,
	[RR_HierarchyLevel] [smallint] NULL,
	[RR_HierarchyName] [nvarchar](255) NULL,
	[RR_RedundancyFactor] [float] NULL,
	[RR_CoF01] [smallint] NULL,
	[RR_CoF02] [smallint] NULL,
	[RR_CoF03] [smallint] NULL,
	[RR_CoF04] [smallint] NULL,
	[RR_CoF05] [smallint] NULL,
	[RR_CoF06] [smallint] NULL,
	[RR_CoF07] [smallint] NULL,
	[RR_CoF08] [smallint] NULL,
	[RR_CoF09] [smallint] NULL,
	[RR_CoF10] [smallint] NULL,
	[RR_CoF11] [smallint] NULL,
	[RR_CoF12] [smallint] NULL,
	[RR_CoF13] [smallint] NULL,
	[RR_CoF14] [smallint] NULL,
	[RR_CoF15] [smallint] NULL,
	[RR_CoF16] [smallint] NULL,
	[RR_CoF17] [smallint] NULL,
	[RR_CoF18] [smallint] NULL,
	[RR_CoF19] [smallint] NULL,
	[RR_CoF20] [smallint] NULL,
	[RR_CoFComment] [nvarchar](255) NULL,
	[RR_LoFPerf01] [smallint] NULL,
	[RR_LoFPerf02] [smallint] NULL,
	[RR_LoFPerf03] [smallint] NULL,
	[RR_LoFPerf04] [smallint] NULL,
	[RR_LoFPerf05] [smallint] NULL,
	[RR_LoFPerf06] [smallint] NULL,
	[RR_LoFPerf07] [smallint] NULL,
	[RR_LoFPerf08] [smallint] NULL,
	[RR_LoFPerf09] [smallint] NULL,
	[RR_LoFPerf10] [smallint] NULL,
	[RR_LoFPerfComment] [nvarchar](255) NULL,
	[RR_HierarchyNotes] [nvarchar](255) NULL,
 CONSTRAINT [PK_RR_Hierarchy] PRIMARY KEY CLUSTERED 
(
	[RR_Hierarchy_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_Hyperlinks]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_Hyperlinks](
	[RR_Hyperlink_ID] [int] IDENTITY(1,1) NOT NULL,
	[RR_Asset_ID] [int] NULL,
	[FileHyperlink] [nvarchar](MAX) NULL,
	[Fulcrum_ID] [nvarchar](255) NULL,
	[HierarchyLevel] [nvarchar](255) NULL,
	[AssetName] [nvarchar](255) NULL,
 CONSTRAINT [PK_RR_Hyperlinks] PRIMARY KEY CLUSTERED 
(
	[RR_Hyperlink_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_Inspections]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_Inspections](
	[RR_Inspection_ID] [int] IDENTITY(1,1) NOT NULL,
	[RR_Asset_ID] [int] NOT NULL,
	[RR_SourceTxt_ID] [nvarchar](64) NULL,
	[RR_SourceNum_ID] [float] NULL,
	[RR_InspectionDate] [date] NULL,
	[RR_InspectionType] [nvarchar](64) NULL,
	[RR_CompleteInspection] [bit] NULL,
	[RR_Fulcrum_ID] [nvarchar](38) NULL,
	[RR_LoFPhys01] [smallint] NULL,
	[RR_LoFPhys02] [smallint] NULL,
	[RR_LoFPhys03] [smallint] NULL,
	[RR_LoFPhys04] [smallint] NULL,
	[RR_LoFPhys05] [smallint] NULL,
	[RR_LoFPhys06] [smallint] NULL,
	[RR_LoFPhys07] [smallint] NULL,
	[RR_LoFPhys08] [smallint] NULL,
	[RR_LoFPhys09] [smallint] NULL,
	[RR_LoFPhys10] [smallint] NULL,
	[RR_LoFPhys11] [smallint] NULL,
	[RR_LoFPhys12] [smallint] NULL,
	[RR_LoFPhys13] [smallint] NULL,
	[RR_LoFPhys14] [smallint] NULL,
	[RR_LoFPhys15] [smallint] NULL,
	[RR_LoFPhys16] [smallint] NULL,
	[RR_LoFPhys17] [smallint] NULL,
	[RR_LoFPhys18] [smallint] NULL,
	[RR_LoFPhys19] [smallint] NULL,
	[RR_LoFPhys20] [smallint] NULL,
	[RR_LoFPhys21] [smallint] NULL,
	[RR_LoFPhys22] [smallint] NULL,
	[RR_LoFPhys23] [smallint] NULL,
	[RR_LoFPhys24] [smallint] NULL,
	[RR_LoFPhys25] [smallint] NULL,
	[RR_LoFPhys26] [smallint] NULL,
	[RR_LoFPhys27] [smallint] NULL,
	[RR_LoFPhys28] [smallint] NULL,
	[RR_LoFPhys29] [smallint] NULL,
	[RR_LoFPhys30] [smallint] NULL,
	[RR_LoFPhys31] [smallint] NULL,
	[RR_LoFPhys32] [smallint] NULL,
	[RR_LoFPhys33] [smallint] NULL,
	[RR_LoFPhys34] [smallint] NULL,
	[RR_LoFPhys35] [smallint] NULL,
	[RR_LoFPhys36] [smallint] NULL,
	[RR_LoFPhys37] [smallint] NULL,
	[RR_LoFPhys38] [smallint] NULL,
	[RR_LoFPhys39] [smallint] NULL,
	[RR_LoFPhys40] [smallint] NULL,
	[RR_LoFPhys41] [smallint] NULL,
	[RR_LoFPhys42] [smallint] NULL,
	[RR_LoFPhys43] [smallint] NULL,
	[RR_LoFPhys44] [smallint] NULL,
	[RR_LoFPhys45] [smallint] NULL,
	[RR_LoFPhys46] [smallint] NULL,
	[RR_LoFPhys47] [smallint] NULL,
	[RR_LoFPhys48] [smallint] NULL,
	[RR_LoFPhys49] [smallint] NULL,
	[RR_LoFPhys50] [smallint] NULL,
	[RR_OM01] [smallint] NULL,
	[RR_OM02] [smallint] NULL,
	[RR_OM03] [smallint] NULL,
	[RR_OM04] [smallint] NULL,
	[RR_OM05] [smallint] NULL,
	[RR_OM06] [smallint] NULL,
	[RR_OM07] [smallint] NULL,
	[RR_OM08] [smallint] NULL,
	[RR_OM09] [smallint] NULL,
	[RR_OM10] [smallint] NULL,
	[RR_OM11] [smallint] NULL,
	[RR_OM12] [smallint] NULL,
	[RR_OM13] [smallint] NULL,
	[RR_OM14] [smallint] NULL,
	[RR_OM15] [smallint] NULL,
	[RR_OM16] [smallint] NULL,
	[RR_OM17] [smallint] NULL,
	[RR_OM18] [smallint] NULL,
	[RR_OM19] [smallint] NULL,
	[RR_OM20] [smallint] NULL,
	[RR_OM21] [smallint] NULL,
	[RR_OM22] [smallint] NULL,
	[RR_OM23] [smallint] NULL,
	[RR_OM24] [smallint] NULL,
	[RR_OM25] [smallint] NULL,
	[RR_OM26] [smallint] NULL,
	[RR_OM27] [smallint] NULL,
	[RR_OM28] [smallint] NULL,
	[RR_OM29] [smallint] NULL,
	[RR_OM30] [smallint] NULL,
	[RR_OM31] [smallint] NULL,
	[RR_OM32] [smallint] NULL,
	[RR_OM33] [smallint] NULL,
	[RR_OM34] [smallint] NULL,
	[RR_OM35] [smallint] NULL,
	[RR_OM36] [smallint] NULL,
	[RR_OM37] [smallint] NULL,
	[RR_OM38] [smallint] NULL,
	[RR_OM39] [smallint] NULL,
	[RR_OM40] [smallint] NULL,
	[RR_OM41] [smallint] NULL,
	[RR_OM42] [smallint] NULL,
	[RR_OM43] [smallint] NULL,
	[RR_OM44] [smallint] NULL,
	[RR_OM45] [smallint] NULL,
	[RR_OM46] [smallint] NULL,
	[RR_OM47] [smallint] NULL,
	[RR_OM48] [smallint] NULL,
	[RR_OM49] [smallint] NULL,
	[RR_OM50] [smallint] NULL,
	[RR_InspectNotes] [nvarchar](255) NULL,
 CONSTRAINT [PK_RR_Inspections] PRIMARY KEY CLUSTERED 
(
	[RR_Inspection_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [RR_ProjectAssetGroups]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_ProjectAssetGroups](
	[RR_ProjectAssetGroup_ID] [int] IDENTITY(1,1) NOT NULL,
	[ProjectAssetGroup] [nvarchar](64) NULL,
	[Asset_ID] [int] NULL,
	[ProjectNumber] [nvarchar](64) NULL,
 CONSTRAINT [PK_RR_ProjectAssetGroups] PRIMARY KEY CLUSTERED 
(
	[RR_ProjectAssetGroup_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_Projects]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_Projects](
	[Project_ID] [int] IDENTITY(1,1) NOT NULL,
	[ProjectNumber] [nvarchar](64) NOT NULL,
	[ProjectName] [nvarchar](255) NULL,
	[ProjectDescription] [nvarchar](255) NULL,
	[ProjectGroup] [float] NULL,
	[ServiceType] [nvarchar](8) NULL,
	[StartYear] [smallint] NULL,
	[ProjectYear]  AS ([StartYear] + CASE WHEN [Year4Pcnt]>(0) THEN (3) WHEN [Year3Pcnt]>(0) THEN (2) WHEN [Year2Pcnt]>(0) THEN (1) ELSE (0) END) PERSISTED,
	[Year1Pcnt] [float] NOT NULL,
	[Year2Pcnt] [float] NOT NULL,
	[Year3Pcnt] [float] NOT NULL,
	[Year4Pcnt] [float] NOT NULL,
	[OverrideCost] [int] NULL,
	[ProjectCost] [int] NULL,
	[Assets] [int] NULL,
	[Length] [int] NULL,
	[PreviousFailures] [smallint] NULL,
	[Min_Age] [int] NULL,
	[Max_Age] [int] NULL,
	[Avg_Age] [float] NULL,
	[Min_Diameter] [int] NULL,
	[Max_Diameter] [int] NULL,
	[Avg_Diameter] [float] NULL,
	[Max_LoF_Perf] [smallint] NULL,
	[Avg_LoF_Perf] [float] NULL,
	[Max_LoF_Phys] [smallint] NULL,
	[Avg_LoF_Phys] [float] NULL,
	[Max_LoF_EUL] [smallint] NULL,
	[Avg_LoF_EUL] [float] NULL,
	[Max_LoF] [smallint] NULL,
	[Avg_LoF] [float] NULL,
	[Max_CoF] [smallint] NULL,
	[Avg_CoF] [float] NULL,
	[Avg_Redundancy] [float] NULL,
	[Avg_CoF_R] [float] NULL,
	[Max_CoF_R] [smallint] NULL,
	[Max_Risk] [smallint] NULL,
	[Avg_Risk] [float] NULL,
	[Active] [smallint] NULL,
	[RR_Year_Avg_Risk] [float] NULL,
	[RR_Year_Avg_LoF] [float] NULL,
	[RR_Year_Avg_LoF_PhysRaw] [float] NULL,
	[CreatedOn] [smalldatetime] NULL,
	[CreatedBy] [nvarchar](64) NULL,
	[EditedOn] [smalldatetime] NULL,
	[EditedBy] [nvarchar](64) NULL,
	[SHAPE] [geometry] NULL,
 CONSTRAINT [PK_RR_Projects] PRIMARY KEY CLUSTERED 
(
	[ProjectNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TRIGGER [dbo].[trg_RR_Projects_Updated]
ON RR_Projects
AFTER UPDATE
AS

	SET NOCOUNT ON

    UPDATE RR_Projects
    SET EditedOn = GETDATE(),
	 EditedBy = SYSTEM_USER
	 FROM RR_Projects
    WHERE Project_ID IN (SELECT DISTINCT Project_ID FROM Inserted)
GO
ALTER TABLE RR_Projects ENABLE TRIGGER [trg_RR_Projects_Updated]
GO

CREATE TRIGGER [dbo].[trg_RR_Projects_Inserted]
ON RR_Projects
AFTER INSERT
AS

	SET NOCOUNT ON

    UPDATE RR_Projects
    SET CreatedOn = GETDATE(),
	 CreatedBy = SYSTEM_USER
	 FROM RR_Projects
    WHERE Project_ID IN (SELECT DISTINCT Project_ID FROM Inserted)
GO
ALTER TABLE RR_Projects ENABLE TRIGGER [trg_RR_Projects_Inserted]
GO


/****** Object:  Table [RR_Revisions]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_Revisions](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Notes] [nvarchar](max) NULL,
	[CreatedOn] [smalldatetime] NULL,
	[CreatedBy] [nvarchar](64) NULL,
	[LastEditedOn] [smalldatetime] NULL,
	[LastEditedBy] [nvarchar](64) NULL,
 CONSTRAINT [PK__Revisions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [RR_RuntimeAssets]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_RuntimeAssets](
	[RR_Asset_ID] [int] NOT NULL,
	[Config_ID] [smallint] NULL,
	[RepairsRemaining] [smallint] NULL,
	[RehabsRemaining] [smallint] NULL,
	[CurrentInstallYear] [smallint] NULL,
	[CurrentEquationType] [nvarchar](1) NULL,
	[CurrentConstIntercept] [float] NULL,
	[CurrentExpSlope] [float] NULL,
	[CurrentFailurePhysOffset] [float] NULL,
	[CurrentAgeOffset] [float] NULL,
	[CurrentPerformance] [smallint] NULL,
 CONSTRAINT [PK_RR_RuntimeAssets] PRIMARY KEY CLUSTERED 
(
	[RR_Asset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_RuntimeConfig]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_RuntimeConfig](
	[ID] [int] NOT NULL,
	[CurrentScenario_ID] [int] NULL,
	[CurrentYear] [int] NULL,
	[CurrentAsset_ID] [int] NULL,
	[CurrentBudget] [int] NULL,
	[StartedOn] [smalldatetime] NULL,
	[StartedBy] [nvarchar](64) NULL,
 CONSTRAINT [PK_RR_RuntimeConfig] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_ScenarioResults]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_ScenarioResults](
	[Config_ID] [tinyint] NOT NULL,
	[Scenario_ID] [int] NOT NULL,
	[ScenarioYear] [int] NOT NULL,
	[RR_Asset_ID] [int] NOT NULL,
	[Age] [int] NULL,
	[PhysRaw] [float] NULL,
	[PerfScore] [float] NULL,
	[PhysScore] [smallint] NULL,
	[CostOfService] [int] NULL,
	[Service] [nvarchar](64) NULL,
 CONSTRAINT [PK_RR_ScenarioResults] PRIMARY KEY CLUSTERED 
(
	[Scenario_ID] ASC,
	[ScenarioYear] ASC,
	[RR_Asset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [RR_ScenarioResults] ADD  CONSTRAINT [DF_RR_ScenarioResults_Config_ID]  DEFAULT ((1)) FOR [Config_ID]
GO


-- 2023-04-22 Consolidation of RR_ScenarioTargetBudgets and RR_ScenarioResultsSummary into RR_ScenarioYears

--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--CREATE TABLE [RR_ScenarioResultsSummary](
--	[Scenario_ID] [int] NOT NULL,
--	[ScenarioYear] [int] NOT NULL,
--	[TargetRiskAllocation] [real] NULL,
--	[TargetBudget] [int] NULL,
--	[Budget] [float] NULL,
--	[OverallCount] [float] NULL,
--	[OverallWeighting] [float] NULL,
--	[OverallAgeWeighted] [float] NULL,
--	[OverallAgeAvg] [float] NULL,
--	[OverallPhysRawWeighted] [float] NULL,
--	[OverallPhysRawAvg] [float] NULL,
--	[OverallPhysScoreWeighted] [float] NULL,
--	[OverallPhysScoreAvg] [float] NULL,
--	[OverallPerfScoreWeighted] [float] NULL,
--	[OverallPerfScoreAvg] [float] NULL,
--	[OverallLoFRawWeighted] [float] NULL,
--	[OverallLoFRawAvg] [float] NULL,
--	[OverallLoFScoreWeighted] [float] NULL,
--	[OverallLoFScoreScore] [float] NULL,
--	[OverallRiskRawWeighted] [float] NULL,
--	[OverallRiskRawAvg] [float] NULL,
--	[OverallRiskScoreWeighted] [float] NULL,
--	[OverallRiskScoreAvg] [float] NULL,
--	[ServicedCount] [float] NULL,
--	[ServicedWeighting] [float] NULL,
--	[ServicedAgeWeighted] [float] NULL,
--	[ServicedAgeAvg] [float] NULL,
--	[ServicedPhysRawWeighted] [float] NULL,
--	[ServicedPhysRawAvg] [float] NULL,
--	[ServicedPhysScoreWeighted] [float] NULL,
--	[ServicedPhysScoreAvg] [float] NULL,
--	[ServicedPerfScoreWeighted] [float] NULL,
--	[ServicedPerfScoreAvg] [float] NULL,
--	[ServicedLoFRawWeighted] [float] NULL,
--	[ServicedLoFRawAvg] [float] NULL,
--	[ServicedLoFScoreWeighted] [float] NULL,
--	[ServicedLoFScoreAvg] [float] NULL,
--	[ServicedCoFWeighted] [float] NULL,
--	[ServicedCoFAvg] [float] NULL,
--	[ServicedRiskRawWeighted] [float] NULL,
--	[ServicedRiskRawAvg] [float] NULL,
--	[ServicedRiskScoreWeighted] [float] NULL,
--	[ServicedRiskScoreAvg] [float] NULL,
-- CONSTRAINT [PK_RR_ScenarioResultsSummary] PRIMARY KEY CLUSTERED 
--(
--	[Scenario_ID] ASC,
--	[ScenarioYear] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY]
--GO

/****** Object:  Table [RR_Scenarios]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_Scenarios](
	[Scenario_ID] [int] IDENTITY(1,1) NOT NULL,
	[ScenarioName] [nvarchar](64) NULL,
	[Description] [nvarchar](64) NULL,
	[PBI_Flag] [bit] NULL,
	[StartYear] [int] NULL,
	[LastRun] [datetime2](0) NULL,
	[TotalCost] [bigint] NULL,
	[ReplacedCost] [int] NULL,
	[RehabbedCost] [int] NULL,
	[TotalWeight] [bigint] NULL,
	[ReplacedWeight] [bigint] NULL,
	[RehabbedWeight] [bigint] NULL, 
 	[CreatedOn] [smalldatetime] NULL,
	[CreatedBy] [nvarchar](64) NULL,
	[EditedOn] [smalldatetime] NULL,
	[EditedBy] [nvarchar](64) NULL,
CONSTRAINT [PK_RR_Scenarios] PRIMARY KEY CLUSTERED 
(
	[Scenario_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TRIGGER [dbo].[trg_RR_Scenarios_Updated]
ON RR_Scenarios
AFTER UPDATE
AS

	SET NOCOUNT ON

    UPDATE RR_Scenarios
    SET EditedOn = GETDATE(),
	 EditedBy = SYSTEM_USER
	 FROM RR_Scenarios
    WHERE Scenario_ID IN (SELECT DISTINCT Scenario_ID FROM Inserted)
GO
ALTER TABLE RR_Scenarios ENABLE TRIGGER [trg_RR_Scenarios_Updated]
GO

CREATE TRIGGER [dbo].[trg_RR_Scenarios_Inserted]
ON RR_Scenarios
AFTER INSERT
AS
 
	SET NOCOUNT ON

   UPDATE RR_Scenarios
    SET CreatedOn = GETDATE(),
	 CreatedBy = SYSTEM_USER
	 FROM RR_Scenarios
    WHERE Scenario_ID IN (SELECT DISTINCT Scenario_ID FROM Inserted)
GO
ALTER TABLE RR_Scenarios ENABLE TRIGGER [trg_RR_Scenarios_Inserted]
GO



--v5.009 LoF5 and Risk 16 Remaining
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
	[LoF5Remaining] [float] NULL,
	[Risk16Remaining] [float] NULL,
 CONSTRAINT [PK_RR_ScenarioYears] PRIMARY KEY CLUSTERED 
(
	[BudgetYear_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
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


/****** Object:  Table [RR_ScenarioTargetBudgets]    Script Date: 1/3/2022 2:40:15 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--CREATE TABLE [RR_ScenarioTargetBudgets](
--	[BudgetYear_ID] [int] IDENTITY(1,1) NOT NULL,
--	[Scenario_ID] [int] NULL,
--	[BudgetYear] [int] NULL,
--	[Budget] [int] NULL,
--	[AllocationToRisk] [real] NULL,
--	[ConditionTarget] [real] NULL,
--	[RiskTarget] [real] NULL,
--	[UseProjectBudget] [bit] NOT NULL,
-- CONSTRAINT [PK_RR_ScenarioTargetBudgets] PRIMARY KEY CLUSTERED 
--(
--	[BudgetYear_ID] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY]
--GO

--v5.007
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[RR_ScenarioTargetBudgets]
AS
SELECT        BudgetYear_ID, Scenario_ID, BudgetYear, Budget, AllocationToRisk, ConditionTarget, RiskTarget, UseProjectBudget
FROM            dbo.RR_ScenarioYears
GO



/****** Object:  Table [RR_StatModel_ImportFiles]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [RR_StatModel_ImportFiles](
	[ImportFile_ID] [int] IDENTITY(1,1) NOT NULL,
	[FileName] [nvarchar](255) NULL,
	[ImportDate] [nvarchar](255) NULL,
	[StartYear] [int] NULL,
	[EndYear] [int] NULL,
	[RecordCount] [int] NULL,
 CONSTRAINT [PK_RR_StatModel_ImportFiles] PRIMARY KEY CLUSTERED 
(
	[ImportFile_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [RR_StatModel_Results]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [RR_StatModel_Results](
	[Asset_IDtxt] [nvarchar](64) NOT NULL,
	[ConditionYear] [smallint] NOT NULL,
	[Condition] [float] NULL,
	[InputFile_ID] [int] NULL,
	[Asset_ID] [int] NULL,
 CONSTRAINT [PK_RR_StatModel_Results] PRIMARY KEY CLUSTERED 
(
	[Asset_IDtxt] ASC,
	[ConditionYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [rr_TraceX]    Script Date: 1/3/2022 2:40:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [rr_TraceX](
	[Trace_ID] [int] IDENTITY(1,1) NOT NULL,
	[Trace_DT] [smalldatetime] NULL,
	[Category_ID] [int] NULL,
	[Trace_Step] [nvarchar](64) NULL,
	[Trace_Details] [nvarchar](max) NULL,
 CONSTRAINT [PK_rr_Trace] PRIMARY KEY CLUSTERED 
(
	[Trace_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [rr_Nodes](
	[Node_ID] [int] IDENTITY(1,1) NOT NULL,
	[X] [float] NULL,
	[Y] [float] NULL,
	[Connections] [smallint] NULL,
 CONSTRAINT [PK_rr_Nodes] PRIMARY KEY CLUSTERED 
(
	[Node_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [rr_merged](
	[Child_ID] [int] NOT NULL,
	[Parent_ID] [int] NULL,
	[Length] [float] NULL,
 CONSTRAINT [PK_rr_merged2] PRIMARY KEY CLUSTERED 
(
	[Child_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [rr_merged_geo](
	[Parent_ID] [int] NOT NULL,
	[Name] [nvarchar](16) NULL,
	[Length] [float] NULL,
	[CreateDate] [datetime] NULL,
	[shape] [geometry] NULL,
 CONSTRAINT [PK_rr_merger_geo2] PRIMARY KEY CLUSTERED 
(
	[Parent_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [rr_merged_geo] ADD  CONSTRAINT [DF_rr_merged_geo_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO


CREATE NONCLUSTERED INDEX [IDX_RR_Assets_SourcdTxtID] ON [RR_Assets]
(
	[RR_SourceTxt_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IDX_RR_Assets_StatusCohortIDAssetID] ON [RR_Assets]
(
	[RR_Status] ASC,
	[RR_Cohort_ID] ASC,
	[RR_Asset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IDX_RR_Assets_StatusConfigCohortAssetID] ON [RR_Assets]
(
	[RR_Status] ASC,
	[RR_Config_ID] ASC,
	[RR_Cohort_ID] ASC,
	[RR_Asset_ID] ASC
)
INCLUDE([RR_AssetType],[RR_InstallYear],[RR_Diameter],[RR_ProjectNumber],[RR_PreviousFailures],[RR_PreviousRehabYear],[RR_EUL],[RR_RUL],[RR_LastInspection],[RR_LoFInspection],[RR_Material],[RR_Length],[RR_LoFPerf],[RR_LoF],[RR_RedundancyFactor],[RR_CoF],[RR_FailurePhysOffset],[RR_AgeOffset],[RR_CoF_R],[RR_Risk],[RR_CostReplace],[Shape],[RR_LoFEUL],[RR_LoFPhys]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IDX_RR_ConfigQueries_Category_ID] ON [RR_ConfigQueries]
(
	[Category_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IDX_RR_CriticalCustomers_SourceTxt_ID] ON [RR_CriticalCustomers]
(
	[SourceTxt_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IDX_rr_Nodes_XY] ON [rr_Nodes]
(
	[X] ASC,
	[Y] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = ON, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

CREATE UNIQUE NONCLUSTERED INDEX [IDX_RR_Scenarios_ScenarioName] ON [RR_Scenarios]
(
	[ScenarioName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

-- 2023-04-22
--CREATE UNIQUE NONCLUSTERED INDEX [IDX_RR_ScenarioTargetBudgets_Scenario_ID] ON [RR_ScenarioTargetBudgets]
--(
--	[Scenario_ID] ASC,
--	[BudgetYear] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--GO

CREATE NONCLUSTERED INDEX [IDX_RR_StatModel_ImportFiles_LEYP_InputFile_ID] ON [RR_StatModel_ImportFiles]
(
	[ImportFile_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IDX_RR_StatModel_Results_Asset_ID] ON [RR_StatModel_Results]
(
	[Asset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [RR_AssetCosts] ADD  CONSTRAINT [DF_RR_AssetCosts_CostRepair]  DEFAULT ((0)) FOR [CostRepair]
GO

ALTER TABLE [RR_AssetCosts] ADD  CONSTRAINT [DF_RR_AssetCosts_CostRehab]  DEFAULT ((0)) FOR [CostRehab]
GO

ALTER TABLE [RR_AssetCosts] ADD  CONSTRAINT [DF_RR_AssetCosts_CostReplacement]  DEFAULT ((0)) FOR [CostReplacement]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_Hierarchy_ID]  DEFAULT ((1)) FOR [RR_Hierarchy_ID]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_Config_ID]  DEFAULT ((1)) FOR [RR_Config_ID]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_Status]  DEFAULT ((1)) FOR [RR_Status]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_AssetType]  DEFAULT ('') FOR [RR_AssetType]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_Diameter]  DEFAULT ((0)) FOR [RR_Diameter]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_ReplacementDiameter]  DEFAULT ((0)) FOR [RR_ReplacementDiameter]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_RedundancyFactor]  DEFAULT ((1)) FOR [RR_RedundancyFactor]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_PreviousFailures]  DEFAULT ((0)) FOR [RR_PreviousFailures]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_FailurePhysOffset]  DEFAULT ((0)) FOR [RR_FailurePhysOffset]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_AgeOffset]  DEFAULT ((0)) FOR [RR_AgeOffset]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_RepairsAllowed]  DEFAULT ((0)) FOR [RR_RepairsAllowed]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_RehabsAllowed]  DEFAULT ((0)) FOR [RR_RehabsAllowed]
GO

ALTER TABLE [RR_Assets] ADD  CONSTRAINT [DF_RR_Assets_RR_InheritCost]  DEFAULT ((1)) FOR [RR_InheritCost]
GO

ALTER TABLE [RR_Conditions] ADD  DEFAULT ((0)) FOR [MinRawCondition]
GO

ALTER TABLE [RR_Conditions] ADD  DEFAULT ((0)) FOR [MaxRawCondition]
GO

ALTER TABLE [RR_ConfigCoFLoF] ADD  CONSTRAINT [DF_RR_ConfigCoFLoF_Active]  DEFAULT ((1)) FOR [Active]
GO

ALTER TABLE [RR_ConfigCoFLoF] ADD  CONSTRAINT [DF_RR_ConfigCoFLoF_Buffer]  DEFAULT ((0)) FOR [RefBuffer]
GO

ALTER TABLE [RR_ConfigCoFLoF] ADD  CONSTRAINT [DF_RR_ConfigCoFLoF_NoteField]  DEFAULT (N'RR_CoFComment') FOR [NoteField]
GO

ALTER TABLE [RR_ConfigQueries] ADD  CONSTRAINT [DF_RR_ConfigQueries_AllowQCEdits]  DEFAULT ((0)) FOR [AllowQCEdits]
GO

ALTER TABLE [RR_ConfigTableLookup] ADD  DEFAULT ((75)) FOR [ColumnWidth]
GO

ALTER TABLE [RR_ConfigTableLookup] ADD  DEFAULT ((64)) FOR [Alignment]
GO

ALTER TABLE [RR_ConfigTableLookup] ADD  DEFAULT ((1)) FOR [AllowEdit]
GO

ALTER TABLE [RR_ConfigTableLookup] ADD  DEFAULT ((0)) FOR [FreezeColumn]
GO

ALTER TABLE [RR_CriticalityActionLimits] ADD  DEFAULT ((1000)) FOR [HighReplace]
GO

ALTER TABLE [RR_CriticalityActionLimits] ADD  DEFAULT ((5)) FOR [PerformanceReplace]
GO

ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_HierarchyLevel]  DEFAULT ((0)) FOR [RR_HierarchyLevel]
GO

ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_RedundancyFactor]  DEFAULT ((1)) FOR [RR_RedundancyFactor]
GO

ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF01]  DEFAULT ((0)) FOR [RR_CoF01]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF02]  DEFAULT ((0)) FOR [RR_CoF02]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF03]  DEFAULT ((0)) FOR [RR_CoF03]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF04]  DEFAULT ((0)) FOR [RR_CoF04]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF05]  DEFAULT ((0)) FOR [RR_CoF05]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF06]  DEFAULT ((0)) FOR [RR_CoF06]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF07]  DEFAULT ((0)) FOR [RR_CoF07]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF08]  DEFAULT ((0)) FOR [RR_CoF08]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF09]  DEFAULT ((0)) FOR [RR_CoF09]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF10]  DEFAULT ((0)) FOR [RR_CoF10]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF11]  DEFAULT ((0)) FOR [RR_CoF11]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF12]  DEFAULT ((0)) FOR [RR_CoF12]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF13]  DEFAULT ((0)) FOR [RR_CoF13]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF14]  DEFAULT ((0)) FOR [RR_CoF14]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF15]  DEFAULT ((0)) FOR [RR_CoF15]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF16]  DEFAULT ((0)) FOR [RR_CoF16]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF17]  DEFAULT ((0)) FOR [RR_CoF17]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF18]  DEFAULT ((0)) FOR [RR_CoF18]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF19]  DEFAULT ((0)) FOR [RR_CoF19]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_CoF20]  DEFAULT ((0)) FOR [RR_CoF20]
GO

ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf01]  DEFAULT ((0)) FOR [RR_LoFPerf01]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf02]  DEFAULT ((0)) FOR [RR_LoFPerf02]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf03]  DEFAULT ((0)) FOR [RR_LoFPerf03]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf04]  DEFAULT ((0)) FOR [RR_LoFPerf04]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf05]  DEFAULT ((0)) FOR [RR_LoFPerf05]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf06]  DEFAULT ((0)) FOR [RR_LoFPerf06]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf07]  DEFAULT ((0)) FOR [RR_LoFPerf07]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf08]  DEFAULT ((0)) FOR [RR_LoFPerf08]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf09]  DEFAULT ((0)) FOR [RR_LoFPerf09]
GO
ALTER TABLE [RR_Hierarchy] ADD  CONSTRAINT [DF_RR_Hierarchy_RR_LoFPerf10]  DEFAULT ((0)) FOR [RR_LoFPerf10]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_RR_Projects_Project_ID] ON [RR_Projects]
(
	[Project_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [RR_Projects] ADD  CONSTRAINT [DF_RR_Projects_ServiceType]  DEFAULT ('Replace') FOR [ServiceType]
GO
ALTER TABLE [RR_Projects] ADD  CONSTRAINT [DF_RR_Projects_Active]  DEFAULT ((0)) FOR [Active]
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


ALTER TABLE [RR_Revisions] ADD  CONSTRAINT [DF_Revisions_CreatedOn]  DEFAULT (getdate()) FOR [CreatedOn]
GO

ALTER TABLE [RR_Revisions] ADD  CONSTRAINT [DF_Revisions_CreatedBy]  DEFAULT (suser_sname()) FOR [CreatedBy]
GO

ALTER TABLE [RR_RuntimeAssets] ADD  CONSTRAINT [DF_RR_RuntimeAssets_Config_ID]  DEFAULT ((1)) FOR [Config_ID]
GO

ALTER TABLE [RR_RuntimeAssets] ADD  CONSTRAINT [DF_RR_RuntimeAssets_RepairsRemaining]  DEFAULT ((0)) FOR [RepairsRemaining]
GO

ALTER TABLE [RR_RuntimeAssets] ADD  CONSTRAINT [DF_RR_RuntimeAssets_RehabsRemaining]  DEFAULT ((1)) FOR [RehabsRemaining]
GO

ALTER TABLE [RR_RuntimeAssets] ADD  CONSTRAINT [DF_RR_RuntimeAssets_CurrentFailurePhysOffset]  DEFAULT ((0)) FOR [CurrentFailurePhysOffset]
GO

ALTER TABLE [RR_RuntimeAssets] ADD  CONSTRAINT [DF_RR_RuntimeAssets_CurrentAgeOffset]  DEFAULT ((0)) FOR [CurrentAgeOffset]
GO

ALTER TABLE [RR_RuntimeAssets] ADD  CONSTRAINT [DF_RR_RuntimeAssets_CurrentPerformance]  DEFAULT ((0)) FOR [CurrentPerformance]
GO

ALTER TABLE [RR_RuntimeConfig] ADD  CONSTRAINT [DF_RR_RuntimeConfig_ID]  DEFAULT ((1)) FOR [ID]
GO

ALTER TABLE [RR_RuntimeConfig] ADD  CONSTRAINT [DF_RR_RuntimeConfig_CurrentRunBudget]  DEFAULT ((0)) FOR [CurrentBudget]
GO

ALTER TABLE [RR_Scenarios] ADD  CONSTRAINT [DF_RR_Scenarios_PBI_Flag]  DEFAULT ((1)) FOR [PBI_Flag]
GO

-- 2023-04-22
--ALTER TABLE [RR_ScenarioTargetBudgets] ADD  CONSTRAINT [DF_RR_ScenarioTargetBudgets_Budget]  DEFAULT ((0)) FOR [Budget]
--GO

--ALTER TABLE [RR_ScenarioTargetBudgets] ADD  CONSTRAINT [DF_RR_ScenarioTargetBudgets_AllocationToRisk]  DEFAULT ((1)) FOR [AllocationToRisk]
--GO

--ALTER TABLE [RR_ScenarioTargetBudgets] ADD  CONSTRAINT [DF_RR_ScenarioTargetBudgets_ConditionTarget]  DEFAULT ((0)) FOR [ConditionTarget]
--GO

--ALTER TABLE [RR_ScenarioTargetBudgets] ADD  CONSTRAINT [DF_RR_ScenarioTargetBudgets_RiskTarget]  DEFAULT ((0)) FOR [RiskTarget]
--GO

--ALTER TABLE [RR_ScenarioTargetBudgets] ADD  CONSTRAINT [DF_RR_ScenarioTargetBudgets_UseProjectBudget]  DEFAULT ((0)) FOR [UseProjectBudget]
--GO

ALTER TABLE [rr_TraceX] ADD  CONSTRAINT [DF_rr_Trace_Trace_DT]  DEFAULT (getdate()) FOR [Trace_DT]
GO

ALTER TABLE [RR_ConfigQueries]  ADD  CONSTRAINT [FK_RR_ConfigQueries_RR_ConfigCategories] FOREIGN KEY([Category_ID])
REFERENCES [dbo].[RR_ConfigCategories] ([Category_ID])
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [FK_RR_Hierarchy_RR_Hierarchy] FOREIGN KEY([RR_Parent_ID])
REFERENCES [dbo].[RR_Hierarchy] ([RR_Hierarchy_ID])
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF01_validation_rule] CHECK (([RR_CoF01]>=(-5) AND [RR_CoF01]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF02_validation_rule] CHECK (([RR_CoF02]>=(-5) AND [RR_CoF02]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF03_validation_rule] CHECK (([RR_CoF03]>=(-5) AND [RR_CoF07]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF04_validation_rule] CHECK (([RR_CoF04]>=(-5) AND [RR_CoF03]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF05_validation_rule] CHECK (([RR_CoF05]>=(-5) AND [RR_CoF04]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF06_validation_rule] CHECK (([RR_CoF06]>=(-5) AND [RR_CoF05]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_CoF07_validation_rule] CHECK (([RR_CoF07]>=(-5) AND [RR_CoF06]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_LoFPerf01_validation_rule] CHECK (([RR_LoFPerf01]>=(-5) AND [RR_CoF07]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_LoFPerf02_validation_rule] CHECK (([RR_LoFPerf02]>=(-5) AND [RR_CoF07]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_LoFPerf03_validation_rule] CHECK (([RR_LoFPerf03]>=(-5) AND [RR_CoF07]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_LoFPerf04_validation_rule] CHECK (([RR_LoFPerf04]>=(-5) AND [RR_CoF07]<=(5)))
GO

ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_LoFPerf05_validation_rule] CHECK (([RR_LoFPerf05]>=(-5) AND [RR_CoF07]<=(5)))
GO


ALTER TABLE [RR_Hierarchy]  ADD  CONSTRAINT [RR_Hierarchy_RR_RedundancyFactor_validation_rule] CHECK  (([RR_RedundancyFactor]>=(0) AND [RR_RedundancyFactor]<=(1)))
GO

ALTER TABLE [RR_RuntimeConfig]  ADD  CONSTRAINT [RR_RuntimeConfig_ID_validation_rule] CHECK  (([ID]=(1)))
GO

ALTER TABLE [RR_Scenarios]  ADD  CONSTRAINT [RR_Scenarios_Description_disallow_zero_length] CHECK  ((len([Description])>(0)))
GO

ALTER TABLE [RR_Scenarios]  ADD  CONSTRAINT [RR_Scenarios_ScenarioName_disallow_zero_length] CHECK  ((len([ScenarioName])>(0)))
GO

ALTER TABLE [RR_StatModel_ImportFiles]  ADD  CONSTRAINT [RR_StatModel_ImportFiles_FileName_disallow_zero_length] CHECK  ((len([FileName])>(0)))
GO

ALTER TABLE [RR_StatModel_ImportFiles]  ADD  CONSTRAINT [RR_StatModel_ImportFiles_ImportDate_disallow_zero_length] CHECK  ((len([ImportDate])>(0)))
GO



ALTER TABLE [RR_Assets]  WITH CHECK ADD  CONSTRAINT [FK_RR_Assets_Cohorts] FOREIGN KEY([RR_Cohort_ID])
REFERENCES [dbo].[RR_Cohorts] ([Cohort_ID])
GO

ALTER TABLE [RR_Assets] CHECK CONSTRAINT [FK_RR_Assets_Cohorts]
GO

ALTER TABLE [RR_Assets]  WITH CHECK ADD  CONSTRAINT [FK_RR_Assets_Projects] FOREIGN KEY([RR_ProjectNumber])
REFERENCES [dbo].[RR_Projects] ([ProjectNumber])
GO

ALTER TABLE [RR_Assets] CHECK CONSTRAINT [FK_RR_Assets_Projects]
GO

ALTER TABLE [RR_Failures]  WITH CHECK ADD  CONSTRAINT [FK_RR_Failures_Assets] FOREIGN KEY([Asset_ID])
REFERENCES [dbo].[RR_Assets] ([RR_Asset_ID])
GO

ALTER TABLE [RR_Failures] CHECK CONSTRAINT [FK_RR_Failures_Assets]
GO

ALTER TABLE [RR_Inspections]  WITH CHECK ADD  CONSTRAINT [FK_RR_Inspections_Assets] FOREIGN KEY([RR_Asset_ID])
REFERENCES [dbo].[RR_Assets] ([RR_Asset_ID])
GO

ALTER TABLE [RR_Inspections] ADD  CONSTRAINT [DF_RR_Inspections_RR_CompleteInspection]  DEFAULT ((1)) FOR [RR_CompleteInspection]
GO

ALTER TABLE [RR_Inspections] CHECK CONSTRAINT [FK_RR_Inspections_Assets]
GO

ALTER TABLE [RR_Inspections] ADD  CONSTRAINT [DF_RR_Inspections_RR_LoFPhys01]  DEFAULT ((0)) FOR [RR_LoFPhys01]
GO

ALTER TABLE [RR_Inspections] ADD  CONSTRAINT [DF_RR_Inspections_RR_LoFPhys02]  DEFAULT ((0)) FOR [RR_LoFPhys02]
GO

ALTER TABLE [RR_Inspections]  WITH CHECK ADD  CONSTRAINT [CK_RR_InspectionsPhys01] CHECK  (([RR_LoFPhys01]>=(-5) AND [RR_LoFPhys01]<=(5)))
GO

ALTER TABLE [RR_Inspections] CHECK CONSTRAINT [CK_RR_InspectionsPhys01]
GO


ALTER TABLE [RR_RuntimeAssets]  WITH CHECK ADD  CONSTRAINT [FK_RR_RuntimeAssets_Assets] FOREIGN KEY([RR_Asset_ID])
REFERENCES [dbo].[RR_Assets] ([RR_Asset_ID])
GO

ALTER TABLE [RR_RuntimeAssets] CHECK CONSTRAINT [FK_RR_RuntimeAssets_Assets]
GO

ALTER TABLE [RR_ScenarioResults]  WITH CHECK ADD  CONSTRAINT [FK_RR_ScenarioResults_Assets] FOREIGN KEY([RR_Asset_ID])
REFERENCES [dbo].[RR_Assets] ([RR_Asset_ID])
GO

ALTER TABLE [RR_ScenarioResults] CHECK CONSTRAINT [FK_RR_ScenarioResults_Assets]
GO

ALTER TABLE [RR_ScenarioResults]  WITH CHECK ADD  CONSTRAINT [FK_RR_ScenarioResults_Scenarios] FOREIGN KEY([Scenario_ID])
REFERENCES [dbo].[RR_Scenarios] ([Scenario_ID])
GO

ALTER TABLE [RR_ScenarioResults] CHECK CONSTRAINT [FK_RR_ScenarioResults_Scenarios]
GO

-- 2023-04-22
--ALTER TABLE [RR_ScenarioResultsSummary]  WITH CHECK ADD  CONSTRAINT [FK_RR_ScenarioResultsSummary_Scenarios] FOREIGN KEY([Scenario_ID])
--REFERENCES [dbo].[RR_Scenarios] ([Scenario_ID])
--GO

--ALTER TABLE [RR_ScenarioResultsSummary] CHECK CONSTRAINT [FK_RR_ScenarioResultsSummary_Scenarios]
--GO

--ALTER TABLE [RR_ScenarioTargetBudgets]  WITH CHECK ADD  CONSTRAINT [FK_RR_ScenarioTargetBudgets_Scenarios] FOREIGN KEY([Scenario_ID])
--REFERENCES [dbo].[RR_Scenarios] ([Scenario_ID])
--GO

--ALTER TABLE [RR_ScenarioTargetBudgets] CHECK CONSTRAINT [FK_RR_ScenarioTargetBudgets_Scenarios]
--GO

ALTER TABLE [RR_StatModel_Results]  WITH CHECK ADD  CONSTRAINT [FK_RR_StatModel_Results_Assets] FOREIGN KEY([Asset_ID])
REFERENCES [dbo].[RR_Assets] ([RR_Asset_ID])
GO

ALTER TABLE [RR_StatModel_Results] CHECK CONSTRAINT [FK_RR_StatModel_Results_Assets]
GO

CREATE VIEW [v__ActiveAssets]
AS
SELECT	RR_Asset_ID, RR_SourceTxt_ID, RR_SourceNum_ID, RR_Source, RR_Hierarchy_ID, RR_Config_ID, RR_Status, RR_Division, RR_Facility, RR_Process, RR_Group, RR_Cohort_ID, RR_AssetType, RR_AssetName, RR_InstallYear,  RR_Decommissioned, RR_Material, RR_Diameter, RR_Length, RR_PreviousFailures, RR_PreviousRehabYear, RR_ReplacementDiameter, RR_ProjectNumber, RR_CurveType, RR_CurveIntercept, RR_CurveSlope, RR_FailurePhysOffset, 
RR_AgeOffset, RR_EUL, RR_RUL, RR_LastInspection, RR_LoFInspection, RR_LoFEUL, RR_LoFPhys, RR_LoFPerf, RR_LoF, RR_RedundancyFactor, RR_CoF, RR_CoF_R, RR_Risk, RR_CoFMaxCriteria, RR_LoFPhysMaxCriteria, 
RR_LoFPerfMaxCriteria, RR_OMMaxCriteria, RR_RepairsAllowed, RR_RehabsAllowed, RR_RehabYear, RR_ReplaceYear, RR_RehabYearCost, RR_RehabYearLoFRaw, RR_RehabYearLoFScore, RR_ReplaceYearCost, 
RR_ReplaceYearLoFRaw, RR_ReplaceYearLoFScore, RR_CostRehab, RR_CostReplace, RR_AssetCostRehab, RR_AssetCostReplace, RR_InheritCost, RR_CoF01, RR_CoF01 AS [CoF 01 Alias], RR_CoF02, RR_CoF02 AS [CoF 02 Alias], 
RR_CoF03, RR_CoF03 AS [CoF 03 Alias], RR_CoF04, RR_CoF04 AS [CoF 04 Alias], RR_CoF05, RR_CoF05 AS [CoF 05 Alias], RR_CoF06, RR_CoF06 AS [CoF 06 Alias], RR_CoF07, RR_CoF07 AS [CoF 07 Alias], RR_CoF08, 
RR_CoF08 AS [CoF 08 Alias], RR_CoF09, RR_CoF09 AS [CoF 09 Alias], RR_CoF10, RR_CoF10 AS [CoF 10 Alias], RR_CoF11, RR_CoF11 AS [CoF 11 Alias], RR_CoF12, RR_CoF12 AS [CoF 12 Alias], RR_CoF13, RR_CoF13 AS [CoF 13 Alias],RR_CoF14, RR_CoF14 AS [CoF 14 Alias], RR_CoF15, RR_CoF15 AS [CoF 15 Alias], RR_CoF16, RR_CoF16 AS [CoF 16 Alias], RR_CoF17, RR_CoF17 AS [CoF 17 Alias], RR_CoF18, RR_CoF18 AS [CoF 18 Alias], RR_CoF19, 
RR_CoF19 AS [CoF 19 Alias], RR_CoF20, RR_CoF20 AS [CoF 20 Alias], RR_CoFComment, RR_LoFPerf01, RR_LoFPerf01 AS [LoFPerf 01 Alias], RR_LoFPerf02, RR_LoFPerf02 AS [LoFPerf 02 Alias], RR_LoFPerf03, 
RR_LoFPerf03 AS [LoFPerf 03 Alias], RR_LoFPerf04, RR_LoFPerf04 AS [LoFPerf 04 Alias], RR_LoFPerf05, RR_LoFPerf05 AS [LoFPerf 05 Alias], RR_LoFPerf06, RR_LoFPerf06 AS [LoFPerf 06 Alias], RR_LoFPerf07, 
RR_LoFPerf07 AS [LoFPerf 07 Alias], RR_LoFPerf08, RR_LoFPerf08 AS [LoFPerf 08 Alias], RR_LoFPerf09, RR_LoFPerf09 AS [LoFPerf 09 Alias], RR_LoFPerf10, RR_LoFPerf10 AS [LoFPerf 10 Alias], RR_LoFPerfComment, RR_OM, 
RR_Fulcrum_ID, RR_InspectionType, RR_Width, RR_Height, RR_Manufacturer, RR_ModelNumber, RR_SerialNumber, RR_CapacityDiameter, RR_HP, RR_RPM, RR_Voltage, RR_Phase, RR_MotorHertz, RR_FLA, RR_ConstructionType, 
RR_Purpose, RR_FieldCode, RR_Barcode, RR_MotorManufacturer, RR_GPM,RR_Head, RR_CFM, RR_FiltrationRate, RR_Tons, RR_CapacityOther, RR_MaxFillHeight, RR_Gallons, RR_SQFT, 
RR_End_ID, RR_Start_ID, RR_CohortAnalysis, RR_Notes, shape, 1 AS Weighting
FROM	dbo.RR_Assets
WHERE	(RR_Status = 1)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Perf_ByCat]
AS
	SELECT	RR_Asset_ID, 'LoFPerf 01 Alias' AS Category, Abs(RR_LoFPerf01) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 02 Alias' AS Category, Abs(RR_LoFPerf02) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 03 Alias' AS Category, Abs(RR_LoFPerf03) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 04 Alias' AS Category, Abs(RR_LoFPerf04) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 05 Alias' AS Category, Abs(RR_LoFPerf05) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 06 Alias' AS Category, Abs(RR_LoFPerf06) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 07 Alias' AS Category, Abs(RR_LoFPerf07) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 08 Alias' AS Category, Abs(RR_LoFPerf08) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 09 Alias' AS Category, Abs(RR_LoFPerf09) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'LoFPerf 10 Alias' AS Category, Abs(RR_LoFPerf10) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'Performance' AS Category, Abs(RR_LoFPerf) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets
	UNION ALL
	SELECT RR_Asset_ID, 'Physical' AS Category, Abs(RR_LoFPhys) AS Val, Weighting AS Weight
	FROM     v__ActiveAssets;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_06_ScenarioResults_Detail]
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

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_06_ScenarioYears]
AS
SELECT	*
FROM	dbo.RR_ScenarioYears;
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_90_CoF_LoF]
AS
SELECT	ConfigCoFLoF_ID, Description, NoteField, Attribute, AttributeValue, OrderNum, 
		CASE WHEN (ISNULL(RefGeoField, N'') <> N'') AND (ISNULL(RefBuffer, N'') <> N'') 
			THEN /*Assign by buffer */
				'UPDATE v__ActiveAssets SET [' + Attribute + '] = ' + AttributeValue + ', [' + NoteField + '] = CASE WHEN ISNULL([' 
				+ NoteField + '], '''') = '''' THEN ''' + Description + ''' WHEN [' + NoteField + '] LIKE ''%' + Description + '%'' THEN [' 
				+ NoteField + ']' + ' ELSE [' + NoteField + '] + '', ' + Description + ''' END' 
				+ ' FROM v__ActiveAssets  a WHERE EXISTS (SELECT 1 FROM [' + RefTable + '] b WHERE a.[' + RefGeoField + '].STBuffer(' 
				+ RefBuffer + ').STIntersects(b.shape) = 1' 
				+ CASE WHEN ISNULL(RefFilter, '') = '' THEN '' ELSE ' AND (' + RefFilter + ')' END + ') AND (a.[' + Attribute + '] > 0 AND a.[' + Attribute + '] < ' + AttributeValue + ');' 
			ELSE /*Assign by attribute */	
				'UPDATE [' + RefTable + '] SET  [' + Attribute + '] = ' + AttributeValue + ', [' + NoteField + '] = CASE WHEN ISNULL([' 
				+ NoteField + '], '''') = '''' THEN ''' + Description + ''' WHEN [' + NoteField + '] LIKE ''%' + Description + '%'' THEN ['
				+ NoteField + ']' + ' ELSE [' + NoteField + '] + '', ' + Description + ''' END' 
				+ ' WHERE (' + RefFilter + ') AND ([' + Attribute + '] > 0 AND [' + Attribute + '] < ' + AttributeValue + ');' 
		END AS SQL
FROM	dbo.RR_ConfigCoFLoF
WHERE	(Active = 1);
GO

--CREATE VIEW [v_90_CoF_Attributes]
--AS
--SELECT        ConfigCoFLoF_ID, Description, NoteField, Attribute, AttributeValue, OrderNum, 
--                         'UPDATE ' + RefTable + ' SET ' + Attribute + ' = ' + AttributeValue + ', ' + NoteField + ' = CASE WHEN ISNULL(' + NoteField + ', '''') = '''' THEN ''' + Description + ''' WHEN ' + NoteField + ' LIKE ''%' + Description + '%'' THEN ' + NoteField
--                          + ' ELSE ' + NoteField + ' + '', ' + Description + ''' END' + ' WHERE (' + RefFilter + ') AND (' + Attribute + ' > 0 AND ' + Attribute + ' < ' + AttributeValue + ');' AS SQL
--FROM            dbo.RR_ConfigCoFLoF
--WHERE        (ISNULL(RefGeoField, N'') = N'') AND (ISNULL(RefBuffer, N'') = N'') AND (Active = 1)
--GO

--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE VIEW [v_90_CoF_Buffer]
--AS
--SELECT        ConfigCoFLoF_ID, NoteField, Description, Attribute, AttributeValue, OrderNum, 
--                         'UPDATE v_91_WaterMains SET ' + Attribute + ' = ' + AttributeValue + ', ' + NoteField + ' = CASE WHEN ISNULL(' + NoteField + ', '''') = '''' THEN ''' + Description + ''' WHEN ' + NoteField + ' LIKE ''%' + Description + '%'' THEN ' + NoteField
--                          + ' ELSE ' + NoteField + ' + '', ' + Description + ''' END' + ' FROM v_91_WaterMains  a WHERE EXISTS (SELECT 1 FROM ' + RefTable + ' b WHERE a.' + RefGeoField + '.STBuffer(' + RefBuffer + ').STIntersects(b.shape) = 1' + CASE
--                          WHEN ISNULL(RefFilter, '') = '' THEN '' ELSE ' AND (' + RefFilter + ')' END + ') AND (a.' + Attribute + ' > 0 AND a.' + Attribute + ' < ' + AttributeValue + ');' AS SQL
--FROM            dbo.RR_ConfigCoFLoF
--WHERE        (ISNULL(RefGeoField, N'') <> N'') AND (ISNULL(RefBuffer, N'') <> N'') AND (Active = 1)
--GO


--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--CREATE VIEW [v_91_CoF_Customers]
--AS
---- Verify Customer CoF is aliased to RR_CoF15
--SELECT	dbo.RR_Assets.RR_Asset_ID, dbo.RR_Assets.RR_CoF15, dbo.RR_Assets.RR_CoFComment, dbo.RR_CriticalCustomers.CoF, dbo.RR_Assets.RR_Status
--FROM	dbo.RR_Assets INNER JOIN
--		dbo.RR_CriticalCustomers ON dbo.RR_Assets.RR_SourceTxt_ID = dbo.RR_CriticalCustomers.SourceTxt_ID
--GO


--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE VIEW [v_91_WaterMains]
--AS
--SELECT        dbo.RR_Assets.*
--FROM            dbo.RR_Assets
--WHERE        (RR_Status = 1)
--GO

--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE PROCEDURE [p_90a_ClearCoFLoF]
--AS
--BEGIN

--	SET NOCOUNT ON;

--	DECLARE @Fld nvarchar(64), @SQL nvarchar(MAX);
	
--	-- Initialize CoF and LoF to 1 where not negative and CoF Field is active in RR_ConfigCoF
--	DECLARE c0 CURSOR
--	FOR SELECT DISTINCT Attribute FROM RR_ConfigCoFLoF WHERE Active = 1;
--	OPEN c0
--	FETCH NEXT FROM c0 INTO @Fld

--	WHILE @@FETCH_STATUS = 0  
--	BEGIN  
--		SELECT	@SQL = 'UPDATE RR_Assets SET [' + @Fld + '] = CASE WHEN ISNULL([' + @Fld + '], 0) >= 0 THEN 1 ELSE [' + @Fld + '] END;'  -- WHERE RR_Status = 1;'
--		EXEC	(@SQL);
--		FETCH NEXT FROM c0 INTO @Fld
--	END   
--	CLOSE c0;  
--	DEALLOCATE c0; 

--END
--GO


--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE PROCEDURE [p_90b_AssignCoF_ByAttributes]
--AS
--BEGIN

--	SET NOCOUNT ON;

--	DECLARE  @ID INT, @SQL nvarchar(MAX), @StartDT datetime;

--	-- Apply CoF or LoF criteria where active in RR_ConfigCoFLoF
--	DECLARE c0 CURSOR
--	FOR SELECT ConfigCoFLoF_ID, SQL FROM v_90_CoF_Attributes ORDER by Attribute, AttributeValue DESC, OrderNum;
--	OPEN c0
--	FETCH NEXT FROM c0 INTO @ID, @SQL

--	WHILE @@FETCH_STATUS = 0  
--	BEGIN  
	
--		SELECT  @StartDT = Getdate();

--		EXEC	(@SQL);

--		UPDATE	RR_ConfigCoFLoF
--		SET		Records = @@RowCount,
--				Duration = DATEDIFF(s, @StartDT, Getdate()),
--				LastRun = Getdate()
--		WHERE	ConfigCoFLoF_ID = @ID;
		
--		FETCH NEXT FROM c0 INTO @ID, @SQL
--	END   
--	CLOSE c0;  
--	DEALLOCATE c0;  

--END
--GO


--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE PROCEDURE [p_90b_AssignCoF_ByBuffer]
--AS
--BEGIN

--	SET NOCOUNT ON;

--	DECLARE @ID INT, @SQL nvarchar(MAX), @StartDT datetime;

--	-- Apply CoF or LoF criteria where active in RR_ConfigCoFLoF
--	DECLARE c0 CURSOR
--	FOR SELECT ConfigCoFLoF_ID, SQL FROM v_90_CoF_Buffer ORDER by Attribute, AttributeValue DESC, OrderNum;
--	OPEN c0
--	FETCH NEXT FROM c0 INTO @ID, @SQL

--	WHILE @@FETCH_STATUS = 0  
--	BEGIN  
	
--		SELECT  @StartDT = Getdate();

--		EXEC	(@SQL);

--		UPDATE	RR_ConfigCoFLoF
--		SET		Records = @@RowCount,
--				Duration = DATEDIFF(s, @StartDT, Getdate()),
--				LastRun = Getdate()
--		WHERE	ConfigCoFLoF_ID = @ID;
		
--		FETCH NEXT FROM c0 INTO @ID, @SQL
--	END   
--	CLOSE c0;  
--	DEALLOCATE c0;  

--END
--GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_90_AssignCoFLoF]
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

--v5.005 update
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v__InventoryWeight]
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
CREATE VIEW [dbo].[v__RuntimeResults]
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
CREATE VIEW [dbo].[v_10_b_ScenarioCurrentYearDetails]
AS
SELECT        dbo.v__RuntimeResults.CurrentScenario_ID, dbo.v__RuntimeResults.CurrentYear, dbo.v__RuntimeResults.CurrentBudget, dbo.v__RuntimeResults.RR_Asset_ID, dbo.v__RuntimeResults.RR_ProjectNumber AS ProjectNumber, 
                         dbo.RR_Projects.ProjectYear, dbo.v__RuntimeResults.RR_InstallYear AS InstallYear, dbo.v__RuntimeResults.CurrentInstallYear, dbo.v__RuntimeResults.CurrentAge, dbo.v__RuntimeResults.CurrentAgeOffset, 
                         dbo.v__RuntimeResults.CurrentFailurePhysOffset, dbo.v__RuntimeResults.CurrentEquationType, dbo.v__RuntimeResults.CurrentConstIntercept, dbo.v__RuntimeResults.CurrentExpSlope, 
                         dbo.v__RuntimeResults.StatsCondition, dbo.v__RuntimeResults.PrelimPhysRaw, dbo.v__RuntimeResults.ConditionLimit, 
                         CASE WHEN PrelimPhysRaw <= ConditionLimit THEN PrelimPhysRaw ELSE ConditionLimit END AS PhysRaw, CASE WHEN PrelimPhysRaw >= ConditionLimit OR
                         CurrentPerformance >= ConditionLimit THEN ConditionLimit WHEN PrelimPhysRaw >= CurrentPerformance THEN PrelimPhysRaw ELSE CurrentPerformance END AS LoFRaw, 
                         dbo.v__RuntimeResults.CurrentPerformance AS PerfScore, dbo.RR_Conditions.Condition_Score AS PhysScore, 
                         CASE WHEN Condition_Score >= CurrentPerformance THEN Condition_Score ELSE CurrentPerformance END AS LoFScore, dbo.v__RuntimeResults.RR_RedundancyFactor AS RedundancyFactor, 
                         dbo.v__RuntimeResults.RR_CoF AS CoF, dbo.v__RuntimeResults.RR_CoF_R AS CoF_R, dbo.v__RuntimeResults.CostRepair, dbo.v__RuntimeResults.CostRehab, dbo.v__RuntimeResults.CostReplace, 
                         dbo.v__RuntimeResults.BaseCostReplace, dbo.v__RuntimeResults.ReplaceEquationType, dbo.v__RuntimeResults.ReplaceConstIntercept, dbo.v__RuntimeResults.ReplaceExpSlope, dbo.v__RuntimeResults.ReplaceEUL, 
                         dbo.v__RuntimeResults.RehabPercentEUL, dbo.v__RuntimeResults.RepairsRemaining, dbo.v__RuntimeResults.RehabsRemaining, dbo.v__RuntimeResults.LowRepair, dbo.v__RuntimeResults.HighRepair, 
                         dbo.v__RuntimeResults.LowRehab, dbo.v__RuntimeResults.HighRehab, dbo.v__RuntimeResults.LowReplace, dbo.v__RuntimeResults.PerformanceReplace, dbo.v__RuntimeResults.TotalLength, 
                         dbo.v__RuntimeResults.Assets, dbo.v__RuntimeResults.CostMultiplier, dbo.v__RuntimeResults.AssetWeight, dbo.v__RuntimeResults.TotalWeight
FROM            dbo.v__RuntimeResults INNER JOIN
                         dbo.RR_Conditions ON dbo.v__RuntimeResults.PrelimPhysRaw >= dbo.RR_Conditions.MinRawCondition LEFT OUTER JOIN
                         dbo.RR_Projects ON dbo.v__RuntimeResults.RR_ProjectNumber = dbo.RR_Projects.ProjectNumber
WHERE        (dbo.v__RuntimeResults.PrelimPhysRaw < dbo.RR_Conditions.MaxRawCondition) OR
                         (dbo.RR_Conditions.MaxRawCondition IS NULL)
GO

-- 2023-07-02
--priorizize rehabs allowed and allow overlapping thresholds except performance threshould
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_10_a_ScenarioCurrentYearDetails]
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
CREATE VIEW [dbo].[v_10_01_ScenarioCurrentYear_RR_Projects]
AS
SELECT        dbo.v_10_a_ScenarioCurrentYearDetails.RR_Asset_ID, dbo.RR_Projects.ProjectYear, CASE WHEN RR_Projects.ServiceType = 'Replace' THEN 'Replace' ELSE 'Rehab' END AS ServiceType, 
                         CASE WHEN RR_Projects.ServiceType = 'Replace' THEN CostReplace ELSE CostRehab END AS ServiceCost, dbo.v_10_a_ScenarioCurrentYearDetails.SystemCondition, 
                         dbo.v_10_a_ScenarioCurrentYearDetails.SystemRiskScore, dbo.v_10_a_ScenarioCurrentYearDetails.SystemRiskRaw, dbo.v_10_a_ScenarioCurrentYearDetails.ProjectNumber, 
                         dbo.v_10_a_ScenarioCurrentYearDetails.CurrentAge, dbo.v_10_a_ScenarioCurrentYearDetails.PhysRaw, dbo.v_10_a_ScenarioCurrentYearDetails.LoFRaw, dbo.v_10_a_ScenarioCurrentYearDetails.PhysScore, 
                         dbo.v_10_a_ScenarioCurrentYearDetails.PerfScore, dbo.v_10_a_ScenarioCurrentYearDetails.LoFScore, dbo.v_10_a_ScenarioCurrentYearDetails.RedundancyFactor, dbo.v_10_a_ScenarioCurrentYearDetails.CoF_R, 
                         dbo.v_10_a_ScenarioCurrentYearDetails.CostReplace, dbo.v_10_a_ScenarioCurrentYearDetails.CostRehab, dbo.v_10_a_ScenarioCurrentYearDetails.CostRepair, dbo.v_10_a_ScenarioCurrentYearDetails.YearRiskRaw, 
                         dbo.v_10_a_ScenarioCurrentYearDetails.YearRiskScore
FROM            dbo.v_10_a_ScenarioCurrentYearDetails INNER JOIN
                         dbo.RR_Projects ON dbo.v_10_a_ScenarioCurrentYearDetails.ProjectNumber = dbo.RR_Projects.ProjectNumber AND dbo.v_10_a_ScenarioCurrentYearDetails.CurrentYear = dbo.RR_Projects.ProjectYear
WHERE        (dbo.v_10_a_ScenarioCurrentYearDetails.UseProjectBudget = 1)
GO

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_06_ScenarioResults_Totals]
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_06_ScenarioResults]
AS
SELECT        [Scenario_ID], [ScenarioName], [ScenarioYear], [TargetBudget], [TargetRiskAllocation], [Budget], [OverallCount], [OverallMiles], [OverallWeighting], [OverallAgeWeighted], [OverallAgeAvg], [OverallPhysRawWeighted], 
                         [OverallPhysRawAvg], [OverallPhysScoreWeighted], [OverallPhysScoreAvg], [OverallPerfScoreWeighted], [OverallPerfScoreAvg], [OverallLoFRawWeighted], [OverallLoFRawAvg], [OverallLoFScoreWeighted], 
                         [OverallLoFScoreScore], [OverallRiskRawWeighted], [OverallRiskRawAvg], [OverallRiskScoreWeighted], [OverallRiskScoreAvg], [ServicedCount], [ServicedMiles], [ServicedWeighting], [ServicedAgeWeighted], [ServicedAgeAvg], 
                         [ServicedPhysRawWeighted], [ServicedPhysRawAvg], [ServicedPhysScoreWeighted], [ServicedPhysScoreAvg], [ServicedPerfScoreWeighted], [ServicedPerfScoreAvg], [ServicedLoFRawWeighted], [ServicedLoFRawAvg], 
                         [ServicedLoFScoreWeighted], [ServicedLoFScoreAvg], [ServicedCoFWeighted], [ServicedCoFAvg], [ServicedRiskRawWeighted], [ServicedRiskRawAvg], [ServicedRiskScoreWeighted], [ServicedRiskScoreAvg], [SortOrder]
FROM            [dbo].[v_00_06_ScenarioResults_Detail]
UNION ALL
SELECT        [Scenario_ID], [ScenarioName], [ScenarioYear], [SumOfTargetBudget], [TargetRiskAllocation], [SumOfBudget], [AvgOfOverallCount], [AvgOfOverallMiles], [SumOfOverallWeighting], [AvgOfOverallAgeWeighted], 
                         [AvgOfOverallAgeAvg], [AvgOfOverallPhysRawWeighted], [AvgOfOverallPhysRawAvg], [AvgOfOverallPhysScoreWeighted], [AvgOfOverallPhysScoreAvg], [AvgOfOverallPerfScoreWeighted], [AvgOfOverallPerfScoreAvg], 
                         [AvgOfOverallLoFRawWeighted], [AvgOfOverallLoFRawAvg], [AvgOfOverallLoFScoreWeighted], [AvgOfOverallLoFScoreScore], [AvgOfOverallRiskRawWeighted], [AvgOfOverallRiskRawAvg], [AvgOfOverallRiskScoreWeighted], 
                         [AvgOfOverallRiskScoreAvg], [SumOfServicedCount], [SumOfServicedMiles], [SumOfServicedWeighting], [AvgOfServicedAgeWeighted], [AvgOfServicedAgeAvg], [AvgOfServicedPhysRawWeighted], [AvgOfServicedPhysRawAvg], 
                         [AvgOfServicedPhysScoreWeighted], [AvgOfServicedPhysScoreAvg], [AvgOfServicedPerfScoreWeighted], [AvgOfServicedPerfScoreAvg], [AvgOfServicedLoFRawWeighted], [AvgOfServicedLoFRawAvg], 
                         [AvgOfServicedLoFScoreWeighted], [AvgOfServicedLoFScoreAvg], [AvgOfServicedCoFWeighted], [AvgOfServicedCoFAvg], [AvgOfServicedRiskRawWeighted], [AvgOfServicedRiskRawAvg], [AvgOfServicedRiskScoreWeighted], 
                         [AvgOfServicedRiskScoreAvg], [SortOrder]
FROM            [dbo].[v_00_06_ScenarioResults_Totals]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Stats_Risk]
AS
SELECT        dbo.v__ActiveAssets.RR_Risk AS Risk, FORMAT(SUM(1), '##,##0') AS Assets, FORMAT(SUM(dbo.v__ActiveAssets.RR_CostReplace), '$#,##0') AS [Asset Cost], FORMAT(SUM(dbo.v__ActiveAssets.RR_Length), '#,##0.##') 
                         AS Miles, FORMAT(SUM(CAST(dbo.v__ActiveAssets.Weighting AS float) / dbo.v__InventoryWeight.Weight), '0.00%') AS [Percent]
FROM            dbo.v__ActiveAssets INNER JOIN
                         dbo.v__InventoryWeight ON dbo.v__ActiveAssets.RR_Config_ID = dbo.v__InventoryWeight.Config_ID
GROUP BY dbo.v__ActiveAssets.RR_Risk
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_20_00_ScenerioYearConditionRisk]
AS
SELECT        dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear, dbo.v__RuntimeResults.CurrentBudget, AVG(CAST(dbo.RR_ScenarioResults.Age AS FLOAT)) AS Avg_Age, 
                         AVG(CASE WHEN [PhysRaw] > [ConditionLimit] THEN [ConditionLimit] ELSE [PhysRaw] END) AS CondAvg, 
                         SUM(dbo.v__RuntimeResults.AssetWeight * CASE WHEN [PhysRaw] > [ConditionLimit] THEN [ConditionLimit] ELSE [PhysRaw] END / dbo.v__RuntimeResults.TotalWeight) AS Cond, 
                         AVG(CAST(dbo.RR_ScenarioResults.PhysScore AS FLOAT)) AS Avg_ConditionScore, 
                         AVG(CAST(CASE WHEN [PhysScore] > [ConditionLimit] THEN [ConditionLimit] ELSE [PhysScore] END * dbo.v__RuntimeResults.RR_CoF_R AS FLOAT)) AS Risk, AVG(CAST(dbo.RR_ScenarioResults.PhysScore AS FLOAT) 
                         * dbo.v__RuntimeResults.RR_CoF_R) AS Avg_RiskScore
FROM            dbo.RR_ScenarioResults INNER JOIN
                         dbo.v__RuntimeResults ON dbo.RR_ScenarioResults.RR_Asset_ID = dbo.v__RuntimeResults.RR_Asset_ID AND dbo.RR_ScenarioResults.Scenario_ID = dbo.v__RuntimeResults.CurrentScenario_ID AND 
                         dbo.RR_ScenarioResults.ScenarioYear = dbo.v__RuntimeResults.CurrentYear
GROUP BY dbo.RR_ScenarioResults.Scenario_ID, dbo.RR_ScenarioResults.ScenarioYear, dbo.v__RuntimeResults.CurrentBudget
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Cohorts_Assignment]
AS
SELECT        dbo.RR_Assets.RR_Asset_ID, dbo.RR_Cohorts.Cohort_ID, dbo.RR_Cohorts.CohortName, dbo.RR_Assets.RR_Material, dbo.RR_Assets.RR_Diameter, dbo.RR_Assets.RR_InstallYear, dbo.RR_Assets.RR_AssetType
FROM            dbo.RR_Cohorts INNER JOIN
                         dbo.RR_Assets ON dbo.RR_Cohorts.MinDia < dbo.RR_Assets.RR_Diameter AND dbo.RR_Cohorts.MaxDia >= dbo.RR_Assets.RR_Diameter AND dbo.RR_Cohorts.MinYear < dbo.RR_Assets.RR_InstallYear AND 
                         dbo.RR_Cohorts.MaxYear >= dbo.RR_Assets.RR_InstallYear
WHERE        (dbo.RR_Cohorts.AssetType LIKE '%''' + dbo.RR_Assets.RR_AssetType + '''%') AND (dbo.RR_Assets.RR_Status = 1) AND (dbo.RR_Cohorts.Materials LIKE '%''' + dbo.RR_Assets.RR_Material + '''%')
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Cohorts_Missing]
AS
SELECT        COUNT(1) AS Cnt, dbo.v__ActiveAssets.RR_AssetType, dbo.v__ActiveAssets.RR_Material, MIN(dbo.v__ActiveAssets.RR_Diameter) AS MinDia, MAX(dbo.v__ActiveAssets.RR_Diameter) AS MaxDia, 
                         MIN(dbo.v__ActiveAssets.RR_InstallYear) AS MinYear, MAX(dbo.v__ActiveAssets.RR_InstallYear) AS MaxYear, ROUND(SUM(dbo.v__ActiveAssets.RR_Length / 5280), 2) AS Length_mi
FROM            dbo.v__ActiveAssets LEFT OUTER JOIN
                         dbo.v_QC_Cohorts_Assignment ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.v_QC_Cohorts_Assignment.RR_Asset_ID
WHERE        (dbo.v_QC_Cohorts_Assignment.RR_Asset_ID IS NULL)
GROUP BY dbo.v__ActiveAssets.RR_Material, dbo.v__ActiveAssets.RR_AssetType
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Cohorts_Duplicate]
AS
SELECT        RR_Asset_ID, RR_AssetType, RR_Material, MIN(CohortName) AS FirstOfPipeClassName, MAX(CohortName) AS LastOfPipeClassName, COUNT(1) AS Cnt
FROM            dbo.v_QC_Cohorts_Assignment
GROUP BY RR_Asset_ID, RR_AssetType, RR_Material
HAVING        (COUNT(1) > 1)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_01_Cohorts]
AS
SELECT        Cohort_ID, CohortName, AssetType, Materials, MinDia, MaxDia, MinYear, MaxYear, ConditionAtEUL, InitEUL, InitEquationType, InitConstIntercept, InitExpSlope, ReplaceEquationType, ReplaceConstIntercept, ReplaceExpSlope, 
                         ReplaceEUL, Comment, RepairsAllowed, RehabsAllowed
FROM            dbo.RR_Cohorts
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_03e_CurveCalc]
AS
SELECT        dbo.v__ActiveAssets.RR_Asset_ID, dbo.v__ActiveAssets.RR_Length AS Length_ft, dbo.v__ActiveAssets.RR_Length / 5280 AS Length_mi, dbo.v__ActiveAssets.RR_InstallYear AS InstallYear, Stats.ConditionYear AS PBNYear, 
                         CAST(Stats.ConditionYear - dbo.v__ActiveAssets.RR_InstallYear AS Int) AS Age, Stats.Condition AS PBN, (100 * Stats.Condition) / (dbo.v__ActiveAssets.RR_Length / 5280) AS PBR
FROM            dbo.RR_StatModel_Results AS Stats INNER JOIN
                         dbo.v__ActiveAssets ON Stats.Asset_ID = dbo.v__ActiveAssets.RR_Asset_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.v_00_02_ScenarioNames
AS
SELECT	Scenario_ID, ScenarioName, 
		ScenarioName + CASE WHEN LastRun IS NOT NULL THEN CONCAT(' ', DATEPART(MONTH, LastRun), '/', DATEPART(DAY, LastRun), '/' ,DATEPART(YEAR, LastRun), ' ', DATEPART(HOUR, LastRun), ':', DATEPART(MINUTE, LastRun), ':', DATEPART(SECOND, LastRun) ) ELSE '' END AS NameLastRun2,
		Description, LastRun, PBI_Flag, TotalCost, ReplacedCost, RehabbedCost, TotalWeight, ReplacedWeight, RehabbedWeight
FROM	dbo.RR_Scenarios
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_08_FailureCount]
AS
SELECT        dbo.RR_Failures.Asset_ID, COUNT(*) AS FailureCount
FROM            dbo.RR_Failures INNER JOIN
                         dbo.RR_Assets ON dbo.RR_Failures.Asset_ID = dbo.RR_Assets.RR_Asset_ID AND YEAR(dbo.RR_Failures.BreakDate) > dbo.RR_Assets.RR_InstallYear
GROUP BY dbo.RR_Failures.Asset_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v___QC_Results]
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

--v5.005 update
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Stats_Cohorts]
AS
SELECT	dbo.RR_Cohorts.CohortName, dbo.RR_Cohorts.InitEUL AS EUL, MIN(dbo.v__ActiveAssets.RR_Diameter) AS MinDia,	
		ROUND(SUM(dbo.v__ActiveAssets.RR_Diameter * dbo.v__ActiveAssets.RR_Length) / SUM(dbo.v__ActiveAssets.RR_Length), 1) AS AvgDia, 
		MAX(dbo.v__ActiveAssets.RR_Diameter) AS MaxDia, MIN(dbo.v__ActiveAssets.RR_InstallYear) AS MinYear, MAX(dbo.v__ActiveAssets.RR_InstallYear) AS MaxYear, 
		ROUND(SUM((dbo.v__InventoryWeight.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear) * dbo.v__ActiveAssets.RR_Length) / SUM(dbo.v__ActiveAssets.RR_Length), 1) AS AvgAge, 
		SUM(dbo.v__ActiveAssets.RR_PreviousFailures) AS Failures, ROUND(SUM(dbo.v__ActiveAssets.RR_Length / 5280), 2) AS Miles, FORMAT(SUM(1), '##,##0') AS Assets, 
		FORMAT(SUM(CAST(dbo.v__ActiveAssets.Weighting AS float) / dbo.v__InventoryWeight.Weight), '0.00%') AS [Percent], 
		Format(SUM(dbo.v__ActiveAssets.RR_CostReplace), '$#,##0') AS [Asset Cost]
FROM	dbo.v__ActiveAssets INNER JOIN
		dbo.v__InventoryWeight ON dbo.v__ActiveAssets.RR_Config_ID = dbo.v__InventoryWeight.Config_ID INNER JOIN
		dbo.RR_Cohorts ON dbo.v__ActiveAssets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID
GROUP BY dbo.RR_Cohorts.CohortName, dbo.RR_Cohorts.InitEUL
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_10_01_ScenarioCurrentYear_RR_Assets]
AS
SELECT	RR_Asset_ID, CurrentScenario_ID, CurrentYear, CurrentBudget, ServiceType, ServiceCost, SystemCondition, SystemRiskScore, SystemRiskRaw, ProjectNumber, ProjectYear, 
		CurrentAge, PhysRaw, LoFRaw, PhysScore, PerfScore, LoFScore, RedundancyFactor, CoF, CoF_R, CostReplace, CostRehab, CostRepair, YearRiskRaw, YearRiskScore, UseProjectBudget
FROM	v_10_a_ScenarioCurrentYearDetails
WHERE	(ServiceCost > 0) AND (UseProjectBudget = 0) OR
		(ServiceCost > 0) AND (ProjectYear IS NULL OR ProjectYear < CurrentYear) AND (UseProjectBudget = 1)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_10_00_Running_Risk]
AS
SELECT	CurrentScenario_ID, CurrentYear, RR_Asset_ID, ServiceCost, ServiceType, LoFRaw, LofScore, YearRiskScore, YearRiskRaw, SystemCondition, SystemRiskScore,  
		ROUND(SUM(CAST(ServiceCost AS bigint)) OVER (ORDER BY YearRiskScore DESC, YearRiskRaw DESC, SystemRiskScore DESC, RR_Asset_ID), 0) RunningCost, 
		SUM(systemcondition) OVER (ORDER BY YearRiskScore DESC, YearRiskRaw DESC, SystemRiskScore DESC, RR_Asset_ID) RunningCondition, 
		SUM(SystemRiskScore) OVER (ORDER BY YearRiskScore DESC, YearRiskRaw DESC, SystemRiskScore DESC, RR_Asset_ID) RunningRisk
FROM	v_10_01_ScenarioCurrentYear_RR_Assets
WHERE	ServiceCost <= CurrentBudget
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_10_00_Running_LoF]
AS
SELECT	CurrentScenario_ID, CurrentYear, RR_Asset_ID, ServiceCost, ServiceType, LoFRaw, LofScore, YearRiskScore, YearRiskRaw, SystemCondition, SystemRiskScore,
		ROUND(SUM(CAST(ServiceCost AS bigint)) OVER (ORDER BY LoFScore DESC, LoFRaw DESC, SystemRiskScore DESC, RR_Asset_ID), 0) RunningCost, 
		SUM(systemcondition) OVER (ORDER BY LoFScore DESC, LoFRaw DESC, SystemRiskScore DESC, RR_Asset_ID) RunningCondition, 
		SUM(SystemRiskScore) OVER (ORDER BY LoFScore DESC, LoFRaw DESC, SystemRiskScore DESC, RR_Asset_ID) RunningRisk
FROM	v_10_01_ScenarioCurrentYear_RR_Assets
WHERE	ServiceCost <= CurrentBudget
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_00_03_Config]
AS
SELECT	ID, Version, ConditionLimit, ConditionFailureFactor, CostMultiplier, BaselineYear, ProjectName, ProjectVersion, 
		ConfigNotes, CommandTimeout, RepairsAllowed, RehabsAllowed, RehabPercentEUL, WeightMultiplier, Initialized
FROM	dbo.RR_Config
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_03_Costs]
AS
SELECT        AssetCost_ID, Description, MinDia, MaxDia, AssetType, CostRepair, CostRehab, CostReplacement
FROM            dbo.RR_AssetCosts
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_03_RR_Thresholds]
AS
SELECT        Criticality, Description, LowRepair, HighRepair, LowRehab, HighRehab, LowReplace, HighReplace, PerformanceReplace
FROM            dbo.RR_CriticalityActionLimits
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_00_03_CoFLoFAssignment]
AS
SELECT        ConfigCoFLoF_ID, Active, Attribute, AttributeValue, RefTable, RefFilter, RefGeoField, RefBuffer, NoteField, Description, OrderNum, Duration, Records, LastRun
FROM            dbo.RR_ConfigCoFLoF
GO

/****** Object:  View [v_00_03_LoFMapping]    Script Date: 8/22/2022 9:43:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_00_03_LoFMapping]
AS
SELECT        Condition_Score, PACP_Score, PACP_Condition, PACP_Description, MinRawCondition, MaxRawCondition
FROM            dbo.RR_Conditions
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_03_RuntimeConfig]
AS
SELECT        ID, StartedOn, StartedBy
FROM            dbo.RR_RuntimeConfig
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_70_GraphCohortCurve]
AS
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, 0 AS X, [InitConstIntercept] AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 1.5, [InitExpSlope]) AS x, 1.5 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 2.5, [InitExpSlope]) AS x, 2.5 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 3.5, [InitExpSlope]) AS x, 3.5 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 4.0, [InitExpSlope]) AS x, 4.0 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 4.5, [InitExpSlope]) AS x, 4.5 AS Y
FROM	RR_Cohorts
UNION ALL
SELECT	Cohort_ID, CohortName, InitEquationType, InitConstIntercept, InitExpSlope, dbo.f_RR_CurveAge([InitEquationType], [InitConstIntercept], 5.0, [InitExpSlope]) AS x, 5.0 AS Y
FROM	RR_Cohorts;

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_03d_CurveCalc]
AS
SELECT        RR_Asset_ID, SUM(Age) AS X, SUM(Age * Age) AS X2, SUM(PBR) AS LY, SUM(LOG (PBR)) AS Y, SUM(PBR * PBR) AS LY2, SUM(Age * LOG (PBR)) AS XY, SUM(LOG (PBR) * LOG (PBR)) AS Y2, SUM(PBR * Age) AS LXY, COUNT(*) 
                         AS N
FROM            dbo.v_03e_CurveCalc
WHERE        (PBR > 0)
GROUP BY RR_Asset_ID
GO

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_05_ScenarioBudgets]
AS
SELECT        BudgetYear_ID, Scenario_ID, BudgetYear, Budget, AllocationToRisk, ConditionTarget, RiskTarget, UseProjectBudget
--FROM            dbo.RR_ScenarioTargetBudgets
FROM	dbo.RR_ScenarioYears;
GO


--v5.005 2023-08-27 LoF5Remaining, Risk16Remaining
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
CREATE VIEW [dbo].[v_03c_CurveCalc]
AS
SELECT        RR_Asset_ID, X, X2, LY, Y, LY2, XY, Y2, LXY, N, N * X2 - X * X AS d
FROM            dbo.v_03d_CurveCalc
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_03b_CurveCalc]
AS
SELECT        RR_Asset_ID, CASE WHEN [d] = 0 THEN NULL ELSE (([N] * [XY] - [X] * [Y]) / [d]) END AS SlopeExponent, CASE WHEN [d] = 0 THEN NULL ELSE (([X2] * [Y] - [X] * [XY]) / [d]) END AS a, CASE WHEN [d] = 0 THEN NULL 
                         ELSE (([N] * [Lxy] - [X] * [Ly]) / [d]) END AS LinearSlopeExponent, CASE WHEN [d] = 0 THEN NULL ELSE (([X2] * [Ly] - [X] * [Lxy]) / [d]) END AS La, X, X2, LY, Y, LY2, XY, Y2, LXY, N, d
FROM            dbo.v_03c_CurveCalc
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_03a_CurveCalc]
AS
SELECT        RR_Asset_ID, d, a, EXP(a) AS InterceptConst, SlopeExponent, CASE WHEN [d] = 0 OR
                         [LinearSlopeExponent] = 0 THEN NULL ELSE ([a] * [Y] + [SlopeExponent] * [XY] - [Y] * [Y] / [N]) / ([Y2] - [Y] * [Y] / [N]) END AS r2, La AS LinearInterceptConst, LinearSlopeExponent, CASE WHEN [d] = 0 OR
                         [LinearSlopeExponent] = 0 THEN NULL ELSE ([La] * [Ly] + [LinearSlopeExponent] * [Lxy] - [Ly] * [Ly] / [N]) / ([Ly2] - [Ly] * [Ly] / [N]) END AS Linearr2
FROM            dbo.v_03b_CurveCalc
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
CREATE VIEW [dbo].[v_00_09_Inspections]
AS
SELECT        dbo.RR_Inspections.*
FROM            dbo.RR_Inspections;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_10_Hyperlinks]
AS
SELECT        RR_Hyperlink_ID, RR_Asset_ID, FileHyperlink, fulcrum_id, hierarchylevel, AssetName
FROM            dbo.RR_Hyperlinks
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_00_14_ProjectAssets]
AS
SELECT        dbo.RR_ProjectAssetGroups.ProjectAssetGroup, dbo.RR_ProjectAssetGroups.ProjectNumber, dbo.RR_Projects.ProjectYear, dbo.RR_ProjectAssetGroups.Asset_ID, dbo.RR_Assets.RR_Division, 
                         dbo.RR_Assets.RR_Facility, dbo.RR_Assets.RR_Process, dbo.RR_Assets.RR_Group, dbo.RR_Assets.RR_AssetType, dbo.RR_Assets.RR_AssetName, dbo.RR_Assets.RR_InstallYear, 
                         dbo.RR_Assets.RR_RUL, dbo.RR_Assets.RR_LoF, dbo.RR_Assets.RR_CoF_R, dbo.RR_Assets.RR_Risk
FROM            dbo.RR_Assets INNER JOIN
                         dbo.RR_ProjectAssetGroups ON dbo.RR_Assets.RR_Asset_ID = dbo.RR_ProjectAssetGroups.Asset_ID INNER JOIN
                         dbo.RR_Projects ON dbo.RR_ProjectAssetGroups.ProjectNumber = dbo.RR_Projects.ProjectNumber
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Stats_Condition]
AS
SELECT        dbo.v__ActiveAssets.RR_LoF AS [Overall LoF], dbo.v__ActiveAssets.RR_LoFPerf AS [Perf Lof], dbo.RR_Conditions.Condition_Score AS [EUL Score], MIN(dbo.v__ActiveAssets.RR_LoFEUL) AS [Min Raw], 
                         MAX(dbo.v__ActiveAssets.RR_LoFEUL) AS [Max Raw], dbo.v__ActiveAssets.RR_LoFPhys AS [Phys Lof], FORMAT(SUM(1), '##,##0') AS Assets, format(SUM(dbo.v__ActiveAssets.Weighting / 5280), '#,##0.00') AS Miles, 
                         FORMAT(SUM(CAST(dbo.v__ActiveAssets.Weighting AS float) / dbo.v__InventoryWeight.Weight), '0.00%') AS [Percent], Format(SUM(CAST(dbo.v__ActiveAssets.RR_CostReplace AS bigint)), '$#,##0') AS [Asset Cost]
FROM            dbo.v__ActiveAssets INNER JOIN
                         dbo.v__InventoryWeight ON dbo.v__ActiveAssets.RR_Config_ID = dbo.v__InventoryWeight.Config_ID INNER JOIN
                         dbo.RR_Conditions ON dbo.v__ActiveAssets.RR_LoFEUL >= dbo.RR_Conditions.MinRawCondition
WHERE        (dbo.v__ActiveAssets.RR_LoFEUL < dbo.RR_Conditions.MaxRawCondition) OR
                         (dbo.RR_Conditions.MaxRawCondition IS NULL)
GROUP BY dbo.v__ActiveAssets.RR_LoF, dbo.v__ActiveAssets.RR_LoFPerf, dbo.v__ActiveAssets.RR_LoFPhys, dbo.RR_Conditions.Condition_Score
GO

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_07_01_ScenarioYears]
AS
SELECT	dbo.RR_ScenarioYears.Scenario_ID, dbo.RR_ScenarioYears.BudgetYear, dbo.RR_RuntimeAssets.RR_Asset_ID
FROM	dbo.RR_RuntimeAssets INNER JOIN
		dbo.RR_RuntimeConfig ON dbo.RR_RuntimeAssets.Config_ID = dbo.RR_RuntimeConfig.ID INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_RuntimeConfig.CurrentScenario_ID = dbo.RR_ScenarioYears.Scenario_ID;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_CohortCurves]
AS
SELECT        Cohort_ID, CohortName, X, Y
FROM            dbo.v_70_GraphCohortCurve
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_40_FirstRehabYear]
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
CREATE VIEW [dbo].[v_40_FirstReplaceYear]
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
CREATE VIEW [dbo].[v_QC_Hierarchy_Union]
AS
SELECT	RR_Hierarchy_1.RR_HierarchyName AS Level1, '' AS Level2, '' AS Level3, '' AS Level4, '' AS Asset,  
		RR_Hierarchy_1.RR_CoF01, RR_Hierarchy_1.RR_CoF02, RR_Hierarchy_1.RR_CoF03, RR_Hierarchy_1.RR_CoF04, RR_Hierarchy_1.RR_CoF05, 
		RR_Hierarchy_1.RR_CoF06, RR_Hierarchy_1.RR_CoF07, RR_Hierarchy_1.RR_CoF08, RR_Hierarchy_1.RR_CoF09, RR_Hierarchy_1.RR_CoF10, 
		RR_Hierarchy_1.RR_CoF11, RR_Hierarchy_1.RR_CoF12, RR_Hierarchy_1.RR_CoF13, RR_Hierarchy_1.RR_CoF14, RR_Hierarchy_1.RR_CoF15, 
		RR_Hierarchy_1.RR_CoF16, RR_Hierarchy_1.RR_CoF17, RR_Hierarchy_1.RR_CoF18, RR_Hierarchy_1.RR_CoF19, RR_Hierarchy_1.RR_CoF20, 
		RR_Hierarchy_1.RR_LoFPerf01, RR_Hierarchy_1.RR_LoFPerf02, RR_Hierarchy_1.RR_LoFPerf03, RR_Hierarchy_1.RR_LoFPerf04, RR_Hierarchy_1.RR_LoFPerf05, 
		RR_Hierarchy_1.RR_LoFPerf06, RR_Hierarchy_1.RR_LoFPerf07, RR_Hierarchy_1.RR_LoFPerf08, RR_Hierarchy_1.RR_LoFPerf09, RR_Hierarchy_1.RR_LoFPerf10, 
		RR_Hierarchy_1.RR_LoFPerfComment, RR_Hierarchy_1.RR_CoFComment, RR_Hierarchy_1.RR_RedundancyFactor,
		'' AS AssetID, '' AS FacilityID, NULL AS LoFPerf, NULL AS LoFPhys, NULL AS CoF, NULL AS CoF_R, NULL AS Risk, NULL AS InstallYear
FROM	RR_Hierarchy AS RR_Hierarchy_1
WHERE	RR_Hierarchy_1.RR_HierarchyLevel = 1
UNION ALL
SELECT	RR_Hierarchy_1.RR_HierarchyName AS Level1, RR_Hierarchy_2.RR_HierarchyName AS Level2, '' AS Level3, '' AS Level4, '' AS Asset, 
		RR_Hierarchy_2.RR_CoF01, RR_Hierarchy_2.RR_CoF02, RR_Hierarchy_2.RR_CoF03, RR_Hierarchy_2.RR_CoF04, RR_Hierarchy_2.RR_CoF05, 
		RR_Hierarchy_2.RR_CoF06, RR_Hierarchy_2.RR_CoF07, RR_Hierarchy_2.RR_CoF08, RR_Hierarchy_2.RR_CoF09, RR_Hierarchy_2.RR_CoF10, 
		RR_Hierarchy_2.RR_CoF11, RR_Hierarchy_2.RR_CoF12, RR_Hierarchy_2.RR_CoF13, RR_Hierarchy_2.RR_CoF14, RR_Hierarchy_2.RR_CoF15, 
		RR_Hierarchy_2.RR_CoF16, RR_Hierarchy_2.RR_CoF17, RR_Hierarchy_2.RR_CoF18, RR_Hierarchy_2.RR_CoF19, RR_Hierarchy_2.RR_CoF20, 
		RR_Hierarchy_2.RR_LoFPerf01,RR_Hierarchy_2.RR_LoFPerf02, RR_Hierarchy_2.RR_LoFPerf03, RR_Hierarchy_2.RR_LoFPerf04, RR_Hierarchy_2.RR_LoFPerf05, 
		RR_Hierarchy_2.RR_LoFPerf06, RR_Hierarchy_2.RR_LoFPerf07, RR_Hierarchy_2.RR_LoFPerf08, RR_Hierarchy_2.RR_LoFPerf09, RR_Hierarchy_2.RR_LoFPerf10, 
		RR_Hierarchy_2.RR_LoFPerfComment, RR_Hierarchy_2.RR_CoFComment,  RR_Hierarchy_2.RR_RedundancyFactor,
		'' AS AssetID, '' AS FacilityID, NULL AS LoFPerf, NULL AS LoFPhys, NULL AS CoF, NULL AS CoF_R, NULL AS Risk, NULL AS InstallYear
FROM	RR_Hierarchy AS RR_Hierarchy_1 RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_1.RR_Hierarchy_ID = RR_Hierarchy_2.RR_Parent_ID
WHERE	RR_Hierarchy_2.RR_HierarchyLevel = 2
UNION ALL
SELECT	RR_Hierarchy_1.RR_HierarchyName AS Level1, RR_Hierarchy_2.RR_HierarchyName AS Level2, RR_Hierarchy_3.RR_HierarchyName AS Level3, '' AS Level4, '' AS Asset, 
		RR_Hierarchy_3.RR_CoF01, RR_Hierarchy_3.RR_CoF02, RR_Hierarchy_3.RR_CoF03, RR_Hierarchy_3.RR_CoF04, RR_Hierarchy_3.RR_CoF05, 
		RR_Hierarchy_3.RR_CoF06, RR_Hierarchy_3.RR_CoF07, RR_Hierarchy_3.RR_CoF08, RR_Hierarchy_3.RR_CoF09, RR_Hierarchy_3.RR_CoF10, 
		RR_Hierarchy_3.RR_CoF11, RR_Hierarchy_3.RR_CoF12, RR_Hierarchy_3.RR_CoF13, RR_Hierarchy_3.RR_CoF14, RR_Hierarchy_3.RR_CoF15, 
		RR_Hierarchy_3.RR_CoF16, RR_Hierarchy_3.RR_CoF17, RR_Hierarchy_3.RR_CoF18, RR_Hierarchy_3.RR_CoF19, RR_Hierarchy_3.RR_CoF20, 
		RR_Hierarchy_3.RR_LoFPerf01, RR_Hierarchy_3.RR_LoFPerf02, RR_Hierarchy_3.RR_LoFPerf03, RR_Hierarchy_3.RR_LoFPerf04, RR_Hierarchy_3.RR_LoFPerf05,
		RR_Hierarchy_3.RR_LoFPerf06, RR_Hierarchy_3.RR_LoFPerf07, RR_Hierarchy_3.RR_LoFPerf08, RR_Hierarchy_3.RR_LoFPerf09, RR_Hierarchy_3.RR_LoFPerf10, 
		RR_Hierarchy_3.RR_LoFPerfComment, RR_Hierarchy_3.RR_CoFComment,  RR_Hierarchy_3.RR_RedundancyFactor,
		'' AS AssetID, '' AS FacilityID, NULL AS LoFPerf, NULL AS LoFPhys, NULL AS CoF, NULL AS CoF_R, NULL AS Risk, NULL AS InstallYear        
FROM	(RR_Hierarchy AS RR_Hierarchy_1 RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_1.RR_Hierarchy_ID = RR_Hierarchy_2.RR_Parent_ID) RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_3 ON RR_Hierarchy_2.RR_Hierarchy_ID = RR_Hierarchy_3.RR_Parent_ID
WHERE	RR_Hierarchy_3.RR_HierarchyLevel = 3
UNION ALL
SELECT	RR_Hierarchy_1.RR_HierarchyName AS Level1, RR_Hierarchy_2.RR_HierarchyName AS Level2, RR_Hierarchy_3.RR_HierarchyName AS Level3, RR_Hierarchy_4.RR_HierarchyName AS Level4, '' AS Asset, 
		RR_Hierarchy_4.RR_CoF01, RR_Hierarchy_4.RR_CoF02, RR_Hierarchy_4.RR_CoF03, RR_Hierarchy_4.RR_CoF04, RR_Hierarchy_4.RR_CoF05, 
		RR_Hierarchy_4.RR_CoF06, RR_Hierarchy_4.RR_CoF07, RR_Hierarchy_4.RR_CoF08, RR_Hierarchy_4.RR_CoF09, RR_Hierarchy_4.RR_CoF10, 
		RR_Hierarchy_4.RR_CoF11, RR_Hierarchy_4.RR_CoF12, RR_Hierarchy_4.RR_CoF13, RR_Hierarchy_4.RR_CoF14, RR_Hierarchy_4.RR_CoF15, 
		RR_Hierarchy_4.RR_CoF16, RR_Hierarchy_4.RR_CoF17, RR_Hierarchy_4.RR_CoF18, RR_Hierarchy_4.RR_CoF19, RR_Hierarchy_4.RR_CoF20, 
		RR_Hierarchy_4.RR_LoFPerf01, RR_Hierarchy_4.RR_LoFPerf02, RR_Hierarchy_4.RR_LoFPerf03, RR_Hierarchy_4.RR_LoFPerf04, RR_Hierarchy_4.RR_LoFPerf05,
		RR_Hierarchy_4.RR_LoFPerf06, RR_Hierarchy_4.RR_LoFPerf07, RR_Hierarchy_4.RR_LoFPerf08, RR_Hierarchy_4.RR_LoFPerf09, RR_Hierarchy_4.RR_LoFPerf10,
		RR_Hierarchy_4.RR_LoFPerfComment, RR_Hierarchy_4.RR_CoFComment,  RR_Hierarchy_4.RR_RedundancyFactor,
		'' AS AssetID, '' AS FacilityID, NULL AS LoFPerf, NULL AS LoFPhys, NULL AS CoF, NULL AS CoF_R, NULL AS Risk, NULL AS InstallYear
FROM	((RR_Hierarchy AS RR_Hierarchy_1 RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_1.RR_Hierarchy_ID = RR_Hierarchy_2.RR_Parent_ID) RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_3 ON RR_Hierarchy_2.RR_Hierarchy_ID = RR_Hierarchy_3.RR_Parent_ID) RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_4 ON RR_Hierarchy_3.RR_Hierarchy_ID = RR_Hierarchy_4.RR_Parent_ID
WHERE	RR_Hierarchy_4.RR_HierarchyLevel = 4
UNION ALL
SELECT	RR_Hierarchy_1.RR_HierarchyName AS Level1, RR_Hierarchy_2.RR_HierarchyName AS Level2, RR_Hierarchy_3.RR_HierarchyName AS Level3, RR_Hierarchy_4.RR_HierarchyName AS Level4, RR_Assets.RR_AssetName AS Asset, 
		RR_Assets.RR_CoF01, RR_Assets.RR_CoF02, RR_Assets.RR_CoF03, RR_Assets.RR_CoF04, RR_Assets.RR_CoF05, 
		RR_Assets.RR_CoF06, RR_Assets.RR_CoF07, RR_Assets.RR_CoF08, RR_Assets.RR_CoF09, RR_Assets.RR_CoF10, 
		RR_Assets.RR_CoF11, RR_Assets.RR_CoF12, RR_Assets.RR_CoF13, RR_Assets.RR_CoF14, RR_Assets.RR_CoF15, 
		RR_Assets.RR_CoF16, RR_Assets.RR_CoF17, RR_Assets.RR_CoF18, RR_Assets.RR_CoF19, RR_Assets.RR_CoF20,
		RR_Assets.RR_LoFPerf01, RR_Assets.RR_LoFPerf02, RR_Assets.RR_LoFPerf03, RR_Assets.RR_LoFPerf04, RR_Assets.RR_LoFPerf05, 
		RR_Assets.RR_LoFPerf06, RR_Assets.RR_LoFPerf07, RR_Assets.RR_LoFPerf08, RR_Assets.RR_LoFPerf09, RR_Assets.RR_LoFPerf10,
		RR_Assets.RR_LoFPerfComment, RR_Assets.RR_CoFComment, RR_Assets.RR_RedundancyFactor,
		RR_Assets.RR_Asset_ID AS AssetID, RR_Assets.RR_SourceTxt_ID AS FacilityID, RR_Assets.RR_LoFPerf AS LoFPerf, 
		RR_Assets.RR_LoFPhys AS LoFPhys, RR_Assets.RR_CoF AS CoF, RR_Assets.RR_CoF_R AS CoF_R, RR_Assets.RR_Risk AS Risk, RR_Assets.RR_InstallYear AS InstallYear
FROM	RR_Assets LEFT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_1 RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_1.RR_Hierarchy_ID = RR_Hierarchy_2.RR_Parent_ID RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_3 ON RR_Hierarchy_2.RR_Hierarchy_ID = RR_Hierarchy_3.RR_Parent_ID RIGHT OUTER JOIN
		RR_Hierarchy AS RR_Hierarchy_4 ON RR_Hierarchy_3.RR_Hierarchy_ID = RR_Hierarchy_4.RR_Parent_ID ON RR_Assets.RR_Hierarchy_ID = RR_Hierarchy_4.RR_Hierarchy_ID
WHERE	RR_Assets.RR_Status = 1
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07_Hierarchy]
AS
SELECT	RR_Hierarchy_ID AS Hierarchy_ID, RR_Parent_ID AS Parent_ID, RR_HierarchyLevel, RR_RedundancyFactor AS RF, 
		RR_CoF01 AS CoF1, RR_CoF02 AS CoF2, RR_CoF03 AS CoF3, RR_CoF04 AS Cof4, RR_CoF05 AS CoF5, RR_CoF06 AS CoF6, RR_CoF07 AS CoF7, 
		RR_CoF08 AS CoF8, RR_CoF09 AS CoF9, RR_CoF10 AS CoF10, RR_CoF11 AS CoF11, RR_CoF12 AS CoF12, RR_CoF13 AS CoF13, RR_CoF14 AS CoF14,
		RR_CoF15 AS CoF15, RR_CoF16 AS CoF16, RR_CoF17 AS CoF17, RR_CoF18 AS CoF18, RR_CoF19 AS CoF19, RR_CoF20 AS CoF20,
		RR_LoFPerf01 AS LoF1, RR_LoFPerf02 AS LoF2, RR_LoFPerf03 AS LoF3, RR_LoFPerf04 AS LoF4, RR_LoFPerf05 AS LoF5,
		RR_LoFPerf06 AS LoF6, RR_LoFPerf07 AS LoF7, RR_LoFPerf08 AS LoF8, RR_LoFPerf09 AS LoF9, RR_LoFPerf10 AS LoF10
FROM	dbo.RR_Hierarchy;
GO


--2023-07-02

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_50_ProjectStats]
AS
SELECT	dbo.v__ActiveAssets.RR_ProjectNumber, 
		SUM(CASE WHEN RR_Projects.ServiceType = 'Replace' THEN dbo.v__ActiveAssets.RR_CostReplace * RR_Config.CostMultiplier WHEN RR_Projects.ServiceType = 'Rehab' THEN dbo.v__ActiveAssets.RR_CostRehab * RR_Config.CostMultiplier ELSE 1 END) AS Cost,
		COUNT(dbo.v__ActiveAssets.RR_Asset_ID) AS Assets, 
		SUM(dbo.v__ActiveAssets.RR_Length) AS Length, MIN(dbo.RR_Config.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear) AS Min_Age, MAX(dbo.RR_Config.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear) AS Max_Age, 
		ROUND(SUM((dbo.RR_Config.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear) * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_Age, MIN(dbo.v__ActiveAssets.RR_Diameter) AS Min_Dia, 
		MAX(dbo.v__ActiveAssets.RR_Diameter) AS Max_Dia, ROUND(SUM(dbo.v__ActiveAssets.RR_Diameter * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_Dia, 
		MAX(dbo.v__ActiveAssets.RR_LOFPerf) AS Max_LOF_Perf, ROUND(SUM(dbo.v__ActiveAssets.RR_LOFPerf * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_LOF_Perf, 
		MAX(dbo.v__ActiveAssets.RR_LOFPhys) AS Max_LOF_Phys, ROUND(SUM(dbo.v__ActiveAssets.RR_LOFPhys * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_LOF_Phys, 
		MAX(dbo.v__ActiveAssets.RR_LOFEUL) AS Max_LoF_EUL, ROUND(SUM(dbo.v__ActiveAssets.RR_LOFEUL * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_LOF_EUL, 
		MAX(dbo.v__ActiveAssets.RR_LOF) AS Max_LoF, ROUND(SUM(dbo.v__ActiveAssets.RR_LOF * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_LoF, MAX(dbo.v__ActiveAssets.RR_COF) 
		AS Max_CoF, ROUND(SUM(dbo.v__ActiveAssets.RR_COF * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_CoF, AVG(dbo.v__ActiveAssets.RR_RedundancyFactor) AS Avg_Redundancy, 
		MAX(dbo.v__ActiveAssets.RR_COF_R) AS Max_CoF_R, ROUND(SUM(dbo.v__ActiveAssets.RR_COF_R * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_CoF_R, 
		MAX(dbo.v__ActiveAssets.RR_Risk) AS Max_Risk, ROUND(SUM(dbo.v__ActiveAssets.RR_Risk * dbo.v__ActiveAssets.Weighting) / SUM(dbo.v__ActiveAssets.Weighting), 1) AS Avg_Risk
FROM	dbo.v__ActiveAssets INNER JOIN
		dbo.RR_Config ON dbo.v__ActiveAssets.RR_Config_ID = dbo.RR_Config.ID INNER JOIN
		dbo.RR_Projects ON dbo.v__ActiveAssets.RR_ProjectNumber = dbo.RR_Projects.ProjectNumber
GROUP	BY dbo.v__ActiveAssets.RR_ProjectNumber
HAVING	(dbo.v__ActiveAssets.RR_ProjectNumber IS NOT NULL);
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_14_Results_Summary_ProjectOverrideCosts]
AS
SELECT	dbo.RR_ScenarioYears.Scenario_ID, dbo.RR_ScenarioYears.BudgetYear, 
		SUM(ISNULL(dbo.RR_Projects.OverrideCost, dbo.RR_Projects.ProjectCost) - ISNULL(dbo.RR_Projects.ProjectCost, 0)) AS CostDiff, 
		SUM(dbo.RR_Projects.ProjectCost) AS ProjectCost
FROM	dbo.RR_Projects INNER JOIN
		dbo.RR_ScenarioYears ON dbo.RR_Projects.ProjectYear = dbo.RR_ScenarioYears.BudgetYear
WHERE	(dbo.RR_ScenarioYears.UseProjectBudget = 1) AND (dbo.RR_Projects.Active = 1)
GROUP BY dbo.RR_ScenarioYears.Scenario_ID, dbo.RR_ScenarioYears.BudgetYear;
GO

--v5.009 2023-08-25 LoF5 and Risk Remaining
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_14_Results_Summary]
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_50_ProjectGeo]
AS
SELECT        dbo.v__ActiveAssets.RR_ProjectNumber, geometry::UnionAggregate(dbo.v__ActiveAssets.Shape) AS AgLine
FROM            dbo.v__ActiveAssets INNER JOIN
                         dbo.RR_Projects ON dbo.v__ActiveAssets.RR_ProjectNumber = dbo.RR_Projects.ProjectNumber
GROUP BY dbo.v__ActiveAssets.RR_ProjectNumber
HAVING        (dbo.v__ActiveAssets.RR_ProjectNumber IS NOT NULL);
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_00_07_HierarchyAssetTree]
AS
SELECT DISTINCT 1 as Level, P1 AS PID, CONCAT(ID1, '') AS ID, CONCAT('H', ID1)  AS Label, Name1 AS Name, AssetCount1 AS Cnt FROM v_00_07_HierarchyTree WHERE ID1 IS NOT NULL
UNION ALL
SELECT DISTINCT 2 as Level, P2 AS PID, CONCAT(ID2, '') AS ID, CONCAT('H', ID2)  AS Label, Name2 AS Name, AssetCount2 AS Cnt FROM v_00_07_HierarchyTree WHERE ID2 IS NOT NULL
UNION ALL
SELECT DISTINCT 3  as Level, P3 AS PID, CONCAT(ID3, '') AS ID, CONCAT('H', ID3)  AS Label, Name3 AS Name, AssetCount3 AS Cnt FROM v_00_07_HierarchyTree WHERE ID3 IS NOT NULL
UNION ALL
SELECT DISTINCT 4 as Level, P4 AS PID, CONCAT(ID4, '') AS ID, CONCAT('H', ID4)  AS Label, Name4 AS Name, AssetCount4 AS Cnt FROM v_00_07_HierarchyTree WHERE ID4 IS NOT NULL
UNION ALL
SELECT DISTINCT 5 as Level, P5 AS PID, CONCAT(ID5, '') AS ID, CONCAT('H', ID5)  AS Label, Name5 AS Name, AssetCount5 AS Cnt FROM v_00_07_HierarchyTree WHERE ID5 IS NOT NULL
UNION ALL
SELECT 6 AS Level,  RR_Hierarchy_ID AS PID, CONCAT('A', RR_Asset_ID) AS ID, CONCAT('A', RR_Asset_ID) AS Label, RR_AssetName AS Name, 0 AS Cnt FROM v__ActiveAssets
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07_HierarchyRecord]
AS
SELECT	RR_Hierarchy_ID, RR_Parent_ID, RR_HierarchyLevel, RR_HierarchyName, RR_RedundancyFactor, 
		RR_CoF01, RR_CoF02, RR_CoF03, RR_CoF04, RR_CoF05, RR_CoF06, RR_CoF07,
		RR_CoF08, RR_CoF09, RR_CoF10, RR_CoF11, RR_CoF12, RR_CoF13, RR_CoF14, RR_CoF15,
		RR_CoF16, RR_CoF17, RR_CoF18, RR_CoF19, RR_CoF20,
		RR_CoFComment, 
		RR_LoFPerf01, RR_LoFPerf02, RR_LoFPerf03, RR_LoFPerf04, RR_LoFPerf05, 
		RR_LoFPerf06, RR_LoFPerf07, RR_LoFPerf08, RR_LoFPerf09, RR_LoFPerf10,
		RR_LoFPerfComment, RR_HierarchyNotes
FROM	dbo.RR_Hierarchy
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_00_07_Hierarchy_Enabled]
AS
SELECT	DISTINCT 
		ChildHierarchy.RR_Hierarchy_ID, ChildHierarchy.RR_Parent_ID, CASE WHEN [ParentHierarchy].[RR_RedundancyFactor] > 0 THEN 0 ELSE 1 END AS RR_RedundancyFactor, 
		CASE WHEN [ParentHierarchy].[RR_CoF01] > 0 THEN 0 ELSE 1 END AS RR_CoF01, CASE WHEN [ParentHierarchy].[RR_CoF02] > 0 THEN 0 ELSE 1 END AS RR_CoF02, 
		CASE WHEN [ParentHierarchy].[RR_CoF03] > 0 THEN 0 ELSE 1 END AS RR_CoF03, CASE WHEN [ParentHierarchy].[RR_CoF04] > 0 THEN 0 ELSE 1 END AS RR_CoF04, 
		CASE WHEN [ParentHierarchy].[RR_CoF05] > 0 THEN 0 ELSE 1 END AS RR_CoF05, CASE WHEN [ParentHierarchy].[RR_CoF06] > 0 THEN 0 ELSE 1 END AS RR_CoF06, 
		CASE WHEN [ParentHierarchy].[RR_CoF07] > 0 THEN 0 ELSE 1 END AS RR_CoF07, CASE WHEN [ParentHierarchy].[RR_CoF08] > 0 THEN 0 ELSE 1 END AS RR_CoF08,
		CASE WHEN [ParentHierarchy].[RR_CoF09] > 0 THEN 0 ELSE 1 END AS RR_CoF09, CASE WHEN [ParentHierarchy].[RR_CoF10] > 0 THEN 0 ELSE 1 END AS RR_CoF10,
		CASE WHEN [ParentHierarchy].[RR_CoF11] > 0 THEN 0 ELSE 1 END AS RR_CoF11, CASE WHEN [ParentHierarchy].[RR_CoF12] > 0 THEN 0 ELSE 1 END AS RR_CoF12,
		CASE WHEN [ParentHierarchy].[RR_CoF13] > 0 THEN 0 ELSE 1 END AS RR_CoF13, CASE WHEN [ParentHierarchy].[RR_CoF14] > 0 THEN 0 ELSE 1 END AS RR_CoF14,
		CASE WHEN [ParentHierarchy].[RR_CoF15] > 0 THEN 0 ELSE 1 END AS RR_CoF15, CASE WHEN [ParentHierarchy].[RR_CoF16] > 0 THEN 0 ELSE 1 END AS RR_CoF16,
		CASE WHEN [ParentHierarchy].[RR_CoF17] > 0 THEN 0 ELSE 1 END AS RR_CoF17, CASE WHEN [ParentHierarchy].[RR_CoF18] > 0 THEN 0 ELSE 1 END AS RR_CoF18,
		CASE WHEN [ParentHierarchy].[RR_CoF19] > 0 THEN 0 ELSE 1 END AS RR_CoF19, CASE WHEN [ParentHierarchy].[RR_CoF20] > 0 THEN 0 ELSE 1 END AS RR_CoF20,
		CASE WHEN [ParentHierarchy].[RR_LoFPerf01] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf01, CASE WHEN [ParentHierarchy].[RR_LoFPerf02] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf02, 
		CASE WHEN [ParentHierarchy].[RR_LoFPerf03] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf03, CASE WHEN [ParentHierarchy].[RR_LoFPerf04] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf04, 
		CASE WHEN [ParentHierarchy].[RR_LoFPerf05] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf05, CASE WHEN [ParentHierarchy].[RR_LoFPerf06] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf06,
		CASE WHEN [ParentHierarchy].[RR_LoFPerf07] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf07, CASE WHEN [ParentHierarchy].[RR_LoFPerf08] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf08,
		CASE WHEN [ParentHierarchy].[RR_LoFPerf09] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf09, CASE WHEN [ParentHierarchy].[RR_LoFPerf10] > 0 THEN 0 ELSE 1 END AS RR_LoFPerf10
FROM	dbo.RR_Hierarchy AS ParentHierarchy INNER JOIN
		dbo.RR_Hierarchy AS ChildHierarchy ON ChildHierarchy.RR_Parent_ID = ParentHierarchy.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.RR_Assets ON dbo.RR_Assets.RR_Hierarchy_ID = ChildHierarchy.RR_Hierarchy_ID;
GO






SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_AssetPhysCond]
AS
SELECT	RR_Hierarchy_1.RR_HierarchyName AS Level1, RR_Hierarchy_2.RR_HierarchyName AS Level2, RR_Hierarchy_3.RR_HierarchyName AS Level3, RR_Hierarchy_4.RR_HierarchyName AS Level4, 
		dbo.v__ActiveAssets.RR_SourceTxt_ID AS FacilityID, dbo.v__ActiveAssets.RR_AssetName AS Asset, dbo.v__ActiveAssets.RR_InstallYear AS [Install Year], dbo.RR_Cohorts.InitEUL AS EUL, 
		dbo.v__ActiveAssets.RR_InstallYear + dbo.RR_Cohorts.InitEUL - YEAR({ fn NOW() }) AS RUL, dbo.RR_Inspections.RR_InspectionDate AS [Inspection Date], dbo.RR_Inspections.RR_InspectionType AS [Inspection Type], 
		dbo.v__ActiveAssets.RR_LoFPhys AS [Phys LoF], dbo.v__ActiveAssets.RR_LoFPerf AS [Perf LoF], dbo.v__ActiveAssets.RR_CoF_R AS CoF, dbo.v__ActiveAssets.RR_RedundancyFactor AS Redundancy, 
		dbo.v__ActiveAssets.RR_Risk AS Risk, dbo.v__ActiveAssets.RR_LoFEUL AS [EUL LoF], dbo.v__ActiveAssets.RR_LoF AS [Overall LoF], 
		dbo.v__ActiveAssets.RR_LoFPerf01 AS [LoFPerf 01 Alias], dbo.v__ActiveAssets.RR_LoFPerf02 AS [LoFPerf 02 Alias], dbo.v__ActiveAssets.RR_LoFPerf03 AS [LoFPerf 03 Alias],
		dbo.v__ActiveAssets.RR_LoFPerf04 AS [LoFPerf 04 Alias], dbo.v__ActiveAssets.RR_LoFPerf05 AS [LoFPerf 05 Alias], 
		dbo.v__ActiveAssets.RR_Status AS Status, dbo.RR_Inspections.RR_CompleteInspection, 
		dbo.RR_Inspections.RR_LoFPhys01 AS [LoFPhys 01 Alias], dbo.RR_Inspections.RR_LoFPhys02 AS [LoFPhys 02 Alias], dbo.RR_Inspections.RR_LoFPhys03 AS [LoFPhys 03 Alias], 
		dbo.RR_Inspections.RR_LoFPhys04 AS [LoFPhys 04 Alias], dbo.RR_Inspections.RR_LoFPhys05 AS [LoFPhys 05 Alias], dbo.RR_Inspections.RR_LoFPhys06 AS [LoFPhys 06 Alias], 
		dbo.RR_Inspections.RR_LoFPhys07 AS [LoFPhys 07 Alias], dbo.RR_Inspections.RR_LoFPhys08 AS [LoFPhys 08 Alias], dbo.RR_Inspections.RR_LoFPhys09 AS [LoFPhys 09 Alias], 
		dbo.RR_Inspections.RR_LoFPhys10 AS [LoFPhys 10 Alias], dbo.RR_Inspections.RR_LoFPhys11 AS [LoFPhys 11 Alias], dbo.RR_Inspections.RR_LoFPhys12 AS [LoFPhys 12 Alias], 
		dbo.RR_Inspections.RR_LoFPhys13 AS [LoFPhys 13 Alias], dbo.RR_Inspections.RR_LoFPhys14 AS [LoFPhys 14 Alias], dbo.RR_Inspections.RR_LoFPhys15 AS [LoFPhys 15 Alias], 
		dbo.RR_Inspections.RR_LoFPhys16 AS [LoFPhys 16 Alias], dbo.RR_Inspections.RR_LoFPhys17 AS [LoFPhys 17 Alias], dbo.RR_Inspections.RR_LoFPhys18 AS [LoFPhys 18 Alias], 
		dbo.RR_Inspections.RR_LoFPhys19 AS [LoFPhys 19 Alias], dbo.RR_Inspections.RR_LoFPhys20 AS [LoFPhys 20 Alias], dbo.RR_Inspections.RR_LoFPhys21 AS [LoFPhys 21 Alias], 
		dbo.RR_Inspections.RR_LoFPhys22 AS [LoFPhys 22 Alias], dbo.RR_Inspections.RR_LoFPhys23 AS [LoFPhys 23 Alias], dbo.RR_Inspections.RR_LoFPhys24 AS [LoFPhys 24 Alias], 
		dbo.RR_Inspections.RR_LoFPhys25 AS [LoFPhys 25 Alias], dbo.RR_Inspections.RR_LoFPhys26 AS [LoFPhys 26 Alias], dbo.RR_Inspections.RR_LoFPhys27 AS [LoFPhys 27 Alias], 
		dbo.RR_Inspections.RR_LoFPhys28 AS [LoFPhys 28 Alias], dbo.RR_Inspections.RR_LoFPhys29 AS [LoFPhys 29 Alias], dbo.RR_Inspections.RR_LoFPhys30 AS [LoFPhys 30 Alias], 
		dbo.RR_Inspections.RR_LoFPhys31 AS [LoFPhys 31 Alias], dbo.RR_Inspections.RR_LoFPhys32 AS [LoFPhys 32 Alias], dbo.RR_Inspections.RR_LoFPhys33 AS [LoFPhys 33 Alias], 
		dbo.RR_Inspections.RR_LoFPhys34 AS [LoFPhys 34 Alias], dbo.RR_Inspections.RR_LoFPhys35 AS [LoFPhys 35 Alias], dbo.RR_Inspections.RR_LoFPhys36 AS [LoFPhys 36 Alias],
		dbo.RR_Inspections.RR_LoFPhys37 AS [LoFPhys 37 Alias], dbo.RR_Inspections.RR_LoFPhys38 AS [LoFPhys 38 Alias], dbo.RR_Inspections.RR_LoFPhys39 AS [LoFPhys 39 Alias],
		dbo.RR_Inspections.RR_LoFPhys40 AS [LoFPhys 40 Alias], dbo.RR_Inspections.RR_LoFPhys41 AS [LoFPhys 41 Alias], dbo.RR_Inspections.RR_LoFPhys42 AS [LoFPhys 42 Alias],
		dbo.RR_Inspections.RR_LoFPhys43 AS [LoFPhys 43 Alias], dbo.RR_Inspections.RR_LoFPhys44 AS [LoFPhys 44 Alias], dbo.RR_Inspections.RR_LoFPhys45 AS [LoFPhys 45 Alias], 
		dbo.RR_Inspections.RR_LoFPhys46 AS [LoFPhys 46 Alias], dbo.RR_Inspections.RR_LoFPhys47 AS [LoFPhys 47 Alias], dbo.RR_Inspections.RR_LoFPhys48 AS [LoFPhys 48 Alias], 
		dbo.RR_Inspections.RR_LoFPhys49 AS [LoFPhys 49 Alias], dbo.RR_Inspections.RR_LoFPhys50 AS [LoFPhys 50 Alias]
FROM	dbo.RR_Hierarchy AS RR_Hierarchy_4 LEFT OUTER JOIN
		dbo.RR_Hierarchy AS RR_Hierarchy_3 LEFT OUTER JOIN
		dbo.RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_3.RR_Parent_ID = RR_Hierarchy_2.RR_Hierarchy_ID LEFT OUTER JOIN
		dbo.RR_Hierarchy RIGHT OUTER JOIN
		dbo.RR_Hierarchy AS RR_Hierarchy_1 ON dbo.RR_Hierarchy.RR_Hierarchy_ID = RR_Hierarchy_1.RR_Parent_ID ON RR_Hierarchy_2.RR_Parent_ID = RR_Hierarchy_1.RR_Hierarchy_ID ON 
		RR_Hierarchy_4.RR_Parent_ID = RR_Hierarchy_3.RR_Hierarchy_ID RIGHT OUTER JOIN
		dbo.v__ActiveAssets INNER JOIN
		dbo.RR_Cohorts ON dbo.v__ActiveAssets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID LEFT OUTER JOIN
		dbo.RR_Inspections ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.RR_Inspections.RR_Asset_ID ON RR_Hierarchy_4.RR_Hierarchy_ID = dbo.v__ActiveAssets.RR_Hierarchy_ID
WHERE	(dbo.v__ActiveAssets.RR_Status = 1)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_HierarchyPerfCondCoF]
AS
SELECT	Level1, Level2, Level3, Level4, Asset, InstallYear, 
		RR_CoF01 AS [CoF 01 Alias], RR_CoF02 AS [CoF 02 Alias], RR_CoF03 AS [CoF 03 Alias], RR_CoF04 AS [CoF 04 Alias], RR_CoF05 AS [CoF 05 Alias], 
		RR_CoF06 AS [CoF 06 Alias], RR_CoF07 AS [CoF 07 Alias], RR_CoF08 AS [CoF 08 Alias], RR_CoF09 AS [CoF 09 Alias], RR_CoF10 AS [CoF 10 Alias], 
		RR_CoF11 AS [CoF 11 Alias], RR_CoF12 AS [CoF 12 Alias], RR_CoF13 AS [CoF 13 Alias], RR_CoF14 AS [CoF 14 Alias], RR_CoF15 AS [CoF 15 Alias],
		RR_CoF16 AS [CoF 16 Alias], RR_CoF17 AS [CoF 17 Alias], RR_CoF18 AS [CoF 18 Alias], RR_CoF19 AS [CoF 19 Alias], RR_CoF20 AS [CoF 20 Alias], 
		RR_LoFPerf01 AS [LoFPerf 01 Alias], RR_LoFPerf02 AS [LoFPerf 02 Alias], RR_LoFPerf03 AS [LoFPerf 03 Alias], RR_LoFPerf04 AS [LoFPerf 04 Alias], RR_LoFPerf05 AS [LoFPerf 05 Alias], 
		RR_LoFPerf06 AS [LoFPerf 06 Alias], RR_LoFPerf07 AS [LoFPerf 07 Alias], RR_LoFPerf08 AS [LoFPerf 08 Alias], RR_LoFPerf09 AS [LoFPerf 09 Alias], RR_LoFPerf10 AS [LoFPerf 10 Alias],
		RR_LoFPerfComment AS [Perf Comment], RR_CoFComment AS [CoF Comment], LoFPerf, LoFPhys, RR_RedundancyFactor AS Redundancy, CoF, CoF_R, Risk, AssetID, FacilityID
FROM	dbo.v_QC_Hierarchy_Union
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07e_LastInspection]
AS
SELECT        RR_Asset_ID, MAX(RR_InspectionDate) AS MaxInspectionDate
FROM            dbo.RR_Inspections
WHERE        (RR_CompleteInspection = 1)
GROUP BY RR_Asset_ID
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v__Inspections]
AS
SELECT	RR_Inspection_ID, v__ActiveAssets.RR_Asset_ID, v__ActiveAssets.RR_SourceTxt_ID, v__ActiveAssets.RR_SourceNum_ID, RR_InspectionDate, Phys.RR_InspectionType, RR_CompleteInspection, Phys.RR_Fulcrum_ID, 
		v__ActiveAssets.RR_LoFInspection, v__ActiveAssets.RR_LoFPhysMaxCriteria, v__ActiveAssets.RR_OM, v__ActiveAssets.RR_OMMaxCriteria, RR_LoFPhys01, RR_LoFPhys01  AS [LoFPhys 01 Alias], RR_LoFPhys02, 
		RR_LoFPhys02 AS [LoFPhys 02 Alias], RR_LoFPhys03, RR_LoFPhys03 AS [LoFPhys 03 Alias], RR_LoFPhys04, RR_LoFPhys04 AS [LoFPhys 04 Alias], RR_LoFPhys05, RR_LoFPhys05 AS [LoFPhys 05 Alias], RR_LoFPhys06, 
		RR_LoFPhys06 AS [LoFPhys 06 Alias], RR_LoFPhys07, RR_LoFPhys07 AS [LoFPhys 07 Alias], RR_LoFPhys08, RR_LoFPhys08 AS [LoFPhys 08 Alias], RR_LoFPhys09, RR_LoFPhys09 AS [LoFPhys 09 Alias], RR_LoFPhys10, 
		RR_LoFPhys10 AS [LoFPhys 10 Alias], RR_LoFPhys11, RR_LoFPhys11 AS [LoFPhys 11 Alias], RR_LoFPhys12, RR_LoFPhys12 AS [LoFPhys 12 Alias], RR_LoFPhys13, RR_LoFPhys13 AS [LoFPhys 13 Alias], RR_LoFPhys14, 
		RR_LoFPhys14 AS [LoFPhys 14 Alias], RR_LoFPhys15, RR_LoFPhys15 AS [LoFPhys 15 Alias], RR_LoFPhys16, RR_LoFPhys16 AS [LoFPhys 16 Alias], RR_LoFPhys17, RR_LoFPhys17 AS [LoFPhys 17 Alias], RR_LoFPhys18, 
		RR_LoFPhys18 AS [LoFPhys 18 Alias], RR_LoFPhys19, RR_LoFPhys19 AS [LoFPhys 19 Alias], RR_LoFPhys20, RR_LoFPhys20 AS [LoFPhys 20 Alias], RR_LoFPhys21, RR_LoFPhys21 AS [LoFPhys 21 Alias], RR_LoFPhys22, 
		RR_LoFPhys22 AS [LoFPhys 22 Alias], RR_LoFPhys23, RR_LoFPhys23 AS [LoFPhys 23 Alias], RR_LoFPhys24, RR_LoFPhys24 AS [LoFPhys 24 Alias], RR_LoFPhys25, RR_LoFPhys25 AS [LoFPhys 25 Alias], RR_LoFPhys26, 
		RR_LoFPhys26 AS [LoFPhys 26 Alias], RR_LoFPhys27, RR_LoFPhys27 AS [LoFPhys 27 Alias], RR_LoFPhys28, RR_LoFPhys28 AS [LoFPhys 28 Alias], RR_LoFPhys29, RR_LoFPhys29 AS [LoFPhys 29 Alias], RR_LoFPhys30, 
		RR_LoFPhys30 AS [LoFPhys 30 Alias], RR_LoFPhys31, RR_LoFPhys31 AS [LoFPhys 31 Alias], RR_LoFPhys32, RR_LoFPhys32 AS [LoFPhys 32 Alias], RR_LoFPhys33, RR_LoFPhys33 AS [LoFPhys 33 Alias], RR_LoFPhys34, 
		RR_LoFPhys34 AS [LoFPhys 34 Alias], RR_LoFPhys35, RR_LoFPhys35 AS [LoFPhys 35 Alias], RR_LoFPhys36, RR_LoFPhys36 AS [LoFPhys 36 Alias], RR_LoFPhys37, RR_LoFPhys37 AS [LoFPhys 37 Alias], RR_LoFPhys38, 
		RR_LoFPhys38 AS [LoFPhys 38 Alias], RR_LoFPhys39, RR_LoFPhys39 AS [LoFPhys 39 Alias], RR_LoFPhys40, RR_LoFPhys40 AS [LoFPhys 40 Alias], RR_LoFPhys41, RR_LoFPhys41 AS [LoFPhys 41 Alias], RR_LoFPhys42, 
		RR_LoFPhys42 AS [LoFPhys 42 Alias], RR_LoFPhys43, RR_LoFPhys43 AS [LoFPhys 43 Alias], RR_LoFPhys44, RR_LoFPhys44 AS [LoFPhys 44 Alias], RR_LoFPhys45, RR_LoFPhys45 AS [LoFPhys 45 Alias], RR_LoFPhys46, 
		RR_LoFPhys46 AS [LoFPhys 46 Alias], RR_LoFPhys47, RR_LoFPhys47 AS [LoFPhys 47 Alias], RR_LoFPhys48, RR_LoFPhys48 AS [LoFPhys 48 Alias], RR_LoFPhys49, RR_LoFPhys49 AS [LoFPhys 49 Alias], RR_LoFPhys50, 
		RR_LoFPhys50 AS [LoFPhys 50 Alias], RR_OM01, RR_OM01 AS [OM 01 Alias], RR_OM02, RR_OM02 AS [OM 02 Alias], RR_OM03, RR_OM03 AS [OM 03 Alias], RR_OM04, RR_OM04 AS [OM 04 Alias], RR_OM05, 
		RR_OM05 AS [OM 05 Alias], RR_OM06, RR_OM06 AS [OM 06 Alias], RR_OM07, RR_OM07 AS [OM 07 Alias], RR_OM08, RR_OM08 AS [OM 08 Alias], RR_OM09, RR_OM09 AS [OM 09 Alias], RR_OM10, 
		RR_OM10 AS [OM 10 Alias], RR_OM11, RR_OM11 AS [OM 11 Alias], RR_OM12, RR_OM12 AS [OM 12 Alias], RR_OM13, RR_OM13 AS [OM 13 Alias], RR_OM14, RR_OM14 AS [OM 14 Alias], RR_OM15, 
		RR_OM15 AS [OM 15 Alias], RR_OM16, RR_OM16 AS [OM 16 Alias], RR_OM17, RR_OM17 AS [OM 17 Alias], RR_OM18, RR_OM18 AS [OM 18 Alias], RR_OM19, RR_OM19 AS [OM 19 Alias], RR_OM20, 
		RR_OM20 AS [OM 20 Alias], RR_OM21, RR_OM21 AS [OM 21 Alias], RR_OM22, RR_OM22 AS [OM 22 Alias], RR_OM23, RR_OM23 AS [OM 23 Alias], RR_OM24, RR_OM24 AS [OM 24 Alias], RR_OM25, 
		RR_OM25 AS [OM 25 Alias], RR_OM26, RR_OM26 AS [OM 26 Alias], RR_OM27, RR_OM27 AS [OM 27 Alias], RR_OM28, RR_OM28 AS [OM 28 Alias], RR_OM29, RR_OM29 AS [OM 29 Alias], RR_OM30, 
		RR_OM30 AS [OM 30 Alias], RR_OM31, RR_OM31 AS [OM 31 Alias], RR_OM32, RR_OM32 AS [OM 32 Alias], RR_OM33, RR_OM33 AS [OM 33 Alias], RR_OM34, RR_OM34 AS [OM 34 Alias], RR_OM35, 
		RR_OM35 AS [OM 35 Alias], RR_OM36, RR_OM36 AS [OM 36 Alias], RR_OM37, RR_OM37 AS [OM 37 Alias], RR_OM38, RR_OM38 AS [OM 38 Alias], RR_OM39, RR_OM39 AS [OM 39 Alias], RR_OM40, 
		RR_OM40 AS [OM 40 Alias], RR_OM41, RR_OM41 AS [OM 41 Alias], RR_OM42, RR_OM42 AS [OM 42 Alias], RR_OM43, RR_OM43 AS [OM 43 Alias], RR_OM44, RR_OM44 AS [OM 44 Alias], RR_OM45, 
		RR_OM45 AS [OM 45 Alias], RR_OM46, RR_OM46 AS [OM 46 Alias], RR_OM47, RR_OM47 AS [OM 47 Alias], RR_OM48, RR_OM48 AS [OM 48 Alias], RR_OM49, RR_OM49 AS [OM 49 Alias], RR_OM50, 
		RR_OM50 AS [OM 50 Alias], RR_InspectNotes
FROM	dbo.v__ActiveAssets INNER JOIN
		dbo.v_00_07e_LastInspection ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.v_00_07e_LastInspection.RR_Asset_ID INNER JOIN
		dbo.RR_Inspections AS Phys ON dbo.v_00_07e_LastInspection.RR_Asset_ID = Phys.RR_Asset_ID AND dbo.v_00_07e_LastInspection.MaxInspectionDate = Phys.RR_InspectionDate
WHERE	(Phys.RR_CompleteInspection = 1)
GO


CREATE VIEW [dbo].[v_PBI_CoF_Thresholds]
AS
SELECT        Criticality AS CoF, Description, LowRepair AS [Start Repair Physical], LowRehab AS [Start Rehab Physical], LowReplace AS [Start Replace Physical], PerformanceReplace AS [Start Replace Performance]
FROM            dbo.RR_CriticalityActionLimits
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Cohorts]
AS
SELECT        dbo.RR_Cohorts.CohortName AS [Cohort Name], dbo.RR_Cohorts.InitEUL AS EUL, dbo.RR_Cohorts.ReplaceEUL, SUM(1) AS [Asset Count], dbo.RR_Cohorts.Materials, dbo.RR_Cohorts.AssetType, dbo.RR_Cohorts.MinDia, 
                         dbo.RR_Cohorts.MaxDia, dbo.RR_Cohorts.MinYear, dbo.RR_Cohorts.MaxYear, dbo.RR_Cohorts.AssetType AS [Asset Type]
FROM            dbo.RR_Assets INNER JOIN
                         dbo.RR_Cohorts ON dbo.RR_Assets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID
WHERE        (dbo.RR_Assets.RR_Status = 1)
GROUP BY dbo.RR_Cohorts.CohortName, dbo.RR_Cohorts.Materials, dbo.RR_Cohorts.AssetType, dbo.RR_Cohorts.InitEUL, dbo.RR_Cohorts.MinDia, dbo.RR_Cohorts.MaxDia, dbo.RR_Cohorts.MinYear, dbo.RR_Cohorts.MaxYear, 
                         dbo.RR_Cohorts.ReplaceEUL
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Config]
AS
SELECT        Version AS [RRPS Version], ProjectName AS [Project Name], ProjectVersion AS [Project Version], ConditionLimit AS [Condition Limit], CostMultiplier AS [Cost Multiplier], RehabPercentEUL AS [Rehab Percent EUL], 
                         MapDocument AS [Map Document], HyperlinkFolder AS [Hyperlink Folder], { fn NOW() } AS [PBI Refreshed], BaselineYear, ConfigNotes, ConditionFailureFactor AS [Failure Factor], RehabsAllowed AS [Rehabs Allowed]
FROM            dbo.RR_Config
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_GenCosts]
AS
SELECT dbo.RR_AssetCosts.Description AS [Gen Cost Category], dbo.RR_AssetCosts.CostRepair AS [Gen Cost Repair], dbo.RR_AssetCosts.CostRehab AS [Gen Cost Rehab], dbo.RR_AssetCosts.CostReplacement AS [Gen Cost Replace], 
                  dbo.RR_Config.CostMultiplier AS [Cost Multiplier], ROUND(dbo.RR_AssetCosts.CostRehab * dbo.RR_Config.CostMultiplier, 0) AS [Gen Project Cost Rehab], ROUND(dbo.RR_AssetCosts.CostReplacement * dbo.RR_Config.CostMultiplier, 0) 
                  AS [Gen Project Cost Replace], dbo.RR_AssetCosts.MinDia, dbo.RR_AssetCosts.MaxDia
FROM     dbo.RR_AssetCosts CROSS JOIN
                  dbo.RR_Config
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Scenarios]
AS
SELECT        Scenario_ID AS [Scenario ID], ScenarioName AS [Scenario Name], Description, LastRun AS [Last Run]
FROM            dbo.RR_Scenarios
WHERE        (PBI_Flag = 1)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_CoF_ByCat]
AS
SELECT	RR_Asset_ID, 'CoF 01 Alias' AS Category, Abs(RR_CoF01) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF01, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 02 Alias' AS Category, Abs(RR_CoF02) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF02, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 03 Alias' AS Category, Abs(RR_CoF03) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF03, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 04 Alias' AS Category, Abs(RR_CoF04) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF04, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 05 Alias' AS Category, Abs(RR_CoF05) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF05, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 06 Alias' AS Category, Abs(RR_CoF06) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF06, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 07 Alias' AS Category, Abs(RR_CoF07) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF07, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 08 Alias' AS Category, Abs(RR_CoF08) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF08, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 09 Alias' AS Category, Abs(RR_CoF09) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF09, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 10 Alias' AS Category, Abs(RR_CoF10) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF10, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 11 Alias' AS Category, Abs(RR_CoF11) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF11, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 12 Alias' AS Category, Abs(RR_CoF12) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF12, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 13 Alias' AS Category, Abs(RR_CoF13) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF13, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 14 Alias' AS Category, Abs(RR_CoF14) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF14, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 15 Alias' AS Category, Abs(RR_CoF15) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF15, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 16 Alias' AS Category, Abs(RR_CoF16) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF16, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 17 Alias' AS Category, Abs(RR_CoF17) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF17, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 18 Alias' AS Category, Abs(RR_CoF18) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF18, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 19 Alias' AS Category, Abs(RR_CoF19) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF19, 0) <> 0
UNION ALL
SELECT	RR_Asset_ID, 'CoF 20 Alias' AS Category, Abs(RR_CoF20) AS Val, RR_Division AS Level1, RR_Facility AS Level2, RR_Process AS Level3, RR_Group AS Level4, RR_AssetName, RR_AssetType, RR_Length / 5280 AS Weight
FROM	v__ActiveAssets
WHERE	ISNULL(RR_CoF20, 0) <> 0
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Physical]
AS
SELECT	dbo.RR_Inspections.RR_Asset_ID, dbo.RR_Inspections.RR_SourceTxt_ID, dbo.RR_Inspections.RR_Fulcrum_ID, dbo.RR_Inspections.RR_InspectionType, 
		dbo.RR_Inspections.RR_InspectionDate, dbo.RR_Inspections.RR_CompleteInspection, dbo.RR_Inspections.RR_InspectNotes,
		dbo.RR_Inspections.RR_LoFPhys01, dbo.RR_Inspections.RR_LoFPhys02, dbo.RR_Inspections.RR_LoFPhys03, dbo.RR_Inspections.RR_LoFPhys04, dbo.RR_Inspections.RR_LoFPhys05, 
		dbo.RR_Inspections.RR_LoFPhys06, dbo.RR_Inspections.RR_LoFPhys07, dbo.RR_Inspections.RR_LoFPhys08, dbo.RR_Inspections.RR_LoFPhys09, dbo.RR_Inspections.RR_LoFPhys10,
		dbo.RR_Inspections.RR_LoFPhys11, dbo.RR_Inspections.RR_LoFPhys12, dbo.RR_Inspections.RR_LoFPhys13, dbo.RR_Inspections.RR_LoFPhys14, dbo.RR_Inspections.RR_LoFPhys15, 
		dbo.RR_Inspections.RR_LoFPhys16, dbo.RR_Inspections.RR_LoFPhys17, dbo.RR_Inspections.RR_LoFPhys18, dbo.RR_Inspections.RR_LoFPhys19, dbo.RR_Inspections.RR_LoFPhys20, 
		dbo.RR_Inspections.RR_LoFPhys21, dbo.RR_Inspections.RR_LoFPhys22, dbo.RR_Inspections.RR_LoFPhys23, dbo.RR_Inspections.RR_LoFPhys24, dbo.RR_Inspections.RR_LoFPhys25, 
		dbo.RR_Inspections.RR_LoFPhys26, dbo.RR_Inspections.RR_LoFPhys27, dbo.RR_Inspections.RR_LoFPhys28, dbo.RR_Inspections.RR_LoFPhys29, dbo.RR_Inspections.RR_LoFPhys30, 
		dbo.RR_Inspections.RR_LoFPhys31, dbo.RR_Inspections.RR_LoFPhys32, dbo.RR_Inspections.RR_LoFPhys33, dbo.RR_Inspections.RR_LoFPhys34, dbo.RR_Inspections.RR_LoFPhys35, 
		dbo.RR_Inspections.RR_LoFPhys36, dbo.RR_Inspections.RR_LoFPhys37, dbo.RR_Inspections.RR_LoFPhys38, dbo.RR_Inspections.RR_LoFPhys39, dbo.RR_Inspections.RR_LoFPhys40,
		dbo.RR_Inspections.RR_LoFPhys41, dbo.RR_Inspections.RR_LoFPhys42, dbo.RR_Inspections.RR_LoFPhys43, dbo.RR_Inspections.RR_LoFPhys44, dbo.RR_Inspections.RR_LoFPhys45,
		dbo.RR_Inspections.RR_LoFPhys46, dbo.RR_Inspections.RR_LoFPhys47, dbo.RR_Inspections.RR_LoFPhys48, dbo.RR_Inspections.RR_LoFPhys49, dbo.RR_Inspections.RR_LoFPhys50
FROM	dbo.v__ActiveAssets INNER JOIN
		dbo.v_00_07e_LastInspection ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.v_00_07e_LastInspection.RR_Asset_ID INNER JOIN
		dbo.RR_Inspections ON dbo.v_00_07e_LastInspection.RR_Asset_ID = dbo.RR_Inspections.RR_Asset_ID AND dbo.v_00_07e_LastInspection.MaxInspectionDate = dbo.RR_Inspections.RR_InspectionDate
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Physical_ByCat]
AS
SELECT        RR_Asset_ID, 'LoFPhys 01 Alias' AS PhysCat, RR_LoFPhys01 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 02 Alias' AS PhysCat, RR_LoFPhys02 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 03 Alias' AS PhysCat, RR_LoFPhys03 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 04 Alias' AS PhysCat, RR_LoFPhys04 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 05 Alias' AS PhysCat, RR_LoFPhys05 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 06 Alias' AS PhysCat, RR_LoFPhys06 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 07 Alias' AS PhysCat, RR_LoFPhys07 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 08 Alias' AS PhysCat, RR_LoFPhys08 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 09 Alias' AS PhysCat, RR_LoFPhys09 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 10 Alias' AS PhysCat, RR_LoFPhys10 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 11 Alias' AS PhysCat, RR_LoFPhys11 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 12 Alias' AS PhysCat, RR_LoFPhys12 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 13 Alias' AS PhysCat, RR_LoFPhys13 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 14 Alias' AS PhysCat, RR_LoFPhys14 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 15 Alias' AS PhysCat, RR_LoFPhys15 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 16 Alias' AS PhysCat, RR_LoFPhys16 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 17 Alias' AS PhysCat, RR_LoFPhys17 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 18 Alias' AS PhysCat, RR_LoFPhys18 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 19 Alias' AS PhysCat, RR_LoFPhys19 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 20 Alias' AS PhysCat, RR_LoFPhys20 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 21 Alias' AS PhysCat, RR_LoFPhys21 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 22 Alias' AS PhysCat, RR_LoFPhys22 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 23 Alias' AS PhysCat, RR_LoFPhys23 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 24 Alias' AS PhysCat, RR_LoFPhys24 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 25 Alias' AS PhysCat, RR_LoFPhys25 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 26 Alias' AS PhysCat, RR_LoFPhys26 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 27 Alias' AS PhysCat, RR_LoFPhys27 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 28 Alias' AS PhysCat, RR_LoFPhys28 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 29 Alias' AS PhysCat, RR_LoFPhys29 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 30 Alias' AS PhysCat, RR_LoFPhys30 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 31 Alias' AS PhysCat, RR_LoFPhys31 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 32 Alias' AS PhysCat, RR_LoFPhys32 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 33 Alias' AS PhysCat, RR_LoFPhys33 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 34 Alias' AS PhysCat, RR_LoFPhys34 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 35 Alias' AS PhysCat, RR_LoFPhys35 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 36 Alias' AS PhysCat, RR_LoFPhys36 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 37 Alias' AS PhysCat, RR_LoFPhys37 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 38 Alias' AS PhysCat, RR_LoFPhys38 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 39 Alias' AS PhysCat, RR_LoFPhys39 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 40 Alias' AS PhysCat, RR_LoFPhys40 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 41 Alias' AS PhysCat, RR_LoFPhys41 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 42 Alias' AS PhysCat, RR_LoFPhys42 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 43 Alias' AS PhysCat, RR_LoFPhys43 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 44 Alias' AS PhysCat, RR_LoFPhys44 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 45 Alias' AS PhysCat, RR_LoFPhys45 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 46 Alias' AS PhysCat, RR_LoFPhys46 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 47 Alias' AS PhysCat, RR_LoFPhys47 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 48 Alias' AS PhysCat, RR_LoFPhys48 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 49 Alias' AS PhysCat, RR_LoFPhys49 AS MaxVal
FROM            v_PBI_Physical
UNION ALL
SELECT        RR_Asset_ID, 'LoFPhys 50 Alias' AS PhysCat, RR_LoFPhys50 AS MaxVal
FROM            v_PBI_Physical
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_PBI_Hyperlinks]
AS
SELECT        RR_Asset_ID, MIN(FileHyperlink) AS FirstOfFileHyperlink
FROM            dbo.RR_Hyperlinks
GROUP BY RR_Asset_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_00_07d_PhysOMScores]
AS
SELECT	dbo.RR_Inspections.RR_Asset_ID, dbo.RR_Inspections.RR_CompleteInspection, dbo.RR_Inspections.RR_InspectionDate, dbo.RR_Inspections.RR_InspectionType,
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys01)) AS Phys1, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys02)) AS Phys2, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys03)) AS Phys3, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys04)) AS Phys4, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys05)) AS Phys5, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys06)) AS Phys6, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys07)) AS Phys7, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys08)) AS Phys8, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys09)) AS Phys9, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys10)) AS Phys10, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys11)) AS Phys11, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys12)) AS Phys12, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys13)) AS Phys13, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys14)) AS Phys14, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys15)) AS Phys15, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys16)) AS Phys16, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys17)) AS Phys17, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys18)) AS Phys18, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys19)) AS Phys19, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys20)) AS Phys20, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys21)) AS Phys21, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys22)) AS Phys22, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys23)) AS Phys23, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys24)) AS Phys24, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys25)) AS Phys25, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys26)) AS Phys26, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys27)) AS Phys27, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys28)) AS Phys28, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys29)) AS Phys29, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys30)) AS Phys30, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys31)) AS Phys31, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys32)) AS Phys32, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys33)) AS Phys33, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys34)) AS Phys34, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys35)) AS Phys35, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys36)) AS Phys36, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys37)) AS Phys37, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys38)) AS Phys38, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys39)) AS Phys39, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys40)) AS Phys40, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys41)) AS Phys41, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys42)) AS Phys42, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys43)) AS Phys43, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys44)) AS Phys44, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys45)) AS Phys45, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys46)) AS Phys46, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys47)) AS Phys47, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys48)) AS Phys48, 
		MAX(ABS(dbo.RR_Inspections.RR_LoFPhys49)) AS Phys49, MAX(ABS(dbo.RR_Inspections.RR_LoFPhys50)) AS Phys50, 
		MAX(ABS(dbo.RR_Inspections.RR_OM01)) AS OM1, MAX(ABS(dbo.RR_Inspections.RR_OM02)) AS OM2, MAX(ABS(dbo.RR_Inspections.RR_OM03)) AS OM3, 
		MAX(ABS(dbo.RR_Inspections.RR_OM04)) AS OM4, MAX(ABS(dbo.RR_Inspections.RR_OM05)) AS OM5, MAX(ABS(dbo.RR_Inspections.RR_OM06)) AS OM6, 
		MAX(ABS(dbo.RR_Inspections.RR_OM07)) AS OM7, MAX(ABS(dbo.RR_Inspections.RR_OM08)) AS OM8, MAX(ABS(dbo.RR_Inspections.RR_OM09)) AS OM9, 
		MAX(ABS(dbo.RR_Inspections.RR_OM10)) AS OM10, MAX(ABS(dbo.RR_Inspections.RR_OM11)) AS OM11, MAX(ABS(dbo.RR_Inspections.RR_OM12)) AS OM12, 
		MAX(ABS(dbo.RR_Inspections.RR_OM13)) AS OM13, MAX(ABS(dbo.RR_Inspections.RR_OM14)) AS OM14, MAX(ABS(dbo.RR_Inspections.RR_OM15)) AS OM15, 
		MAX(ABS(dbo.RR_Inspections.RR_OM16)) AS OM16, MAX(ABS(dbo.RR_Inspections.RR_OM17)) AS OM17, MAX(ABS(dbo.RR_Inspections.RR_OM18)) AS OM18, 
		MAX(ABS(dbo.RR_Inspections.RR_OM19)) AS OM19, MAX(ABS(dbo.RR_Inspections.RR_OM20)) AS OM20, MAX(ABS(dbo.RR_Inspections.RR_OM21)) AS OM21, 
		MAX(ABS(dbo.RR_Inspections.RR_OM22)) AS OM22, MAX(ABS(dbo.RR_Inspections.RR_OM23)) AS OM23, MAX(ABS(dbo.RR_Inspections.RR_OM24)) AS OM24, 
		MAX(ABS(dbo.RR_Inspections.RR_OM25)) AS OM25, MAX(ABS(dbo.RR_Inspections.RR_OM26)) AS OM26, MAX(ABS(dbo.RR_Inspections.RR_OM27)) AS OM27, 
		MAX(ABS(dbo.RR_Inspections.RR_OM28)) AS OM28, MAX(ABS(dbo.RR_Inspections.RR_OM29)) AS OM29, MAX(ABS(dbo.RR_Inspections.RR_OM30)) AS OM30, 
		MAX(ABS(dbo.RR_Inspections.RR_OM31)) AS OM31, MAX(ABS(dbo.RR_Inspections.RR_OM32)) AS OM32, MAX(ABS(dbo.RR_Inspections.RR_OM33)) AS OM33, 
		MAX(ABS(dbo.RR_Inspections.RR_OM34)) AS OM34, MAX(ABS(dbo.RR_Inspections.RR_OM35)) AS OM35, MAX(ABS(dbo.RR_Inspections.RR_OM36)) AS OM36, 
		MAX(ABS(dbo.RR_Inspections.RR_OM37)) AS OM37, MAX(ABS(dbo.RR_Inspections.RR_OM38)) AS OM38, MAX(ABS(dbo.RR_Inspections.RR_OM39)) AS OM39,
		MAX(ABS(dbo.RR_Inspections.RR_OM40)) AS OM40, MAX(ABS(dbo.RR_Inspections.RR_OM41)) AS OM41, MAX(ABS(dbo.RR_Inspections.RR_OM42)) AS OM42, 
		MAX(ABS(dbo.RR_Inspections.RR_OM43)) AS OM43, MAX(ABS(dbo.RR_Inspections.RR_OM44)) AS OM44, MAX(ABS(dbo.RR_Inspections.RR_OM45)) AS OM45, 
		MAX(ABS(dbo.RR_Inspections.RR_OM46)) AS OM46, MAX(ABS(dbo.RR_Inspections.RR_OM47)) AS OM47, MAX(ABS(dbo.RR_Inspections.RR_OM48)) AS OM48, 
		MAX(ABS(dbo.RR_Inspections.RR_OM49)) AS OM49, MAX(ABS(dbo.RR_Inspections.RR_OM50)) AS OM50
FROM	dbo.RR_Inspections INNER JOIN
		dbo.v_00_07e_LastInspection ON dbo.RR_Inspections.RR_Asset_ID = dbo.v_00_07e_LastInspection.RR_Asset_ID AND dbo.RR_Inspections.RR_InspectionDate = dbo.v_00_07e_LastInspection.MaxInspectionDate
GROUP BY dbo.RR_Inspections.RR_Asset_ID, dbo.RR_Inspections.RR_InspectionDate, dbo.RR_Inspections.RR_InspectionType, dbo.RR_Inspections.RR_CompleteInspection
HAVING	(dbo.RR_Inspections.RR_CompleteInspection = 1);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07c_MaxPhysOM] AS 
SELECT  RR_Asset_ID, RR_InspectionDate, RR_InspectionType, RR_CompleteInspection, 
		CASE WHEN RR_CompleteInspection = 0 THEN 0 
			ELSE	(SELECT MAX(myval) 
					FROM	(VALUES (0), (Phys1), (Phys2), (Phys3), (Phys4), (Phys5), (Phys6), (Phys7), (Phys8), (Phys9), (Phys10), 
							(Phys11), (Phys12), (Phys13), (Phys14), (Phys15), (Phys16), (Phys17), (Phys18), (Phys19), (Phys20), 
							(Phys21), (Phys22), (Phys23), (Phys24), (Phys25), (Phys26), (Phys27), (Phys28), (Phys29), (Phys30), 
							(Phys31), (Phys32), (Phys33), (Phys34), (Phys35), (Phys36), (Phys37), (Phys38), (Phys39), (Phys40),
							(Phys41), (Phys42), (Phys43), (Phys44), (Phys45), (Phys46), (Phys47), (Phys48), (Phys49), (Phys40)
							) AS D(myval))
		END AS 'MaxPhys', 
		(SELECT MAX(myval) 
		FROM	(VALUES (0), (OM1), (OM2), (OM3), (OM4), (OM5), (OM6), (OM7), (OM8), (OM9), (OM10), 
				(OM11), (OM12), (OM13), (OM14), (OM15), (OM16), (OM17), (OM18), (OM19), (OM20), 
				(OM21), (OM22), (OM23), (OM24), (OM25), (OM26), (OM27), (OM28), (OM29), (OM30), 
				(OM31), (OM32), (OM33), (OM34), (OM35), (OM36), (OM37), (OM38), (OM39), (OM40), 
				(OM41), (OM42), (OM43), (OM44), (OM45), (OM46), (OM47), (OM48), (OM49), (OM50)) AS D(myval)) AS 'MaxOM' 
FROM	v_00_07d_PhysOMScores
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [v_00_07d_CoFPerfScores]
AS
SELECT	RR_Asset_ID,
		ABS(RR_CoF01) AS CoF1, ABS(RR_CoF02) AS CoF2, ABS(RR_CoF03) AS CoF3, ABS(RR_CoF04) AS CoF4, ABS(RR_CoF05) AS CoF5, 
		ABS(RR_CoF06) AS CoF6, ABS(RR_CoF07) AS CoF7, ABS(RR_CoF08) AS CoF8, ABS(RR_CoF09) AS CoF9, ABS(RR_CoF10) AS CoF10, 
		ABS(RR_CoF11) AS CoF11, ABS(RR_CoF12) AS CoF12, ABS(RR_CoF13) AS CoF13, ABS(RR_CoF14) AS CoF14, ABS(RR_CoF15) AS CoF15,
		ABS(RR_CoF16) AS CoF16, ABS(RR_CoF17) AS CoF17, ABS(RR_CoF18) AS CoF18, ABS(RR_CoF19) AS CoF19, ABS(RR_CoF20) AS CoF20,
		ABS(RR_LoFPerf01) AS Perf1, ABS(RR_LoFPerf02) AS Perf2, ABS(RR_LoFPerf03) AS Perf3, ABS(RR_LoFPerf04) AS Perf4, ABS(RR_LoFPerf05) AS Perf5, 
		ABS(RR_LoFPerf06) AS Perf6, ABS(RR_LoFPerf07) AS Perf7, ABS(RR_LoFPerf08) AS Perf8, ABS(RR_LoFPerf09) AS Perf9, ABS(RR_LoFPerf10) AS Perf10
FROM	dbo.v__ActiveAssets;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE   VIEW [dbo].[v_00_07c_MaxCoFPerf]
AS
SELECT	RR_Asset_ID,
		(SELECT	MAX(myval)
		FROM	(VALUES (1), (CoF1), (CoF2), (CoF3), (CoF4), (CoF5), (CoF6), (CoF7), (CoF8), (CoF9), (CoF10), (CoF11), (CoF12), (CoF13), (CoF14), (CoF15), (CoF16), (CoF17), (CoF18), (CoF19), (CoF20)) AS D (myval)) AS 'MaxCoF',
		(SELECT	MAX(myval)
		FROM	(VALUES (1), (Perf1), (Perf2), (Perf3), (Perf4), (Perf5), (Perf6), (Perf7), (Perf8), (Perf9), (Perf10)) AS D (myval)) AS 'MaxPerf'
FROM            v_00_07d_CoFPerfScores
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_60_LEYP_Assets_All]
AS
SELECT        1 AS Sort_Order, 'IDT' AS ID, 'IDR' AS Net, 'DDP' AS InstallDate, 'DHS' AS AbandonedDate, 'DIAM' AS Dia, 'LNG' AS Len, 'MAT' AS Matl, 'OWNER' AS Owner, 'PrevMatl' AS PrevMatl, CAST('01/01/2020' AS Date) AS InstallDt, 
                         CAST('01/01/2020' AS Date) AS AbandonedDt
FROM            RR_Config
UNION
SELECT        2 AS Sort_Order, 'PIPE_ID' AS ID, 'Network' AS Net, 'DATE_LAID' AS InstallDAte, 'DATE_REMOVED' AS AbandonedDate, 'DIAMETER' AS Dia, 'PIPE_LENGTH' AS Len, 'MATERIAL' AS Matl, 'OWNER' AS Owner, NULL AS PrevMatl, 
                         CAST('01/01/2020' AS Date) AS InstallDt, CAST('01/01/2020' AS Date) AS AbandonedDt
FROM            RR_Config
UNION
SELECT        3 AS Sort_Order, NULL AS ID, 'QUAL' AS Net, 'DATE' AS InstallDate, 'DATE' AS AbandonedDate, 'QUAN' AS Dia, 'QUAN' AS Len, 'QUAL' AS Matl, 'QUAL' AS Owner, NULL AS PrevMatl, CAST('01/01/2020' AS Date) AS InstallDt, 
                         CAST('01/01/2020' AS Date) AS AbandonedDt
FROM            RR_Config
UNION
SELECT        4 AS Sort_Order, NULL AS ID, NULL AS Net, 'm/d/y' AS InstallDate, 'm/d/y' AS AbandonedDate, 'in' AS Dia, 'mi' AS Len, NULL AS Matl, NULL AS Owner, NULL AS PrevMatl, CAST('01/01/2020' AS Date) AS InstallDt, 
                         CAST('01/01/2020' AS Date) AS AbandonedDt
FROM            RR_Config
UNION
SELECT        5 AS Sort_Order, RR_SourceTxt_ID AS ID, 'Utility' AS Net, '01/01/' + CAST(RR_InstallYear AS varchar(4)) AS InstallDate, '01/01/' + CAST(RR_Decommissioned AS varchar(4)) AS AbandonedDate, CAST(RR_Diameter AS Varchar(6)) AS Dia, 
                         CAST(RR_Length / 5280 AS varchar(16)) AS Len, RR_Material AS Matl, 'Utility' AS Owner, RR_Material AS PrevMatl, CAST('01/01/' + CAST(RR_InstallYear AS varchar(4)) AS Date) AS InstallDt,  CAST('01/01/' + CAST(RR_Decommissioned AS varchar(4)) AS Date) AbandonedDt
FROM            RR_Assets
WHERE        'UPDATE TO CLIENT SPECIFIC CRITERIA' <> 'PROPOSED';
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07d_PhysEUL]
AS
SELECT        dbo.RR_Assets.RR_Asset_ID, dbo.RR_Assets.RR_CurveType, dbo.RR_Assets.RR_CurveIntercept, dbo.RR_Assets.RR_CurveSlope, dbo.RR_Config.BaselineYear, dbo.RR_Assets.RR_AgeOffset, dbo.RR_Assets.RR_InstallYear, 
                         dbo.RR_Config.BaselineYear - dbo.RR_Assets.RR_InstallYear AS Age, dbo.RR_Assets.RR_EUL, ROUND(dbo.RR_Assets.RR_FailurePhysOffset + dbo.f_RR_CurveCondition(dbo.RR_Assets.RR_CurveType, 
                         dbo.RR_Assets.RR_CurveIntercept, dbo.RR_Config.BaselineYear - dbo.RR_Assets.RR_InstallYear + dbo.RR_Assets.RR_AgeOffset, dbo.RR_Assets.RR_CurveSlope), 2) AS EULPhys, dbo.RR_Assets.RR_FailurePhysOffset, 
                         dbo.RR_Config.ConditionLimit, dbo.RR_Assets.RR_RedundancyFactor, dbo.RR_Assets.RR_Status
FROM            dbo.RR_Config INNER JOIN
                         dbo.RR_Assets ON dbo.RR_Config.ID = dbo.RR_Assets.RR_Config_ID
WHERE        (dbo.RR_Assets.RR_Status = 1)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07c_PhysEUL]
AS
SELECT        dbo.v_00_07d_PhysEUL.RR_Asset_ID, dbo.v_00_07d_PhysEUL.RR_InstallYear, dbo.v_00_07d_PhysEUL.Age, dbo.v_00_07d_PhysEUL.RR_AgeOffset, dbo.v_00_07d_PhysEUL.RR_FailurePhysOffset, 
                         ROUND(dbo.f_RR_CurveAge(dbo.v_00_07d_PhysEUL.RR_CurveType, dbo.v_00_07d_PhysEUL.RR_CurveIntercept, dbo.v_00_07d_PhysEUL.EULPhys, dbo.v_00_07d_PhysEUL.RR_CurveSlope), 1) AS ApparentAge, 
                         ROUND(dbo.v_00_07d_PhysEUL.RR_EUL, 1) AS InitEUL, dbo.v_00_07d_PhysEUL.RR_CurveType AS InitEquationType, dbo.v_00_07d_PhysEUL.RR_CurveIntercept AS InitConstIntercept, 
                         dbo.v_00_07d_PhysEUL.RR_CurveSlope AS InitExpSlope, CASE WHEN EULPhys > ConditionLimit THEN ConditionLimit ELSE EULPhys END AS EULPhysRaw, dbo.RR_Conditions.Condition_Score AS EULPhysScore, 
                         dbo.v_00_07d_PhysEUL.RR_RedundancyFactor
FROM            dbo.v_00_07d_PhysEUL INNER JOIN
                         dbo.RR_Conditions ON dbo.v_00_07d_PhysEUL.EULPhys >= dbo.RR_Conditions.MinRawCondition
WHERE        (dbo.v_00_07d_PhysEUL.EULPhys < dbo.RR_Conditions.MaxRawCondition) OR
                         (dbo.RR_Conditions.MaxRawCondition IS NULL)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07b_MaxCoFLoF]
AS
SELECT        dbo.v_00_07c_PhysEUL.RR_Asset_ID, dbo.v_00_07c_PhysEUL.RR_InstallYear, dbo.v_00_07c_PhysEUL.Age, dbo.v_00_07c_MaxPhysOM.MaxOM, dbo.v_00_07c_MaxCoFPerf.MaxPerf, dbo.v_00_07c_MaxPhysOM.MaxPhys, 
                         dbo.v_00_07c_PhysEUL.EULPhysRaw, dbo.v_00_07c_PhysEUL.EULPhysScore, CASE WHEN MaxPhys > 0 THEN 0 ELSE v_00_07c_PhysEUL.EULPhysRaw END AS EULPhys, 
                         CASE WHEN MaxPerf > EULPhysScore THEN MaxPerf ELSE EULPhysScore END AS MaxLoF, dbo.v_00_07c_MaxCoFPerf.MaxCoF, dbo.v_00_07c_PhysEUL.RR_RedundancyFactor, 
                         CASE WHEN MaxCoF * RR_RedundancyFactor < 0.5 THEN 1 ELSE ROUND(MaxCoF * RR_RedundancyFactor, 0) END AS MaxCoF_R, dbo.v_00_07c_PhysEUL.RR_FailurePhysOffset, dbo.v_00_07c_PhysEUL.RR_AgeOffset, 
                         dbo.v_00_07c_PhysEUL.ApparentAge, ROUND(dbo.v_00_07c_PhysEUL.InitEUL - dbo.v_00_07c_PhysEUL.ApparentAge, 1) AS RUL, dbo.v_00_07c_PhysEUL.InitEUL, dbo.v_00_07c_PhysEUL.InitEquationType, 
                         dbo.v_00_07c_PhysEUL.InitConstIntercept, dbo.v_00_07c_PhysEUL.InitExpSlope, dbo.v_00_07c_MaxPhysOM.RR_InspectionDate
FROM            dbo.v_00_07c_PhysEUL LEFT OUTER JOIN
                         dbo.v_00_07c_MaxPhysOM ON dbo.v_00_07c_PhysEUL.RR_Asset_ID = dbo.v_00_07c_MaxPhysOM.RR_Asset_ID LEFT OUTER JOIN
                         dbo.v_00_07c_MaxCoFPerf ON dbo.v_00_07c_PhysEUL.RR_Asset_ID = dbo.v_00_07c_MaxCoFPerf.RR_Asset_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_00_07a_CoFLoFRisk]
AS
SELECT        RR_Asset_ID, MaxPerf, MaxPhys, EULPhysScore, EULPhysRaw, EULPhys, MaxOM AS OM, MaxLoF AS LoF, MaxCoF AS CoF, RR_RedundancyFactor, MaxCoF_R AS CoF_R, MaxCoF_R * MaxLoF AS Risk, RUL
FROM            dbo.v_00_07b_MaxCoFLoF
GO



-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_ScenariosResultsDetails]
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

-- 2023-05-14, v5.009 2023-08-25 LoF 5 and Risk 16 remaining
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_ScenariosResultsSummary]
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

-- 2023-04-22 tweak
CREATE VIEW [dbo].[v_PBI_3DMatrix]
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


-- 2023-07-02
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Projects]
AS
SELECT	ProjectNumber, ProjectName, ProjectDescription, ProjectGroup, ProjectYear, ServiceType, ISNULL(ProjectCost, 0) AS CalculatedCost, ISNULL(OverrideCost, 0) AS OverrideCost, 
		CASE WHEN overridecost IS NULL THEN ProjectCost ELSE OverrideCost END AS ProjectCost, Assets, Length, PreviousFailures, Min_Age, Max_Age, Avg_Age, Min_Diameter, Max_Diameter, Avg_Diameter, Max_LOF_Perf, Avg_LOF_Perf, Max_LOF_Phys, 
		Avg_LOF_Phys, Max_LoF_EUL, Avg_LoF_EUL, Max_LoF, Avg_LoF, Max_CoF, Avg_CoF, Avg_Redundancy, Avg_CoF_R, Max_CoF_R, Max_Risk, Avg_Risk, Active, SHAPE
FROM	dbo.RR_Projects
WHERE	Active = 1
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

--v5.005 update
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
CREATE
VIEW [dbo].[v_QC_AgeOffset]
AS
SELECT        dbo.v__ActiveAssets.RR_Division, dbo.v__ActiveAssets.RR_Facility, dbo.v__ActiveAssets.RR_Process, dbo.v__ActiveAssets.RR_Group, dbo.v__ActiveAssets.RR_AssetType, dbo.v__ActiveAssets.RR_AssetName, 
                         dbo.v__ActiveAssets.RR_Asset_ID, dbo.v__ActiveAssets.RR_InstallYear, dbo.v__ActiveAssets.RR_LoFPhys, dbo.RR_Cohorts.InitEUL, dbo.RR_RuntimeAssets.CurrentAgeOffset, 
                         dbo.RR_Config.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear AS ActualAge, dbo.RR_Config.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear + dbo.RR_RuntimeAssets.CurrentAgeOffset AS ApparentAge, 
                         dbo.RR_Config.BaselineYear, dbo.RR_Cohorts.CohortName, ROUND(dbo.f_RR_CurveCondition(dbo.RR_Cohorts.InitEquationType, dbo.RR_Cohorts.InitConstIntercept, 
                         dbo.RR_Config.BaselineYear - dbo.v__ActiveAssets.RR_InstallYear, dbo.RR_Cohorts.InitExpSlope), 1) AS CurrentLoF
FROM            dbo.v__ActiveAssets INNER JOIN
                         dbo.RR_RuntimeAssets ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.RR_RuntimeAssets.RR_Asset_ID INNER JOIN
                         dbo.RR_Cohorts ON dbo.v__ActiveAssets.RR_Cohort_ID = dbo.RR_Cohorts.Cohort_ID INNER JOIN
                         dbo.RR_Config ON dbo.v__ActiveAssets.RR_Config_ID = dbo.RR_Config.ID
WHERE        (dbo.RR_RuntimeAssets.CurrentAgeOffset <> 0)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE
VIEW [dbo].[v_QC_DuplicateFacilityIDs]
AS
SELECT        RR_SourceTxt_ID, SUM(1) AS Count
FROM            dbo.v__ActiveAssets
GROUP BY RR_SourceTxt_ID
HAVING        (SUM(1) > 1)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_InvalidValues]
AS
SELECT        RR_Asset_ID, RR_SourceTxt_ID, RR_Division, RR_Facility, RR_Group, RR_AssetName, RR_AssetType, CASE WHEN RR_CostReplace IS NULL OR
                         RR_CostReplace <= 0 THEN 'No replace cost; ' ELSE '' END + CASE WHEN RR_InstallYear IS NULL OR
                         RR_InstallYear <= 1869 THEN 'Invalid year; ' ELSE '' END + CASE WHEN RR_LoF IS NULL OR
                         RR_LoF <= 0 OR
                         RR_LoF > 5 THEN 'Invalid LoF; ' ELSE '' END + CASE WHEN RR_CoF_R IS NULL OR
                         RR_CoF_R <= 0 OR
                         RR_CoF_R > 5 THEN 'Invalid CoF; ' ELSE '' END + CASE WHEN RR_Risk IS NULL OR
                         RR_Risk <= 0 OR
                         RR_Risk > 25 THEN 'Invalid Risk; ' ELSE '' END + CASE WHEN RR_RedundancyFactor IS NULL OR
                         RR_RedundancyFactor <= 0 OR
                         RR_RedundancyFactor > 1 THEN 'Invalid Redundancy ; ' ELSE '' END AS Reason, RR_InstallYear, RR_CostReplace, RR_LoF, RR_RedundancyFactor, RR_CoF, RR_CoF_R, RR_Risk
FROM            dbo.v__ActiveAssets
WHERE        (RR_InstallYear IS NULL) OR
                         (RR_InstallYear < 1869) OR
                         (RR_CostReplace IS NULL) OR
                         (RR_CostReplace <= 0) OR
                         (RR_LoF IS NULL) OR
                         (RR_LoF <= 0) OR
                         (RR_LoF > 5) OR
                         (RR_RedundancyFactor IS NULL) OR
                         (RR_RedundancyFactor <= 0) OR
                         (RR_RedundancyFactor > 1) OR
                         (RR_CoF_R IS NULL) OR
                         (RR_CoF_R <= 0) OR
                         (RR_CoF_R > 5) OR
                         (RR_Risk IS NULL) OR
                         (RR_Risk <= 0) OR
                         (RR_Risk > 25)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_60_LEYP_Breaks_All]
AS
SELECT        1 AS Sort_Order, 'IDT' AS ID, 'DDC' AS BreakDate, '' AS Matl, '' AS InstallDate, '' AS PrevMatl
FROM            RR_Config
UNION
SELECT        2 AS Sort_Order, 'PIPE_ID' AS ID, 'BREAK_DATE' AS BreakDate, '' AS Matl, '' AS InstallDate, '' AS PrevMatl
FROM            RR_Config
UNION
SELECT        3 AS Sort_Order, NULL AS ID, 'DATE' AS BreakDate, '' AS Matl, '' AS InstallDate, '' AS PrevMatl
FROM            RR_Config
UNION
SELECT        4 AS Sort_Order, 'BREAKS' AS ID, 'm/d/y' AS BreakDate, '' AS Matl, '' AS InstallDate, '' AS PrevMatl
FROM            RR_Config
UNION
SELECT        Sort_Order, ID, FORMAT(BreakDate, 'MM/dd/yyyy') AS BreakDate, Matl, InstallDate, PrevMatl
FROM            dbo.v_60_LEYP_Assets_All INNER JOIN
                         dbo.RR_Failures ON dbo.v_60_LEYP_Assets_All.ID = dbo.RR_Failures.Asset_ID AND dbo.v_60_LEYP_Assets_All.InstallDt < dbo.RR_Failures.BreakDate AND 
                         dbo.v_60_LEYP_Assets_All.AbandonedDt > dbo.RR_Failures.BreakDate
WHERE        (dbo.v_60_LEYP_Assets_All.Sort_Order = 5)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_QC_Cohorts_Unused]
AS
SELECT        dbo.RR_Cohorts.Cohort_ID, dbo.RR_Cohorts.CohortName, dbo.RR_Cohorts.AssetType, dbo.RR_Cohorts.Materials, dbo.RR_Cohorts.MinDia, dbo.RR_Cohorts.MaxDia, dbo.RR_Cohorts.MinYear, dbo.RR_Cohorts.MaxYear, 
                         dbo.RR_Cohorts.ConditionAtEUL, dbo.RR_Cohorts.InitEUL, dbo.RR_Cohorts.InitEquationType, dbo.RR_Cohorts.InitConstIntercept, dbo.RR_Cohorts.InitExpSlope, dbo.RR_Cohorts.ReplaceEquationType, 
                         dbo.RR_Cohorts.ReplaceConstIntercept, dbo.RR_Cohorts.ReplaceExpSlope, dbo.RR_Cohorts.ReplaceEUL, dbo.RR_Cohorts.Comment
FROM            dbo.v_QC_Cohorts_Assignment RIGHT OUTER JOIN
                         dbo.RR_Cohorts ON dbo.v_QC_Cohorts_Assignment.Cohort_ID = dbo.RR_Cohorts.Cohort_ID
WHERE        (dbo.v_QC_Cohorts_Assignment.Cohort_ID IS NULL)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_Stats_Criticality]
AS
SELECT        dbo.v__ActiveAssets.RR_CoF_R AS CoF, FORMAT(SUM(1), '##,##0') AS Assets, FORMAT(SUM(dbo.v__ActiveAssets.RR_CostReplace), '$#,##0') AS [Asset Cost], FORMAT(SUM(dbo.v__ActiveAssets.RR_Length), '#,##0.##') 
                         AS Miles, FORMAT(SUM(CAST(dbo.v__ActiveAssets.Weighting AS float) / dbo.v__InventoryWeight.Weight), '0.00%') AS [Percent]
FROM            dbo.v__ActiveAssets INNER JOIN
                         dbo.v__InventoryWeight ON dbo.v__ActiveAssets.RR_Config_ID = dbo.v__InventoryWeight.Config_ID
GROUP BY dbo.v__ActiveAssets.RR_CoF_R
GO

--2024-01-16 (need to verify utilization)
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_CoFPerfComments]
AS
SELECT dbo.v__ActiveAssets.RR_Asset_ID, dbo.v__ActiveAssets.RR_Status, dbo.v__ActiveAssets.RR_Division, dbo.v__ActiveAssets.RR_Facility, dbo.v__ActiveAssets.RR_Group, dbo.v__ActiveAssets.RR_Process, 
                  dbo.v__ActiveAssets.RR_AssetName, dbo.RR_Hierarchy.RR_LoFPerfComment, dbo.RR_Hierarchy.RR_HierarchyNotes, dbo.RR_Hierarchy.RR_CoFComment
FROM     dbo.v__ActiveAssets INNER JOIN
                  dbo.RR_Hierarchy ON dbo.v__ActiveAssets.RR_Hierarchy_ID = dbo.RR_Hierarchy.RR_Hierarchy_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_PBI_Inventory]
AS
SELECT	dbo.RR_Hierarchy.RR_HierarchyName AS Level0, RR_Hierarchy_1.RR_HierarchyName AS Level1, RR_Hierarchy_2.RR_HierarchyName AS Level2, RR_Hierarchy_3.RR_HierarchyName AS Level3, 'Assets' AS Level4, 
dbo.v__ActiveAssets.RR_Asset_ID AS [Asset ID], dbo.v__ActiveAssets.RR_AssetName AS [Asset Name], dbo.v__ActiveAssets.RR_AssetType AS [Asset Type], dbo.v__ActiveAssets.RR_InstallYear AS [Asset Install Year], 
dbo.v__ActiveAssets.RR_Material AS [Asset Material], dbo.v__ActiveAssets.RR_Diameter AS [Asset Diameter], dbo.v__ActiveAssets.RR_Length AS PipeFeet, dbo.v__ActiveAssets.RR_Length / 5280 AS PipeMiles,  dbo.RR_Cohorts.InitEUL AS ReplaceEUL, dbo.v__ActiveAssets.RR_InheritCost AS [Inherit Cost], dbo.v__ActiveAssets.RR_CostReplace AS [Replace Cost], dbo.v__ActiveAssets.RR_CostRehab AS [Cost Equipment Rehab],  dbo.v__ActiveAssets.RR_CostReplace * dbo.RR_Config.CostMultiplier AS [Cost Capital Replace], dbo.v__ActiveAssets.RR_CostRehab * dbo.RR_Config.CostMultiplier AS [Cost Capital Rehab],  dbo.v__ActiveAssets.RR_Purpose AS Purpose, dbo.v__ActiveAssets.RR_Length AS Length, CASE WHEN dbo.v__ActiveAssets.RR_LoFInspection IS NULL THEN 0 ELSE dbo.v__ActiveAssets.RR_LoFInspection END AS [Lof Inspection], 
CASE WHEN ISNULL(dbo.v__ActiveAssets.RR_LoFInspection, 0) = 0 THEN RR_LoFPhys ELSE 0 END AS [LoF EUL No Inspection], dbo.v__ActiveAssets.RR_LoFEUL AS [LoF EUL Raw], ISNULL(dbo.v__ActiveAssets.RR_LoFPhys, 0) 
AS [LoF EUL], ISNULL(dbo.v__ActiveAssets.RR_LoFPhys, 0) AS LoFCond, ISNULL(dbo.v__ActiveAssets.RR_LoFPhys, 0) AS [LoF Phys], dbo.v__ActiveAssets.RR_LoFPerf AS LoFPerf, dbo.v__ActiveAssets.RR_LoF AS LoF, 
dbo.v__ActiveAssets.RR_RedundancyFactor AS [Redundancy Factor], dbo.v__ActiveAssets.RR_CoF_R AS [CoF-R], dbo.v__ActiveAssets.RR_CoF AS CoF, dbo.v__ActiveAssets.RR_Risk AS [Risk Score], 
ROUND(dbo.v__ActiveAssets.RR_CoF * dbo.v__ActiveAssets.RR_RedundancyFactor, 2) AS RR_CoF_Raw, ROUND(dbo.v__ActiveAssets.RR_LoF * dbo.v__ActiveAssets.RR_CoF * dbo.v__ActiveAssets.RR_RedundancyFactor, 2) 
AS RR_Risk_Raw, ROUND(dbo.v__ActiveAssets.RR_CoF * dbo.v__ActiveAssets.RR_RedundancyFactor, 2) AS [CoF Raw], 
ROUND(dbo.v__ActiveAssets.RR_LoF * dbo.v__ActiveAssets.RR_CoF * dbo.v__ActiveAssets.RR_RedundancyFactor, 2) AS [Risk Raw], dbo.v__ActiveAssets.RR_CoFMaxCriteria AS [Max CoF Factors], 
dbo.v__ActiveAssets.RR_LoFPerfMaxCriteria AS [Max Perf Factors], dbo.v__ActiveAssets.RR_LoFPhysMaxCriteria AS [Max Phys Factors], dbo.v__ActiveAssets.RR_CoF01, dbo.v__ActiveAssets.RR_CoF02, 
dbo.v__ActiveAssets.RR_CoF03, dbo.v__ActiveAssets.RR_CoF04, dbo.v__ActiveAssets.RR_CoF05, dbo.v__ActiveAssets.RR_CoF06, dbo.v__ActiveAssets.RR_CoF07, dbo.v__ActiveAssets.RR_CoF08, dbo.v__ActiveAssets.RR_CoF09, 
dbo.v__ActiveAssets.RR_CoF10, dbo.v__ActiveAssets.RR_CoF11, dbo.v__ActiveAssets.RR_CoF12, dbo.v__ActiveAssets.RR_CoF13, dbo.v__ActiveAssets.RR_CoF14, dbo.v__ActiveAssets.RR_CoF15, dbo.v__ActiveAssets.RR_CoF16, 
dbo.v__ActiveAssets.RR_CoF17, dbo.v__ActiveAssets.RR_CoF18, dbo.v__ActiveAssets.RR_CoF19, dbo.v__ActiveAssets.RR_CoF20, dbo.v__ActiveAssets.RR_LoFPerf01, dbo.v__ActiveAssets.RR_LoFPerf02, 
dbo.v__ActiveAssets.RR_LoFPerf03, dbo.v__ActiveAssets.RR_LoFPerf04, dbo.v__ActiveAssets.RR_LoFPerf05, dbo.v__ActiveAssets.RR_LoFPerf06, dbo.v__ActiveAssets.RR_LoFPerf07, dbo.v__ActiveAssets.RR_LoFPerf08, 
dbo.v__ActiveAssets.RR_LoFPerf09, dbo.v__ActiveAssets.RR_LoFPerf10, dbo.v_PBI_Hyperlinks.FirstOfFileHyperlink AS Hyperlink, dbo.v__ActiveAssets.RR_LoFPerfComment AS [Perf Comment], 
dbo.v__ActiveAssets.RR_CoFComment AS [CoF Comment], dbo.v__ActiveAssets.RR_OM AS [O&M Score], dbo.v__ActiveAssets.RR_CostRehab AS [Cost Rehab], dbo.v__ActiveAssets.RR_Status AS Status,
dbo.v_PBI_Physical.RR_InspectionType AS [Inspection Type], dbo.v_PBI_Physical.RR_InspectionDate AS [Inspection Date], dbo.v_PBI_Physical.RR_CompleteInspection AS [Inspection Completed],       
dbo.v_PBI_Physical.RR_LoFPhys01,dbo.v_PBI_Physical.RR_LoFPhys02, dbo.v_PBI_Physical.RR_LoFPhys03, dbo.v_PBI_Physical.RR_LoFPhys04, dbo.v_PBI_Physical.RR_LoFPhys05, dbo.v_PBI_Physical.RR_LoFPhys06, 
dbo.v_PBI_Physical.RR_LoFPhys07, dbo.v_PBI_Physical.RR_LoFPhys08, dbo.v_PBI_Physical.RR_LoFPhys09, dbo.v_PBI_Physical.RR_LoFPhys10, dbo.v_PBI_Physical.RR_LoFPhys11, dbo.v_PBI_Physical.RR_LoFPhys12, 
dbo.v_PBI_Physical.RR_LoFPhys13, dbo.v_PBI_Physical.RR_LoFPhys14, dbo.v_PBI_Physical.RR_LoFPhys15, dbo.v_PBI_Physical.RR_LoFPhys16, dbo.v_PBI_Physical.RR_LoFPhys17, dbo.v_PBI_Physical.RR_LoFPhys18, 
dbo.v_PBI_Physical.RR_LoFPhys19, dbo.v_PBI_Physical.RR_LoFPhys20, dbo.v_PBI_Physical.RR_LoFPhys21, dbo.v_PBI_Physical.RR_LoFPhys22, dbo.v_PBI_Physical.RR_LoFPhys23, dbo.v_PBI_Physical.RR_LoFPhys24, 
dbo.v_PBI_Physical.RR_LoFPhys25, dbo.v_PBI_Physical.RR_LoFPhys26, dbo.v_PBI_Physical.RR_LoFPhys27, dbo.v_PBI_Physical.RR_LoFPhys28, dbo.v_PBI_Physical.RR_LoFPhys29, dbo.v_PBI_Physical.RR_LoFPhys30, 
dbo.v_PBI_Physical.RR_LoFPhys31, dbo.v_PBI_Physical.RR_LoFPhys32, dbo.v_PBI_Physical.RR_LoFPhys33, dbo.v_PBI_Physical.RR_LoFPhys34, dbo.v_PBI_Physical.RR_LoFPhys35, dbo.v_PBI_Physical.RR_LoFPhys36, 
dbo.v_PBI_Physical.RR_LoFPhys37, dbo.v_PBI_Physical.RR_LoFPhys38, dbo.v_PBI_Physical.RR_LoFPhys39, dbo.v_PBI_Physical.RR_LoFPhys40, dbo.v_PBI_Physical.RR_LoFPhys41, dbo.v_PBI_Physical.RR_LoFPhys42, 
dbo.v_PBI_Physical.RR_LoFPhys43, dbo.v_PBI_Physical.RR_LoFPhys44, dbo.v_PBI_Physical.RR_LoFPhys45, dbo.v_PBI_Physical.RR_LoFPhys46, dbo.v_PBI_Physical.RR_LoFPhys47, dbo.v_PBI_Physical.RR_LoFPhys48, dbo.v_PBI_Physical.RR_LoFPhys49, dbo.v_PBI_Physical.RR_LoFPhys50, 
dbo.v_PBI_Physical.RR_InspectNotes AS [Phys Comment], dbo.v__ActiveAssets.shape, dbo.v__ActiveAssets.RR_EUL, dbo.v__ActiveAssets.RR_RUL,dbo.v__ActiveAssets.RR_FieldCode, dbo.v__ActiveAssets.RR_AgeOffset, 
dbo.v__ActiveAssets.RR_CurveSlope, dbo.v__ActiveAssets.RR_CurveType, dbo.v__ActiveAssets.RR_CurveIntercept, dbo.v__ActiveAssets.RR_FailurePhysOffset,dbo.v__ActiveAssets.RR_Manufacturer, 
dbo.v__ActiveAssets.RR_ModelNumber, dbo.v__ActiveAssets.RR_SerialNumber, dbo.v__ActiveAssets.RR_MotorManufacturer, dbo.v__ActiveAssets.RR_GPM, dbo.v__ActiveAssets.RR_Head, dbo.v__ActiveAssets.RR_CFM, 
dbo.v__ActiveAssets.RR_FiltrationRate, dbo.v__ActiveAssets.RR_Tons, dbo.v__ActiveAssets.RR_CapacityDiameter, dbo.v__ActiveAssets.RR_HP, dbo.v__ActiveAssets.RR_Voltage, dbo.v__ActiveAssets.RR_FLA, 
dbo.v__ActiveAssets.RR_Phase, dbo.v__ActiveAssets.RR_RPM, dbo.v__ActiveAssets.RR_SQFT, dbo.v__ActiveAssets.RR_Gallons, dbo.v__ActiveAssets.RR_MaxFillHeight, dbo.v__ActiveAssets.RR_CapacityOther, 
dbo.v__ActiveAssets.RR_MotorHertz, dbo.v__ActiveAssets.RR_ConstructionType, dbo.v_PBI_CoFPerfComments.RR_LoFPerfComment, dbo.v_PBI_CoFPerfComments.RR_CoFComment
FROM     dbo.RR_Cohorts INNER JOIN
dbo.v__ActiveAssets INNER JOIN
dbo.RR_Config ON dbo.v__ActiveAssets.RR_Config_ID = dbo.RR_Config.ID ON dbo.RR_Cohorts.Cohort_ID = dbo.v__ActiveAssets.RR_Cohort_ID INNER JOIN
dbo.RR_Hierarchy AS RR_Hierarchy_1 RIGHT OUTER JOIN
dbo.RR_Hierarchy AS RR_Hierarchy_2 ON RR_Hierarchy_1.RR_Hierarchy_ID = RR_Hierarchy_2.RR_Parent_ID RIGHT OUTER JOIN
dbo.RR_Hierarchy AS RR_Hierarchy_3 ON RR_Hierarchy_2.RR_Hierarchy_ID = RR_Hierarchy_3.RR_Parent_ID ON dbo.v__ActiveAssets.RR_Hierarchy_ID = RR_Hierarchy_3.RR_Hierarchy_ID INNER JOIN 
 dbo.v_PBI_CoFPerfComments ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.v_PBI_CoFPerfComments.RR_Asset_ID LEFT OUTER JOIN
dbo.RR_Hierarchy ON RR_Hierarchy_1.RR_Parent_ID = dbo.RR_Hierarchy.RR_Hierarchy_ID LEFT OUTER JOIN
dbo.v_PBI_Physical ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.v_PBI_Physical.RR_Asset_ID LEFT OUTER JOIN
dbo.v_PBI_Hyperlinks ON dbo.v__ActiveAssets.RR_Asset_ID = dbo.v_PBI_Hyperlinks.RR_Asset_ID
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_QC_MinMaxRisk]
AS
SELECT AVG(dbo.v__ActiveAssets.RR_LoFPerf) AS AvgOfRR_LoFPerf, AVG(dbo.v__ActiveAssets.RR_LoFPhys) AS AvgOfRR_LoFPhys, AVG(dbo.v__ActiveAssets.RR_CoF_R) AS AvgOfRR_CoF_R, AVG(dbo.v__ActiveAssets.RR_Risk) 
                  AS AvgOfRR_Risk, AVG(dbo.v__ActiveAssets.RR_CoF_R * 5) AS MaxRiskScore, AVG(dbo.v__ActiveAssets.RR_CoF_R * dbo.RR_CriticalityActionLimits.LowReplace) AS ThresholdRisk
FROM     dbo.RR_CriticalityActionLimits INNER JOIN
                  dbo.v__ActiveAssets ON dbo.RR_CriticalityActionLimits.Criticality = dbo.v__ActiveAssets.RR_CoF_R
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p___QC_FindText]
@SEARCHSTRING VARCHAR(255),
@EXCLUDESTRING VARCHAR(255) = ''
AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT 
		case when sysobjects.xtype = 'P' then 'Stored Proc'
			when sysobjects.xtype = 'TF' then 'Function'
			when sysobjects.xtype = 'TR' then 'Trigger'
			when sysobjects.xtype = 'V' then 'View'
			when sysobjects.xtype = 'U' then 'Table'
			when sysobjects.xtype = 'FN' then 'Function'
		end as [Object Type],
		sysobjects.name AS [Object Name] ,
		syscomments.text AS Def
	FROM sysobjects,syscomments
	WHERE sysobjects.id = syscomments.id
	AND sysobjects.type in ('P','TF','TR','V','U','FN')
	AND sysobjects.category = 0
	AND CHARINDEX(@SEARCHSTRING,syscomments.text)>0
	AND CHARINDEX(@EXCLUDESTRING,syscomments.text)=0
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p___QC_ResultsReview]
AS
BEGIN

	SET NOCOUNT ON;

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p_00_01_Cohorts_Update]
AS
BEGIN

	SET NOCOUNT ON;
	-- update dbo.RR_Cohors InitExpSlope and ReplaceExpSlope and if empty InitEUL and ReplaceEUL 
	UPDATE [dbo].[RR_Cohorts] 
	SET 
		[RR_Cohorts].[InitExpSlope] = 
		ROUND(
		CASE WHEN [InitConstIntercept] IS NOT NULL AND [ConditionAtEUL]>0 AND [InitEUL]>0
			THEN [dbo].[f_RR_CurveSlope]([InitEquationType],[InitConstIntercept],[ConditionAtEUL],[InitEUL])
			ELSE [InitExpSlope]
		END
		,5),

		[RR_Cohorts].[InitEUL] =
		ROUND(
			CASE WHEN [InitEUL] Is Null And [InitConstIntercept] IS NOT NULL AND [InitExpSlope]>0 And [ConditionAtEUL]>0
				THEN  [dbo].[f_RR_CurveAge]([InitEquationType],[InitConstIntercept],[ConditionAtEUL],[InitExpSlope])
				ELSE [InitEUL]
			END
		,0),

		[RR_Cohorts].[ReplaceExpSlope] =
		ROUND(
			CASE WHEN [ReplaceConstIntercept] IS NOT NULL AND  [ConditionAtEUL]>0 AND [ReplaceEUL]>0
				THEN  [dbo].[f_RR_CurveSlope]([ReplaceEquationType],[ReplaceConstIntercept],[ConditionAtEUL],[ReplaceEUL])
				ELSE [ReplaceExpSlope]
			END
		,5),
		
		[RR_Cohorts].[ReplaceEUL] =
		ROUND(
			CASE WHEN [ReplaceEUL] Is Null And [ReplaceConstIntercept] IS NOT NULL AND [ReplaceExpSlope]>0 And [ConditionAtEUL]>0
				THEN  [dbo].[f_RR_CurveAge]([ReplaceEquationType],[ReplaceConstIntercept],[ConditionAtEUL],[ReplaceExpSlope])
				ELSE [ReplaceEUL]
			END
		,0)

END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p_00_02_CreateMissingCohorts]

AS
BEGIN
	
	SET NOCOUNT ON;
	-- inserts cohorts from view dbo.q_QC_Cohorts_Missing in dbo.RR_Corhorts
	INSERT INTO [dbo].[RR_Cohorts]([CohortName], [AssetType], [Materials], MinDia, MaxDia, MinYear, MaxYear)
	SELECT ' New ' + [RR_AssetType] + ' ' + [RR_Material] AS [PipeClassName], '''' + [RR_AssetType] + '''' AS [AssetType], '''' + [RR_Material] + '''' AS [Mtl], MinDia-1, MaxDia, MinYear-1, MaxYear
	FROM [dbo].[v_QC_Cohorts_Missing]


END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [p_00_04_CopyHierarchyCoF]
	@SrcID int, @DestID int
AS
BEGIN

	SET NOCOUNT ON;

	--Copy source hierarhy values to destination
	UPDATE RR_Hierarchy
	SET RR_RedundancyFactor = Src.RR_RedundancyFactor,
	RR_CoF01 = Src.RR_CoF01, 
	RR_CoF02 = Src.RR_CoF02, 
	RR_CoF03 = Src.RR_CoF03, 
	RR_CoF04 = Src.RR_CoF04, 
	RR_CoF05 = Src.RR_CoF05, 
	RR_CoF06 = Src.RR_CoF06, 
	RR_CoF07 = Src.RR_CoF07, 
	RR_CoF08 = Src.RR_CoF08,
	RR_CoF09 = Src.RR_CoF09,
	RR_CoF10 = Src.RR_CoF10,
	RR_CoF11 = Src.RR_CoF11,
	RR_CoF12 = Src.RR_CoF12,
	RR_CoF13 = Src.RR_CoF13,
	RR_CoF14 = Src.RR_CoF14,
	RR_CoF15 = Src.RR_CoF15,
	RR_CoF16 = Src.RR_CoF16,
	RR_CoF17 = Src.RR_CoF17,
	RR_CoF18 = Src.RR_CoF18,
	RR_CoF19 = Src.RR_CoF19,
	RR_CoF20 = Src.RR_CoF20,
	RR_CoFComment = Src.RR_CoFComment
	FROM RR_Hierarchy AS Src CROSS JOIN RR_Hierarchy
	WHERE (Src.RR_Hierarchy_ID = @SrcID) AND (RR_Hierarchy.RR_Hierarchy_ID = @DestID);

	--Copy source hierarhy values to child of destination where hierarchy names are the same
	UPDATE RR_Hierarchy
	SET RR_RedundancyFactor = Src.[RR_RedundancyFactor], 
	RR_CoF01 = Src.[RR_CoF01], 
	RR_CoF02 = Src.[RR_CoF02], 
	RR_CoF03 = Src.[RR_CoF03], 
	RR_CoF04 = Src.[RR_CoF04], 
	RR_CoF05 = Src.[RR_CoF05],
	RR_CoF06 = Src.[RR_CoF06],
	RR_CoF07 = Src.[RR_CoF07],
	RR_CoF08 = Src.[RR_CoF08],
	RR_CoF09 = Src.[RR_CoF09],
	RR_CoF10 = Src.[RR_CoF10],
	RR_CoF11 = Src.[RR_CoF11],
	RR_CoF12 = Src.[RR_CoF12],
	RR_CoF13 = Src.[RR_CoF13],
	RR_CoF14 = Src.[RR_CoF14],
	RR_CoF15 = Src.[RR_CoF15],
	RR_CoF16 = Src.[RR_CoF16],
	RR_CoF17 = Src.[RR_CoF17],
	RR_CoF18 = Src.[RR_CoF18],
	RR_CoF19 = Src.[RR_CoF19],
	RR_CoF20 = Src.[RR_CoF20],
	RR_CoFComment = Src.[RR_CoFComment]
	FROM RR_Hierarchy AS Src INNER JOIN RR_Hierarchy ON Src.RR_HierarchyName = RR_Hierarchy.RR_HierarchyName
	WHERE Src.RR_Parent_ID=@SrcID AND RR_Hierarchy.RR_Parent_ID=@DestID;
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_00_05_CopyHierarchyLoF]
	@SrcID int, @DestID int
AS
BEGIN

	SET NOCOUNT ON;

	--Copy source hierarhy values to destination
	UPDATE RR_Hierarchy
	SET RR_LoFPerf01 = Src.RR_LoFPerf01, 
	RR_LoFPerf02 = Src.RR_LoFPerf02, 
	RR_LoFPerf03 = Src.RR_LoFPerf03, 
	RR_LoFPerf04 = Src.RR_LoFPerf04, 
	RR_LoFPerf05 = Src.RR_LoFPerf05, 
	RR_LoFPerf06 = Src.RR_LoFPerf06, 
	RR_LoFPerf07 = Src.RR_LoFPerf07, 
	RR_LoFPerf08 = Src.RR_LoFPerf08, 
	RR_LoFPerf09 = Src.RR_LoFPerf09, 
	RR_LoFPerf10 = Src.RR_LoFPerf10, 
	RR_LoFPerfComment = Src.RR_LoFPerfComment
	FROM RR_Hierarchy AS Src CROSS JOIN RR_Hierarchy
	WHERE (Src.RR_Hierarchy_ID = @SrcID) AND (RR_Hierarchy.RR_Hierarchy_ID = @DestID)

	--Copy source hierarhy values to child of destination where hierarchy names are the same
	UPDATE RR_Hierarchy
	SET RR_LoFPerf01 = Src.RR_LoFPerf01, 
	RR_LoFPerf02 = Src.RR_LoFPerf02, 
	RR_LoFPerf03 = Src.RR_LoFPerf03, 
	RR_LoFPerf04 = Src.RR_LoFPerf04, 
	RR_LoFPerf05 = Src.RR_LoFPerf05, 
	RR_LoFPerf06 = Src.RR_LoFPerf06, 
	RR_LoFPerf07 = Src.RR_LoFPerf07, 
	RR_LoFPerf08 = Src.RR_LoFPerf08, 
	RR_LoFPerf09 = Src.RR_LoFPerf09, 
	RR_LoFPerf10 = Src.RR_LoFPerf10, 
	RR_LoFPerfComment = Src.RR_LoFPerfComment
	FROM RR_Hierarchy AS Src INNER JOIN RR_Hierarchy ON Src.RR_HierarchyName = RR_Hierarchy.RR_HierarchyName
	WHERE Src.RR_Parent_ID=@SrcID AND RR_Hierarchy.RR_Parent_ID=@DestID

END
GO

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_00_06_Scenario]
	@Name nvarchar(64),
	@Year int
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO RR_Scenarios (ScenarioName, StartYear) VALUES (@Name, @Year);
END

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_00_06_ScenarioYears]
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [p_01_UpdateAssetInfo]
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


	 --UPDATE TO CLIENT SPECIFIC CRITERIA
	UPDATE RR_ASSETS
	SET 
		RR_Status = 1,
		RR_Diameter = 0, 
		RR_Material = 'UNK',
		RR_InstallYear = ISNULL(RR_InstallYear, 1900),
		RR_Length = 1

		--For Traininig, Comment previous four lines and uncomment the next six lines
	
		--RR_Status = CASE WHEN RR_FieldCode IN ('Not an Asset', 'Retired','Permanently Removed','Abandoned in Place','Duplicate') THEN 0 ELSE 1 END,
		--RR_Diameter = ISNULL(DIAMETER, 0), 
		--RR_ReplacementDiameter = ISNULL(DIAMETER, 0),  
		--RR_Material = ISNULL(MATERIAL,'UNK'),
		--RR_InstallYear = CASE WHEN RR_Fulcrum_ID IS NULL THEN ISNULL(YR_INST, 1900) ELSE RR_InstallYear END,
		--RR_AssetType = CASE WHEN RR_Fulcrum_ID IS NULL THEN 'Linear' ELSE RR_AssetType END,
		--RR_PreviousRehabYear
		--RR_Length = ISNULL(shape.STLength(), 1)
	;

	UPDATE	RR_Assets
	SET		RR_PreviousFailures = ISNULL(v_00_08_FailureCount.FailureCount, 0)
	FROM	RR_Assets LEFT OUTER JOIN
			v_00_08_FailureCount ON RR_Assets.RR_Asset_ID = v_00_08_FailureCount.Asset_ID;

END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_02_AssignCohortsCosts]
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
CREATE PROCEDURE [dbo].[p_03_UpdateAssetCurves]
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
	
	-- Update rehabs allowed to 0 if Replace Diameter is larger than Diameter 2023-09-03
	UPDATE	RR_Assets
	SET		RR_RehabsAllowed = 0
	FROM	RR_Assets
	WHERE	RR_ReplacementDiameter > RR_Diameter;

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

END
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Initialize RR_Hierarchy CoF and LoF Perf
--Initialize RR_Assets CoF, LoF Perf and redundany based on hierarchy, cost, diameter and critical customers
--Initialize RR_Assets LoFPerf, LoFPhys, LoFEUL, LoF, CoF, CoF_R, RUL and Risk
--p_03_UpdateAssetCurves should have been run to set CurveType, CurveIntercept, CurveSlope, EUL, FailurePhysOffset, RehabsAllowed, RepairsAllowed, LoFInspection, LastInspection and OM
CREATE PROCEDURE [p_04_Update_CoF_LoF_Risk]
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

	-- 2023-12-26
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Initializes RR_RuntimeAssets by removing unused assets and adding missing assets
--Initializes RR_RuntimeAssets values CurrentInstallYea, CurrentPerformance, CurrentEquationType, CurrentConstIntercept, CurrentExpSlope, 
-- CurrentFailurePhysOffset, CurrentAgeOffset, RehabsRemaining, RepairsRemaining based on RR_Assets or RR_Cohorts if assets is in RR_Projects
CREATE PROCEDURE [dbo].[p_05_InitializeRuntimeSetting]
AS
BEGIN

	SET NOCOUNT ON;

	-- deletes records from dbo.RR_RuntimeAssets where RR_Asset_ID is not in dbo.v__INVENTORY
	DELETE
	FROM RR_RuntimeAssets
	FROM RR_RuntimeAssets
	LEFT JOIN  v__ActiveAssets ON v__ActiveAssets.RR_Asset_ID = RR_RuntimeAssets.RR_Asset_ID
	WHERE v__ActiveAssets.RR_Asset_ID IS NULL;

	-- insert into dbo.RR_RuntimeAssets config_ID and RR_Asset_ID from dbo.v__INVENTORY where RR_Asset_ID is not in dbo.RR_RuntimeAssets
	INSERT INTO RR_RuntimeAssets(Config_ID, RR_Asset_ID)
	SELECT 1 AS Config_ID, v__ActiveAssets.RR_Asset_ID
	FROM v__ActiveAssets 
	LEFT JOIN RR_RuntimeAssets ON RR_RuntimeAssets.RR_Asset_ID = v__ActiveAssets.RR_Asset_ID
	WHERE RR_RuntimeAssets.RR_Asset_ID IS NULL;

	UPDATE	RR_RuntimeAssets 
	SET		CurrentInstallYear = RR_InstallYear,
			CurrentEquationType = RR_CurveType,
			CurrentConstIntercept = RR_CurveIntercept,
			CurrentExpSlope = RR_CurveSlope,
			CurrentPerformance = RR_LoFPerf,
			CurrentFailurePhysOffset =  RR_FailurePhysOffset,
			CurrentAgeOffset = RR_AgeOffset,
			RepairsRemaining =  RR_RepairsAllowed,
			RehabsRemaining =  RR_RehabsAllowed
	FROM	RR_RuntimeAssets
	INNER JOIN RR_Assets ON RR_Assets.RR_Asset_ID = RR_RuntimeAssets.RR_Asset_ID;

	-- Set current equation to replacement EUL for bundled pipes with a project date before the baseline year.
	UPDATE	RR_RuntimeAssets
	SET		CurrentInstallYear = RR_Projects.ProjectYear,
			CurrentEquationType = RR_Cohorts.ReplaceEquationType,
			CurrentConstIntercept = RR_Cohorts.ReplaceConstIntercept,
			CurrentExpSlope = RR_Cohorts.ReplaceExpSlope,
			CurrentPerformance = 1,
			CurrentFailurePhysOffset = 0,
			CurrentAgeOffset = 0,
			RepairsRemaining = RR_Cohorts.RepairsAllowed,
			RehabsRemaining = RR_Cohorts.RehabsAllowed
	FROM	RR_RuntimeAssets 
			INNER JOIN RR_Assets ON RR_Assets.RR_Asset_ID = RR_RuntimeAssets.RR_Asset_ID
			INNER JOIN RR_Cohorts ON RR_Cohorts.Cohort_ID = RR_Assets.RR_Cohort_ID 
			INNER JOIN RR_Config ON RR_RuntimeAssets.Config_ID = RR_Config.ID 
			INNER JOIN RR_Projects ON RR_Projects.ProjectNumber = RR_Assets.RR_ProjectNumber 
			AND RR_Config.BaselineYear > RR_Projects.ProjectYear;

END
GO

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_07_InitializeScenarioResultsForAllYears]
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_09_UpdateScenarioResultsForAYear]
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO RR_ScenarioResults (Scenario_ID, ScenarioYear, RR_Asset_ID, Age, PhysRaw, PhysScore, PerfScore, CostOfService, [Service])
	SELECT CurrentScenario_ID, CurrentYear, RR_Asset_ID, CurrentAge, PhysRaw, PhysScore, PerfScore, 0, 'Maintain'
	FROM	v_10_a_ScenarioCurrentYearDetails;

END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_10a_ScenarioYearLoFUpdate]
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
	SET		CurrentInstallYear = CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.CurrentYear  ELSE CurrentInstallYear END   , 
			CurrentEquationType = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceEquationType  ELSE CurrentEquationType END,  
			CurrentConstIntercept =  CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.ReplaceConstIntercept ELSE CurrentConstIntercept END, 
			CurrentExpSlope = CASE WHEN  [ServiceType] = 'Replace' THEN v__RuntimeResults.ReplaceExpSlope   ELSE  CurrentExpSlope END, 
			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentPerformance =  CASE WHEN  [ServiceType] = 'Replace' THEN  1 ELSE  CurrentPerformance END, 
			RepairsRemaining =  CASE WHEN  [ServiceType] = 'Repair' THEN  RepairsRemaining - 1    ELSE   v__RuntimeResults.RepairsAllowed END, 
			RehabsRemaining =  CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
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
CREATE PROCEDURE [dbo].[p_10a_ScenarioYearRiskUpdate]
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
			CurrentFailurePhysOffset = CASE WHEN  [ServiceType] = 'Repair' THEN  CurrentFailurePhysOffset ELSE 0 END, 
			CurrentAgeOffset = CASE WHEN  [ServiceType] = 'Rehab' THEN v__RuntimeResults.RehabPercentEUL * v__RuntimeResults.InitEUL - (v__RuntimeResults.CurrentYear - v__RuntimeResults.CurrentInstallYear) ELSE 0 END, 
			CurrentPerformance =  CASE WHEN  [ServiceType] = 'Replace' THEN  1 ELSE  CurrentPerformance END, 
			RepairsRemaining =  CASE WHEN  [ServiceType] = 'Repair' THEN  RepairsRemaining - 1    ELSE   v__RuntimeResults.RepairsAllowed END, 
			RehabsRemaining =  CASE WHEN  [ServiceType] = 'Replace' THEN  v__RuntimeResults.RehabsAllowed  ELSE RehabsRemaining  END
	FROM	v__RuntimeResults INNER JOIN
			v_10_00_Running_Risk ON v__RuntimeResults.RR_Asset_ID = v_10_00_Running_Risk.RR_Asset_ID
	WHERE	[ServiceCost] < =  @iBudget AND
			RunningCost <= @iBudget AND 
			RunningRisk <= @fCurrentRisk - @fTargetRisk AND 
			RunningCondition <= @fCurrentCondition - @fTargetCondition ;

END
GO

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_10_ScenarioYearLoF] 
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

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_10_ScenarioYearRisk] 
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
CREATE PROCEDURE [dbo].[p_11_UpdateScenarioAsset]
	@iAssetID int, @sServiceType nvarchar(8), @iServiceCost int, @iScenarioID int, @ScenarioYear smallint
AS
BEGIN
	SET NOCOUNT ON;

	-- UPDATE RR_Config SET CurrentAsset_ID = @iAssetID WHERE ID=1;
	
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

	UPDATE	RR_ScenarioResults 
	SET		CostOfService = @iServiceCost, Service = @sServiceType 
	WHERE	Scenario_ID = @iScenarioID AND ScenarioYear = @ScenarioYear AND RR_Asset_ID = @iAssetID;
END
GO

-- 2023-04-22
-- v5.009 2023-08-25 lof5 and risk16 remaining
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_14_Results_Summary_Update]
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

-- 2023-04-22
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE p_19_DeleteScenario
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_40_Update_Asset_Current_Results]
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


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_50_UpdateProjectStats]
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
			Avg_Risk = v_50_ProjectStats.Avg_Risk,
			Active = 1
	FROM	RR_Projects INNER JOIN
			v_50_ProjectStats ON v_50_ProjectStats.RR_ProjectNumber = RR_Projects.ProjectNumber;

	UPDATE	RR_Projects
	SET		SHAPE = v_50_ProjectGeo.AgLine.STBuffer(50)
	FROM	v_50_ProjectGeo INNER JOIN
			RR_Projects ON v_50_ProjectGeo.RR_ProjectNumber = RR_Projects.ProjectNumber;

END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_60_DeleteStatModelResults]
AS
BEGIN

	SET NOCOUNT ON;

	DELETE  FROM RR_StatModel_Results;

	DELETE  FROM RR_StatModel_ImportFiles;

END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[RR_ConfigQueries_Category] 
   ON  [dbo].[RR_ConfigQueries]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	UPDATE RR_ConfigQueries
	SET Category = RR_ConfigCategories.Category + ' (' + RR_ConfigCategories.FunctionGroup + ')' 
	FROM RR_ConfigCategories INNER JOIN RR_ConfigQueries ON RR_ConfigCategories.Category_ID = RR_ConfigQueries.Category_ID
	INNER JOIN inserted ON RR_ConfigQueries.Query_ID = inserted.Query_ID

END
GO
ALTER TABLE [dbo].[RR_ConfigQueries] ENABLE TRIGGER [RR_ConfigQueries_Category]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trg_RR_Revisions_UpdateLastEdited]
ON [dbo].[RR_Revisions]
AFTER INSERT,UPDATE
AS
    UPDATE dbo.RR_Revisions
    SET LastEditedOn = GETDATE(),
	 LastEditedBy = SYSTEM_USER
	 FROM RR_Revisions
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)
GO
ALTER TABLE [dbo].[RR_Revisions] ENABLE TRIGGER [trg_RR_Revisions_UpdateLastEdited]
GO

CREATE PROCEDURE [dbo].[p___GrantEditorPermission]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @name VARCHAR(255)
	DECLARE @sql VARCHAR(255)

	PRINT 'CREATE ROLE [rrps_Admins]';
	PRINT 'GO';
	PRINT 'GRANT CONNECT TO [rrps_Admins]';
	PRINT 'GRANT DELETE TO [rrps_Admins]';
	PRINT 'GRANT EXECUTE TO [rrps_Admins]';
	PRINT 'GRANT INSERT TO [rrps_Admins]';
	PRINT 'GRANT SELECT TO [rrps_Admins]';
	PRINT 'GRANT UPDATE TO [rrps_Admins]';
	PRINT 'GRANT ALTER TO [rrps_Admins]';
	PRINT 'GRANT BACKUP DATABASE TO [rrps_Admins]';
	PRINT 'GRANT CREATE DEFAULT TO [rrps_Admins]';
	PRINT 'GRANT CREATE FUNCTION TO [rrps_Admins]';
	PRINT 'GRANT CREATE PROCEDURE TO [rrps_Admins]';
	PRINT 'GRANT CREATE RULE TO [rrps_Admins]';
	PRINT 'GRANT CREATE TABLE TO [rrps_Admins]';
	PRINT 'GRANT CREATE VIEW TO [rrps_Admins]';
	PRINT 'GO';

	PRINT 'CREATE ROLE [rrps_Editors]';
	PRINT 'GO';
	PRINT 'GRANT CONNECT TO [rrps_Editors]';
	PRINT 'GRANT DELETE TO [rrps_Editors]';
	PRINT 'GRANT EXECUTE TO [rrps_Editors]';
	PRINT 'GRANT INSERT TO [rrps_Editors]';
	PRINT 'GRANT SELECT TO [rrps_Editors]';
	PRINT 'GRANT UPDATE TO [rrps_Editors]';
	PRINT 'GO';

	DECLARE db_cursor CURSOR FOR 
	SELECT	DISTINCT sysobjects.name AS [Object Name]
	FROM	sysobjects,syscomments
	WHERE	sysobjects.category = 0	 
	AND ((sysobjects.type = 'P' AND sysobjects.name LIKE 'p_%') OR (sysobjects.type = 'FN' AND sysobjects.name LIKE 'f_RR_%')) ;
		
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @name  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SELECT @sql = 'GRANT EXECUTE ON dbo.' + @name + ' TO rrps_Editors';
		PRINT @sql;
		PRINT 'GO';
		FETCH NEXT FROM db_cursor INTO @name 
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 	
	
	DECLARE db_cursor CURSOR FOR 
	SELECT	DISTINCT sysobjects.name AS [Object Name]
	FROM	sysobjects,syscomments
	WHERE	sysobjects.category = 0	
	AND ((sysobjects.type = 'V' AND sysobjects.name LIKE 'v_%') OR (sysobjects.type = 'U' AND sysobjects.name LIKE 'RR_%')) ;
	
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @name  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SELECT @sql = 'GRANT DELETE, INSERT, SELECT, UPDATE ON dbo.' + @name + ' TO rrps_Editors';
		PRINT @sql;
		PRINT 'GO';
		FETCH NEXT FROM db_cursor INTO @name 
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor

END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v_60_NodeEndCount]
AS
SELECT	rr_Nodes.Node_ID, COUNT(RR_Assets.RR_Asset_ID) AS Count
FROM	RR_Assets INNER JOIN
		rr_Nodes ON RR_Assets.RR_End_ID = rr_Nodes.Node_ID
GROUP BY rr_Nodes.Node_ID
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v_60_NodeStartCount]
AS
SELECT	rr_Nodes.Node_ID, COUNT(RR_Assets.RR_Asset_ID) AS Count
FROM	RR_Assets INNER JOIN
		rr_Nodes ON RR_Assets.RR_Start_ID = rr_Nodes.Node_ID
GROUP BY rr_Nodes.Node_ID
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [p_60_InsertNodes]

AS
BEGIN

	SET NOCOUNT ON;

	--IGNORE_DUP_KEY is set ON in rr_Nodes to continue on duplicate X, Y error

	INSERT	INTO rr_Nodes
	SELECT	ROUND(Shape.STStartPoint().STX, 1) AS X, ROUND(Shape.STStartPoint().STY, 1) AS Y, 0 AS Connections
	FROM	RR_Assets
	WHERE	RR_Status = 1;

	INSERT	INTO rr_Nodes
	SELECT	ROUND(Shape.STEndPoint().STX, 1) AS X, ROUND(Shape.STEndPoint().STY, 1) AS Y, 0 AS Connections
	FROM	RR_Assets
	WHERE	RR_Status = 1;

	UPDATE	RR_Assets
	SET		RR_Start_ID = NULL,
			RR_End_ID = NULL;

	UPDATE	RR_Assets
	SET		RR_Start_ID = Node_ID
	FROM	RR_Assets, rr_Nodes
	WHERE	RR_Status = 1
	AND		ROUND(RR_Assets.Shape.STStartPoint().STX, 1) = rr_Nodes.X
	AND		ROUND(RR_Assets.Shape.STStartPoint().STY, 1) = rr_Nodes.Y;

	UPDATE	RR_Assets
	SET		RR_End_ID = Node_ID
	FROM	RR_Assets, rr_Nodes
	WHERE	RR_Status = 1
	AND		ROUND(RR_Assets.Shape.STEndPoint().STX, 1) = rr_Nodes.X
	AND		ROUND(RR_Assets.Shape.STEndPoint().STY, 1) = rr_Nodes.Y;

	UPDATE	rr_Nodes
	SET Connections = 0;
	
	UPDATE	rr_Nodes
	SET		Connections = v_60_NodeStartCount.Count
	FROM	v_60_NodeStartCount INNER JOIN rr_Nodes ON v_60_NodeStartCount.Node_ID = rr_Nodes.Node_ID;

	UPDATE	rr_Nodes
	SET		Connections = Connections + v_60_NodeEndCount.Count
	FROM	v_60_NodeEndCount INNER JOIN rr_Nodes ON v_60_NodeEndCount.Node_ID = rr_Nodes.Node_ID;

END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v_60_Merge_Nodes]
AS
SELECT	dbo.rr_Nodes.Connections, rr_Nodes.Node_ID, Assets1.RR_Asset_ID AS AssetID1, Assets1.RR_Length AS Length1, Assets1.RR_End_ID AS NodeID1, Assets2.RR_Asset_ID AS AssetID2, Assets2.RR_Length AS Length2, 
		Assets2.RR_Start_ID AS NodeID2, Assets1.RR_AssetName, Merged1.Child_ID AS MergedID1, Merged2.Child_ID AS MergedID2
FROM	dbo.rr_merged AS Merged2 RIGHT OUTER JOIN
		dbo.RR_Assets AS Assets1 INNER JOIN
		dbo.rr_Nodes ON Assets1.RR_Start_ID = dbo.rr_Nodes.Node_ID INNER JOIN
		dbo.RR_Assets AS Assets2 ON dbo.rr_Nodes.Node_ID = Assets2.RR_End_ID AND Assets1.RR_InstallYear = Assets2.RR_InstallYear AND Assets1.RR_Material = Assets2.RR_Material AND 
		Assets1.RR_Diameter = Assets2.RR_Diameter AND Assets1.RR_Status = Assets2.RR_Status AND Assets1.RR_Asset_ID <> Assets2.RR_Asset_ID  LEFT OUTER JOIN
		dbo.rr_merged AS Merged1 ON Assets1.RR_Asset_ID = Merged1.Child_ID ON Merged2.Child_ID = Assets2.RR_Asset_ID
		AND Assets1.RR_Diameter > 0 AND Assets1.RR_InstallYear > 0 AND Assets1.RR_Material <> 'UNK'
WHERE	(dbo.rr_Nodes.Connections = 2) AND Assets1.RR_Length < 500 AND Assets2.RR_Length < 500 AND Assets1.RR_Status = 1
UNION
SELECT	dbo.rr_Nodes.Connections, rr_Nodes.Node_ID, Assets1.RR_Asset_ID AS AssetID1, Assets1.RR_Length AS Length1, Assets1.RR_End_ID AS NodeID1, Assets2.RR_Asset_ID AS AssetID2, Assets2.RR_Length AS Length2, 
		Assets2.RR_End_ID AS NodeID2, Assets1.RR_AssetName, Merged1.Child_ID AS MergedID1, Merged2.Child_ID AS MergedID2
FROM	dbo.rr_merged AS Merged2 RIGHT OUTER JOIN
		dbo.RR_Assets AS Assets1 INNER JOIN
		dbo.rr_Nodes ON Assets1.RR_Start_ID = dbo.rr_Nodes.Node_ID INNER JOIN
		dbo.RR_Assets AS Assets2 ON dbo.rr_Nodes.Node_ID = Assets2.RR_Start_ID AND Assets1.RR_InstallYear = Assets2.RR_InstallYear AND Assets1.RR_Material = Assets2.RR_Material AND 
		Assets1.RR_Diameter = Assets2.RR_Diameter AND Assets1.RR_Status = Assets2.RR_Status AND Assets1.RR_Asset_ID <> Assets2.RR_Asset_ID LEFT OUTER JOIN
		dbo.rr_merged AS Merged1 ON Assets1.RR_Asset_ID = Merged1.Child_ID ON Merged2.Child_ID = Assets2.RR_Asset_ID
		AND Assets1.RR_Diameter > 0 AND Assets1.RR_InstallYear > 0 AND Assets1.RR_Material <> 'UNK'
WHERE	(dbo.rr_Nodes.Connections = 2) AND Assets1.RR_Length < 500 AND Assets2.RR_Length < 500 AND Assets1.RR_Status = 1
UNION
SELECT	dbo.rr_Nodes.Connections, rr_Nodes.Node_ID, Assets1.RR_Asset_ID AS AssetID1, Assets1.RR_Length AS Length1, Assets1.RR_Start_ID AS NodeID1, Assets2.RR_Asset_ID AS AssetID2, Assets2.RR_Length AS Length2, 
		Assets2.RR_Start_ID AS NodeID2, Assets1.RR_AssetName, Merged1.Child_ID AS MergedID1, Merged2.Child_ID AS MergedID2
FROM	dbo.rr_merged AS Merged2 RIGHT OUTER JOIN
		dbo.RR_Assets AS Assets1 INNER JOIN
		dbo.rr_Nodes ON Assets1.RR_End_ID = dbo.rr_Nodes.Node_ID INNER JOIN
		dbo.RR_Assets AS Assets2 ON dbo.rr_Nodes.Node_ID = Assets2.RR_End_ID AND Assets1.RR_InstallYear = Assets2.RR_InstallYear AND Assets1.RR_Material = Assets2.RR_Material AND 
		Assets1.RR_Diameter = Assets2.RR_Diameter AND Assets1.RR_Status = Assets2.RR_Status AND Assets1.RR_Asset_ID <> Assets2.RR_Asset_ID LEFT OUTER JOIN
		dbo.rr_merged AS Merged1 ON Assets1.RR_Asset_ID = Merged1.Child_ID ON Merged2.Child_ID = Assets2.RR_Asset_ID
		AND Assets1.RR_Diameter > 0 AND Assets1.RR_InstallYear > 0 AND Assets1.RR_Material <> 'UNK'
WHERE	(dbo.rr_Nodes.Connections = 2) AND Assets1.RR_Length < 500 AND Assets2.RR_Length < 500 AND Assets1.RR_Status = 1
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [p_60_MergePipesSub]
@NodeID int, @PrevAssetID int, @ParentID int, @Len float
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @AssetID int, @LenNew float, @Existing int, @NextNode int, @MergedID int;
	DECLARE @Count int = 0;
	
	DECLARE c2 CURSOR LOCAL FOR SELECT 
		CASE WHEN AssetID2=@PrevAssetID THEN AssetID1 ELSE AssetID2 END AS AssetID, 
		CASE WHEN AssetID2=@PrevAssetID THEN MergedID1 ELSE MergedID2 END AS MergedID, 
		CASE WHEN AssetID2=@PrevAssetID THEN Length1 ELSE Length2 END AS LenFt,  
		CASE WHEN AssetID2=@PrevAssetID THEN NodeID1 ELSE NodeID2 END AS NexNode FROM [v_60_Merge_Nodes] WHERE Node_ID = @NodeID
		AND (MergedID1 IS NULL OR MergedID2 IS NULL);
	OPEN c2;
	FETCH NEXT FROM c2 INTO  @AssetID, @MergedID, @LenNew, @NextNode;
	--WHILE @@FETCH_STATUS = 0  
	IF @@FETCH_STATUS = 0  --There could be two records for the same asset id du to start to start or end to end link
	BEGIN  

		SELECT @Count = @Count +1;

		--DECLARE c3 CURSOR LOCAL FOR SELECT Parent_ID FROM rr_merged WHERE Child_ID = @AssetID;
		--OPEN c3;
		--FETCH NEXT FROM c3 INTO @Existing;
		--IF @@FETCH_STATUS = 0  
		--	PRINT '  Exsting Parent: ' + CAST(@ParentID AS varchar(20)) + ', Child: ' + CAST(@AssetID AS varchar(20)) ;
		--ELSE 
		IF @MergedID IS NULL
		  PRINT '  Exsting Parent: ' + CAST(@ParentID AS varchar(20)) + ', Child: ' + CAST(@AssetID AS varchar(20)) ;
		BEGIN
		  IF @Len + @LenNew < 800
			BEGIN

			PRINT '  Insert Parent('+ CAST(@Count AS varchar(4)) + '): ' + CAST(@ParentID AS varchar(20)) + ', Child: ' + CAST(@AssetID AS varchar(20)) + ', Len=' + CAST(Round(@LenNew, 1) AS varchar(20)) + ', Totl=' + CAST(Round(@Len + @LenNew, 1) AS varchar(20)) ;

			INSERT INTO rr_merged (Child_ID, Parent_ID, Length) VALUES (@AssetID, @ParentID, @LenNew);
			SELECT @Len = @Len + @LenNew;
			EXEC [p_60_MergePipesSub] @NextNode, @AssetID, @ParentID, @Len;
			END
		END
		--CLOSE c3;  
		--DEALLOCATE c3;

	--	FETCH NEXT FROM c2 INTO  @AssetID, @MergedID, @LenNew, @NextNode; --this should not return
	END
	CLOSE c2;  
	DEALLOCATE c2;

END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [p_60_MergePipes]
AS 
BEGIN

-- select the 2 pipes with a 2 connection node
-- add the first pipe to rr_merged
-- process the first pipe's other node (recursively) to capture all 2 connection pipes on that side
-- add the second pipe to rr_merged
-- process the second pipe's other node (recursively) to capture all 2 connection pipes on that side

	SET NOCOUNT ON;

	DECLARE @NodeID int, @AssetName varchar(16), @AssetID1 int, @Len1 float, @NodeID1 int, @AssetID2 int, @Len2 float, @NodeID2 int, @Existing int, @NewParentID int, @Shape GEOMETRY;
	DECLARE @Found1 int, @Found2 int;
	DECLARE @SRID int = 2273;  --must set this to the projection used by RR_Assets

	delete from rr_merged
	delete from rr_merged_geo


	DECLARE c0 CURSOR FOR 
	SELECT Node_ID, AssetID1, Length1, NodeID1, AssetID2, Length2, NodeID2, RR_AssetName FROM [v_60_Merge_Nodes] 
	WHERE MergedID1 IS NULL and MergedID1 IS NULL
	ORDER BY Length1 ;
	OPEN c0;
	FETCH NEXT FROM c0 INTO @NodeID, @AssetID1, @Len1, @NodeID1, @AssetID2, @Len2, @NodeID2, @AssetName;
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		SELECT @Found1 = 0, @Found2 = 0;

		DECLARE c1 CURSOR FOR SELECT Parent_ID FROM rr_merged WHERE Child_ID = @AssetID1;
		OPEN c1;
		FETCH NEXT FROM c1 INTO @Existing;
		IF @@FETCH_STATUS =	0 
			SELECT @AssetID1 = @AssetID2; --so ID2 is used as parent
		ELSE
			BEGIN
				SELECT @Found1 = 1;

				INSERT INTO rr_merged (Child_ID, Parent_ID, Length) VALUES (@AssetID1, @AssetID1, @Len1);
				PRINT 'Parent: ' + CAST(@AssetID1 AS varchar(20)) + ', Child: ' + CAST(@AssetID1 AS varchar(20)) + ', Len=' + CAST(Round(@Len1, 1) AS varchar(20)) ;

				EXEC p_60_MergePipesSub @NodeID1, @AssetID1, @AssetID1, @Len1;	
			END
		CLOSE c1;  
		DEALLOCATE c1; 				

		DECLARE c1 CURSOR FOR SELECT Parent_ID FROM rr_merged WHERE Child_ID = @AssetID2;
		OPEN c1;
		FETCH NEXT FROM c1 INTO @Existing;
		IF @@FETCH_STATUS <> 0  
			BEGIN
				SELECT @Found2 = 1;

				INSERT INTO rr_merged (Child_ID, Parent_ID, Length) VALUES (@AssetID2, @AssetID1, @Len2);
				PRINT '  Insert Parent: ' + CAST(@AssetID1 AS varchar(20)) + ', Child: ' + CAST(@AssetID2 AS varchar(20)) + ', Len=' + CAST(Round(@Len2, 1) AS varchar(20)) ;

				SELECT @Len1 = Sum(Length) FROM rr_merged WHERE Parent_ID = @AssetID1;

				EXEC p_60_MergePipesSub @NodeID2, @AssetID2, @AssetID1, @Len2;	
			END
		CLOSE c1;  
		DEALLOCATE c1; 				
				
		IF @Found1 = 1 OR @Found2 = 1
		BEGIN
			DECLARE c1a CURSOR FOR SELECT TOP 1 Child_ID FROM rr_merged WHERE Parent_ID = @AssetID1 ORDER BY Length DESC;
			OPEN c1a;
			FETCH NEXT FROM c1a INTO @NewParentID;
			IF @@FETCH_STATUS = 0 
				BEGIN
					PRINT '   Update new parent: ' +  CAST(@NewParentID AS varchar(20));
					UPDATE rr_merged SET Parent_ID = @NewParentID WHERE Parent_ID = @AssetID1;

					SET @Shape = GEOMETRY::STGeomFromText('GEOMETRYCOLLECTION EMPTY', @SRID);
					SELECT @Shape = @Shape.STUnion(Shape) FROM rr_merged JOIN RR_Assets ON rr_merged.Child_ID = RR_Assets.RR_Asset_ID WHERE rr_merged.Parent_ID = @NewParentID;
					INSERT INTO rr_merged_geo (Parent_ID, Name, Length, shape) VALUES (@NewParentID, @AssetName, @Shape.STLength(), @Shape);
					PRINT '   Insert Geo: ' +  CAST(@NewParentID AS varchar(20));

				END
			CLOSE c1a;  
			DEALLOCATE c1a; 
		END
		ELSE PRINT 'Not Found'

		FETCH NEXT FROM c0 INTO @NodeID, @AssetID1, @Len1, @NodeID1, @AssetID2, @Len2, @NodeID2, @AssetName;
	END   
	CLOSE c0;  
	DEALLOCATE c0; 

END
GO

/****** Object:  StoredProcedure [p___Alias_PBI]    Script Date: 10/21/2022 9:24:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [p___Alias_PBI]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @sSearch nvarchar(64)
	DECLARE @sReplace nvarchar(64)
	DECLARE @sResult nvarchar(max)

	DECLARE c0 CURSOR
	FOR	SELECT ColumnName, ReplaceText FROM RR_ConfigAliases WHERE Usage <> 'NA'; -- AND ColumnName NOT LIKE 'RR_OM%' ;
	OPEN c0
	FETCH NEXT FROM c0 INTO @sSearch, @sReplace ;

	SELECT @sResult = '= Table.RenameColumns(dbo_q_PBI_Inventory,{';
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SELECT @sResult = @sResult + '{"' + @sSearch + '", "' + REPLACE(REPLACE(@sReplace, '[', ''), ']', '') + '"}, ';
		FETCH NEXT FROM c0 INTO @sSearch, @sReplace ;
	END
	CLOSE c0;  
	DEALLOCATE c0; 
	
	SELECT @sResult = SUBSTRING(@sResult, 1, LEN(@sResult)-2) + '}})';
	
	SELECT @sResult;

END
GO

/****** Object:  StoredProcedure [p___Alias_Views]    Script Date: 10/21/2022 9:24:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [p___Alias_Views] 

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

--v5.006
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [p___FulcrumUpdate]
AS
BEGIN

	SET NOCOUNT ON;

	--Insert hierarchy records and asset record placeholders
	DECLARE @minid int = (select min(id) from [ref_Fulcrum])
	,@maxid bigint = (select max(id) from [ref_Fulcrum] )
	,@hierarchyname varchar(510), @RR_hierarchyid int, @fulcrumid varchar(510)
	,@ssql int, @rshierarchyid int

	WHILE (@minid<=@maxid)
	BEGIN
		SELECT @fulcrumid = _record_id, @hierarchyname = rr_hierarchylevel
		FROM [ref_Fulcrum] 
		WHERE ID = @minid 

		drop table if exists #hierarchy;
		select id = identity(int), value
		into #hierarchy
		from STRING_SPLIT(@hierarchyname, ',') 

		declare @minvalue int, @maxvalue int, @parentid int = null
		select @minvalue = min(id), @maxvalue = max(id) 
		from #hierarchy

		while(@minvalue <= @maxvalue)
		begin
			select @hierarchyname=value from #hierarchy where id=@minvalue
			if @parentid is null
				set @ssql =null
			else
				set @ssql =@parentid

				set @RR_hierarchyid = (SELECT RR_Hierarchy_ID FROM RR_Hierarchy WHERE RR_HierarchyName = @hierarchyname and 
																	1= case when rr_parent_id is null and @ssql is null then 1 
																			when  @ssql =@parentid and rr_parent_id=@parentid then 1 end )
			
			if count(@RR_hierarchyid)=1
				set @parentid=@RR_hierarchyid
			else 
			begin
				INSERT INTO RR_Hierarchy (RR_HierarchyName,RR_Parent_ID)
				select @hierarchyname,@parentid
				set @parentid = scope_identity()
			end
	
			set @minvalue=@minvalue+1

		end
			
		if not exists (SELECT top 1 1  FROM RR_Assets WHERE RR_Fulcrum_ID = @fulcrumid )
			begin
				insert into RR_Assets(RR_Fulcrum_ID, RR_Hierarchy_ID)
				select @fulcrumid,@parentid
			end
		else
			begin
				set @rshierarchyid  =(SELECT top 1 RR_Hierarchy_ID FROM RR_Assets WHERE RR_Fulcrum_ID = @fulcrumid ) 
				if @rshierarchyid is not null and @parentid is not null
					UPDATE RR_Assets SET RR_Hierarchy_ID=@parentid where RR_Fulcrum_ID = @fulcrumid and RR_Hierarchy_ID =@rshierarchyid
			end

		set @minid=@minid+1
	END


 	--Update asset records with additional attributes
	UPDATE	RR_Assets
	SET	RR_AssetName = SUBSTRING(ref_Fulcrum.rr_asset_name, 0, 64),
			RR_InstallYear = ISNULL(ref_Fulcrum.rr_install_year, 1900), 
			RR_AssetType = ISNULL(ref_Fulcrum.rr_asset_type, 'Unknown'),
			RR_Status = 1, 
			RR_SourceTxt_ID = ref_Fulcrum.rr_cmms_id, 
			RR_FieldCode = ref_Fulcrum.rr_field_code, 
			RR_Barcode = ref_Fulcrum.rr_asset_number,
			RR_InspectionType = ref_Fulcrum.rr_inspection_type,
			RR_Manufacturer = ref_Fulcrum.rr_manufacturer, 
			RR_ModelNumber = ref_Fulcrum.rr_model_number, 
			RR_SerialNumber = ref_Fulcrum.rr_serial_number, 
			RR_TagNumber = ref_Fulcrum.rr_tag_number, 
			RR_MotorManufacturer = ref_Fulcrum.rr_motor_manufacturer, 
			RR_GPM = ref_Fulcrum.rr_gpm, 
			RR_Head = ref_Fulcrum.rr_head, 
			RR_CFM = ref_Fulcrum.rr_cfm,
			RR_FiltrationRate = ref_Fulcrum.rr_filtration_rate, 
			RR_Tons = ref_Fulcrum.rr_tons, 
			RR_CapacityDiameter = ref_Fulcrum.rr_diameter, 
			RR_HP = ref_Fulcrum.rr_hp, 
			RR_Voltage = ref_Fulcrum.rr_voltage,
			RR_FLA = ref_Fulcrum.rr_fla,
			RR_Phase = ref_Fulcrum.rr_phase, 
			RR_RPM = ref_Fulcrum.rr_rpm,
			RR_SQFT = ref_Fulcrum.rr_sqft,
			RR_Gallons = ref_Fulcrum.rr_gallons, 
			RR_MaxFillHeight = ref_Fulcrum.rr_max_fill_height,
			RR_CapacityOther = ref_Fulcrum.rr_capacity_other, 
			RR_MotorHertz = ref_Fulcrum.rr_motor_hertz,
			RR_ConstructionType = ref_Fulcrum.rr_construction_type,
--			RR_AssetCostReplace = 100,
			RR_InheritCost = 0
	FROM	RR_Assets INNER JOIN ref_Fulcrum ON ref_Fulcrum._record_id = RR_Assets.RR_Fulcrum_ID;


	--Build and execute SQL to insert inspection records based on aliases 
	DECLARE	@ColumnName NVARCHAR(max), @FulcrumName NVARCHAR(max);

	SET @ColumnName = NULL;
	SET @fulcrumname = NULL;

	SELECT	@ColumnName = COALESCE(@ColumnName + ',', ',') + ColumnName
			,@FulcrumName = COALESCE(@FulcrumName + ',f.', ',f.') + FulcrumName
	FROM	RR_ConfigAliases
	WHERE	FulcrumName IS NOT NULL
	ORDER	BY alias_id;

	DECLARE @sql NVARCHAR(max) = 'INSERT INTO RR_Inspections (RR_Asset_ID, RR_SourceTxt_ID, RR_Fulcrum_ID, RR_InspectionType, RR_InspectionDate';

	SET @sql = @sql + @ColumnName + ' )' + CHAR(10)
	SET @sql = @sql + ' SELECT a.RR_Asset_ID, a.RR_SourceTxt_ID, f._record_id, f.rr_inspection_type, f._server_updated_at' + @FulcrumName
	SET @sql = @sql + ' FROM ref_Fulcrum AS f INNER JOIN RR_Assets AS a ON a.RR_Fulcrum_ID = f._record_id LEFT OUTER JOIN RR_Inspections ON f._record_id = RR_Inspections.RR_Fulcrum_ID'
	SET @sql = @sql + ' WHERE RR_Inspections.RR_Fulcrum_ID IS NULL';
	
	--SELECT @sql;

	EXEC sp_executesql @sql;

	--Update inspection records concatonated notes
	UPDATE	RR_Inspections
	SET		RR_InspectNotes = CONCAT_WS('; ', [corrosion_comments],[transformer_coolant_comments], [leakage_comments], [vibration_comments], [steel_damage_comments], [electrical_damage_comments],
				[motors_core_comments], [roof_core_comments], [concrete_masonry_damage_comments], [joint_damage_comments], [settling_comments], [wood_damage_comments], 
				[general_comments], [concrete_pedestals_comments], [steel_supports_comments], [support_base_comments], [piping_valves_comments], [local_panels_comments], [field_instruments_comments],
				[electrical_connections_comments],  [roof_comments], [walkways_comments], [doors_comments], [ductwork_comments],  [filters_traps_comments],
				[motors_comments], [insulation_comments], [performance_comments])
	FROM	RR_Inspections INNER JOIN ref_Fulcrum ON ref_Fulcrum._record_id = RR_Inspections.RR_Fulcrum_ID;

	--Insert hyperlink records
	MERGE RR_Hyperlinks AS TARGET
	USING	(SELECT RR_Assets.RR_Asset_ID, RR_Assets.rr_fulcrum_id, RR_Assets.RR_AssetName, ref_Fulcrum.rr_photos
			FROM ref_Fulcrum INNER JOIN RR_Assets ON ref_Fulcrum._record_id = RR_Assets.rr_fulcrum_id
			WHERE ref_Fulcrum.rr_photos Is Not Null) AS SOURCE
	ON (TARGET.RR_Asset_ID = SOURCE.RR_Asset_ID AND TARGET.fulcrum_id = SOURCE.rr_fulcrum_id )
	WHEN NOT MATCHED BY TARGET
	THEN INSERT (RR_Asset_ID, FileHyperlink, Fulcrum_ID, AssetName)         
			VALUES (SOURCE.RR_Asset_ID, SOURCE.rr_photos, SOURCE.rr_fulcrum_id, SOURCE.RR_AssetName);
			 
END
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

--2024-01-16 updated
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[p___QC_ListTables] 
	@tablename nvarchar(64) = '%'
AS
BEGIN

-- 2024-01-15 tweak
--	SET ANSI_WARNINGS OFF
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
	CREATE TABLE #tempColumnDetails (TableName nvarchar(64), ColumnName nvarchar(64), DataType nvarchar(32), MinVal float, MaxVal float, ZeroVals int, NegativeVals int, TotalRows int, DistinctVals int, Populated int)

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
			ELSE IF @type LIKE '%xml%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, NULL AS mn, NULL AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated FROM ' + QUOTENAME(@tablename)
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
			ELSE IF @type LIKE '%uniqueidentifier%'
				SET @sql = 'INSERT INTO #tempColumnDetails '
							+ 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, NULL AS mn, NULL AS mx, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated FROM ' + QUOTENAME(@tablename)
			ELSE IF @type LIKE '%varbinary%'
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

-- 2024-01-15 tweak
--	SET ANSI_WARNINGS OFF

END


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ref_MaterialYearDiameters](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[System] [nvarchar](32) NULL,
	[Material] [nvarchar](64) NULL,
	[RRPS_Material] [nvarchar](64) NULL,
	[MinYear] [int] NULL,
	[MaxYear] [int] NULL,
	[MinDia] [int] NULL,
	[MaxDia] [int] NULL,
	[EarlierAssume] [nvarchar](64) NULL,
	[LaterAssume] [nvarchar](64) NULL,
	[Notes] [nvarchar](500) NULL,
 CONSTRAINT [PK_ref_MaterialYears] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ref_MaterialYearDiameters] ADD  CONSTRAINT [DF_ref_MaterialYearDiameters_System]  DEFAULT (N'Water or Sewer') FOR [System]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create VIEW [dbo].[v_QC_Stats_MtlYearDia]
AS
SELECT	RR_Asset_ID, RR_SourceTxt_ID, RR_Material, RR_Diameter, RR_InstallYear, RR_Length, 
		ISNULL('Material', 'UNK') AS Material, ISNULL(0, 0) AS Diameter, ISNULL(0, 0) AS InstallYear, 
		ISNULL('Owner', 'UNK') AS Owner, ISNULL('Status', 'UNK') AS Status, ISNULL('Type', 'UNK') AS Type
FROM            dbo.RR_Assets
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW [dbo].[v_QC_Stats_MtlYearDiaIssues]
AS
SELECT	ref.Material AS Description, Assets.Material, ref.Notes, 
		MIN(Assets.InstallYear) AS ActualMinDate, MAX(Assets.InstallYear) AS ActualMaxDate, 
		ref.MinYear AS StandardMinYear, ref.MaxYear AS StandardMaxYear, 
		SUM(CASE WHEN InstallYear < 1800 THEN 1 ELSE 0 END) AS UnknownInstallCount, 
		ROUND(SUM(CASE WHEN InstallYear < 1800 THEN RR_Length / 5280 ELSE 0 END), 2) AS UnknownInstallMiles, 
		SUM(CASE WHEN InstallYear < ISNULL(MinYear, 1800) THEN 1 ELSE 0 END) AS EarlierInstallCount, 
		ROUND(SUM(CASE WHEN InstallYear < ISNULL(MinYear, 1800) THEN RR_Length / 5280 ELSE 0 END), 2) AS EarlierInstallMiles, 
		SUM(CASE WHEN InstallYear > ISNULL(MaxYear, 2022) THEN 1 ELSE 0 END) AS LaterInstallCount, 
		ROUND(SUM(CASE WHEN InstallYear > ISNULL(MaxYear, 2022) THEN RR_Length / 5280 ELSE 0 END), 2) AS LaterInstallMiles, 
		MIN(Assets.Diameter) AS ActualMinDia, MAX(Assets.Diameter) AS ActualMaxDia, ref.MinDia AS StandardMinDia, ref.MaxDia AS StandardMaxDia, 
		SUM(CASE WHEN Diameter <= 0 THEN 1 ELSE 0 END) AS UnknownDiaCount, ROUND(SUM(CASE WHEN Diameter <= 0 THEN RR_Length / 5280 ELSE 0 END), 2) AS UnknownDiaMiles,
		SUM(CASE WHEN Diameter < ISNULL(MinDia, 1) THEN 1 ELSE 0 END) AS SmallerDiaCount,
		ROUND(SUM(CASE WHEN Diameter < ISNULL(MinDia, 1) THEN RR_Length / 5280 ELSE 0 END), 2) AS SmallerDiaMiles, 
		SUM(CASE WHEN Diameter > ISNULL(MaxDia, 1000) THEN 1 ELSE 0 END) AS LargerDiaCount, 
		ROUND(SUM(CASE WHEN Diameter > ISNULL(MaxDia, 1000) THEN RR_Length / 5280 ELSE 0 END), 2) AS LargerDiaMiles
FROM	dbo.ref_MaterialYearDiameters AS ref INNER JOIN
		dbo.v_QC_Stats_MtlYearDia AS Assets ON ref.RRPS_Material = Assets.Material
WHERE	(ref.System LIKE N'%Sewer%')
GROUP BY ref.Notes, ref.MinYear, ref.MaxYear, ref.MinDia, ref.MaxDia, Assets.Material, ref.Material
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_QC__Status]
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
CREATE VIEW [dbo].[v_00_11_Revisions]
AS
SELECT	ID, Notes, CreatedOn, CreatedBy, LastEditedOn, LastEditedBy
FROM	dbo.RR_Revisions
GO



--v5.005a
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
