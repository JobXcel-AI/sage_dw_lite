--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Budget_Lines'), '(
	job_number BIGINT,
	cost_code NVARCHAR(50),
	total_budget DECIMAL(12,2),
	materials DECIMAL(12,2),
	labor DECIMAL(12,2),
	equipment DECIMAL(12,2),
	subcontract DECIMAL(12,2),
	other DECIMAL(12,2),
	user_defined6 DECIMAL(12,2),
	user_defined7 DECIMAL(12,2),
	user_defined8 DECIMAL(12,2),
	user_defined9 DECIMAL(12,2),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Budget_Lines'),' 

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
')

EXECUTE sp_executesql @SqlInsertCommand