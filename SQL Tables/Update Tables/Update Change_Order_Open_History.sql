--Specify Reporting DB Name
--This must be run AFTER change order history table is created
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME('Vertex Coatings Reporting');
--Initial variable declaration
DECLARE @SqlInsertCommand NVARCHAR(MAX);


--Clear existing History Table
DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Open_History;

--Recreate History Table

SET @SqlInsertCommand = CONCAT(N'
DECLARE @DateVal DATETIME
SET @DateVal = CAST(CAST(DATEPART(YEAR,GETDATE()) -1 as NVARCHAR) + ''-01-01'' as datetime)
WHILE (@DateVal < GETDATE())
BEGIN
	INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_Open_History'), ' 
	SELECT @DateVal as change_order_open_date, record_number, job_number 
	FROM ',@Reporting_DB_Name,'.dbo.Change_Order_History
	WHERE 
		change_order_status_number BETWEEN 2 AND 4
		AND valid_from_date < @DateVal 
		AND valid_to_date >= @DateVal
	SET @DateVal = DATEADD(MONTH,1,@DateVal)
END
')

EXECUTE sp_executesql @SqlInsertCommand