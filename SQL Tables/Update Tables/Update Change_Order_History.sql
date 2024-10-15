--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SQLinsertChangeOrderHistory1 NVARCHAR(MAX);
DECLARE @SQLinsertChangeOrderHistory2 NVARCHAR(MAX);
DECLARE @SQLinsertChangeOrderHistory NVARCHAR(MAX);

--Clear existing History Table
DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_History;

--Recreate History Table

SET @SQLinsertChangeOrderHistory1 = CONCAT(N'
DECLARE @ChangeOrderHistory TABLE (record_number BIGINT, job_number BIGINT, version_date DATETIME, change_order_status_number INT, change_order_status NVARCHAR(8))
INSERT INTO @ChangeOrderHistory 

SELECT DISTINCT
	coalesce(a.recnum,b.change_order_id) as record_number,
	coalesce(a.jobnum,b.job_number) as job_number,
	coalesce(a._Date, b.last_updated_date) as version_date,
	coalesce(a.status, b.status_number) as change_order_status_number,
	CASE coalesce(a.status, b.status_number)
		WHEN 1 THEN ''Approved''
		WHEN 2 THEN ''Open''
		WHEN 3 THEN ''Review''
		WHEN 4 THEN ''Disputed''
		WHEN 5 THEN ''Void''
		WHEN 6 THEN ''Rejected''
		ELSE ''Other''
	END as change_order_status
FROM (
	SELECT 
		recnum,
		status,
		_Date,
		jobnum
	FROM ',QUOTENAME(@Client_DB_Name),N'.[dbo_Audit].[prmchg]
) a
RIGHT JOIN ',@Reporting_DB_Name,'.dbo.Change_Orders b on a.recnum = b.change_order_id
UNION ALL 
SELECT record_number, job_number, version_date, change_order_status_number, change_order_status 
FROM (
	SELECT 
		coalesce(a.recnum,b.change_order_id) as record_number,
		coalesce(a.jobnum,b.job_number) as job_number,
		b.created_date as version_date,
		coalesce(a.status, b.status_number) as change_order_status_number,
		CASE coalesce(a.status, b.status_number)
			WHEN 1 THEN ''Approved''
			WHEN 2 THEN ''Open''
			WHEN 3 THEN ''Review''
			WHEN 4 THEN ''Disputed''
			WHEN 5 THEN ''Void''
			WHEN 6 THEN ''Rejected''
			ELSE ''Other''
		END as change_order_status,
		ROW_NUMBER() OVER (PARTITION BY coalesce(a.recnum,b.change_order_id) ORDER BY coalesce(a.recnum,b.change_order_id), b.created_date, coalesce(a.status, b.status_number)) as row_num
	FROM (
		SELECT 
			recnum,
			status,
			_Date,
			jobnum
		FROM ',QUOTENAME(@Client_DB_Name),'.[dbo_Audit].[prmchg]
	) a
	RIGHT JOIN ',@Reporting_DB_Name,'.dbo.Change_Orders b on a.recnum = b.change_order_id
) q2 
WHERE row_num = 1
UNION ALL 
SELECT
	change_order_id as record_number,
	job_number,
	DATEADD(SECOND,1,last_updated_date) as version_date,
	status_number as change_order_status_number, 
	status as change_order_status
FROM ',@Reporting_DB_Name,'.dbo.Change_Orders
WHERE last_updated_date IS NOT NULL

DECLARE @ChangeOrderHistory2 TABLE (id BIGINT, record_number BIGINT, job_number BIGINT, version_date DATETIME, change_order_status_number INT, change_order_status NVARCHAR(8), can_be_removed BIT)
INSERT INTO @ChangeOrderHistory2 
	
SELECT 
	ROW_NUMBER() OVER (PARTITION BY record_number ORDER BY record_number, version_date) as id,
	record_number, job_number, version_date, change_order_status_number, change_order_status,
	CASE WHEN 
		LAG(change_order_status) OVER(PARTITION BY record_number ORDER BY record_number, version_date) = change_order_status AND 
		LEAD(change_order_status) OVER(PARTITION BY record_number ORDER BY record_number, version_date) = change_order_status
	THEN 1
	ELSE 0
	END as can_be_removed
FROM @ChangeOrderHistory 
')
SET @SQLinsertChangeOrderHistory2 = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_History'), ' 

SELECT DISTINCT
	record_number,
	job_number,
	change_order_status_number,
	change_order_status,
	CASE WHEN prior_version_date IS NULL THEN first_version_date ELSE version_date END as valid_from_date,
	CASE WHEN next_version_date IS NULL THEN DATEADD(YEAR,100,version_date) ELSE next_version_date END as valid_to_date
FROM
(
	SELECT
		record_number,
		job_number,
		version_date,
		change_order_status_number,
		change_order_status,
		FIRST_VALUE(version_date) OVER(PARTITION BY record_number, change_order_status ORDER BY record_number, version_date) as first_version_date,
		LAG(version_date) OVER(PARTITION BY record_number ORDER BY record_number, version_date) as prior_version_date,
		LEAD(version_date) OVER(PARTITION BY record_number ORDER BY record_number, version_date) as next_version_date,
		DATEADD(SECOND,-1,LAST_VALUE(version_date) OVER(PARTITION BY record_number, change_order_status ORDER BY record_number, version_date RANGE BETWEEN CURRENT ROW
					AND UNBOUNDED FOLLOWING)) as last_version_date,
		record_count = COUNT(*) OVER(PARTITION BY record_number ORDER BY record_number, version_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
		ROW_NUMBER() OVER (PARTITION BY record_number ORDER BY record_number, version_date) as record_row_number
	FROM @ChangeOrderHistory2 
	WHERE version_date IS NOT NULL AND can_be_removed = 0
) q
')

SET @SQLinsertChangeOrderHistory = @SQLinsertChangeOrderHistory1 + @SQLinsertChangeOrderHistory2
EXECUTE sp_executesql @SQLinsertChangeOrderHistory
