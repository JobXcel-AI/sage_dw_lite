--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Castle';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Budget_Lines_Pivot'), '(
	job_number BIGINT,
	cost_code NVARCHAR(50),
	cost_type NVARCHAR(15),
	budget DECIMAL(12,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Budget_Lines_Pivot'),' 

SELECT
	recnum as job_number,
	cstcde as cost_code,
	''Material'' as cost_type,
	SUM(matbdg) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(matbdg) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''Labor'' as cost_type,
	SUM(laborg) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(laborg) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''Equipment'' as cost_type,
	SUM(eqpbdg) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(eqpbdg) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''Subcontract'' as cost_type,
	SUM(subbdg) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(subbdg) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''Other'' as cost_type,
	SUM(othbdg) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(othbdg) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''User Def Type 6'' as cost_type,
	SUM(usrcs6) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(usrcs6) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''User Def Type 7'' as cost_type,
	SUM(usrcs7) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(usrcs7) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''User Def Type 8'' as cost_type,
	SUM(usrcs8) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(usrcs8) <> 0
UNION ALL
SELECT
	recnum as job_number,
	cstcde as cost_code,
	''User Def Type 9'' as cost_type,
	SUM(usrcs9) as budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.bdglin
GROUP BY recnum, cstcde
HAVING SUM(usrcs9) <> 0
')

EXECUTE sp_executesql @SqlInsertCommand