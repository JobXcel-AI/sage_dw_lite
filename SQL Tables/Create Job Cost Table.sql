--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job Cost'), '(
	job_id BIGINT,
	job_number BIGINT,
	job_name NVARCHAR(75),
	job_status NVARCHAR(8),
	job_cost_code NVARCHAR(50),
	work_order_number NVARCHAR(20),
	transaction_number NVARCHAR(20),
	job_cost_description NVARCHAR(50),
	job_cost_source NVARCHAR(20),
	vendor_id BIGINT,
	vendor NVARCHAR(75),
	cost_type NVARCHAR(30),
	cost_in_hours DECIMAL(7,2),
	cost_amount DECIMAL(12,2),
	material_cost DECIMAL(12,2),
	labor_cost DECIMAL(12,2),
	equipment_cost DECIMAL(12,2),
	other_cost DECIMAL(12,2),
	billing_quantity DECIMAL(7,2),
	billing_amount DECIMAL(12,2),
	overhead_amount DECIMAL(12,2),
	job_cost_status NVARCHAR(4)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job Cost'),' 

SELECT 
	j.recnum as job_id,
	j.jobnum as job_number,
	ar.jobnme as job_name,
	CASE ar.status 
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
	END as job_status,
	cd.cdenme as job_cost_code,
	j.wrkord as work_order_number,
	trnnum as transaction_number,
	j.dscrpt as job_cost_description,
	s.srcnme as job_cost_source,
	v.recnum as vendor_id,
	v.vndnme as vendor,
	ct.typnme as cost_type,
	csthrs as cost_in_hours,
	cstamt as cost_amount,
	CASE 
		WHEN ct.typnme = ''Material'' THEN cstamt 
		ELSE 0 
	END as material_cost,
	CASE 
		WHEN ct.typnme = ''Labor'' THEN cstamt 
		ELSE 0 
	END as labor_cost,
	CASE 
		WHEN ct.typnme = ''Equipment'' THEN cstamt 
		ELSE 0 
	END as equipment_cost,
	CASE 
		WHEN ct.typnme = ''Other'' THEN cstamt 
		ELSE 0 
	END as other_cost,
	j.blgqty as billing_quantity,
	j.blgamt as billing_amount,
	j.ovhamt as overhead_amount,
	CASE j.status
		WHEN 1 THEN ''Open''
		WHEN 2 THEN ''Void''
	END as job_cost_status
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst j
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = j.csttyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.source s on s.recnum = j.srcnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cd on cd.recnum = j.cstcde
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actpay v on v.recnum = j.vndnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec ar on ar.recnum = j.jobnum')

EXECUTE sp_executesql @SqlInsertCommand