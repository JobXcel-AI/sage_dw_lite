--Version 1.0.2

--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = '[CLIENT_DB_NAME]';
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME('SageXcel Rollup Reporting');
--Initial variable declaration
DECLARE @SqlDeleteCommand NVARCHAR(100);
DECLARE @SqlPatchQuery NVARCHAR(MAX);
DECLARE @DropConstraints NVARCHAR(MAX);
DECLARE @TranName NVARCHAR(30);
DECLARE @ErrorMessage NVARCHAR(4000);  
DECLARE @ErrorSeverity INT;  
DECLARE @ErrorState INT;  

--If Version, Update_log, or Ledger_Accounts_by_Month doesn't exist, create them
SET @SqlPatchQuery = N'
IF OBJECT_ID(''[SageXcel Rollup Reporting].dbo.[Version]'',''U'') IS NULL
BEGIN
	CREATE TABLE [SageXcel Rollup Reporting].dbo.[Version] (
		db_source NVARCHAR(100),
		name NVARCHAR(10),
		update_date DATETIME NOT NULL DEFAULT GETDATE(),
		update_user CHAR(50) NOT NULL DEFAULT CURRENT_USER
	);
END'
EXECUTE sp_executesql @SqlPatchQuery

SET @SqlPatchQuery = N'
IF OBJECT_ID(''[SageXcel Rollup Reporting].dbo.[Update_Log]'',''U'') IS NULL
BEGIN
	CREATE TABLE [SageXcel Rollup Reporting].dbo.[Update_Log] (
		db_source NVARCHAR(100),
		version_name NVARCHAR(10),
		run_date DATETIME NOT NULL DEFAULT GETDATE(),
		update_user CHAR(50) NOT NULL DEFAULT CURRENT_USER
	);
END'
EXECUTE sp_executesql @SqlPatchQuery

SET @SqlPatchQuery = N'
IF OBJECT_ID(''[SageXcel Rollup Reporting].dbo.[Ledger_Accounts_by_Month]'',''U'') IS NULL
BEGIN
	CREATE TABLE [SageXcel Rollup Reporting].dbo.[Ledger_Accounts_by_Month] (
		db_source NVARCHAR(100),
		ledger_account_id BIGINT,
		ledger_account NVARCHAR(50),
		subsidiary_type NVARCHAR(12),
		summary_account NVARCHAR(50),
		cost_type NVARCHAR(30),
		current_balance DECIMAL(14,2),
		account_type NVARCHAR(22),
		debit_or_credit NVARCHAR(6),
		notes NVARCHAR(MAX),
		balance_budget_date DATE,
		balance DECIMAL(14,2),
		budget DECIMAL(14,2),
		created_date DATETIME,
		last_updated_date DATETIME,
		is_deleted BIT DEFAULT 0,
		deleted_date DATETIME
	);
END'
EXECUTE sp_executesql @SqlPatchQuery


--Add additional fields to Job_Cost if doesn't exist
SET @DropConstraints = N'
DECLARE @NestedSQL NVARCHAR(MAX);
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Job_Cost'', ''supervisor'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE [SageXcel Rollup Reporting].dbo.[Job_Cost] drop constraint [''+dc.name+N'']''
	FROM sys.default_constraints dc
	JOIN sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''[SageXcel Rollup Reporting].dbo.Job_Cost'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END'

SELECT @TranName = 'Job Cost_Drop_Constraint_Is_Deleted';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @DropConstraints

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH

SET @SqlPatchQuery = N'
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Job_Cost'', ''supervisor'') IS NULL
BEGIN
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Job_Cost
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Job_Cost
	ADD [supervisor_id] BIGINT,
	[supervisor] NVARCHAR(100),
	[salesperson_id] BIGINT,
	[salesperson] NVARCHAR(100),
	[estimator_id] BIGINT,	
	[estimator] NVARCHAR(100), 
	created_date DATETIME, last_updated_date DATETIME, is_deleted BIT DEFAULT 0, deleted_date DATETIME;
END'

SELECT @TranName = 'Job Cost_Supervisor_add';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlPatchQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH

--Alter TimeCard table to accept larger hours per day
SET @SqlPatchQuery = N'
IF(
	SELECT NUMERIC_PRECISION
	FROM [SageXcel Rollup Reporting].INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = ''Timecards'' AND COLUMN_NAME = ''hours_worked'') = ''4''
BEGIN
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Timecards ALTER COLUMN hours_worked DECIMAL (7,2);
END'

EXECUTE sp_executesql @SqlPatchQuery

--Add budget_hours to Budget hours to Job_Budget_Lines if it doesn't exist
SET @SqlPatchQuery = N'
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Job_Budget_Lines'', ''budget_hours'') IS NULL
BEGIN
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Job_Budget_Lines
	ADD budget_hours DECIMAL(12,2);
END'

EXECUTE sp_executesql @SqlPatchQuery

--Add approved_change_hours to Change_Order_Lines if it doesn't exist
SET @DropConstraints = N'
DECLARE @NestedSQL NVARCHAR(MAX);
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Change_Order_Lines'', ''approved_change_hours'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE [SageXcel Rollup Reporting].dbo.[Change_Order_Lines] drop constraint [''+dc.name+N'']''
	FROM [SageXcel Rollup Reporting].sys.default_constraints dc
	JOIN [SageXcel Rollup Reporting].sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''[SageXcel Rollup Reporting].dbo.Change_Order_Lines'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END'

SELECT @TranName = 'Change_Order_Lines_Drop_Constraint_Is_Deleted';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @DropConstraints

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH

SET @SqlPatchQuery = N'
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Change_Order_Lines'', ''approved_change_hours'') IS NULL
BEGIN
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Change_Order_Lines
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Change_Order_Lines
    ADD [approved_change_hours] DECIMAL (12,2), [approved_change_units] DECIMAL (10,4), 
	created_date DATETIME, last_updated_date DATETIME, is_deleted BIT DEFAULT 0, deleted_date DATETIME
END'

SELECT @TranName = 'Change_Order_Lines_Approved_Hours';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlPatchQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH

--Remove constraint on is_deleted if account_type doesn't exist in Ledger Transaction Lines
SET @DropConstraints = N'
DECLARE @NestedSQL NVARCHAR(MAX);
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Ledger_Transaction_Lines'', ''account_type'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE [SageXcel Rollup Reporting].dbo.[Ledger_Transaction_Lines] drop constraint [''+dc.name+N'']''
	FROM [SageXcel Rollup Reporting].sys.default_constraints dc
	JOIN [SageXcel Rollup Reporting].sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''[SageXcel Rollup Reporting].dbo.Ledger_Transaction_Lines'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END
'
SELECT @TranName = 'Ledger_Transaction_Lines_Drop_Constraint_Is_Deleted';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @DropConstraints

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH

--Insert account_type, subsidiary_type, debit_or_credit, cost_type into Ledger_Transaction_Lines.  
--Also places it 5th-8th from the last, temporarily removing and readding the last 4 columns in LTL
SET @SqlPatchQuery = N'
IF COL_LENGTH(''[SageXcel Rollup Reporting].dbo.Ledger_Transaction_Lines'', ''account_type'') IS NULL
BEGIN
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Ledger_Transaction_Lines
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE [SageXcel Rollup Reporting].dbo.Ledger_Transaction_Lines
    ADD [account_type] NVARCHAR(22),
	[subsidiary_type] NVARCHAR(12),
	[debit_or_credit] NVARCHAR(6),
	[cost_type] NVARCHAR(30),
	[status] NVARCHAR(1),
	created_date DATETIME, last_updated_date DATETIME, is_deleted BIT DEFAULT 0, deleted_date DATETIME;
END
'

SELECT @TranName = 'Ledger_Transaction_Line_AccountType_add';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlPatchQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH




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

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts_by_Month;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Update_Log;')
EXECUTE sp_executesql @SqlDeleteCommand

SET @SqlDeleteCommand = CONCAT(
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Version;')
EXECUTE sp_executesql @SqlDeleteCommand

