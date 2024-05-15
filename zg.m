SELECT InstallYear, DIAMETER, MATERIAL, 
                  CASE WHEN InstallYear > 2023 THEN '>2023' WHEN InstallYear > 2000 THEN '2001-2023' WHEN InstallYear > 1980 THEN '1981-2000' WHEN InstallYear > 1960 THEN '1961-1980' WHEN InstallYear > 1940 THEN '1941-1960' WHEN InstallYear > 1920
                   THEN '1921-1940' WHEN InstallYear > 1900 THEN '1901-1920' WHEN InstallYear = 1900 THEN '1900' ELSE '<1900' END AS Tag, RR_Length
FROM     dbo.v__ActiveAssets

SELECT Tag AS YearRange, COUNT(*) AS Count, MIN(DIAMETER) AS MinDia, MAX(DIAMETER) AS MaxDia, ROUND(SUM(RR_Length) / 5280, 2) AS Miles
FROM     dbo.v_YearSummary
GROUP BY Tag

Stat_byInstallYear
