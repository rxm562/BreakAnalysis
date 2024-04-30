SELECT OBJECTID, Shape, GEOID10, SF, CF, DF_PFS, AF_PFS, HDF_PFS, DSF_PFS, EBF_PFS, EALR_PFS, EBLR_PFS, EPLR_PFS, HBF_PFS, LLEF_PFS, LIF_PFS, LMI_PFS, PM25F_PFS, HSEF, P100_PFS, P200_I_PFS, AJDLI_ET, LPF_PFS, KP_PFS, 
                  NPL_PFS, RMP_PFS, TSDF_PFS, TPF, TF_PFS, UF_PFS, WF_PFS, UST_PFS, N_WTR, N_WKFC, N_CLT, N_ENY, N_TRN, N_HSG, N_PLN, N_HLTH, SN_C, SN_T, DLI, ALI, PLHSE, LMILHSE, ULHSE, EPL_ET, EAL_ET, EBL_ET, EB_ET, PM25_ET, 
                  DS_ET, TP_ET, LPP_ET, HRS_ET, KP_ET, HB_ET, RMP_ET, NPL_ET, TSDF_ET, WD_ET, UST_ET, DB_ET, A_ET, HD_ET, LLE_ET, UN_ET, LISO_ET, POV_ET, LMI_ET, IA_LMI_ET, IA_UN_ET, IA_POV_ET, TC, CC, IAULHSE, IAPLHSE, IALMILHSE, 
                  IALMIL_76, IAPLHS_77, IAULHS_78, LHE, IALHE, IAHSEF, N_CLT_EOMI, N_ENY_EOMI, N_TRN_EOMI, N_HSG_EOMI, N_PLN_EOMI, N_WTR_EOMI, N_HLTH_88, N_WKFC_89, FPL200S, N_WKFC_91, TD_ET, TD_PFS, FLD_PFS, WFR_PFS, 
                  FLD_ET, WFR_ET, ADJ_ET, IS_PFS, IS_ET, AML_ET, FUDS_RAW, FUDS_ET, IMP_FLG, DM_B, DM_AI, DM_A, DM_HI, DM_T, DM_W, DM_H, DM_O, AGE_10, AGE_MIDDLE, AGE_OLD, TA_COU_116, TA_COUNT_C, TA_PERC, TA_PERC_FE, 
                  UI_EXP, THRHLD
FROM     dbo.USA_Climate_EquityTool
WHERE  (SF = 'New Hampshire')

SELECT OBJECTID, GEOID10 AS CTrackID, Shape, AGE_10 AS [Age<10yrs], AGE_MIDDLE AS Age10to64yrs, AGE_OLD AS [Age>64yrs]
FROM     dbo.v___County

SELECT OBJECTID, GEOID10 AS CTrackID, LPF_PFS, LPP_ET, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10 AS CTrackID, DM_B AS Black, DM_AI AS AmericanIndian, DM_A AS Asian, DM_HI AS NativeHawaiian, DM_W AS White, DM_T AS TwoRaces, DM_H AS Hispanic, DM_O AS Other, TPF AS TotalPop, AJDLI_ET, 
                  P200_I_PFS, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10 AS CTrackID, EAL_ET AS AgrLoss, EBL_ET AS BldgLoss, EPL_ET AS PopLoss, FLD_ET AS FldRisk, WFR_ET AS WildFRisk, EALR_PFS AS PrctAgr, EBLR_PFS AS PrctBldg, EPLR_PFS AS PrctPop, FLD_PFS AS PrctFld, 
                  WFR_PFS AS PrctWildF, Shape
FROM     dbo.v___County


SELECT OBJECTID, GEOID10, N_WTR AS Water_Fact, N_WKFC AS Workforce_Fact, N_CLT AS Climate_Fact, N_ENY AS Energy_Fact, N_TRN AS Transport_Fact, N_HSG AS Housing_Fact, N_PLN AS Pollution_Fact, N_HLTH AS Health_Fact, 
                  N_CLT_EOMI AS OneClimateExceed, N_ENY_EOMI AS OneEnergyExceed, N_TRN_EOMI AS OneTransportExceed, N_HSG_EOMI AS OneHousingExceed, N_PLN_EOMI AS OnePollutionExceed, N_WTR_EOMI AS OneWaterExceed, 
                  N_HLTH_88 AS OneHealthExceed, N_WKFC_89 AS OneWorkForceExceed, N_WKFC_91 AS BothWorkForce_SocioExceed, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10 AS CTrackID, EB_ET AS EnergyCost, PM25_ET AS PM25, EBF_PFS AS PrctEnergyCost, PM25F_PFS AS PrctPM25, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10, DB_ET AS Diabetes, A_ET AS Asthma, HD_ET AS HeartD, LLE_ET AS LowLE, DF_PFS AS PrctDiabetes, AF_PFS AS PrctAsthma, HDF_PFS AS PrctHeartD, LLEF_PFS AS PrctLowLE, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10 AS CTrackID, RMP_ET AS rmpProximity, NPL_ET AS nplProximity, TSDF_ET AS hazardProximity, AML_ET AS MineSite, FUDS_ET AS DefenseSite, NPL_PFS AS PrctNPL, RMP_PFS AS PrctRMP, 
                  TSDF_PFS AS PrctHazardW, Shape
FROM     dbo.v___County

SELECT OBJECTID, DS_ET AS DieselPM, TP_ET AS TrafficProximity, TD_ET AS TravelBarrier, DSF_PFS AS PrctDieselPM, TF_PFS AS PrctTrafficProximity, TD_PFS AS PrctTravelBarrier, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10 AS CTrackID, WD_ET AS WWDischarge, UST_ET AS LeakyTank, WF_PFS AS PrctWWDischage, UST_PFS AS PrctLeakyTank, Shape
FROM     dbo.v___County

SELECT OBJECTID, GEOID10, UN_ET AS Unemployment, LISO_ET AS LinguisticIso, POV_ET AS Poverty, LMI_ET AS LowMHIncome, UF_PFS AS PrctUnemployment, LIF_PFS AS PrctLinguisticIso, LMI_PFS AS PrctLowMHIncome, 
                  P100_PFS AS PrctPoverty, Shape
FROM     dbo.v___County
