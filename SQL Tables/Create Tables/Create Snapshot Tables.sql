--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Jobs'),'  
FROM ',@Reporting_DB_Name,'.dbo.Jobs;
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Jobs'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Jobs'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_AR_Invoices'),'  
FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('AR_Invoices'),';
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_AR_Invoices'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_AR_Invoices'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Job_Cost'),'  
FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost'),';
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Job_Cost'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Job_Cost'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Change_Orders'),'  
FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Orders'),';
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Change_Orders'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Weekly_Snapshot_Change_Orders'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Jobs'),'  
FROM ',@Reporting_DB_Name,'.dbo.Jobs;
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Jobs'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Jobs'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_AR_Invoices'),'  
FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('AR_Invoices'),';
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_AR_Invoices'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_AR_Invoices'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Job_Cost'),'  
FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost'),';
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Job_Cost'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Job_Cost'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
SELECT * INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Change_Orders'),'  
FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Orders'),';
DELETE FROM ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Change_Orders'),';
ALTER TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Monthly_Snapshot_Change_Orders'),'
ADD snapshot_date DATETIME;
')

EXECUTE sp_executesql @SqlCreateTableCommand