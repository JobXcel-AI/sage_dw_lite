--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Payroll_Records'), '(
	payroll_record_id BIGINT,
	employee_id BIGINT,
	employee_full_name NVARCHAR(100),
	employee_status NVARCHAR(12),
	check_number NVARCHAR(20),
	check_date DATE,
	period_start DATE,
	period_end DATE,
	regular_hours DECIMAL(9,4) DEFAULT 0,
	overtime_hours DECIMAL(9,4) DEFAULT 0,
	premium_hours DECIMAL(9,4) DEFAULT 0,
	sick_hours DECIMAL(9,4) DEFAULT 0,
	vacation_hours DECIMAL(9,4) DEFAULT 0,
	holiday_hours DECIMAL(9,4) DEFAULT 0,
	total_hours DECIMAL(9,4) DEFAULT 0,
	comp_wage DECIMAL(9,2) DEFAULT 0,
	comp_gross DECIMAL(9,2) DEFAULT 0,
	comp_code BIGINT,
	comp_type NVARCHAR(50),
	payroll_type NVARCHAR(13),
	payroll_status NVARCHAR(8),
	regular_pay DECIMAL(9,2) DEFAULT 0,
	overtime_pay DECIMAL(9,2) DEFAULT 0,
	premium_pay DECIMAL(9,2) DEFAULT 0,
	sick_pay DECIMAL(9,2) DEFAULT 0,
	vacation_pay DECIMAL(9,2) DEFAULT 0,
	holiday_pay DECIMAL(9,2) DEFAULT 0,
	piece_pay DECIMAL(9,2) DEFAULT 0,
	per_diem DECIMAL(9,2) DEFAULT 0,
	misc_pay DECIMAL(9,2) DEFAULT 0,
	gross_pay DECIMAL(9,2) DEFAULT 0,
	deducts DECIMAL(9,2) DEFAULT 0,
	additions DECIMAL(9,2) DEFAULT 0,
	netpay DECIMAL(9,2) DEFAULT 0,
	timecard_regular_hours DECIMAL(9,2) DEFAULT 0,
	timecard_overtime_hours DECIMAL(9,2) DEFAULT 0,
	timecard_premium_hours DECIMAL(9,2) DEFAULT 0,
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Payroll_Records'),' 

SELECT
	p.recnum as payroll_record_id,
	p.empnum as employee_id,
	CONCAT(e.fstnme, '' '', e.lstnme) as employee_full_name,
	CASE e.status
		WHEN 1 THEN ''Current'' 
		WHEN 2 THEN ''On Leave''
		WHEN 3 THEN ''Quit'' 
		WHEN 4 THEN ''Laid Off'' 
		WHEN 5 THEN ''Terminated'' 
		WHEN 6 THEN ''On Probation''
		WHEN 7 THEN ''Deceased'' 
		WHEN 8 THEN ''Retired''
	END as employee_status,
	p.chknum as check_number,
	p.chkdte as check_date,
	p.strprd as period_start,
	p.payprd as period_end,
	ISNULL(p.reghrs,0) as regular_hours,
	ISNULL(p.ovthrs,0) as overtime_hours,
	ISNULL(p.prmhrs,0) as premium_hours,
	ISNULL(p.sckhrs,0) as sick_hours,
	ISNULL(p.vachrs,0) as vacation_hours,
	ISNULL(p.holhrs,0) as holiday_hours,
	ISNULL(p.ttlhrs,0) as total_hours,
	ISNULL(p.cmpwge,0) as comp_wage,
	ISNULL(p.cmpgrs,0) as comp_gross,
	e.wrkcmp as comp_code,
	w.cdenme as comp_type,
	CASE p.paytyp
		WHEN 1 THEN ''Regular''
		WHEN 2 THEN ''Bonus''
		WHEN 3 THEN ''Hand Computed''
		WHEN 4 THEN ''Startup''
		WHEN 5 THEN ''Advance''
		WHEN 6 THEN ''Third Party''
		ELSE ''Other''
	END as payroll_type,
	CASE p.status
		WHEN 1 THEN ''Open''
		WHEN 2 THEN ''Computed''
		WHEN 3 THEN ''Posted''
		WHEN 5 THEN ''Void''
		ELSE ''Other''
	END as payroll_status,
	ISNULL(p.regpay,0) as regular_pay,
	ISNULL(p.ovtpay,0) as overtime_pay,
	ISNULL(p.prmpay,0) as premium_pay,
	ISNULL(p.sckpay,0) as sick_pay,
	ISNULL(p.vacpay,0) as vacation_pay,
	ISNULL(p.holpay,0) as holiday_pay,
	ISNULL(p.pcerte,0) as piece_pay,
	ISNULL(p.perdim,0) as per_diem,
	ISNULL(p.mscpay,0) as misc_pay,
	ISNULL(p.grspay,0) as gross_pay,
	ISNULL(p.dedttl,0) as deducts,
	ISNULL(p.addttl,0) as additions,
	ISNULL(p.netpay,0) as netpay,
	ISNULL(tc.regular_hours,0) as timecard_regular_hours,
	ISNULL(tc.overtime_hours,0) as timecard_overtime_hours,
	ISNULL(tc.premium_hours,0) as timecard_premium_hours,
	p.insdte as created_date,
	p.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.payrec p
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = p.empnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.wkrcmp w on w.recnum = e.wrkcmp
LEFT JOIN (
	SELECT
		recnum,
		SUM(CASE WHEN paytyp = 1 THEN hrswrk ELSE 0 END) as regular_hours,
		SUM(CASE WHEN paytyp = 2 THEN hrswrk ELSE 0 END) as overtime_hours,
		SUM(CASE WHEN paytyp = 3 THEN hrswrk ELSE 0 END) as premium_hours
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.tmcdln 
	WHERE jobnum IS NOT NULL
	GROUP BY recnum
) tc on tc.recnum = p.recnum
')

EXECUTE sp_executesql @SqlInsertCommand