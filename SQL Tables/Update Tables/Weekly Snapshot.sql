--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = [CLIENT_DB_NAME];  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Weekly_Snapshot_Jobs
SELECT *, GETDATE() as snapshot_date
FROM ',@Reporting_DB_Name,N'.dbo.Jobs;
')
EXECUTE sp_executesql @SqlInsertQuery

SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Weekly_Snapshot_AR_Invoices
SELECT *, GETDATE() as snapshot_date
FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices;
')
EXECUTE sp_executesql @SqlInsertQuery

SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Weekly_Snapshot_Job_Cost
SELECT *, GETDATE() as snapshot_date
FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost;
')
EXECUTE sp_executesql @SqlInsertQuery

SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Weekly_Snapshot_Change_Orders
SELECT *, GETDATE() as snapshot_date
FROM ',@Reporting_DB_Name,N'.dbo.Change_Orders;
')
EXECUTE sp_executesql @SqlInsertQuery
