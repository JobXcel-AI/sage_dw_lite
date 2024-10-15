--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Status_History'), '(
	job_number BIGINT,
	job_status_number INT,
	job_status NVARCHAR(8),
	valid_from_date DATETIME,
	valid_to_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

DECLARE @SQLinsertJobHistory NVARCHAR(MAX);
SET @SQLinsertJobHistory = CONCAT(N'
DECLARE @JobHistory TABLE (job_number BIGINT, version_date DATETIME, job_status_number INT, job_status NVARCHAR(8))
INSERT INTO @JobHistory 

SELECT DISTINCT
	coalesce(a.recnum,b.recnum) as job_number,
	coalesce(a._Date, b.upddte) as version_date,
	coalesce(a.status, b.status) as job_status_number,
	CASE coalesce(a.status, b.status)
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status
FROM (
	SELECT 
		recnum,
		status,
		_Date,
		jobnme
	FROM ',QUOTENAME(@Client_DB_Name),N'.[dbo_Audit].[actrec]
) a
RIGHT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec b on a.recnum = b.recnum
UNION ALL 
SELECT job_number, version_date, job_status_number, job_status 
FROM (
	SELECT 
		coalesce(a.recnum,b.recnum) as job_number,
		b.insdte as version_date,
		coalesce(a.status, b.status) as job_status_number,
		CASE coalesce(a.status, b.status)
			WHEN 1 THEN ''Bid''
			WHEN 2 THEN ''Refused''
			WHEN 3 THEN ''Contract''
			WHEN 4 THEN ''Current''
			WHEN 5 THEN ''Complete''
			WHEN 6 THEN ''Closed''
			ELSE ''Other''
		END as job_status,
		ROW_NUMBER() OVER (PARTITION BY coalesce(a.recnum,b.recnum) ORDER BY coalesce(a.recnum,b.recnum), b.insdte, a.status) as row_num
	FROM (
		SELECT 
			recnum,
			status,
			_Date,
			jobnme
		FROM ',QUOTENAME(@Client_DB_Name),'.[dbo_Audit].[actrec]
	) a
	RIGHT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.actrec b on a.recnum = b.recnum
) q2 
WHERE row_num = 1
UNION ALL 
SELECT
	recnum as job_number,
	DATEADD(SECOND,1,upddte) as version_date,
	status as job_status_number, 
	CASE status
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status
FROM ',QUOTENAME(@Client_DB_Name),N'.dbo.actrec
WHERE upddte IS NOT NULL

DECLARE @JobHistory2 TABLE (id BIGINT, job_number BIGINT, version_date DATETIME, job_status_number INT, job_status NVARCHAR(8), can_be_removed BIT)
INSERT INTO @JobHistory2 
	
SELECT 
	ROW_NUMBER() OVER (PARTITION BY job_number ORDER BY job_number, version_date) as id,
	job_number, version_date, job_status_number, job_status,
	CASE WHEN 
		LAG(job_status) OVER(PARTITION BY job_number ORDER BY job_number, version_date) = job_status AND 
		LEAD(job_status) OVER(PARTITION BY job_number ORDER BY job_number, version_date) = job_status
	THEN 1
	ELSE 0
	END as can_be_removed
FROM @JobHistory 

INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Status_History'), ' 
SELECT DISTINCT
	job_number,
	job_status_number,
	job_status,
	CASE WHEN prior_version_date IS NULL THEN first_version_date ELSE version_date END as valid_from_date,
	CASE WHEN next_version_date IS NULL THEN DATEADD(YEAR,100,version_date) ELSE next_version_date END as valid_to_date
FROM
(
	SELECT
		job_number,
		version_date,
		job_status_number,
		job_status,
		FIRST_VALUE(version_date) OVER(PARTITION BY job_number, job_status ORDER BY job_number, version_date) as first_version_date,
		LAG(version_date) OVER(PARTITION BY job_number ORDER BY job_number, version_date) as prior_version_date,
		LEAD(version_date) OVER(PARTITION BY job_number ORDER BY job_number, version_date) as next_version_date,
		DATEADD(SECOND,-1,LAST_VALUE(version_date) OVER(PARTITION BY job_number, job_status ORDER BY job_number, version_date RANGE BETWEEN CURRENT ROW
					AND UNBOUNDED FOLLOWING)) as last_version_date,
		record_count = COUNT(*) OVER(PARTITION BY job_number ORDER BY job_number, version_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
		ROW_NUMBER() OVER (PARTITION BY job_number ORDER BY job_number, version_date) as record_number
	FROM @JobHistory2 
	WHERE version_date IS NOT NULL AND can_be_removed = 0
) q
')

EXECUTE sp_executesql @SQLinsertJobHistory
