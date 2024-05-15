SELECT Assets.MATERIAL, dbo.ref_MaterialYearDiameters.Material AS Description, dbo.ref_MaterialYearDiameters.Notes, MIN(ISNULL(YEAR(Assets.INSTALLDATE), 1800)) AS ActualMinDate, MAX(ISNULL(YEAR(Assets.INSTALLDATE), 1800)) 
                  AS ActualMaxDate, dbo.ref_MaterialYearDiameters.MinYear AS StandardMinYear, dbo.ref_MaterialYearDiameters.MaxYear AS StandardMaxYear, SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 0) < 1800 THEN 1 ELSE 0 END) 
                  AS UnknownInstallCount, ROUND(SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 0) < 1800 THEN RR_Length / 5280 ELSE 0 END), 2) AS UnknownInstallMiles, SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) < ISNULL(MinYear, 
                  1800) THEN 1 ELSE 0 END) AS EarlierInstallCount, ROUND(SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) < ISNULL(MinYear, 1800) THEN RR_Length / 5280 ELSE 0 END), 2) AS EarlierInstallMiles, 
                  SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) > ISNULL(MaxYear, 2023) THEN 1 ELSE 0 END) AS LaterInstallCount, ROUND(SUM(CASE WHEN ISNULL(YEAR(INSTALLDATE), 1800) > ISNULL(MaxYear, 2022) 
                  THEN RR_Length / 5280 ELSE 0 END), 2) AS LaterInstallMiles, MIN(Assets.DIAMETER) AS ActualMinDia, MAX(Assets.DIAMETER) AS ActualMaxDia, dbo.ref_MaterialYearDiameters.MinDia AS StandardMinDia, 
                  dbo.ref_MaterialYearDiameters.MaxDia AS StandardMaxDia, SUM(CASE WHEN ISNULL(DIAMETER, 0) <= 0 THEN 1 ELSE 0 END) AS UnknownDiaCount, ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 0) 
                  <= 0 THEN RR_Length / 5280 ELSE 0 END), 2) AS UnknownDiaMiles, SUM(CASE WHEN ISNULL(DIAMETER, 1000) < ISNULL(MinDia, 1) THEN 1 ELSE 0 END) AS SmallerDiaCount, ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 1000) 
                  < ISNULL(MinDia, 1) THEN RR_Length / 5280 ELSE 0 END), 2) AS SmallerDiaMiles, SUM(CASE WHEN ISNULL(DIAMETER, 0) > ISNULL(MaxDia, 1000) THEN 1 ELSE 0 END) AS LargerDiaCount, ROUND(SUM(CASE WHEN ISNULL(DIAMETER, 0) 
                  > ISNULL(MaxDia, 1000) THEN RR_Length / 5280 ELSE 0 END), 2) AS LargerDiaMiles
FROM     dbo.v__ActiveAssets AS Assets INNER JOIN
                  dbo.ref_MaterialYearDiameters ON Assets.MATERIAL = dbo.ref_MaterialYearDiameters.RRPS_Material
WHERE  (dbo.ref_MaterialYearDiameters.System LIKE N'%Water%')
GROUP BY dbo.ref_MaterialYearDiameters.Notes, dbo.ref_MaterialYearDiameters.MinYear, dbo.ref_MaterialYearDiameters.MaxYear, dbo.ref_MaterialYearDiameters.MinDia, dbo.ref_MaterialYearDiameters.MaxDia, Assets.MATERIAL, 
                  dbo.ref_MaterialYearDiameters.Material


v_QC_Stats_MtlYearDiaIssues

SELECT TOP (100) PERCENT MATERIAL, MIN(InstallYear) AS MinInstall, MAX(InstallYear) AS MaxInstall, MIN(DIAMETER) AS MinDia, MAX(DIAMETER) AS MaxDia, COUNT(*) AS Count, ROUND(SUM(RR_Length) / 5280, 4) AS Miles
FROM     dbo.v__ActiveAssets
GROUP BY MATERIAL

Stat_byMaterials

SELECT TOP (100) PERCENT DIAMETER, MIN(InstallYear) AS MinInsYear, MAX(InstallYear) AS MaxInsYear, COUNT(*) AS Assets, ROUND(SUM(RR_Length) / 5280, 2) AS Miles
FROM     dbo.v__ActiveAssets
GROUP BY DIAMETER

Stats_byDiameter

SELECT Tag AS YearRange, COUNT(*) AS Count, MIN(DIAMETER) AS MinDia, MAX(DIAMETER) AS MaxDia, ROUND(SUM(RR_Length) / 5280, 2) AS Miles
FROM     dbo.v_YearSummary
GROUP BY Tag

Stat_byInstallYear
