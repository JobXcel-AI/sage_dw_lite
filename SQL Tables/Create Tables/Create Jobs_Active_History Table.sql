--Specify Reporting DB Name
--This must be run AFTER job status history table is created
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME('Vertex Coatings Reporting');

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Jobs_Active_History'), '(
	job_active_date DATETIME,
	job_number BIGINT
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
DECLARE @DateVal DATETIME
SET @DateVal = CAST(CAST(DATEPART(YEAR,GETDATE()) -1 as NVARCHAR) + ''-01-01'' as datetime)
WHILE (@DateVal < GETDATE())
BEGIN
	INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Jobs_Active_History'), ' 
	SELECT @DateVal as job_active_date, job_number 
	FROM ',@Reporting_DB_Name,'.dbo.Job_Status_History
	WHERE 
		job_status_number BETWEEN 3 AND 5
		AND valid_from_date < @DateVal 
		AND valid_to_date >= @DateVal
	SET @DateVal = DATEADD(MONTH,1,@DateVal)
END
')

EXECUTE sp_executesql @SqlInsertCommand