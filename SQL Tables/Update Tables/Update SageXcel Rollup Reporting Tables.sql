--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = QUOTENAME('[CLIENT_DB_NAME]' + ' Reporting';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME('SageXcel Rollup Reporting');
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);


--Update AR_Invoices Table
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.AR_Invoices
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.AR_Invoices')
EXECUTE sp_executesql @SqlInsertQuery

--Update Change Orders
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Orders
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Change_Orders')
EXECUTE sp_executesql @SqlInsertQuery

--Update Change Order History
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Order_History
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Change_Order_History')
EXECUTE sp_executesql @SqlInsertQuery

--Update Change Order Open History
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Order_Open_History
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Change_Order_Open_History')
EXECUTE sp_executesql @SqlInsertQuery

--Update Employees
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Employee
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Employee')
EXECUTE sp_executesql @SqlInsertQuery

--Update Inventory
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Inventory
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Inventory')
EXECUTE sp_executesql @SqlInsertQuery

--Update Jobs
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Jobs
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Jobs')
EXECUTE sp_executesql @SqlInsertQuery

--Update Job Cost
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Cost
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Job_Cost')
EXECUTE sp_executesql @SqlInsertQuery

--Update Job Status History
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Status_History
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Job_Status_History')
EXECUTE sp_executesql @SqlInsertQuery

--Update Jobs Active History
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Jobs_Active_History
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Jobs_Active_History')
EXECUTE sp_executesql @SqlInsertQuery

--Update Job Cost Waterfall
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Cost_Waterfall
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Job_Cost_Waterfall')
EXECUTE sp_executesql @SqlInsertQuery

--Update Ledger Accounts
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Ledger_Accounts')
EXECUTE sp_executesql @SqlInsertQuery

--Update Ledger Transaction Lines
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Ledger_Transaction_Lines')
EXECUTE sp_executesql @SqlInsertQuery

--Update Payroll Records
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Payroll_Records
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Payroll_Records')
EXECUTE sp_executesql @SqlInsertQuery

--Update Purchase Orders
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Purchase_Orders
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Purchase_Orders')
EXECUTE sp_executesql @SqlInsertQuery

--Update Vendor Contacts
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Vendor_Contacts')
EXECUTE sp_executesql @SqlInsertQuery

--Update Subcontract_Lines Table
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Subcontract_Lines')
EXECUTE sp_executesql @SqlInsertQuery

--Update Change_Order_Lines Table
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Change_Order_Lines')
EXECUTE sp_executesql @SqlInsertQuery

--Update Purchase_Orders Table
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Purchase_Order_Lines')
EXECUTE sp_executesql @SqlInsertQuery

--Update Job_Budget_Lines Table
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Job_Budget_Lines')
EXECUTE sp_executesql @SqlInsertQuery

--Update Timecard Table
SET @SqlInsertQuery = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines
SELECT ''[CLIENT_DB_NAME]'' as db_source, * FROM ',@Client_DB_Name,N'.dbo.Timecards')
EXECUTE sp_executesql @SqlInsertQuery