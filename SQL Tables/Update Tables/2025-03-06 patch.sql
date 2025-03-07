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

--Insert budget hours into Job_Budget_Lines.
SET @SqlPatchQuery = CONCAT(N'
IF COL_LENGTH(''',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines'', ''budget_hours'') IS NULL
BEGIN
	ALTER TABLE ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines
    ADD [budget_hours] DECIMAL(12,2);
END')

SELECT @TranName = 'Job_Budget_Lines_Hours_1';
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

SET @SqlPatchQuery = CONCAT(N'	
	UPDATE a
	SET a.budget_hours = b.budget_hours
	FROM ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines a
	LEFT JOIN (
		SELECT
			recnum,
			cstcde,
			''Material'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE matbdg <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''Labor'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE laborg <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''Equipment'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE eqpbdg <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''Subcontract'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE subbdg <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''Other'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE othbdg <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''User Def Type 6'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE usrcs6 <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''User Def Type 7'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE usrcs7 <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''User Def Type 8'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE usrcs8 <> 0
		GROUP BY recnum, cstcde
		UNION ALL 
		SELECT
			recnum,
			cstcde,
			''User Def Type 9'' as cost_type,
			SUM(hrsbdg) as budget_hours
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
		WHERE usrcs9 <> 0
		GROUP BY recnum, cstcde
	) b ON a.job_number = b.recnum AND a.cost_code = b.cstcde AND a.cost_type = b.cost_type
')

SELECT @TranName = 'Job_Budget_Lines_Hours_2';
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


