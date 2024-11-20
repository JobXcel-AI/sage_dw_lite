--This patch relies on existing reporting tables

--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @TranName VARCHAR(20);
DECLARE @ErrorMessage NVARCHAR(4000);  
DECLARE @ErrorSeverity INT;  
DECLARE @ErrorState INT; 
DECLARE @SqlPatchQuery NVARCHAR(MAX);
DECLARE @DropConstraints NVARCHAR(MAX);

--Remove constraint on is_deleted if there is last_date_worked doesn't exist in AR Invoices
SET @DropConstraints = CONCAT(N'
DECLARE @NestedSQL NVARCHAR(MAX);
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Jobs'', ''invoice_billed'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE ',@Reporting_DB_Name,N'.dbo.[Jobs] drop constraint [''+dc.name+N'']''
	FROM sys.default_constraints dc
	JOIN sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''',@Reporting_DB_Name,N'.dbo.Jobs'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END
')
SELECT @TranName = 'Jobs_Drop_Constraint_Is_Deleted';
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


--Insert new columns into Jobs.  Leaves last 4 columns by temporarily removing and readding the last 4 columns in Jobs
SET @SqlPatchQuery = CONCAT(N'
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Jobs'', ''invoice_billed'') IS NULL
BEGIN
    SELECT job_number, created_date, last_updated_date, is_deleted, deleted_date INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Jobs;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Jobs
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Jobs
    ADD [invoice_billed] DECIMAL(14,2), 
	[job_number_job_name] NVARCHAR(100), 
	[total_contract_amount] DECIMAL(14,2),
	[original_budget_amount] DECIMAL(14,2),
	[total_budget_amount] DECIMAL(14,2),
	[estimated_gross_profit] DECIMAL(14,2),
	created_date DATETIME, 
	last_updated_date DATETIME, 
	is_deleted BIT DEFAULT 0, 
	deleted_date DATETIME;
    UPDATE j
	SET 
		j.invoice_billed = ISNULL(j.invoice_total,0) - ISNULL(j.invoice_sales_tax,0),
		j.job_number_job_name = CONCAT(j.job_number,'' - '',j.job_name),
		j.total_contract_amount = ISNULL(j.contract_amount,0) + ISNULL(j.change_order_approved_amount,0),
		j.original_budget_amount = ISNULL(b.budget,0),
		j.total_budget_amount = ISNULL(b.budget,0) + ISNULL(c.budget,0),
		j.estimated_gross_profit = ISNULL(j.contract_amount,0) 
						+ ISNULL(j.change_order_approved_amount,0)
						- ISNULL(b.budget,0) 
						- ISNULL(c.budget,0),
		j.created_date = meta.created_date,
		j.last_updated_date = meta.last_updated_date,
		j.is_deleted = meta.is_deleted,
		j.deleted_date = meta.deleted_date
	FROM ',@Reporting_DB_Name,N'.dbo.Jobs j
	LEFT JOIN #TempTbl meta ON meta.job_number = j.job_number
	LEFT JOIN (
		SELECT 
			job_number,
			SUM(budget) as budget
		FROM ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines
		GROUP BY job_number
	) b on b.job_number = j.job_number
	LEFT JOIN (
		SELECT 
			job_number,
			SUM(approved_change_amount) as budget
		FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines
		GROUP BY job_number
	) c on c.job_number = j.job_number
END
')

SELECT @TranName = 'Jobs_Patch';
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


