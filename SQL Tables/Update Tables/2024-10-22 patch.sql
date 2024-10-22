--This patch has already been applied to all production instances.


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
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.AR_Invoices'', ''last_date_worked'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE ',@Reporting_DB_Name,N'.dbo.[AR_Invoices] drop constraint [''+dc.name+N'']''
	FROM sys.default_constraints dc
	JOIN sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''',@Reporting_DB_Name,N'.dbo.AR_Invoices'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END
')
SELECT @TranName = 'AR_Invoice_Drop_Constraint_Is_Deleted';
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


--Insert last_date_worked column into AR_Invoices.  Also places it 5th from the last, temporarily removing and readding the last 4 columns in AR_Invoices
SET @SqlPatchQuery = CONCAT(N'
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.AR_Invoices'', ''last_date_worked'') IS NULL
BEGIN
    SELECT ar_invoice_id, created_date, last_updated_date, is_deleted, deleted_date INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.AR_Invoices
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.AR_Invoices
    ADD [last_date_worked] DATE, created_date DATETIME, last_updated_date DATETIME, is_deleted BIT DEFAULT 0, deleted_date DATETIME;
	UPDATE a
	SET a.last_date_worked = tc.last_date_worked,
		a.created_date = meta.created_date,
		a.last_updated_date = meta.last_updated_date,
		a.is_deleted = meta.is_deleted,
		a.deleted_date = meta.deleted_date
	FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices a
	LEFT JOIN (
		SELECT
			MAX(dtewrk) last_date_worked,
			jobnum
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.tmcdln
		GROUP BY jobnum
	) tc ON a.job_number = tc.jobnum
	LEFT JOIN #TempTbl meta ON meta.ar_invoice_id = a.ar_invoice_id
END
')

SELECT @TranName = 'AR_Invoices_Last_Worked_Date';
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


