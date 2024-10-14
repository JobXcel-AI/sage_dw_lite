--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost_Waterfall'), '(
	job_number BIGINT,	
	waterfall_category NVARCHAR(50),
	waterfall_value DECIMAL(14,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

DECLARE @SQLinsertWFtable NVARCHAR(MAX);
SET @SQLinsertWFtable = CONCAT(N'
DECLARE @wf_table TABLE (
	job_number BIGINT, contract_amount DECIMAL(14,2), 
	invoice_total DECIMAL(14,2), invoice_amount_paid DECIMAL(14,2), 
	invoice_sales_tax DECIMAL(14,2),material_cost DECIMAL(14,2),
	labor_cost DECIMAL(14,2), equipment_cost DECIMAL(14,2),
	other_cost DECIMAL(14,2), overhead_cost DECIMAL(14,2),
	approved_amount DECIMAL(14,2)
);

INSERT INTO @wf_table 
SELECT
	a.recnum as job_number,	
	ISNULL(a.cntrct,0) as contract_amount,
	ISNULL(i.invttl,0) as invoice_total,
	ISNULL(i.amtpad,0) as invoice_amount_paid,
	ISNULL(i.slstax,0) * -1 as invoice_sales_tax,
	ISNULL(jc.material_cost,0) * -1 as material_cost,
	ISNULL(jc.labor_cost,0) * -1 as labor_cost,
	ISNULL(jc.equipment_cost,0) * -1 as equipment_cost,
	ISNULL(jc.other_cost,0) * -1 as other_cost,
	ISNULL(jc.overhead_amount,0) * -1 as overhead_cost,
	ISNULL(c.appamt,0) as approved_amount
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
LEFT JOIN (
	SELECT
		jobnum,
		SUM(CASE 
			WHEN ct.typnme = ''Material'' THEN cstamt 
			ELSE 0 
		END) as material_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Labor'' THEN cstamt 
			ELSE 0 
		END) as labor_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Equipment'' THEN cstamt 
			ELSE 0 
		END) as equipment_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Other'' THEN cstamt 
			ELSE 0 
		END) as other_cost,
		SUM(jcst.ovhamt) as overhead_amount
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst jcst
	INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = jcst.csttyp
	WHERE jcst.status = 1
	GROUP BY jobnum
) jc on jc.jobnum = a.recnum
INNER JOIN (
	SELECT 
		jobnum,
		SUM(invttl) as invttl,
		SUM(amtpad) as amtpad,
		SUM(slstax) as slstax
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv 
	WHERE 
		invtyp = 1
		AND status != 5
		GROUP BY jobnum
) as i on a.recnum = i.jobnum
LEFT JOIN 
(SELECT 
	jobnum,
	SUM(appamt) as appamt,
	sum(ovhamt) as ovhamt
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg 
WHERE status < 5
GROUP BY jobnum) c on c.jobnum = a.recnum

INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost_Waterfall'), ' 

SELECT
	job_number,
	waterfall_category,
	waterfall_value 
FROM (
	SELECT 
		job_number,
		''Contract Amount'' as waterfall_category,
		contract_amount as waterfall_value
	FROM @wf_table
	UNION ALL 
	SELECT 
		job_number,
		''Invoice Total'' as waterfall_category,
		invoice_total as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Invoice Amount Paid'' as waterfall_category,
		invoice_amount_paid as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Invoice Sales Tax'' as waterfall_category,
		invoice_sales_tax as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Material Cost'' as waterfall_category,
		material_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Labor Cost'' as waterfall_category,
		labor_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Equipment Cost'' as waterfall_category,
		equipment_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Other Cost'' as waterfall_category,
		other_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Overhead Cost'' as waterfall_category,
		overhead_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Approved Amount'' as waterfall_category,
		approved_amount as waterfall_value
	FROM @wf_table
) wf 
WHERE waterfall_value < 0 OR waterfall_value > 0
')

EXECUTE sp_executesql @SQLinsertWFtable
