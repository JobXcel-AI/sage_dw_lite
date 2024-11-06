--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
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
	total_change_amount DECIMAL(12,2),
	material DECIMAL(12,2), 
	other DECIMAL(12,2), 
	subcontract DECIMAL(12,2), 
	equipment DECIMAL(12,2),
	labor DECIMAL(12,2),
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
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_Lines'),' 

SELECT 
	c.recnum as change_order_id,
	chgnum as change_order_number,
	chgdte as change_order_date,
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
	dscrpt as change_order_description,
	ct.typnme as change_type,
	reason,
	subdte as submitted_date,
	aprdte as approved_date,
	invdte as invoice_date,
	c.pchord as purchase_order_number,
	s.cstcde as cost_code,	
	s.total_change_amount,
	s.material, 
	s.other, 
	s.subcontract, 
	s.equipment,
	s.labor,
	s.user_defined6,
	s.user_defined7,
	s.user_defined8,
	s.user_defined9,
	c.insdte as created_date,
	c.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg c
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a on a.recnum = c.jobnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.chgtyp ct on ct.recnum = c.chgtyp
LEFT JOIN (
	SELECT 
	recnum, 
	cstcde, 
	SUM(Material) as material, 
	SUM(Other) as other, 
	SUM(Subcontract) as subcontract, 
	SUM(Equipment) as equipment,
	SUM(Labor) as labor,
	SUM(user_defined6) as user_defined6,
	SUM(user_defined7) as user_defined7,
	SUM(user_defined8) as user_defined8,
	SUM(user_defined9) as user_defined9,
	SUM(Material) + SUM(Other) + SUM(Subcontract) + SUM(Equipment) + SUM(Labor) + SUM(user_defined6) + SUM(user_defined7) + SUM(user_defined8) + SUM(user_defined9) as total_change_amount
	FROM (
		SELECT
		recnum, 
		ISNULL(cstcde,0) as cstcde,
		CASE WHEN csttyp = 1 THEN SUM(bdgprc) ELSE 0 END as Material,
		CASE WHEN csttyp = 2 THEN SUM(bdgprc) ELSE 0 END as Labor,
		CASE WHEN csttyp = 3 THEN SUM(bdgprc) ELSE 0 END as Equipment,
		CASE WHEN csttyp = 4 THEN SUM(bdgprc) ELSE 0 END as Subcontract,
		CASE WHEN csttyp = 5 THEN SUM(bdgprc) ELSE 0 END as Other,
		CASE WHEN csttyp = 6 THEN SUM(bdgprc) ELSE 0 END as user_defined6,
		CASE WHEN csttyp = 7 THEN SUM(bdgprc) ELSE 0 END as user_defined7,
		CASE WHEN csttyp = 8 THEN SUM(bdgprc) ELSE 0 END as user_defined8,
		CASE WHEN csttyp = 9 THEN SUM(bdgprc) ELSE 0 END as user_defined9
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.sbcgln 
		GROUP BY recnum, ISNULL(cstcde,0), csttyp
  ) s2 
  group by recnum, cstcde
) s ON c.recnum = s.recnum
')

EXECUTE sp_executesql @SqlInsertCommand