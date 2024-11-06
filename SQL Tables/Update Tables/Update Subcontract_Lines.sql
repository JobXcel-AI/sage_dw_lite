--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

--Update Subcontract_Lines Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines
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
	l.remaining_amount,
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
	recnum,
	cstcde,
	SUM(remain) as remaining_amount
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.sbcnln
	GROUP BY recnum, cstcde
) l on l.recnum = p.recnum

;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.subcontract_id NOT IN (SELECT subcontract_id FROM ',@Reporting_DB_Name,N'.dbo.Subcontract_Lines)
UNION ALL 
SELECT * FROM #DeletedRecords
')
EXECUTE sp_executesql @SqlInsertQuery