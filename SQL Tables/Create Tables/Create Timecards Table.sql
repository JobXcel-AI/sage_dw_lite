--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Timecards'), '(
	payroll_record_id BIGINT,
	timecard_line_number BIGINT,
	employee_id BIGINT,
	employee_full_name NVARCHAR(100),
	employee_status NVARCHAR(12),
	check_number NVARCHAR(20),
	check_date DATE,
	period_start DATE,
	period_end DATE,
	date_worked DATE,
	day_worked NVARCHAR(10),
	description NVARCHAR(50),
	service_order_number NVARCHAR(20),
	service_order_invoice_number NVARCHAR(20),
	client_id BIGINT,
	client_name NVARCHAR(100),
	job_number BIGINT,
	job_name NVARCHAR(100),
	job_status NVARCHAR(8),
	job_status_number INT,
	job_type NVARCHAR(50),
	equipment_number_repaired BIGINT,
	equipment_name_repaired NVARCHAR(100),
	job_phase_number INT,
	job_phase_name NVARCHAR(50),
	cost_code_number DECIMAL(11,3),
	cost_code_name NVARCHAR(50),
	pay_type_number INT,
	pay_type_name NVARCHAR(9),
	pay_group_number INT,
	pay_group_name NVARCHAR(50),
	pay_rate DECIMAL(9,4),
	hours_worked DECIMAL(4,2),
	comp_code BIGINT,
	workers_compensation_name NVARCHAR(50),
	department_id BIGINT,
	department_name NVARCHAR(50),
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Timecards'),' 

SELECT
	t.recnum as payroll_record_id,
	t.linnum as timecard_line_number,
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
	t.dtewrk as date_worked,
	t.daywrk as day_worked,
	t.dscrpt as description,
	t.wrkord as service_order_number,
	s.invnum as service_order_invoice_number,
	s.clnnum as client_id,
	c.clnnme as client_name,
	t.jobnum as job_number,
	j.jobnme as job_name,
	CASE j.status
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status,
	j.status as job_status_number,
	jt.typnme as job_type,
	t.eqpnum as equipment_number_repaired,
	eq.eqpnme as equipment_name_repaired,
	t.phsnum as job_phase_number,
	jp.phsnme as job_phase_name,
	t.cstcde as cost_code_number,
	cc.cdenme as cost_code_name,
	t.paytyp as pay_type_number,
	CASE t.paytyp 
		WHEN 1 THEN ''Regular''
		WHEN 2 THEN ''Overtime''
		WHEN 3 THEN ''Premium''
		WHEN 4 THEN ''Sick''
		WHEN 5 THEN ''Vacation''
		WHEN 6 THEN ''Holiday''
		WHEN 7 THEN ''Piece''
		WHEN 8 THEN ''Per Diem''
		WHEN 9 THEN ''Misc. Pay''
		ELSE ''Other''
	END as pay_type_name,
	t.paygrp as pay_group_number,
	pg.grpnme as pay_group_name,
	t.payrte as pay_rate,
	t.hrswrk as hours_worked,
	t.cmpcde as comp_code,	
	w.cdenme as workers_compensation_name,
	t.dptmnt as department_id,
	d.dptnme as department_name,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.tmcdln t
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.payrec p on p.recnum = t.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = p.empnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.srvinv s on s.ordnum = t.wrkord
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.reccln c on c.recnum = s.clnnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec j on j.recnum = t.jobnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.jobtyp jt on jt.recnum = j.jobtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.eqpmnt eq on eq.recnum = t.eqpnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.jobphs jp on jp.phsnum = t.phsnum AND j.recnum = jp.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cc on cc.recnum = t.cstcde
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.paygrp pg on pg.recnum = t.paygrp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.wkrcmp w on w.recnum = t.cmpcde
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.dptmnt d on d.recnum = t.dptmnt
')

EXECUTE sp_executesql @SqlInsertCommand