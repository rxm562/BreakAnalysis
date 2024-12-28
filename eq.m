USE [SAWS_Infor]
GO
/****** Object:  StoredProcedure [dbo].[p_Report_Inventory]    Script Date: 12/28/2024 12:01:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[p_Report_Inventory]
AS
BEGIN

	SET NOCOUNT ON;

	--Stats by Diameter
	Select PIPEDIAM, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles,
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_MAINS
	Group by PIPEDIAM

	Select DIAM as Diameter, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles,
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_LATERALS
	Group by DIAM

	Select DIAM as Diameter, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles,
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from RCY_MAINS
	Group by DIAM order by DIAM

	Select DIAM as Diameter, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles,
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from RCY_LATERALS
	Group by DIAM order by DIAM

	--Stats by Material, Install Year Range and Diameter Range
	--Sewer Mains (excluding Year==9999):
	SELECT PIPETYPE, min(Year(InstDate)) as [Min Ins Year], max(Year(InstDate)) as [Max Ins Year], min(PIPEDIAM) as [Min Dia], max(PIPEDIAM) as [Max Dia],
	Count(*) as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_MAINS --where Year(InstDate)<>9999
	group by PIPETYPE order by PIPETYPE

	--Sewer Laterals (excluding Year==9999):
	SELECT PIPETYPE, min(Year(InstDate)) as [Min Ins Year], max(Year(InstDate)) as [Max Ins Year], min(DIAM) as [Min Dia], max(DIAM) as [Max Dia], 
	Count(*) as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles from SWR_LATERALS --where Year(InstDate)<>9999
	group by PIPETYPE order by PIPETYPE

	--RCY Mains (excluding Year==9999):
	SELECT PIPETYPE, min(Year(InstDate)) as [Min Ins Year], max(Year(InstDate)) as [Max Ins Year], min(DIAM) as [Min Dia], max(DIAM) as [Max Dia], 
	Count(*) as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles from RCY_MAINS --where Year(InstDate)<>9999
	group by PIPETYPE order by PIPETYPE

	--RCY Laterals (excluding Year==9999):
	SELECT PIPETYPE, min(Year(InstDate)) as [Min Ins Year], max(Year(InstDate)) as [Max Ins Year], min(DIAM) as [Min Dia], max(DIAM) as [Max Dia], 
	Count(*) as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles from RCY_LATERALS --where Year(InstDate)<>9999
	group by PIPETYPE order by PIPETYPE

	--UnitType Sewer Mains:
	Select Unittype, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles,
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_MAINS
	Group by Unittype

	--UnitType Sewer Laterals:
	Select Unittype, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, 
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_LATERALS
	Group by Unittype

	--UnitType RCY MAINS:
	Select Unittype, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, 
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from RCY_MAINS
	Group by Unittype

	--UnitType RCY LATERALS:
	Select Unittype, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, 
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from RCY_LATERALS
	Group by Unittype

	--Owner Sewer Mains:
	Select Own, SERVSTAT, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, 
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_MAINS
	Group by Own, SERVSTAT

	--Owner Sewer Laterals:
	Select Own, SERVSTAT, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, 
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from SWR_LATERALS
	Group by Own, SERVSTAT

	--Owner RCY MAINS:
	Select Own, SERVSTAT, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles,
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from RCY_MAINS
	Group by Own, SERVSTAT

	--Owner RCY LATERALS:
	Select Own, SERVSTAT, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, 
	ROUND(SUM(PIPELEN) / SUM(SUM(PIPELEN)) OVER () * 100, 2) AS [% Sys] from RCY_LATERALS
	Group by Own, SERVSTAT


	-- Unique idenifier duplicates
	Select UNITID, Count(*) from SWR_MAINS
	group by UNITID having Count(*)>1
	order by UNITID

	Select COMPKEY, Count(*) from SWR_MAINS
	group by COMPKEY having Count(*)>1
	order by COMPKEY
	
	-- Unit Type Counts
	Select UNITTYPE, UNITTYPECODE, Count(*) from SWR_MAINS
	group by UNITTYPE, UNITTYPECODE

	-- Easement Stats
	Select EASEMENT, Format(Count(*),'#,##0.##') as Segments, Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles from SWR_MAINS
	Group by EASEMENT

	Select AssetType, Year(StartDate) as InitialYear  from v_ArcadisDP_WorkOrders

	Select AssetType, Count(*) as Segments  from v_ArcadisDP_WorkOrders
	group by AssetType


		--All four inventory
	Select Distinct MAINKEY1, UNITID from SWR_MAINS
	Select * from SWR_MAINS
	Select * from SWR_LATERALS
	Select * from RCY_MAINS
	Select * from RCY_LATERALS

	Select distinct Unittype from SWR_MAINS

	Select COMPDESC, Count(*) from WorkOrders
	group by COMPDESC

	Select Format(Round(Sum(PIPELEN/5280),2),'#,##0.##') as Miles, Format(Count(*),'#,##0.##') as Segments from RCY_LATERALS

END
