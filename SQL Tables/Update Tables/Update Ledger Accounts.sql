--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);
DECLARE @SqlInsertQuery1 NVARCHAR(MAX);
DECLARE @SqlInsertQuery2 NVARCHAR(MAX);

--Update Ledger_Accounts Table
SET @SqlInsertQuery1 = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts
SELECT 
	a.recnum as ledger_account_id,
	a.lngnme as ledger_account,
	CASE a.subact
		WHEN 0 THEN ''None''
		WHEN 1 THEN ''Subaccounts''
		WHEN 2 THEN ''Departments''
		ELSE ''Other''
	END as subsidary_type,
	pa.lngnme as summary_account,
	ct.typnme as cost_type,
	a.endbal as ending_balance,
	CASE a.acttyp 
		WHEN 1 THEN ''Cash Accounts''
		WHEN 2 THEN ''Current Assets''
		WHEN 3 THEN ''WIP Assets''
		WHEN 4 THEN ''Other Assets''
		WHEN 5 THEN ''Fixed Assets''
		WHEN 6 THEN ''Depreciation''
		WHEN 7 THEN ''Current Liabilities''
		WHEN 8 THEN ''Long Term Liabilities''
		WHEN 9 THEN ''Equity''
		WHEN 11 THEN ''Operating Income''
		WHEN 12 THEN ''Other Income''
		WHEN 13 THEN ''Direct Expense''
		WHEN 14 THEN ''Equip/Shop Expense''
		WHEN 15 THEN ''Overhead Expense''
		WHEN 16 THEN ''Administrative Expense''
		WHEN 17 THEN ''After Tax Inc/Expense''
		ELSE ''Other''
	END as account_type,
	CASE a.dbtcrd
		WHEN 1 THEN ''Debit''
		WHEN 2 THEN ''Credit''
		ELSE ''Other''
	END as debit_or_credit,
	a.ntetxt as notes,
	ab.CY_PD1_Balance,
	ab.CY_PD2_Balance,
	ab.CY_PD3_Balance,
	ab.CY_PD4_Balance,
	ab.CY_PD5_Balance,
	ab.CY_PD6_Balance,
	ab.CY_PD7_Balance,
	ab.CY_PD8_Balance,
	ab.CY_PD9_Balance,
	ab.CY_PD10_Balance,
	ab.CY_PD11_Balance,
	ab.CY_PD12_Balance,
	ab.PY_PD1_Balance,
	ab.PY_PD2_Balance,
	ab.PY_PD3_Balance,
	ab.PY_PD4_Balance,
	ab.PY_PD5_Balance,
	ab.PY_PD6_Balance,
	ab.PY_PD7_Balance,
	ab.PY_PD8_Balance,
	ab.PY_PD9_Balance,
	ab.PY_PD10_Balance,
	ab.PY_PD11_Balance,
	ab.PY_PD12_Balance,
	ab.CY_PD1_Budget,
	ab.CY_PD2_Budget,
	ab.CY_PD3_Budget,
	ab.CY_PD4_Budget,
	ab.CY_PD5_Budget,
	ab.CY_PD6_Budget,
	ab.CY_PD7_Budget,
	ab.CY_PD8_Budget,
	ab.CY_PD9_Budget,
	ab.CY_PD10_Budget,
	ab.CY_PD11_Budget,
	ab.CY_PD12_Budget,
	ab.PY_PD1_Budget,
	ab.PY_PD2_Budget,
	ab.PY_PD3_Budget,
	ab.PY_PD4_Budget,
	ab.PY_PD5_Budget,
	ab.PY_PD6_Budget,
	ab.PY_PD7_Budget,
	ab.PY_PD8_Budget,
	ab.PY_PD9_Budget,
	ab.PY_PD10_Budget,
	ab.PY_PD11_Budget,
	ab.PY_PD12_Budget,
	a.insdte as created_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgract a 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.lgract pa on pa.recnum = a.sumact
LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.csttyp ct on ct.recnum = a.csttyp
')
SET @SqlInsertQuery2 = CONCAT(N'
LEFT JOIN (
	SELECT 
		lgract,
		SUM(ISNULL(CY_PD1_Balance,0)) as CY_PD1_Balance,
		SUM(ISNULL(CY_PD2_Balance,0)) as CY_PD2_Balance,
		SUM(ISNULL(CY_PD3_Balance,0)) as CY_PD3_Balance,
		SUM(ISNULL(CY_PD4_Balance,0)) as CY_PD4_Balance,
		SUM(ISNULL(CY_PD5_Balance,0)) as CY_PD5_Balance,
		SUM(ISNULL(CY_PD6_Balance,0)) as CY_PD6_Balance,
		SUM(ISNULL(CY_PD7_Balance,0)) as CY_PD7_Balance,
		SUM(ISNULL(CY_PD8_Balance,0)) as CY_PD8_Balance,
		SUM(ISNULL(CY_PD9_Balance,0)) as CY_PD9_Balance,
		SUM(ISNULL(CY_PD10_Balance,0)) as CY_PD10_Balance,
		SUM(ISNULL(CY_PD11_Balance,0)) as CY_PD11_Balance,
		SUM(ISNULL(CY_PD12_Balance,0)) as CY_PD12_Balance,
		SUM(ISNULL(PY_PD1_Balance,0)) as PY_PD1_Balance,
		SUM(ISNULL(PY_PD2_Balance,0)) as PY_PD2_Balance,
		SUM(ISNULL(PY_PD3_Balance,0)) as PY_PD3_Balance,
		SUM(ISNULL(PY_PD4_Balance,0)) as PY_PD4_Balance,
		SUM(ISNULL(PY_PD5_Balance,0)) as PY_PD5_Balance,
		SUM(ISNULL(PY_PD6_Balance,0)) as PY_PD6_Balance,
		SUM(ISNULL(PY_PD7_Balance,0)) as PY_PD7_Balance,
		SUM(ISNULL(PY_PD8_Balance,0)) as PY_PD8_Balance,
		SUM(ISNULL(PY_PD9_Balance,0)) as PY_PD9_Balance,
		SUM(ISNULL(PY_PD10_Balance,0)) as PY_PD10_Balance,
		SUM(ISNULL(PY_PD11_Balance,0)) as PY_PD11_Balance,
		SUM(ISNULL(PY_PD12_Balance,0)) as PY_PD12_Balance,
		SUM(ISNULL(CY_PD1_Budget,0)) as CY_PD1_Budget,
		SUM(ISNULL(CY_PD2_Budget,0)) as CY_PD2_Budget,
		SUM(ISNULL(CY_PD3_Budget,0)) as CY_PD3_Budget,
		SUM(ISNULL(CY_PD4_Budget,0)) as CY_PD4_Budget,
		SUM(ISNULL(CY_PD5_Budget,0)) as CY_PD5_Budget,
		SUM(ISNULL(CY_PD6_Budget,0)) as CY_PD6_Budget,
		SUM(ISNULL(CY_PD7_Budget,0)) as CY_PD7_Budget,
		SUM(ISNULL(CY_PD8_Budget,0)) as CY_PD8_Budget,
		SUM(ISNULL(CY_PD9_Budget,0)) as CY_PD9_Budget,
		SUM(ISNULL(CY_PD10_Budget,0)) as CY_PD10_Budget,
		SUM(ISNULL(CY_PD11_Budget,0)) as CY_PD11_Budget,
		SUM(ISNULL(CY_PD12_Budget,0)) as CY_PD12_Budget,
		SUM(ISNULL(PY_PD1_Budget,0)) as PY_PD1_Budget,
		SUM(ISNULL(PY_PD2_Budget,0)) as PY_PD2_Budget,
		SUM(ISNULL(PY_PD3_Budget,0)) as PY_PD3_Budget,
		SUM(ISNULL(PY_PD4_Budget,0)) as PY_PD4_Budget,
		SUM(ISNULL(PY_PD5_Budget,0)) as PY_PD5_Budget,
		SUM(ISNULL(PY_PD6_Budget,0)) as PY_PD6_Budget,
		SUM(ISNULL(PY_PD7_Budget,0)) as PY_PD7_Budget,
		SUM(ISNULL(PY_PD8_Budget,0)) as PY_PD8_Budget,
		SUM(ISNULL(PY_PD9_Budget,0)) as PY_PD9_Budget,
		SUM(ISNULL(PY_PD10_Budget,0)) as PY_PD10_Budget,
		SUM(ISNULL(PY_PD11_Budget,0)) as PY_PD11_Budget,
		SUM(ISNULL(PY_PD12_Budget,0)) as PY_PD12_Budget
	FROM 
	(
		SELECT 
			lgract,
			SUM(CASE WHEN current_year = 1 AND actprd = 1 THEN balnce ELSE 0 END) as CY_PD1_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 2 THEN balnce ELSE 0 END) as CY_PD2_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 3 THEN balnce ELSE 0 END) as CY_PD3_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 4 THEN balnce ELSE 0 END) as CY_PD4_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 5 THEN balnce ELSE 0 END) as CY_PD5_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 6 THEN balnce ELSE 0 END) as CY_PD6_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 7 THEN balnce ELSE 0 END) as CY_PD7_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 8 THEN balnce ELSE 0 END) as CY_PD8_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 9 THEN balnce ELSE 0 END) as CY_PD9_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 10 THEN balnce ELSE 0 END) as CY_PD10_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 11 THEN balnce ELSE 0 END) as CY_PD11_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 12 THEN balnce ELSE 0 END) as CY_PD12_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 1 THEN balnce ELSE 0 END) as PY_PD1_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 2 THEN balnce ELSE 0 END) as PY_PD2_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 3 THEN balnce ELSE 0 END) as PY_PD3_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 4 THEN balnce ELSE 0 END) as PY_PD4_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 5 THEN balnce ELSE 0 END) as PY_PD5_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 6 THEN balnce ELSE 0 END) as PY_PD6_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 7 THEN balnce ELSE 0 END) as PY_PD7_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 8 THEN balnce ELSE 0 END) as PY_PD8_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 9 THEN balnce ELSE 0 END) as PY_PD9_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 10 THEN balnce ELSE 0 END) as PY_PD10_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 11 THEN balnce ELSE 0 END) as PY_PD11_Balance,
			SUM(CASE WHEN current_year = 0 AND actprd = 12 THEN balnce ELSE 0 END) as PY_PD12_Balance,
			SUM(CASE WHEN current_year = 1 AND actprd = 1 THEN budget ELSE 0 END) as CY_PD1_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 2 THEN budget ELSE 0 END) as CY_PD2_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 3 THEN budget ELSE 0 END) as CY_PD3_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 4 THEN budget ELSE 0 END) as CY_PD4_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 5 THEN budget ELSE 0 END) as CY_PD5_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 6 THEN budget ELSE 0 END) as CY_PD6_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 7 THEN budget ELSE 0 END) as CY_PD7_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 8 THEN budget ELSE 0 END) as CY_PD8_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 9 THEN budget ELSE 0 END) as CY_PD9_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 10 THEN budget ELSE 0 END) as CY_PD10_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 11 THEN budget ELSE 0 END) as CY_PD11_Budget,
			SUM(CASE WHEN current_year = 1 AND actprd = 12 THEN budget ELSE 0 END) as CY_PD12_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 1 THEN budget ELSE 0 END) as PY_PD1_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 2 THEN budget ELSE 0 END) as PY_PD2_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 3 THEN budget ELSE 0 END) as PY_PD3_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 4 THEN budget ELSE 0 END) as PY_PD4_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 5 THEN budget ELSE 0 END) as PY_PD5_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 6 THEN budget ELSE 0 END) as PY_PD6_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 7 THEN budget ELSE 0 END) as PY_PD7_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 8 THEN budget ELSE 0 END) as PY_PD8_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 9 THEN budget ELSE 0 END) as PY_PD9_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 10 THEN budget ELSE 0 END) as PY_PD10_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 11 THEN budget ELSE 0 END) as PY_PD11_Budget,
			SUM(CASE WHEN current_year = 0 AND actprd = 12 THEN budget ELSE 0 END) as PY_PD12_Budget
		FROM
		(
			SELECT 
				lgract, actprd,	balnce,	budget,
				CASE WHEN postyr = DATEPART(YEAR,GETDATE()) THEN 1 ELSE 0 END as current_year
			FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgrbal 
			WHERE DATEPART(YEAR,DATEADD(YEAR,-1,GETDATE())) <= postyr
		) q1
		GROUP BY lgract, current_year, actprd
	) q2
	GROUP BY lgract
) ab on ab.lgract = a.recnum;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.ledger_account_id NOT IN (SELECT ledger_account_id FROM ',@Reporting_DB_Name,N'.dbo.Ledger_Accounts)
UNION ALL 
SELECT * FROM #DeletedRecords
')
SET @SqlInsertQuery = @SqlInsertQuery1 + @SqlInsertQuery2
EXECUTE sp_executesql @SqlInsertQuery