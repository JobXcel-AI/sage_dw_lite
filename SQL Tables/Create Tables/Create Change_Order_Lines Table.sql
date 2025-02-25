--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Castle';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_Lines'), '(
	change_order_id BIGINT,
	change_order_number NVARCHAR(20),
	change_order_date DATE,
	job_number BIGINT,
	job_name NVARCHAR(75),
	job_phase_number BIGINT,
	status NVARCHAR(8),
	status_number INT,
	change_order_description NVARCHAR(50),
	change_type NVARCHAR(50),
	reason NVARCHAR(50),
	submitted_date DATE,
	approved_date DATE,
	invoice_date DATE,
	purchase_order_number NVARCHAR(30),
	cost_code NVARCHAR(50),
	cost_code_name NVARCHAR(50),
	cost_type NVARCHAR(30),
	approved_change_amount DECIMAL(12,2),
	change_amount DECIMAL(12,2),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_Lines'),' 

SELECT 
	c.recnum as change_order_id,
	c.chgnum as change_order_number,
	c.chgdte as change_order_date,
	jobnum as job_number,
	a.jobnme as job_name,
	c.phsnum as job_phase_number,
	CASE c.status
		WHEN 1 THEN ''Approved''
		WHEN 2 THEN ''Open''
		WHEN 3 THEN ''Review''
		WHEN 4 THEN ''Disputed''
		WHEN 5 THEN ''Void''
		WHen 6 THEN ''Rejected''
	END as status,
	c.status as status_number,
	c.dscrpt as change_order_description,
	ct.typnme as change_type,
	reason,
	subdte as submitted_date,
	aprdte as approved_date,
	invdte as invoice_date,
	c.pchord as purchase_order_number,
	cl.cstcde as cost_code,
	cd.cdenme as cost_code_name,	
	cst.typnme as cost_type,
	CASE c.status WHEN 1 THEN SUM(ISNULL(cl.bdgprc,0)) ELSE 0 END as approved_change_amount,
	SUM(ISNULL(cl.bdgprc,0)) as change_amount,
	c.insdte as created_date,
	c.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg c
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a on a.recnum = c.jobnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.chgtyp ct on ct.recnum = c.chgtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.sbcgln cl on cl.recnum = c.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp cst on cst.recnum = cl.csttyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cd on cd.recnum = cl.cstcde
GROUP BY c.recnum, c.chgnum, c.chgdte, jobnum, a.jobnme, c.phsnum, c.status, c.dscrpt, ct.typnme, reason, subdte, aprdte, invdte, c.pchord, cd.cdenme, cl.cstcde, cst.typnme, c.insdte,c.upddte
')

EXECUTE sp_executesql @SqlInsertCommand