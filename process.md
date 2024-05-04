1)	Create RRPS Project Database using SSMS
a)	Create an empty new database on SQL Server 
Initial Data and Log Files: 1 MB, grow by 10%
Recovery Model:  Simple
b)	Use SQL scripts to create RRPS functions, tables, view, procedures, and populate config tables
RRPS_DB.sql
RRPS_DB_Data.sql
If database is for Linear Water run RRPS_DB_Water_Update.sql to change LoF range from 1-5 to 1-100
If database is for Linear Sewer run RRPS_DB_Sewer_Update.sql
c)	Create Roles and Role Permissions
Exec p___GrantEditorPermission
Copy messages into a new query window and execute
Assign Users to the Database with rrps_Admins and rrps_Editors Roles
d)	Add new database to Maintenance Plans: Nightly Backup
2)	Load Client Data
a)	Load Facility Asset Data from Fulcrum using SSMS
i)	Add any client specific columns in ref_Fulcrum and RR_Assets Tables
ii)	Import Fulcrum spreadsheet to ref_Fulcrum table (change destination table to ref_Fulcrum from the dropdown menu)
iii)	Verify/Correct RR_ConfigAliases ColumnName to FulcrumName
iv)	Verify/Correct fulcrum attribute updates to RR_Assets and exec p___FulcrumUpdate
b)	Load Linear Asset Data from GIS 
i)	Use ArcGIS
(1)	Create a database connection to the RRPS database 
(Connection Name = RRPS Database Name + “_” + Server Name)
(2)	Copy client’s source feature class by either dragging it from the source gdb and dropping it, or by using the import feature class tool
(3)	Assign Coordinate System to RR_Assets, RR_Failures and RR_Projects
ii)	Use SSMS
(1)	Rename feature class to ref_Assets
(2)	Add source gdb specific fields to RR_Assets table, excluding ObjectID and GDB_GEOMATTR_DATA fields.
(Change decimal to float)
(3)	Update v__ActiveAssets to include all added fields
(4)	Create a custom INSERT query and run to insert ref_Assets records to RR_Assets
(5)	Correct views: v_QC_Assumed_Diameter_Details, v_QC_Assumed_InstallYear_Details, v_QC_Assumed_Material_Details
iii)	Verify RR_Assets and ref_Assets are using the same projection
(1)	SELECT DISTINCT shape.STSrid FROM RR_Assets 
and 
SELECT DISTINCT shape.STSrid FROM ref_Assets 
to make sure only one projection Well Known ID (WKID) is used by all records
(2)	Exec p__SpatialIndex
3)	Apply Assumptions
a)	Use SSMS to modify the p_01_UpdateAssetInfo stored procedure and make necessary changes to ensure that RR_Diameter, RR_Material, RR_InstallYear and other key attributes (like status, asset type, lining, etc.) are being assigned correctly
4)	Configure Aliases
a)	Specify CoF and LoFPerf factors Usage as ‘Hierarchy’ or ‘Attribute’, otherwise ‘NA’ if not used
b)	Specify LoFPhys and OM Usage as ‘Attribute’, otherwise ‘NA’ if not used
c)	Exec p___Alias_Views
5)	Configure RRPS
a)	Use RRPS 
i)	Create Cohorts on the main screen
ii)	Create R&R Costs in the Configuration screen
iii)	Set project appropriate CoF LoF Mapping in the Configuration screen
iv)	Create CoF and LoF Assignments in the Configuration screen
Note, percentage of pipe buffer can be applied with this syntax:
b.Shape.STBuffer(10).STIntersection(a.Shape).STLength()/a.shape.STLength()>0.9
that selects pipes where 90% are within 10ft of the reference layer.
v)	Set project appropriate Configuration in the Configuration screen
vi)	Run quality control to ensure criteria are being correctly applied
vii)	Create a 20-year no funding scenario and verify it runs without error and assets age properly
viii)	Create a 20-year max funding scenario and verify spending is occurring
b)	Using SSMS
i)	Select Zero Funding scenario in RRPS then execute p___QC_ResultsReview to verify assets are aging properly.
ii)	Select Max Funding scenario in RRPS then execute p___QC_ResultsReview to verify service is being correctly shown (asset needs to be replaced after it crosses EUL, or against low replace
6)	Using Power BI
a)	Set data source and refresh
b)	Apply PBI Aliases
7)	If editing in ArcGIS use ArcCatalog
a)	Right click connection and press “enable geodatabase” and browse to location of license file 
b)	Register RR_Assets with the geodatabase by right-click manage -> register context menu
8)	For vertical assets – photo hyperlinks can sometimes exceed Excel's 255-character limit per cell. To avoid truncation, download the photo IDs and record id as a separate csv. Import the csv as a flat file and use an update query to set FileHyperlinks in RR_Hyperlinks to be rr_photos from the csv.
       Use the following specifications while downloading your data – Format: CSV; Media fields: File URL;       Photos box should be unchecked.
