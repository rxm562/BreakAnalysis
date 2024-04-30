SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ref_BRA_Cohorts](
	[CohortRange_ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](64) NULL,
	[Material] [nvarchar](64) NULL,
	[MinYear] [smallint] NULL,
	[MaxYear] [smallint] NULL,
	[MinDiameter] [smallint] NULL,
	[MaxDiameter] [smallint] NULL,
	[Segments] [int] NULL,
	[Miles] [float] NULL,
	[Breaks] [smallint] NULL,
	[E_Slope] [float] NULL,
	[E_Intcpt] [float] NULL,
	[E_EUL] [float] NULL,
	[E_R2] [float] NULL,
	[L_Slope] [float] NULL,
	[L_Intcpt] [float] NULL,
	[L_EUL] [float] NULL,
	[L_R2] [float] NULL,
	[Active] [bit] NULL,
 CONSTRAINT [PK_ref_CohortRanges] PRIMARY KEY CLUSTERED 
(
	[CohortRange_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_ref_CohortRanges_MatlYearDia]    Script Date: 12/8/2022 6:26:41 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ref_CohortRanges_MatlYearDia] ON [ref_BRA_Cohorts]
(
	[Material] ASC,
	[MinYear] ASC,
	[MaxYear] ASC,
	[MinDiameter] ASC,
	[MaxDiameter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = ON, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [ref_BRA_Cohorts] ADD  CONSTRAINT [DF_ref_CohortRanges_Active]  DEFAULT ((1)) FOR [Active]
GO



/****** Object:  View [v___BRA_Assets]    Script Date: 12/8/2022 6:25:30 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Modified 2024-01-20 to remove unnecessary group by 

CREATE VIEW [v___BRA_Assets]
AS
--SELECT        RR_Asset_ID, RR_Material, RR_InstallYear, RR_Diameter, RR_Length, RR_PreviousFailures, SUM(RR_PreviousFailures) AS Breaks, COUNT(*) AS Segments, ROUND(SUM(RR_Length / 5280), 4) AS Miles
--FROM            dbo.v__ActiveAssets
--GROUP BY RR_Material, RR_InstallYear, RR_Diameter, RR_Length, RR_PreviousFailures, RR_Asset_ID
SELECT	RR_Asset_ID, RR_Material, RR_InstallYear, RR_Diameter, RR_Length, RR_PreviousFailures, RR_PreviousFailures AS Breaks, 1 AS Segments, ROUND(RR_Length / 5280, 4) AS Miles
FROM	dbo.v__ActiveAssets
GO

/****** Object:  View [v___BRA_Cohort_Assets]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_Assets]
AS
SELECT        Cohorts.CohortRange_ID, Assets.RR_Asset_ID, Assets.RR_Material, Assets.RR_InstallYear, Assets.RR_Diameter, Assets.RR_Length, Assets.RR_PreviousFailures, Cohorts.Active
FROM            dbo.ref_BRA_Cohorts AS Cohorts INNER JOIN
                         dbo.v___BRA_Assets AS Assets ON Cohorts.Material = Assets.RR_Material AND Cohorts.MinYear <= Assets.RR_InstallYear AND Cohorts.MaxYear >= Assets.RR_InstallYear AND 
                         Cohorts.MinDiameter <= Assets.RR_Diameter AND Cohorts.MaxDiameter >= Assets.RR_Diameter
GO

/****** Object:  View [v___BRA_BreakYears]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_BreakYears]
AS
SELECT DISTINCT YEAR(BreakDate) AS BreakYear
FROM            dbo.RR_Failures
WHERE        (NOT (YEAR(BreakDate) IS NULL))
GO

/****** Object:  View [v___BRA_Cohort_QC_BreakYearAgeLength]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_QC_BreakYearAgeLength]
AS
SELECT        CohortAssets.CohortRange_ID, BreakYears.BreakYear, BreakYears.BreakYear - CohortAssets.RR_InstallYear AS Age, SUM(CohortAssets.RR_Length) AS Len
FROM            dbo.v___BRA_BreakYears AS BreakYears CROSS JOIN
                         dbo.v___BRA_Cohort_Assets AS CohortAssets
GROUP BY BreakYears.BreakYear, BreakYears.BreakYear - CohortAssets.RR_InstallYear, CohortAssets.CohortRange_ID
HAVING        (BreakYears.BreakYear - CohortAssets.RR_InstallYear > 0)
GO

/****** Object:  View [v___BRA_Cohort_AgeLength]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_AgeLength]
AS
SELECT        CohortAssets.CohortRange_ID, BreakYears.BreakYear - CohortAssets.RR_InstallYear AS Age, ROUND(SUM(CohortAssets.RR_Length / 5280), 4) AS Miles
FROM            dbo.v___BRA_BreakYears AS BreakYears CROSS JOIN
                         dbo.v___BRA_Cohort_Assets AS CohortAssets
GROUP BY BreakYears.BreakYear - CohortAssets.RR_InstallYear, CohortAssets.CohortRange_ID
HAVING        (BreakYears.BreakYear - CohortAssets.RR_InstallYear > 0)
GO

/****** Object:  View [v___BRA_Cohort_AgeBreaks]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_AgeBreaks]
AS
SELECT        CohortAssets.CohortRange_ID, YEAR(dbo.RR_Failures.BreakDate) - CohortAssets.RR_InstallYear AS Age, COUNT(*) AS Breaks
FROM            dbo.v___BRA_Cohort_Assets AS CohortAssets INNER JOIN
                         dbo.RR_Failures ON CohortAssets.RR_Asset_ID = dbo.RR_Failures.Asset_ID
GROUP BY CohortAssets.CohortRange_ID, YEAR(dbo.RR_Failures.BreakDate) - CohortAssets.RR_InstallYear
HAVING        (YEAR(dbo.RR_Failures.BreakDate) - CohortAssets.RR_InstallYear > 0)
GO

/****** Object:  View [v___BRA_Ages]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Ages]
AS
SELECT DISTINCT number AS n
FROM            master.dbo.spt_values
WHERE        (number BETWEEN 1 AND 150)
GO

/****** Object:  View [v___BRA_Cohort_Ages]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_Ages]
AS
SELECT        Cohorts.CohortRange_ID, dbo.v___BRA_Ages.n AS Age
FROM            dbo.ref_BRA_Cohorts AS Cohorts CROSS JOIN
                         dbo.v___BRA_Ages
GO

/****** Object:  View [v___BRA_Cohort_BreakRate]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_BreakRate]
AS
SELECT        CohortAges.CohortRange_ID, FORMAT(Cohorts.MinDiameter, '#') + '"-' + FORMAT(Cohorts.MaxDiameter, '#') + '"' AS Size, FORMAT(Cohorts.MinYear, '####') + '-' + FORMAT(Cohorts.MaxYear, '####') 
                         + ', ' + FORMAT(Cohorts.MinDiameter, '0#') + '-' + FORMAT(Cohorts.MaxDiameter, '0#') + ' EUL ' + FORMAT(Cohorts.E_EUL, '#') AS YearsDiameters, FORMAT(Cohorts.MinDiameter, '0#') + '-' + FORMAT(Cohorts.MaxDiameter, '0#')
                          + ', ' + FORMAT(Cohorts.MinYear, '####') + '-' + FORMAT(Cohorts.MaxYear, '####') + ', EUL ' + FORMAT(Cohorts.E_EUL, '#') AS DiametersYears, 
                         CASE WHEN Material = 'CI' THEN CASE WHEN MaxYear < 1920 THEN 'CI 1' WHEN MinYear >= 1920 AND MaxYear < 1950 THEN 'CI 2' WHEN MinYear >= 1940 THEN 'CI 3' ELSE 'CI' END ELSE Material END AS MaterialClass, 
                         Cohorts.Description, Cohorts.Material, Cohorts.MinYear, Cohorts.MaxYear, Cohorts.MinDiameter, Cohorts.MaxDiameter, Cohorts.Segments, Cohorts.Miles, Cohorts.Breaks, CohortAges.Age, CohortAgeLength.Miles AS AgeMiles, 
                         CohortAgeBreaks.Breaks AS AgeBreaks, ROUND(100 * CohortAgeBreaks.Breaks / CohortAgeLength.Miles, 2) AS BreakRate, Cohorts.E_Slope, Cohorts.E_Intcpt, Cohorts.E_EUL, Cohorts.E_R2, 
                         Cohorts.E_Intcpt * EXP(Cohorts.E_Slope * CohortAges.Age) AS CalcBR, GETDATE() AS LastRefreshed, Cohorts.Active
FROM            dbo.v___BRA_Cohort_AgeBreaks AS CohortAgeBreaks RIGHT OUTER JOIN
                         dbo.ref_BRA_Cohorts AS Cohorts INNER JOIN
                         dbo.v___BRA_Cohort_Ages AS CohortAges ON Cohorts.CohortRange_ID = CohortAges.CohortRange_ID LEFT OUTER JOIN
                         dbo.v___BRA_Cohort_AgeLength AS CohortAgeLength ON CohortAges.CohortRange_ID = CohortAgeLength.CohortRange_ID AND CohortAges.Age = CohortAgeLength.Age ON 
                         CohortAgeBreaks.CohortRange_ID = CohortAgeLength.CohortRange_ID AND CohortAgeBreaks.Age = CohortAgeLength.Age
GO

/****** Object:  View [v___BRA_Cohort_BreakRate_PBI]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v___BRA_Cohort_BreakRate_PBI]
AS
SELECT        CohortRange_ID, Size, YearsDiameters, DiametersYears, MaterialClass, Description, Material, MinYear, MaxYear, MinDiameter, MaxDiameter, Segments, Miles, Breaks, Age, AgeMiles, AgeBreaks, BreakRate, E_Slope, 
                         E_Intcpt, E_EUL, E_R2, CalcBR, LastRefreshed, Active, 80 AS EUL_BR
FROM            dbo.v___BRA_Cohort_BreakRate AS CohortBreakRate
WHERE        (Active = 1) OR
                         (Breaks > 2) AND (E_Slope > 0.001) AND (E_Intcpt < 10) AND (E_EUL > 30) AND (E_EUL < 300) AND (MaxDiameter < 20)
GO

/****** Object:  View [v_____BRA_YearlyInventoryBreaks]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [v_____BRA_YearlyInventoryBreaks]
AS
SELECT        dbo.v___BRA_BreakYears.BreakYear, a.RR_Asset_ID, dbo.v___BRA_BreakYears.BreakYear - a.RR_InstallYear AS Age, a.RR_InstallYear, a.RR_Material, a.RR_Diameter, a.RR_Length, a.RR_PreviousFailures, 
                         SUM(CASE WHEN YEAR(BreakDate) = BreakYear THEN 1 ELSE 0 END) AS Breaks
FROM            dbo.RR_Failures RIGHT OUTER JOIN
                         dbo.v__ActiveAssets AS a ON dbo.RR_Failures.Asset_ID = a.RR_Asset_ID CROSS JOIN
                         dbo.v___BRA_BreakYears
GROUP BY dbo.v___BRA_BreakYears.BreakYear, a.RR_Asset_ID, a.RR_InstallYear, a.RR_Material, a.RR_Diameter, a.RR_Length, a.RR_PreviousFailures, dbo.v___BRA_BreakYears.BreakYear - a.RR_InstallYear
HAVING        (dbo.v___BRA_BreakYears.BreakYear - a.RR_InstallYear > 0)
GO

/****** Object:  View [v_____BRA_YearlyInventoryBreakRate]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create view [v_____BRA_YearlyInventoryBreakRate]
as
select BreakYear, sum(Breaks) as brks, round(sum(rr_length/5280),2) as miles,  round(100.0*sum(Breaks)/sum(rr_length/5280),2) as BR
from v_____BRA_YearlyInventoryBreaks
group by BreakYear 
GO

/****** Object:  View [v_____BRA_YearlyInventoryBreakRate_Materials]    Script Date: 12/8/2022 6:25:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [v_____BRA_YearlyInventoryBreakRate_Materials]
AS
SELECT        RR_Material, Age, ROUND(SUM(RR_Length / 5280), 2) AS miles, SUM(Breaks) AS Brks, ROUND(100 * SUM(Breaks) / SUM(RR_Length / 5280), 2) AS BR
FROM            dbo.v_____BRA_YearlyInventoryBreaks
WHERE        (RR_Diameter >= 0) AND (RR_Diameter <= 100)
GROUP BY RR_Material, Age
GO



/****** Object:  StoredProcedure [p___BRA_Cohorts]    Script Date: 12/8/2022 6:27:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [p___BRA_Cohorts]

AS
BEGIN

-- delete from ref_CohortRanges

	SET NOCOUNT ON;

	DECLARE @Matl nvarchar(64), @Year smallint, @MDia smallint, @MinYear smallint, @MaxYear smallint, @MinDia smallint, @MaxDia smallint;
	DECLARE @MinMinYear smallint, @MaxMaxYear smallint, @MinMinDia smallint, @MaxMaxDia smallint;
	DECLARE @Segs int, @Miles float, @Breaks int, @TotalSegs int, @TotalMiles float, @TotalBreaks int 

	INSERT INTO ref_BRA_Cohorts
		([Description], [Material], [MinYear], [MaxYear], [MinDiameter], [MaxDiameter], [Segments], [Miles], [Breaks])
		SELECT	'Material', [RR_Material], 
				MIN([RR_InstallYear]) AS MinYear, MAX([RR_InstallYear]) AS MaxYear, 
				MIN([RR_Diameter]) AS MinDIa, MAX([RR_Diameter]) AS MaxDIa, 
				SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks
		FROM	[v___BRA_Assets]
		GROUP BY [RR_Material]
		HAVING SUM([Breaks]) > 2
		ORDER BY [RR_Material]; 

	INSERT INTO ref_BRA_Cohorts
		([Description], [Material], [MinYear], [MaxYear], [MinDiameter], [MaxDiameter], [Segments], [Miles], [Breaks])
		SELECT	'Material Year', [RR_Material], 
				[RR_InstallYear] AS MinYear, [RR_InstallYear] AS MaxYear, 
				MIN([RR_Diameter]) AS MinDIa, MAX([RR_Diameter]) AS MaxDIa, 
				SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks
		FROM	[v___BRA_Assets]
		GROUP BY [RR_Material], [RR_InstallYear]
		HAVING SUM([Breaks]) > 2
		ORDER BY [RR_Material], [RR_InstallYear]; 

	INSERT INTO ref_BRA_Cohorts
		([Description], [Material], [MinYear], [MaxYear], [MinDiameter], [MaxDiameter], [Segments], [Miles], [Breaks])
		SELECT	'Material Diameter', [RR_Material], 
				MIN([RR_InstallYear]) AS MinYear, MAX([RR_InstallYear]) AS MaxYear, 
				[RR_Diameter] AS MinDIa, [RR_Diameter] AS MaxDIa, 
				SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks
		FROM	[v___BRA_Assets]
		GROUP BY [RR_Material], [RR_Diameter]
		HAVING SUM([Breaks]) > 2
		ORDER BY [RR_Material], [RR_Diameter]; 


	--Process material years
	DECLARE c0 CURSOR FOR
	SELECT	[RR_Material], [RR_InstallYear],
			MIN([RR_Diameter]) AS MinDIa, MAX([RR_Diameter]) AS MaxDIa, 
			SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks
	FROM	[v___BRA_Assets]
	GROUP BY [RR_Material], [RR_InstallYear]
	HAVING SUM([Breaks]) > 0
	ORDER BY [RR_Material], [RR_InstallYear];

	OPEN c0
	FETCH NEXT FROM c0 INTO @Matl, @MinYear, @MinMinDia, @MaxMaxDia, @TotalSegs, @TotalMiles, @TotalBreaks ;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		DECLARE c1 CURSOR FOR
		SELECT	[RR_InstallYear],
				MIN([RR_Diameter]) AS MinDIa, MAX([RR_Diameter]) AS MaxDIa, 
				SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks 
		FROM	[v___BRA_Assets]
		WHERE	[RR_Material] = @Matl AND [RR_InstallYear] > @MinYear
		GROUP BY [RR_Material], [RR_InstallYear]
		HAVING SUM([Breaks]) > 0
		ORDER BY [RR_Material], [RR_InstallYear];

		OPEN c1
		FETCH NEXT FROM c1 INTO @MaxYear, @MinDia, @MaxDia, @Segs, @Miles, @Breaks ;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			SELECT @TotalSegs = @TotalSegs + @Segs;
			SELECT @TotalMiles = @TotalMiles + @Miles;
			SELECT @TotalBreaks = @TotalBreaks + @Breaks;
			SELECT @MinMinDia = IIF(@MinDia < @MinMinDia, @MinDia, @MinMinDia);
			SELECT @MaxMaxDia = IIF(@MaxDia > @MaxMaxDia, @MaxDia, @MaxMaxDia);

			INSERT INTO ref_BRA_Cohorts
				([Description], [Material], [MinYear], [MaxYear], MinDiameter, MaxDiameter, Segments, Miles, Breaks)
				VALUES ('Material Years', @Matl, @MinYear, @MaxYear, @MinMinDia, @MaxMaxDia, @TotalSegs, @TotalMiles, @TotalBreaks);

			FETCH NEXT FROM c1 INTO @MaxYear, @MinDia, @MaxDia, @Segs, @Miles, @Breaks ;
		END
		CLOSE c1
		DEALLOCATE c1; 

		FETCH NEXT FROM c0 INTO @Matl, @MinYear, @MinMinDia, @MaxMaxDia, @TotalSegs, @TotalMiles, @TotalBreaks ;
	END
	CLOSE c0
	DEALLOCATE c0; 




	--Process material Diameters
	DECLARE c0 CURSOR FOR
	SELECT	[RR_Material], [RR_Diameter],
			MIN([RR_InstallYear]) AS MinYear, MAX([RR_InstallYear]) AS MaxYear, 
			SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks
	FROM	[v___BRA_Assets]
	GROUP BY [RR_Material], [RR_Diameter]
	HAVING SUM([Breaks]) > 0
	ORDER BY [RR_Material], [RR_Diameter];

	OPEN c0
	FETCH NEXT FROM c0 INTO @Matl, @MinDia, @MinMinYear, @MaxMaxYear, @TotalSegs, @TotalMiles, @TotalBreaks ;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		DECLARE c1 CURSOR FOR
		SELECT	[RR_Diameter],
				MIN([RR_InstallYear]) AS MinYear, MAX([RR_InstallYear]) AS MaxYear, 
				SUM([Segments]) AS Segments, SUM([Miles]) AS Miles, SUM([Breaks]) AS Breaks 
		FROM	[v___BRA_Assets]
		WHERE	[RR_Material] = @Matl AND [RR_Diameter] > @MinDia
		GROUP BY [RR_Material], [RR_Diameter]
		HAVING SUM([Breaks]) > 0
		ORDER BY [RR_Material], [RR_Diameter];

		OPEN c1
		FETCH NEXT FROM c1 INTO @MaxDia, @MinYear, @MaxYear, @Segs, @Miles, @Breaks ;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			SELECT @TotalSegs = @TotalSegs + @Segs;
			SELECT @TotalMiles = @TotalMiles + @Miles;
			SELECT @TotalBreaks = @TotalBreaks + @Breaks;
			SELECT @MinMinYear = IIF(@MinYear < @MinMinYear, @MinYear, @MinMinYear);
			SELECT @MaxMaxYear = IIF(@MaxYear > @MaxMaxYear, @MaxYear, @MaxMaxYear);

			INSERT INTO ref_BRA_Cohorts
				([Description], [Material], [MinYear], [MaxYear], MinDiameter, MaxDiameter, Segments, Miles, Breaks)
				VALUES ('Material Diameters', @Matl, @MinMinYear, @MaxMaxYear, @MinDia, @MaxDia, @TotalSegs, @TotalMiles, @TotalBreaks);

		FETCH NEXT FROM c1 INTO @MaxDia, @MinYear, @MaxYear, @Segs, @Miles, @Breaks ;
		END
		CLOSE c1
		DEALLOCATE c1; 

		FETCH NEXT FROM c0 INTO @Matl, @MinDia, @MinMinYear, @MaxMaxYear, @TotalSegs, @TotalMiles, @TotalBreaks ;
	END
	CLOSE c0
	DEALLOCATE c0; 


	--set curve parameters
	--UPDATE	ref_CohortRanges
	--SET		E_Slope = ROUND(v____BRAnalysis_CalcCurve2.b, 4), 
	--		E_Intcpt = ROUND(v____BRAnalysis_CalcCurve2.a, 4), 
	--		E_EUL = ROUND(LOG (80 / v____BRAnalysis_CalcCurve2.a) / v____BRAnalysis_CalcCurve2.b, 2), 
	--		E_R2 = ROUND(v____BRAnalysis_CalcCurve2.r2, 4)
	--FROM	ref_CohortRanges INNER JOIN
	--		v____BRAnalysis_CalcCurve2 ON ref_CohortRanges.CohortRange_ID = v____BRAnalysis_CalcCurve2.CohortRange_ID;





	SELECT  ref_BRA_Cohorts.CohortRange_ID,    SUM(1) AS CalcSegments, ROUND(SUM(RR_Length/5280), 6) AS CalcMiles, SUM(RR_PreviousFailures) AS CalcBreaks
	INTO cX##
	FROM     ref_BRA_Cohorts JOIN v___BRA_Cohort_Assets ON ref_BRA_Cohorts.CohortRange_ID = v___BRA_Cohort_Assets.CohortRange_ID
	GROUP BY ref_BRA_Cohorts.CohortRange_ID;

	UPDATE       ref_BRA_Cohorts
	SET                Segments = CalcSegments, Miles = CalcMiles, Breaks = CalcBreaks
	FROM            ref_BRA_Cohorts INNER JOIN
							 cX## ON ref_BRA_Cohorts.CohortRange_ID = cX##.CohortRange_ID;

	DROP TABLE cX##;



	SELECT	CohortRange_ID, COUNT(*) AS n, SUM(Age) AS x, SUM(Age * Age) AS x2, SUM(LOG (BreakRate)) AS y, SUM(Age * LOG (BreakRate)) AS xy, 
			SUM(LOG (BreakRate) * LOG (BreakRate)) AS y2, COUNT(*) * SUM(Age * Age) - SUM(Age) * SUM(Age) AS d
	INTO	c0## 
	FROM	v___BRA_Cohort_BreakRate
	WHERE	(NOT (BreakRate IS NULL))
	GROUP BY CohortRange_ID
	HAVING	(COUNT(*) * SUM(Age * Age) - SUM(Age) * SUM(Age) <> 0);


	SELECT	CohortRange_ID, n, x, x2, y, xy, y2, d, (x2 * y - x * xy) / d AS a, (n * xy - x * y) / d AS b
	INTO	c1##
	FROM	c0##
	WHERE	(d <> 0) AND (n <> 0) AND (y2 - y * y <> 0) AND (n * xy - x * y <> 0);

--	SELECT * FROM c1##;

	SELECT	CohortRange_ID, EXP(a) AS a, b, (a * y + b * xy - y * y / n) / (y2 - y * y / n) AS r2
	INTO	c2##
	FROM	c1##
	WHERE (y2 - y * y / n) <> 0;

--	SELECT * FROM c2##;

	UPDATE	ref_BRA_Cohorts
	SET		E_Slope = ROUND(c2##.b, 4), 
			E_Intcpt = ROUND(c2##.a, 4), 
			E_EUL = ROUND(LOG (80 / c2##.a) / c2##.b, 2), 
			E_R2 = ROUND(c2##.r2, 4)
	FROM	ref_BRA_Cohorts INNER JOIN
			c2## ON ref_BRA_Cohorts.CohortRange_ID = c2##.CohortRange_ID;

	DROP TABLE c0##;
	DROP TABLE c1##;
	DROP TABLE c2##;


END

GO

