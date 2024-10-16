--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

--Update Ledger_Transaction_Lines Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines
SELECT 
	ltl.dscrpt ledger_transaction_description,
	ltl.lgract ledger_account_id,
	la.lngnme ledger_account_name,
	lt.trnnum transaction_number,
	lt.recnum ledger_transaction_id,
	v.vndnme as vendor_name,
	ISNULL(jobvar,0) as job_variance,
	ISNULL(eqpvar,0) as equipment_variance,
	ISNULL(wipvar,0) as work_in_progress_variance,
	ISNULL(dbtamt,0) as debit_amount,
	ISNULL(crdamt,0) as credit_amount,
	ISNULL(lt.chkamt,0) as check_amount,
	s.srcnme as source_name,
	ISNULL(jc.cstamt,0) as job_cost,
	ISNULL(ec.cstamt,0) as equip_cost,
	lt.trndte as transaction_date,
	lt.pchord as purchase_order_number,
	lt.entdte as entered_date,
	lt.actprd as month_id,
	lt.postyr as posting_year,
	lt.insdte as created_date,
	lt.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgrtrn lt
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.lgtnln ltl on lt.recnum = ltl.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.lgract la on la.recnum = ltl.lgract
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actpay v on v.recnum = lt.vndnum
LEFT JOIN 
(
	SELECT
		vndnum,
		SUM(cstamt) as cstamt
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst 
	GROUP BY vndnum
) jc on jc.vndnum = v.recnum
LEFT JOIN 
(
	SELECT
		vndnum,
		SUM(cstamt) as cstamt
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.eqpcst 
	GROUP BY vndnum
) ec on ec.vndnum = v.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.source s on s.recnum = lt.srcnum;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.ledger_transaction_id NOT IN (SELECT ledger_transaction_id FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Transaction_Lines)
UNION ALL 
SELECT * FROM #DeletedRecords
')

EXECUTE sp_executesql @SqlInsertQuery