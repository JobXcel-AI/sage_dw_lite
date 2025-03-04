--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = '[CLIENT_DB_NAME]';
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME('SageXcel Rollup Reporting');
--Initial variable declaration
DECLARE @SqlDeleteCommand NVARCHAR(100);


--Clear out SageXcel Rollup database
SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Orders;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_History;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Open_History;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Employees;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Inventory;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Jobs;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Job_Status_History;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Jobs_Active_History;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost_Waterfall;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Payroll_Records;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Orders;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Timecards;')
EXECUTE sp_executesql @SqlDeleteCommand

