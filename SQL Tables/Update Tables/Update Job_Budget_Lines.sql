--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

--Update Job_Budget_Lines Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines
SELECT
	recnum as job_number,
	cstcde as cost_code,
	SUM(matbdg) + SUM(laborg) + SUM(eqpbdg) + SUM(subbdg) + SUM(othbdg) + SUM(cs6org) + SUM(cs7org) + SUM(cs8org) + SUM(cs9org) as total_budget,
	SUM(matbdg) as materials, 
	SUM(laborg) as labor, 
	SUM(eqpbdg) as equipment, 
	SUM(subbdg) as subcontract, 
	SUM(othbdg) as other, 
	SUM(cs6org) as user_defined6, 
	SUM(cs7org) as user_defined7, 
	SUM(cs8org) as user_defined8, 
	SUM(cs9org) as user_defined9,
	insdte as created_date,
	upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde, insdte, upddte
;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE CONCAT(t.job_number,t.cost_code) NOT IN (SELECT CONCAT(job_number,cost_code) FROM ',@Reporting_DB_Name,N'.dbo.Job_Budget_Lines)
UNION ALL 
SELECT * FROM #DeletedRecords
')
EXECUTE sp_executesql @SqlInsertQuery