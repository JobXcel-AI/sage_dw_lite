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
	period_start DATE,
	period_end DATE,
	regular_hours DECIMAL(9,4),
	overtime_hours DECIMAL(9,4),
	premium_hours DECIMAL(9,4),
	sick_hours DECIMAL(9,4),
	vacation_hours DECIMAL(9,4),
	holiday_hours DECIMAL(9,4),
	total_hours DECIMAL(9,4),
	comp_wage DECIMAL(9,2),
	comp_gross DECIMAL(9,2),
	comp_code BIGINT,
	comp_type NVARCHAR(30),
	payroll_type NVARCHAR(13),
	payroll_status NVARCHAR(6),
	regular_pay DECIMAL(9,2),
	overtime_pay DECIMAL(9,2),
	premium_pay DECIMAL(9,2),
	sick_pay DECIMAL(9,2),
	vacation_pay DECIMAL(9,2),
	holiday_pay DECIMAL(9,2),
	piece_pay DECIMAL(9,2),
	per_diem DECIMAL(9,2),
	misc_pay DECIMAL(9,2),
	gross_pay DECIMAL(9,2),
	deducts DECIMAL(9,2),
	additions DECIMAL(9,2),
	netpay DECIMAL(9,2)
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
	p.strprd as period_start,
	p.payprd as period_end,
	p.reghrs as regular_hours,
	p.ovthrs as overtime_hours,
	p.prmhrs as premium_hours,
	p.sckhrs as sick_hours,
	p.vachrs as vacation_hours,
	p.holhrs as holiday_hours,
	p.ttlhrs as total_hours,
	p.cmpwge as comp_wage,
	p.cmpgrs as comp_gross,
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
		WHEN 3 THEN ''Posted''
		ELSE ''Other''
	END as payroll_status,
	p.regpay as regular_pay,
	p.ovtpay as overtime_pay,
	p.prmpay as premium_pay,
	p.sckpay as sick_pay,
	p.vacpay as vacation_pay,
	p.holpay as holiday_pay,
	p.pcerte as piece_pay,
	p.perdim as per_diem,
	p.mscpay as misc_pay,
	p.grspay as gross_pay,
	p.dedttl as deducts,
	p.addttl as additions,
	p.netpay as netpay
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.payrec p
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = p.empnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.wkrcmp w on w.recnum = e.wrkcmp
')

EXECUTE sp_executesql @SqlInsertCommand