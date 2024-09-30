--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Transaction_Lines'), '(
	ledger_transaction_description NVARCHAR(50),
	ledger_account_id BIGINT,
	ledger_account_name NVARCHAR(50),
	transaction_number NVARCHAR(20),
	ledger_transaction_id BIGINT,
	vendor_name NVARCHAR(50),
	job_variance DECIMAL(14,2),
	equipment_variance DECIMAL(14,2),
	work_in_progress_variance DECIMAL(14,2),
	debit_amount DECIMAL(14,2),
	credit_amount DECIMAL(14,2),
	check_amount DECIMAL(14,2),
	source_name NVARCHAR(20),
	job_cost DECIMAL(14,2),
	equip_cost DECIMAL(14,2),
	transaction_date DATE,
	purchase_order_number NVARCHAR(20),
	entered_date DATE,
	month_id INT,
	posting_year INT
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Transaction_Lines'),' 

SELECT 
	ltl.dscrpt ledger_transaction_description,
	ltl.lgract ledger_account_id,
	la.lngnme ledger_account_name,
	lt.trnnum transaction_number,
	lt.recnum ledger_transaction_id,
	v.vndnme as vendor_name,
	jobvar as job_variance,
	eqpvar as equipment_variance,
	wipvar as work_in_progress_variance,
	dbtamt as debit_amount,
	crdamt as credit_amount,
	lt.chkamt as check_amount,
	s.srcnme as source_name,
	jc.cstamt as job_cost,
	ec.cstamt as equip_cost,
	lt.trndte as transaction_date,
	lt.pchord as purchase_order_number,
	lt.entdte as entered_date,
	lt.actprd as month_id,
	lt.postyr as posting_year
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.source s on s.recnum = lt.srcnum
')

EXECUTE sp_executesql @SqlInsertCommand