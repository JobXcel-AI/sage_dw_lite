--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

--Update Timecard Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Timecards;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Timecards;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Timecards
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.dptmnt d on d.recnum = t.dptmnt;
',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Timecards
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE CONCAT(t.payroll_record_id,''-'',t.timecard_line_number) NOT IN (SELECT CONCAT(payroll_record_id,''-'',timecard_line_number) FROM ',@Reporting_DB_Name,N'.dbo.Timecards)
UNION ALL 
SELECT * FROM #DeletedRecords
')
EXECUTE sp_executesql @SqlInsertQuery