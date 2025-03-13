--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = '[CLIENT_DB_NAME]';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @TranName VARCHAR(20);
DECLARE @ErrorMessage NVARCHAR(4000);  
DECLARE @ErrorSeverity INT;  
DECLARE @ErrorState INT; 
DECLARE @SqlPatchQuery NVARCHAR(MAX);
DECLARE @DropConstraints NVARCHAR(MAX);

--Remove constraint on is_deleted if supervisor doesn't exist in Job Cost
SET @DropConstraints = CONCAT(N'
DECLARE @NestedSQL NVARCHAR(MAX);
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Job_Cost'', ''approved_change_hours'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE ',@Reporting_DB_Name,N'.dbo.[Job_Cost] drop constraint [''+dc.name+N'']''
	FROM sys.default_constraints dc
	JOIN sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''',@Reporting_DB_Name,N'.dbo.Job_Cost'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END
')
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


--Insert supervisor/estimator/salesperson into Job Cost.  
--Also places it 5th/6th from the last, temporarily removing and readding the last 4 columns in Job Cost
SET @SqlPatchQuery = CONCAT(N'
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Job_Cost'', ''supervisor'') IS NULL
BEGIN
    SELECT job_cost_id, created_date, last_updated_date, is_deleted, deleted_date INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Job_Cost
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Job_Cost
    ADD [supervisor_id] BIGINT,
	[supervisor] NVARCHAR(100),
	[salesperson_id] BIGINT,
	[salesperson] NVARCHAR(100),
	[estimator_id] BIGINT,	
	[estimator] NVARCHAR(100), 
	created_date DATETIME, last_updated_date DATETIME, is_deleted BIT DEFAULT 0, deleted_date DATETIME;
    UPDATE a
	SET a.supervisor_id = cl.supervisor_id,
		a.supervisor = cl.supervisor,
		a.salesperson_id = cl.salesperson_id,
		a.salesperson = cl.salesperson,
		a.estimator_id = cl.estimator_id,
		a.estimator = cl.estimator,
		a.created_date = meta.created_date,
		a.last_updated_date = meta.last_updated_date,
		a.is_deleted = meta.is_deleted,
		a.deleted_date = meta.deleted_date
	FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost a
	LEFT JOIN (
		SELECT
			a.recnum,
			a.sprvsr as supervisor_id,
			CONCAT(es.fstnme, '' '', es.lstnme) as supervisor,
			a.slsemp as salesperson_id,
			CONCAT(e.fstnme, '' '', e.lstnme) as salesperson,
			a.estemp as estimator_id,
			CONCAT(est.fstnme, '' '', est.lstnme) as estimator
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
		LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ es on es.recnum = a.sprvsr 
		LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = a.slsemp
		LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.employ est on est.recnum = a.estemp
	) cl ON a.job_number = cl.recnum
	LEFT JOIN #TempTbl meta ON meta.job_cost_id = a.job_cost_id
END
')

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


