--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Vendor_Contacts'), '(
	vendor_contact_id NVARCHAR(20),
	contact_name NVARCHAR(50),
	contact_email NVARCHAR(75),
	contact_phone NVARCHAR(14),
	job_title NVARCHAR(50),
	vendor_id BIGINT,
	vendor_name NVARCHAR(75),
	vendor_type NVARCHAR(50),
	address1 NVARCHAR(50),
	address2 NVARCHAR(50),
	zip NVARCHAR(10),
	city NVARCHAR(50),
	state NVARCHAR(2),
	vendor_account_number NVARCHAR(30),
	vendor_resale_number NVARCHAR(30),
	vendor_license_number NVARCHAR(30),
	cost_code NVARCHAR(50),
	cost_type NVARCHAR(30),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Vendor_Contacts'),' 

SELECT
	CONCAT(act.recnum,''-'',c.linnum) as vendor_contact_id,
	c.cntnme as contact_name,
	c.e_mail as contact_email,
	c.phnnum as contact_phone,
	c.jobttl as job_title,
	act.recnum as vendor_id,
	act.vndnme as vendor_name,
	vt.typnme as vendor_type,
	act.addrs1 as address1,
	act.addrs2 as address2,
	act.zipcde as zip,
	act.ctynme as city,
	act.state_ as state,
	act.actnum as vendor_account_number,
	act.resnum as vendor_resale_number,
	act.licnum as vendor_license_number,
	cst.cdenme as cost_code,
	ct.typnme as cost_type,
	c.insdte as created_date,
	c.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actpay AS act 
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndcnt AS c ON act.recnum = c.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cst on cst.recnum = act.cdedft
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = act.typdft
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndtyp vt on vt.recnum = act.vndtyp')

EXECUTE sp_executesql @SqlInsertCommand