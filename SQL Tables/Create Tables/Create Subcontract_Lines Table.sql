--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Subcontract_Lines'), '(
	subcontract_id BIGINT,
	subcontract_number NVARCHAR(20),
	subcontract_date DATE,
	scheduled_start_date DATE,
	scheduled_finish_date DATE,
	actual_start_date DATE,
	actual_finish_date DATE,
	subcontract_status NVARCHAR(8),
	job_number BIGINT,
	cost_code NVARCHAR(50),
	cost_type NVARCHAR(30),
	committed_amount DECIMAL(12,2),
	remaining_amount DECIMAL(12,2),
	hot_list BIT,
	vendor_id BIGINT,
	vendor_name NVARCHAR(75),
	vendor_account_number NVARCHAR(30),
	vendor_type NVARCHAR(50),
	vendor_email NVARCHAR(75),
	vendor_phone_number NVARCHAR(14),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Subcontract_Lines'),' 

SELECT
	p.recnum as subcontract_id,
	p.ctcnum as subcontract_number,
	p.condte as subcontract_date,
	p.orgstr as scheduled_start_date,
	p.orgfin as scheduled_finish_date,
	p.strdte as actual_start_date,
	p.findte as actual_finish_date,
	CASE
		WHEN p.status = 1 THEN ''Bid''
		WHEN p.status = 2 THEN ''Refused''
		WHEN p.status = 3 THEN ''Contract''
		WHEN p.status = 4 THEN ''Current''
		WHEN p.status = 5 THEN ''Complete''
		WHEN p.status = 6 THEN ''Closed''
	END as subcontract_status,
	p.jobnum as job_number,
	l.cstcde as cost_code,
	l.typnme as cost_type,
	CASE WHEN p.status in (3,4) THEN ISNULL(l.remaining_amount,0) ELSE 0 END as committed_amount,
	ISNULL(l.remaining_amount,0) as remaining_amount,
	p.hotlst as hot_list,
	a.recnum as vendor_id,
	a.vndnme as vendor_name,
	a.actnum as vendor_account_number,
	vt.typnme as vendor_type,
	a.e_mail as vendor_email,
	a.phnnum as vendor_phone_number,
	p.insdte as created_date,
	p.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.subcon p
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actpay a on a.recnum = p.vndnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndtyp vt on vt.recnum = a.vndtyp
LEFT JOIN (
	SELECT 
	s.recnum,
	cstcde,
	typnme,
	SUM(remain) as remaining_amount
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.sbcnln s
	INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp c on c.recnum = s.csttyp
	GROUP BY s.recnum, cstcde, typnme
) l on l.recnum = p.recnum
')

EXECUTE sp_executesql @SqlInsertCommand