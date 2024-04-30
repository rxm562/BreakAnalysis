--This script creates Arcadis DataProfiler tables, views and procedures in the current database


	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE TABLE [dbo].[ArcadisDP_Tables](
		[Table_ID] [int] IDENTITY(1,1) NOT NULL,
		[DatabaseName] [nvarchar](255) NULL,
		[Schema] [nvarchar](255) NULL,
		[TableName] [nvarchar](255) NULL,
		[Description] [nvarchar](255) NULL,
		[Dataset] [nvarchar](64) NULL,
		[RecordCount] [int] NULL,
		[TotalLength] [float] NULL,
		[GeometryField] [nvarchar](64) NULL,
		[GeometryType] [nvarchar](64) NULL,
		[PrimaryKey] [nvarchar](255) NULL,
		[Projection] [nvarchar](255) NULL,
		[PBI] [bit] NOT NULL,
		[Category] [nvarchar](64) NULL,
	 CONSTRAINT [PK_ArcadisDP_Tables] PRIMARY KEY CLUSTERED 
	(
		[Table_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
	--, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
	) ON [PRIMARY]
	) ON [PRIMARY]
	GO

	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO	
	CREATE TABLE [dbo].[ArcadisDP_Columns](
		[Column_ID] [int] IDENTITY(1,1) NOT NULL,
		[Table_ID] [int] NULL,
		[Schema] [nvarchar](255) NULL,
		[TableName] [nvarchar](255) NULL,
		[ColumnName] [nvarchar](255) NULL,
		[Description] [nvarchar](255) NULL,
		[DataType] [nvarchar](64) NULL,
		[Domain] [nvarchar](64) NULL,
		[Alias] [nvarchar](64) NULL,
		[DefaultValue] [nvarchar](255) NULL,
		[MaxLength] [int] NULL,
		[Precision] [int] NULL,
		[Scale] [int] NULL,
		[IsNullable] [bit] NOT NULL,
		[NullCount] [int] NULL,
		[ZeroCount] [int] NULL,
		[NegativeCount] [int] NULL,
		[UniqueCount] [int] NULL,
		[PopulatedCount] [int] NULL,
		[TotalCount] [int] NULL,
		[MinValue] [float] NULL,
		[MaxValue] [float] NULL,
		[Mean] [float] NULL,
		[StdDev] [float] NULL,
		[Non0MinValue] [float] NULL,
		[Non0Mean] [float] NULL,
		[Non0StdDev] [float] NULL,
		CONSTRAINT [PK_ArcadisDP_Columns] PRIMARY KEY CLUSTERED 
	(
		[Column_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
	--, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
	) ON [PRIMARY]
	) ON [PRIMARY]
	GO

	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE TABLE [dbo].[ArcadisDP_ColumnValues](
		[Column_ID] [int] IDENTITY(1,1) NOT NULL,
		[TableName] [nvarchar](255) NULL,
		[ColumnName] [nvarchar](255) NULL,
		[Value] [nvarchar](255) NULL,
		[Count] [float] NULL,
		[ShapeLength] [float] NULL,
		CONSTRAINT [PK_ArcadisDP_ColumnValues] PRIMARY KEY CLUSTERED 
	(
		[Column_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
	--, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
	) ON [PRIMARY]
	) ON [PRIMARY]
	GO

	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE TABLE [dbo].[ArcadisDP_GeoDatabaseDomains](
		[Doamin_ID] [int] IDENTITY(1,1) NOT NULL,
		[DomainName] [nvarchar](64) NULL,
		[DomainCode] [nvarchar](64) NULL,
		[DomainDescription] [nvarchar](255) NULL,
	 CONSTRAINT [PK_ArcadisDP_GeoDatabaseDomains] PRIMARY KEY CLUSTERED 
	(
		[Doamin_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
	--, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
	) ON [PRIMARY]
	) ON [PRIMARY]
	GO

	ALTER TABLE [dbo].[ArcadisDP_Columns] ADD  CONSTRAINT [DF_ArcadisDP_Columns_IsNullable]  DEFAULT ((1)) FOR [IsNullable]
	GO

	ALTER TABLE [dbo].[ArcadisDP_Tables] ADD  CONSTRAINT [DF_ArcadisDP_Tables_PBI]  DEFAULT ((1)) FOR [PBI]
	GO


	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE OR ALTER VIEW [dbo].[v_ArcadisDP_ColumnValues]
	AS
	SELECT	dbo.ArcadisDP_Tables.TableName, dbo.ArcadisDP_Tables.Description, dbo.ArcadisDP_Tables.RecordCount, dbo.ArcadisDP_Tables.TotalLength, dbo.ArcadisDP_Columns.ColumnName, 
			dbo.ArcadisDP_Columns.Description AS ColDescription, dbo.ArcadisDP_Columns.Domain, dbo.ArcadisDP_GeoDatabaseDomains.DomainCode, dbo.ArcadisDP_GeoDatabaseDomains.DomainDescription, 
			CASE WHEN DomainCode IS NULL THEN [value] WHEN DomainCode = DomainDescription THEN DomainCode ELSE concat(DomainDescription, ' (', DomainCode, ')') END AS DomainValue, 
			dbo.ArcadisDP_ColumnValues.Count, dbo.ArcadisDP_ColumnValues.ShapeLength
	FROM	dbo.ArcadisDP_Tables INNER JOIN
			dbo.ArcadisDP_Columns ON dbo.ArcadisDP_Tables.TableName = dbo.ArcadisDP_Columns.TableName INNER JOIN
			dbo.ArcadisDP_ColumnValues ON dbo.ArcadisDP_Columns.TableName = dbo.ArcadisDP_ColumnValues.TableName AND dbo.ArcadisDP_Columns.ColumnName = dbo.ArcadisDP_ColumnValues.ColumnName LEFT OUTER JOIN
			dbo.ArcadisDP_GeoDatabaseDomains ON dbo.ArcadisDP_ColumnValues.Value = dbo.ArcadisDP_GeoDatabaseDomains.DomainCode AND dbo.ArcadisDP_Columns.Domain = dbo.ArcadisDP_GeoDatabaseDomains.DomainName
	GO


	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE OR ALTER VIEW [dbo].[v_ArcadisDP_PrimaryKeys]
	AS
	SELECT	tc.TABLE_NAME, ccu.CONSTRAINT_NAME, string_agg(ccu.COLUMN_NAME, ', ') AS PK
	FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc INNER JOIN
			INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS ccu ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
	WHERE	(tc.CONSTRAINT_TYPE = 'Primary Key')
	GROUP BY tc.TABLE_NAME, ccu.CONSTRAINT_NAME
	GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	ALTER   PROCEDURE [dbo].[p__ArcadisDP_GenerateResults] 
		@tablenamefilter nvarchar(64) = '%'
	AS
	BEGIN

	--The following four statements can be uncommented to clear previous results
	--DELETE FROM ArcadisDP_Columns
	--DELETE FROM ArcadisDP_ColumnValues
	--DELETE FROM ArcadisDP_GeoDatabaseDomains
	--DELETE FROM ArcadisDP_Tables

		SET ANSI_WARNINGS OFF
		SET NOCOUNT ON

		DECLARE @tablename nvarchar(64)
		DECLARE @column nvarchar(64)
		DECLARE @type nvarchar(32)
		DECLARE @rows integer
		DECLARE @empty integer 
		DECLARE @zero integer 
		DECLARE @negative integer 
		DECLARE @sql nvarchar(MAX)
		DECLARE @FieldeName nvarchar(64)
		DECLARE @ShapeLength integer

		DECLARE @IsNullable integer
		DECLARE @DefaultValue nvarchar(255)
		DECLARE @MaxLength integer
		DECLARE @Precision integer
		DECLARE @Scale integer

		CREATE TABLE #tempTableColumns (TableName nvarchar(64), ColumnName nvarchar(64), Non0MinValue float, Non0Mean float, Non0StdDev float);


		SET @sql = 'INSERT INTO ArcadisDP_Tables (TableName, RecordCount) '
					+ 'SELECT sOBJ.name AS TableName, SUM(sPTN.Rows) AS Records '
					+ 'FROM sys.objects AS sOBJ INNER JOIN sys.partitions AS sPTN ON sOBJ.object_id = sPTN.object_id '
					+ 'WHERE sOBJ.type = ''U'' AND sOBJ.is_ms_shipped = 0x0 AND index_id < 2 '
					+ 'AND sOBJ.name LIKE ''' + @tablenamefilter + ''' '
					+ 'AND sOBJ.name NOT LIKE ''GDB_%'' AND sOBJ.name NOT LIKE ''SDE_%'' AND sOBJ.name NOT LIKE ''i[0-9]%'' AND sOBJ.name NOT LIKE ''ArcadisDP_%''' 
					+ 'GROUP BY sOBJ.name '
					+ 'HAVING SUM(sPTN.Rows) > 0 '
					+ 'ORDER BY TableName '

		EXEC sp_executesql @sql;

		UPDATE	ArcadisDP_Tables
		SET		DatabaseName = INFORMATION_SCHEMA.TABLES.TABLE_CATALOG, [Schema] = INFORMATION_SCHEMA.TABLES.TABLE_SCHEMA
		FROM	INFORMATION_SCHEMA.TABLES INNER JOIN
				ArcadisDP_Tables ON INFORMATION_SCHEMA.TABLES.TABLE_NAME = ArcadisDP_Tables.TableName;

		UPDATE	ArcadisDP_Tables
		SET		PrimaryKey = v_ArcadisDP_PrimaryKeys.PK
		FROM	v_ArcadisDP_PrimaryKeys INNER JOIN ArcadisDP_Tables
				ON v_ArcadisDP_PrimaryKeys.TABLE_NAME = ArcadisDP_Tables.TableName;

		DECLARE c0 CURSOR
		FOR	SELECT TABLE_NAME, COLUMN_NAME FROM ArcadisDP_Tables as t JOIN information_schema.columns as c ON t.TableName=c.TABLE_NAME WHERE DATA_TYPE = 'geometry' ORDER BY TABLE_NAME
		OPEN c0
		FETCH NEXT FROM c0 INTO @tablename, @FieldeName;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			SET @sql =	'UPDATE ArcadisDP_Tables '
					+	'SET Projection = (SELECT STRING_AGG([WKID], '', '') FROM (SELECT DISTINCT ' + @FieldeName + '.STSrid AS [WKID] '
					+						'FROM ' +	@tablename + ' WHERE ' + @FieldeName + '.STSrid IS NOT NULL) AS tbl1), '
					+	'GeometryField = ''' + @FieldeName + ''', '
					+	'GeometryType = (SELECT STRING_AGG([TYP], '', '') FROM (SELECT DISTINCT ' + @FieldeName + '.STGeometryType() AS [TYP] '
					+						'FROM ' +	@tablename + ' WHERE ' + @FieldeName + '.STSrid IS NOT NULL) AS tbl2), '
					+	'TotalLength = (SELECT SUM(' + @FieldeName + '.STLength()) AS ShapeLength '
					+						'FROM ' +	@tablename + ') '
					+	'WHERE TableName = ''' + @tablename + '''' 

			--PRINT  @sql
			EXEC sp_executesql @sql;

			FETCH NEXT FROM c0 INTO @tablename, @FieldeName;
		
		END
		CLOSE c0;  
		DEALLOCATE c0;

		DECLARE c0 CURSOR
		FOR	SELECT TableName, RecordCount, GeometryField FROM ArcadisDP_Tables WHERE RecordCount > 0 ORDER BY TableName 
		OPEN c0
		FETCH NEXT FROM c0 INTO @tablename, @rows, @FieldeName;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
	
			DECLARE c1 CURSOR
			FOR	SELECT COLUMN_NAME, DATA_TYPE, CASE WHEN IS_NULLABLE = 'YES' THEN 1 ELSE 0 END, COLUMN_DEFAULT, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE FROM information_schema.columns WHERE TABLE_NAME = @tablename AND DATA_TYPE <> 'geometry' ORDER BY COLUMN_NAME
			OPEN c1
			FETCH NEXT FROM c1 INTO @column, @type, @IsNullable, @DefaultValue, @MaxLength, @Precision, @Scale;
			WHILE @@FETCH_STATUS = 0  
			BEGIN 

				--PRINT @tablename + ', ' + @column + ', ' + @type ;

				SET @sql = 'INSERT INTO ArcadisDP_Columns (TableName, ColumnName, DataType, MinValue, Mean, MaxValue, StdDev, ZeroCount, NegativeCount, TotalCount, UniqueCount, PopulatedCount, IsNullable, DefaultValue, MaxLength, Precision, Scale) '
				SET @sql = @sql + 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, ''' + @type  + ''' AS DataType, '
			
				IF @type LIKE '%char%'
					SET @sql = @sql + 'MIN(LEN(' + @column + ')) AS mn, AVG(LEN(' + @column + ')) AS avg, MAX(LEN(' + @column + ')) AS mx, STDEV(LEN(' + @column + ')) AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ISNULL(' + @column + ', '''') = '''' THEN 0 ELSE 1 END) AS Populated ' --FROM ' + QUOTENAME(@tablename)
				ELSE IF @type LIKE '%xml%'
					SET @sql = @sql + 'NULL AS mn, NULL AS avg, NULL AS mx, NULL AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated '
				ELSE IF @type LIKE '%smalldate%'
					SET @sql = @sql + 'MIN(YEAR(' + @column + ')) AS mn, AVG(YEAR(' + @column + ')) AS avg, MAX(YEAR(' + @column + ')) AS mx, STDEV(YEAR(' + @column + ')) AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL THEN 0 ELSE 1 END) AS Populated ' -- FROM ' + QUOTENAME(@tablename)
				ELSE IF @type LIKE '%date%'
					SET @sql = @sql + 'MIN(YEAR(' + @column + ')) AS mn, AVG(YEAR(' + @column + ')) AS avg, MAX(YEAR(' + @column + ')) AS mx, STDEV(YEAR(' + @column + ')) AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL OR ' + @column + ' < ''1800-01-01'' THEN 0 ELSE 1 END) AS Populated ' -- FROM ' + QUOTENAME(@tablename)
				ELSE IF @type LIKE '%bit%'
					SET @sql = @sql + 'NULL AS mn, NULL AS avg, NULL AS mx, NULL AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, NULL AS Populated ' --FROM ' + QUOTENAME(@tablename)
				ELSE IF @type LIKE '%geometry%'
					SET @sql = @sql + 'NULL AS mn, NULL AS avg, NULL AS mx, NULL AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated ' --FROM ' + QUOTENAME(@tablename)
				ELSE IF @type LIKE '%uniqueidentifier%'
					SET @sql = @sql + 'NULL AS mn, NULL AS avg, NULL AS mx, NULL AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated ' --FROM ' + QUOTENAME(@tablename)
				ELSE IF @type LIKE '%varbinary%'
					SET @sql = @sql + 'NULL AS mn, NULL AS avg, NULL AS mx, NULL AS stdv, NULL AS Zeros, NULL AS Negatives, COUNT(*) AS TotalRows, NULL AS DistinctVal, NULL AS Populated ' --FROM ' + QUOTENAME(@tablename)
				ELSE
					SET @sql = @sql + 'MIN(' + @column + ') AS mn, AVG(CAST(' + @column + ' AS float)) AS avg, MAX(' + @column + ') AS mx, STDEV(' + @column + ') AS stdv, SUM(CASE WHEN ' + @column + ' = 0 THEN 1 ELSE 0 END) AS Zeros, SUM(CASE WHEN ' + @column + ' < 0 THEN 1 ELSE 0 END) AS Negatives, COUNT(*) AS TotalRows, COUNT(DISTINCT ' + @column + ') AS DistinctVal, SUM(CASE WHEN ' + @column + ' IS NULL THEN 0 ELSE 1 END) AS Populated ' -- FROM ' + QUOTENAME(@tablename)

				SET	@sql = @sql + CONCAT(', ''', @IsNullable, ''' AS IsNullable, ''', REPLACE(@DefaultValue, '''', ''), ''' AS DefaultValue, ''', @MaxLength, ''' AS MaxLength, ''', @Precision, ''' AS Precision, ''', @Scale, ''' AS Scale FROM ', QUOTENAME(@tablename))

				--PRINT @sql;
				exec sp_executesql @sql


				IF @type LIKE '%smalldate%'
				BEGIN
					SET @sql = 'INSERT INTO #tempTableColumns (TableName, ColumnName, Non0MinValue, Non0Mean, Non0StdDev) '
					SET @sql = @sql + 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, '
					SET	@sql = @sql + 'MIN(YEAR(' + @column + ')) AS mn, AVG(YEAR(' + @column + ')) AS avg, STDEV(YEAR(' + @column + ')) AS stdv '
					SET	@sql = @sql + 'FROM [' + @tablename + '] '
					SET	@sql = @sql + 'WHERE ' + @column + ' > 0'
				
					--PRINT @sql;
					exec sp_executesql @sql;
 				END
				ELSE IF @type LIKE '%date%'
				BEGIN
					SET @sql = 'INSERT INTO #tempTableColumns (TableName, ColumnName, Non0MinValue, Non0Mean, Non0StdDev) '
					SET @sql = @sql + 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, '
					SET	@sql = @sql + 'MIN(YEAR(' + @column + ')) AS mn, AVG(YEAR(' + @column + ')) AS avg, STDEV(YEAR(' + @column + ')) AS stdv '
					SET	@sql = @sql + 'FROM [' + @tablename + '] '
					SET	@sql = @sql + 'WHERE ' + @column + ' > ''1800-01-01'''
				
					--PRINT @sql;
					exec sp_executesql @sql;
 				END
				ELSE IF NOT (@type LIKE '%char%' OR @type LIKE '%xml%' OR @type LIKE '%bit%' OR @type LIKE '%geometry%' OR @type LIKE '%uniqueidentifier%' OR  @type LIKE '%varbinary%')
				BEGIN
					SET @sql = 'INSERT INTO #tempTableColumns (TableName, ColumnName, Non0MinValue, Non0Mean, Non0StdDev) '
					SET @sql = @sql + 'SELECT ''' + @tablename + ''' AS TableName, ''' + @column + ''' AS ColumnName, '
					SET	@sql = @sql + 'MIN(' + @column + ') AS mn, AVG(CAST(' + @column + ' AS float)) AS avg, STDEV(' + @column + ') AS stdv '
					SET	@sql = @sql + 'FROM [' + @tablename + '] '
					SET	@sql = @sql + 'WHERE ' + @column + ' > 0'				
				
					--PRINT @sql;
					exec sp_executesql @sql;
				END


				IF NOT (@type LIKE '%xml%' OR @type LIKE '%bit%' OR @type LIKE '%geometry%' OR @type LIKE '%uniqueidentifier%' OR @type LIKE '%varbinary%')
				BEGIN
					SET	@sql = 'INSERT INTO ArcadisDP_ColumnValues (TableName, ColumnName, [Value], [Count], ShapeLength) '
					SET	@sql = @sql + 'SELECT TOP 100 ''' + @tablename + ''' AS tbl, ''' + @column + ''' AS cl, ' + @column + ' AS val, COUNT(*) AS cnt, '
					SET	@sql = @sql +  CASE WHEN ISNULL(@FieldeName, '') = '' THEN '0' ELSE 'SUM(' + @FieldeName + '.STLength())' END + ' AS Len FROM ' + @tablename
					SET	@sql = @sql + ' WHERE ' + @column + ' IS NOT NULL GROUP BY ' + @column + ' HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC'

					--PRINT @sql;
					exec sp_executesql @sql		
				END

				FETCH NEXT FROM c1 INTO @column, @type, @IsNullable, @DefaultValue, @MaxLength, @Precision, @Scale;
			END
			CLOSE c1;  
			DEALLOCATE c1;

			FETCH NEXT FROM c0 INTO @tablename, @rows, @FieldeName;

		END
		CLOSE c0;  
		DEALLOCATE c0;

		IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GDB_ITEMS]') AND type in (N'U'))
			BEGIN

			--PRINT 'Start domains'

				SET ANSI_WARNINGS ON;

				INSERT INTO ArcadisDP_GeoDatabaseDomains (DomainName, DomainCode, DomainDescription)
				SELECT	i.Name, n.c.value('(Code)[1]', 'nvarchar(100)') AS cd, n.c.value('(Name)[1]', 'nvarchar(100)') AS descript
				FROM	GDB_ITEMS AS i INNER JOIN GDB_ITEMTYPES AS t ON i.Type = t.UUID
				CROSS APPLY i.definition.nodes('/GPCodedValueDomain2/CodedValues/CodedValue') n(c)
				WHERE	t.Name = 'Coded Value Domain';


				UPDATE	ArcadisDP_Columns
				SET		Domain = codedValue.value('DomainName[1]', 'nvarchar(max)') 
				FROM	ArcadisDP_Columns, dbo.[GDB_ITEMS] AS items INNER JOIN
							 dbo.[GDB_ITEMTYPES] AS itemtypes ON items.Type = itemtypes.UUID CROSS APPLY 
							 items.Definition.nodes('/DEFeatureClassInfo/GPFieldInfoExs/GPFieldInfoEx') AS CodedValues(codedValue)
				WHERE items.Name LIKE '%.' + ArcadisDP_Columns.TableName
						AND codedValue.value('Name[1]', 'nvarchar(max)') = ArcadisDP_Columns.ColumnName
						AND codedValue.value('DomainName[1]', 'nvarchar(max)') is not null;
			
				UPDATE	ArcadisDP_Tables
				SET		--GeometryType = items.Definition.value('(/DEFeatureClassInfo/ShapeType)[1]', 'nvarchar(max)'),
						Description = items.Definition.value('(/DEFeatureClassInfo/AliasName)[1]', 'nvarchar(max)')
				FROM	ArcadisDP_Tables, dbo.[GDB_ITEMS] AS items INNER JOIN
						dbo.[GDB_ITEMTYPES] AS itemtypes ON items.Type = itemtypes.UUID 
				WHERE	items.Name LIKE '%.' + ArcadisDP_Tables.TableName;

			END

		UPDATE ArcadisDP_Columns
		SET Non0MinValue = a.Non0MinValue,
		Non0Mean = a.Non0Mean,
		Non0StdDev = a.Non0StdDev
		FROM ArcadisDP_Columns join #tempTableColumns as a on ArcadisDP_Columns.TableName = a.TableName AND ArcadisDP_Columns.ColumnName= a.ColumnName;

		DROP TABLE #tempTableColumns;

		SET ANSI_WARNINGS OFF

	END


