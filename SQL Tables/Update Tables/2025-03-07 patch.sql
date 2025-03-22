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

--Remove constraint on is_deleted if approved_change_hours doesn't exist in Change Order Lines
SET @DropConstraints = CONCAT(N'
DECLARE @NestedSQL NVARCHAR(MAX);
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Change_Order_Lines'', ''approved_change_hours'') IS NULL
BEGIN
	SELECT TOP 1 @NestedSQL = N''ALTER TABLE ',@Reporting_DB_Name,N'.dbo.[Change_Order_Lines] drop constraint [''+dc.name+N'']''
	FROM ',@Reporting_DB_Name,N'.sys.default_constraints dc
	JOIN ',@Reporting_DB_Name,N'.sys.columns c ON c.default_object_id = dc.object_id
	WHERE dc.parent_object_id = OBJECT_ID(''',@Reporting_DB_Name,N'.dbo.Change_Order_Lines'') AND c.name = ''is_deleted''
	EXECUTE sp_executesql @NestedSQL
END
')
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


--Insert approved changed hours/units columns into Change_Order_Lines.  
--Also places it 5th/6th from the last, temporarily removing and readding the last 4 columns in Change_Order_Lines
SET @SqlPatchQuery = CONCAT(N'
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Change_Order_Lines'', ''approved_change_hours'') IS NULL
BEGIN
    SELECT change_order_id, created_date, last_updated_date, is_deleted, deleted_date INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines
	DROP COLUMN created_date, last_updated_date, is_deleted, deleted_date;
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines
    ADD [approved_change_hours] DECIMAL (12,2), [approved_change_units] DECIMAL (10,4), created_date DATETIME, last_updated_date DATETIME, is_deleted BIT DEFAULT 0, deleted_date DATETIME;
	UPDATE a
	SET a.approved_change_hours = cl.approved_change_hours,
		a.approved_change_units = cl.approved_change_units,
		a.created_date = meta.created_date,
		a.last_updated_date = meta.last_updated_date,
		a.is_deleted = meta.is_deleted,
		a.deleted_date = meta.deleted_date
	FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines a
	LEFT JOIN (
		SELECT
			p.recnum,
			SUM(ISNULL(s.chghrs,0)) as approved_change_hours,
			SUM(ISNULL(s.chgunt,0)) as approved_change_units
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg p
		LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.sbcgln s ON p.recnum = s.recnum
		WHERE p.status = 1
		GROUP BY p.recnum
	) cl ON a.change_order_id = cl.recnum
	LEFT JOIN #TempTbl meta ON meta.change_order_id = a.change_order_id
END
')

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


