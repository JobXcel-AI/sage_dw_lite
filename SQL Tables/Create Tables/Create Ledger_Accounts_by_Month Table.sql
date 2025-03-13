--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = '[CLIENT_DB_NAME]';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Accounts_by_Month'), '(
	ledger_account_id BIGINT,
	ledger_account NVARCHAR(50),
	subsidiary_type NVARCHAR(12),
	summary_account NVARCHAR(50),
	cost_type NVARCHAR(30),
	current_balance DECIMAL(14,2),
	account_type NVARCHAR(22),
	debit_or_credit NVARCHAR(6),
	notes NVARCHAR(MAX),
	balance_budget_date DATE,
	balance DECIMAL(14,2),
	budget DECIMAL(14,2),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Accounts_by_Month'),' 

SELECT 
		a.recnum as ledger_account_id,
		a.lngnme as ledger_account,
		CASE a.subact
			WHEN 0 THEN ''None''
			WHEN 1 THEN ''Subaccounts''
			WHEN 2 THEN ''Departments''
			ELSE ''Other''
		END as subsidiary_type,
		pa.lngnme as summary_account,
		ct.typnme as cost_type,
		a.endbal as current_balance,
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
		q1.Account_Date as balance_budget_date,
		SUM(q1.balnce) as balance,
		SUM(q1.budget) as budget,
		a.insdte as created_date,
		a.upddte as last_updated_date,
		0 as is_deleted,
		null as deleted_date
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgract a 
	LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.lgract pa on pa.recnum = a.sumact
	LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.csttyp ct on ct.recnum = a.csttyp
	LEFT JOIN
	(
		SELECT 
			lgract, actprd,	balnce,	budget,
			DATEADD(day,-1,DATEFROMPARTS(CASE WHEN actprd=12 THEN postyr + 1 ELSE postyr END, CASE WHEN actprd=12 THEN 1 ELSE actprd + 1 END, 1)) as Account_Date
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgrbal 
		WHERE DATEPART(YEAR,DATEADD(YEAR,-4,GETDATE())) <= postyr
	) q1 on q1.lgract = a.recnum
	GROUP BY a.recnum, a.lngnme, a.subact, pa.lngnme, ct.typnme, a.endbal, a.acttyp, a.dbtcrd, a.ntetxt, q1.Account_Date, a.insdte, a.upddte ')

EXECUTE sp_executesql @SqlInsertCommand