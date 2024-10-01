--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('AR_Invoices'), '(
	job_number BIGINT,
	job_name NVARCHAR(75),
	job_phone_number NVARCHAR(14),
	job_notes NVARCHAR(MAX),
	job_address1 NVARCHAR(50),
	job_address2 NVARCHAR(50),
	job_city NVARCHAR(50),
	job_state NVARCHAR(2),
	job_zip_code NVARCHAR(10),
	job_tax_district NVARCHAR(50),
	job_type NVARCHAR(50),
	job_status NVARCHAR(10),
	ar_invoice_id BIGINT,
	ar_invoice_date DATE,
	ar_invoice_description NVARCHAR(50),
	ar_invoice_number NVARCHAR(20),
	ar_invoice_status NVARCHAR(8),
	ar_invoice_tax_district NVARCHAR(50),
	tax_entity1 NVARCHAR(50),
	tax_entity1_rate DECIMAL(8,4),
	tax_entity2 NVARCHAR(50),
	tax_entity2_rate DECIMAL(8,4),
	ar_invoice_due_date DATE,
	ar_invoice_total DECIMAL(12,2),
	ar_invoice_sales_tax DECIMAL(12,2),
	ar_invoice_amount_paid DECIMAL(12,2),
	ar_invoice_type NVARCHAR(8),
	client_name NVARCHAR(75),
	job_supervisor NVARCHAR(50),
	job_salesperson NVARCHAR(50)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('AR_Invoices'),' 

SELECT 
	a.recnum as job_number,
	a.jobnme as job_name,
	a.phnnum as job_phone_number,
	a.ntetxt as job_notes,
	a.addrs1 as job_address1,
	a.addrs2 as job_address2,
	a.ctynme as job_city,
	a.state_ as job_state,
	a.zipcde as job_zip_code,
	j_t.dstnme as job_tax_district,
	jt.typnme as job_type,
	CASE a.status 
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status,
	acrinv.recnum as ar_invoice_id,
	acrinv.invdte as ar_invoice_date,
	acrinv.dscrpt as ar_invoice_description,
	acrinv.invnum as ar_invoice_number,
	CASE acrinv.status 
		WHEN 1 THEN ''Open''
		WHEN 2 THEN ''Review''
		WHEN 3 THEN ''Dispute''
		WHEN 4 THEN ''Paid''
		WHEN 5 THEN ''Void''
		ELSE ''Other''
	END as ar_invoice_status,
	tax.dstnme as ar_invoice_tax_district,
	te.entnme as tax_entity1,
	te.taxrt1 as tax_entity1_rate,
	te2.entnme as tax_entity2,
	te2.taxrt1 as tax_entity2_rate,
	acrinv.duedte as ar_invoice_due_date,
	acrinv.invttl as ar_invoice_total,
	acrinv.slstax as ar_invoice_sales_tax,
	acrinv.amtpad as ar_invoice_amount_paid,
	CASE acrinv.invtyp 
		WHEN 1 THEN ''Contract''
		WHEN 2 THEN ''Memo''
		ELSE ''Other''
	END as ar_invoice_type,
	r.clnnme as client_name,
	CONCAT(es.fstnme, '' '', es.lstnme) as job_supervisor,
	CONCAT(e.fstnme, '' '', e.lstnme) as job_salesperson
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv acrinv on acrinv.jobnum = a.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.taxdst tax on tax.recnum = acrinv.taxdst
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.taxdst j_t on j_t.recnum = a.slstax
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.jobtyp jt on jt.recnum = a.jobtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.reccln r on r.recnum = a.clnnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.taxent te on te.recnum = tax.entty1
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.taxent te2 on te2.recnum = tax.entty2
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ es on es.recnum = a.sprvsr 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = a.slsemp')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Orders'), '(
	change_order_id BIGINT,
	change_order_number NVARCHAR(20),
	change_order_date DATE,
	job_number BIGINT,
	job_name NVARCHAR(75),
	job_phase_number BIGINT,
	status NVARCHAR(8),
	change_order_description NVARCHAR(50),
	change_type NVARCHAR(50),
	reason NVARCHAR(50),
	submitted_date DATE,
	approved_date DATE,
	invoice_date DATE,
	purchase_order_number NVARCHAR(30),
	requested_amount DECIMAL(12,2),
	approved_amount DECIMAL(12,2),
	overhead_amount DECIMAL(12,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Orders'),' 

SELECT 
	c.recnum as change_order_id,
	chgnum as change_order_number,
	chgdte as change_order_date,
	jobnum as job_number,
	a.jobnme as job_name,
	c.phsnum as job_phase_number,
	CASE c.status
		WHEN 1 THEN ''Approved''
		WHEN 2 THEN ''Open''
		WHEN 3 THEN ''Review''
		WHEN 4 THEN ''Disputed''
		WHEN 5 THEN ''Void''
		WHen 6 THEN ''Rejected''
	END as status,
	dscrpt as change_order_description,
	ct.typnme as change_type,
	reason,
	subdte as submitted_date,
	aprdte as approved_date,
	invdte as invoice_date,
	c.pchord as purchase_order_number,
	reqamt as requested_amount,
	appamt as approved_amount,
	ovhamt as overhead_amount
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg c
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a on a.recnum = c.jobnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.chgtyp ct on ct.recnum = c.chgtyp')

EXECUTE sp_executesql @SqlInsertCommand

SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Employees'), '(
	employee_id BIGINT,
	last_name NVARCHAR(50),
	first_name NVARCHAR(50),
	full_name NVARCHAR(100),
	employee_status NVARCHAR(12),
	address1 NVARCHAR(50),
	address2 NVARCHAR(50),
	city NVARCHAR(50),
	state NVARCHAR(2),
	zip_code NVARCHAR(10),
	phone_number NVARCHAR(14),
	email NVARCHAR(75),
	position NVARCHAR(50),
	department NVARCHAR(50),
	hire_date DATE,
	date_inactive DATE
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Employees'),' 

SELECT 
	e.recnum as employee_id,
	lstnme as last_name,
	fstnme as first_name,
	CONCAT(fstnme, '' '', lstnme) as full_name,
	CASE 
		WHEN status = 1 THEN ''Current'' 
		WHEN status = 2 THEN ''On Leave''
		WHEN status = 3 THEN ''Quit'' 
		WHEN status = 4 THEN ''Laid Off'' 
		WHEN status = 5 THEN ''Terminated'' 
		WHEN status = 6 THEN ''On Probation''
		WHEN status = 7 THEN ''Deceased'' 
		WHEN status = 8 THEN ''Retired''
	END as employee_status,
	addrs1 as address1,
	addrs2 as address2,
	ctynme as city,
	state_ as state,
	zipcde as zip_code,
	phnnum as phone_number,
	e_mail as email,
	p.pstnme as position,
	d.dptnme as department,
	dtehre as hire_date,
	dteina as date_inactive 
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.employ e
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.paypst p ON p.recnum = e.paypst
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.dptmnt d ON d.recnum = p.dptmnt')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Inventory'), '(
	part_number BIGINT,
	location NVARCHAR(50),
	default_location NVARCHAR(50),
	quantity_on_hand DECIMAL(12,4),
	quantity_available DECIMAL(12,4),
	description NVARCHAR(75),
	unit NVARCHAR(10),
	bin_number NVARCHAR(10),
	alpha_part_number NVARCHAR(50),
	msds_number NVARCHAR(30),
	manufacturer NVARCHAR(50),
	manufacturer_part_number NVARCHAR(30),
	cost_code NVARCHAR(50),
	cost_type NVARCHAR(30),
	last_updated DATE,
	part_notes NVARCHAR(MAX)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Inventory'),' 

SELECT
	q.prtnum as part_number,
	l.locnme as location,
	dl.locnme as default_location,
	q.qtyohn as quantity_on_hand,
	q.qtyavl as quantity_available,
	p.prtnme as description,
	p.prtunt as unit,
	p.binnum as bin_number,
	p.alpnum as alpha_part_number,
	p.msdsnm as msds_number,
	p.mannme as manufacturer,
	p.mannum as manufacturer_part_number,
	cd.cdenme as cost_code,
	ct.typnme as cost_type,
	p.lstupd as last_updated,
	p.ntetxt as part_notes
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.invqty q
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.invloc l on l.recnum = q.locnum 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.tkfprt p on p.recnum = q.prtnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.invloc dl on dl.recnum = p.dftloc 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cd on cd.recnum = p.cstcde
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = p.csttyp
')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost'), '(
	job_id BIGINT,
	job_number BIGINT,
	job_name NVARCHAR(75),
	job_status NVARCHAR(8),
	job_cost_code NVARCHAR(50),
	work_order_number NVARCHAR(20),
	transaction_number NVARCHAR(20),
	job_cost_description NVARCHAR(50),
	job_cost_source NVARCHAR(20),
	vendor_id BIGINT,
	vendor NVARCHAR(75),
	cost_type NVARCHAR(30),
	cost_in_hours DECIMAL(7,2),
	cost_amount DECIMAL(12,2),
	material_cost DECIMAL(12,2),
	labor_cost DECIMAL(12,2),
	equipment_cost DECIMAL(12,2),
	other_cost DECIMAL(12,2),
	billing_quantity DECIMAL(7,2),
	billing_amount DECIMAL(12,2),
	overhead_amount DECIMAL(12,2),
	job_cost_status NVARCHAR(4)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost'),' 

SELECT 
	j.recnum as job_id,
	j.jobnum as job_number,
	ar.jobnme as job_name,
	CASE ar.status 
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
	END as job_status,
	cd.cdenme as job_cost_code,
	j.wrkord as work_order_number,
	trnnum as transaction_number,
	j.dscrpt as job_cost_description,
	s.srcnme as job_cost_source,
	v.recnum as vendor_id,
	v.vndnme as vendor,
	ct.typnme as cost_type,
	csthrs as cost_in_hours,
	cstamt as cost_amount,
	CASE 
		WHEN ct.typnme = ''Material'' THEN cstamt 
		ELSE 0 
	END as material_cost,
	CASE 
		WHEN ct.typnme = ''Labor'' THEN cstamt 
		ELSE 0 
	END as labor_cost,
	CASE 
		WHEN ct.typnme = ''Equipment'' THEN cstamt 
		ELSE 0 
	END as equipment_cost,
	CASE 
		WHEN ct.typnme = ''Other'' THEN cstamt 
		ELSE 0 
	END as other_cost,
	j.blgqty as billing_quantity,
	j.blgamt as billing_amount,
	j.ovhamt as overhead_amount,
	CASE j.status
		WHEN 1 THEN ''Open''
		WHEN 2 THEN ''Void''
	END as job_cost_status
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst j
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = j.csttyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.source s on s.recnum = j.srcnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cd on cd.recnum = j.cstcde
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actpay v on v.recnum = j.vndnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec ar on ar.recnum = j.jobnum')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Accounts'), '(
	ledger_account_id BIGINT,
	ledger_account NVARCHAR(50),
	subsidary_type NVARCHAR(12),
	summary_account NVARCHAR(50),
	cost_type NVARCHAR(30),
	ending_balance DECIMAL(14,2),
	account_type NVARCHAR(22),
	debit_or_credit NVARCHAR(6),
	notes NVARCHAR(MAX),
	CY_PD1_Balance DECIMAL(14,2),
	CY_PD2_Balance DECIMAL(14,2),
	CY_PD3_Balance DECIMAL(14,2),
	CY_PD4_Balance DECIMAL(14,2),
	CY_PD5_Balance DECIMAL(14,2),
	CY_PD6_Balance DECIMAL(14,2),
	CY_PD7_Balance DECIMAL(14,2),
	CY_PD8_Balance DECIMAL(14,2),
	CY_PD9_Balance DECIMAL(14,2),
	CY_PD10_Balance DECIMAL(14,2),
	CY_PD11_Balance DECIMAL(14,2),
	CY_PD12_Balance DECIMAL(14,2),
	PY_PD1_Balance DECIMAL(14,2),
	PY_PD2_Balance DECIMAL(14,2),
	PY_PD3_Balance DECIMAL(14,2),
	PY_PD4_Balance DECIMAL(14,2),
	PY_PD5_Balance DECIMAL(14,2),
	PY_PD6_Balance DECIMAL(14,2),
	PY_PD7_Balance DECIMAL(14,2),
	PY_PD8_Balance DECIMAL(14,2),
	PY_PD9_Balance DECIMAL(14,2),
	PY_PD10_Balance DECIMAL(14,2),
	PY_PD11_Balance DECIMAL(14,2),
	PY_PD12_Balance DECIMAL(14,2),
	CY_PD1_Budget DECIMAL(14,2),
	CY_PD2_Budget DECIMAL(14,2),
	CY_PD3_Budget DECIMAL(14,2),
	CY_PD4_Budget DECIMAL(14,2),
	CY_PD5_Budget DECIMAL(14,2),
	CY_PD6_Budget DECIMAL(14,2),
	CY_PD7_Budget DECIMAL(14,2),
	CY_PD8_Budget DECIMAL(14,2),
	CY_PD9_Budget DECIMAL(14,2),
	CY_PD10_Budget DECIMAL(14,2),
	CY_PD11_Budget DECIMAL(14,2),
	CY_PD12_Budget DECIMAL(14,2),
	PY_PD1_Budget DECIMAL(14,2),
	PY_PD2_Budget DECIMAL(14,2),
	PY_PD3_Budget DECIMAL(14,2),
	PY_PD4_Budget DECIMAL(14,2),
	PY_PD5_Budget DECIMAL(14,2),
	PY_PD6_Budget DECIMAL(14,2),
	PY_PD7_Budget DECIMAL(14,2),
	PY_PD8_Budget DECIMAL(14,2),
	PY_PD9_Budget DECIMAL(14,2),
	PY_PD10_Budget DECIMAL(14,2),
	PY_PD11_Budget DECIMAL(14,2),
	PY_PD12_Budget DECIMAL(14,2)

)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Accounts'),' 

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
	ab.PY_PD12_Budget
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgract a 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.lgract pa on pa.recnum = a.sumact
LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.csttyp ct on ct.recnum = a.csttyp
LEFT JOIN (
	SELECT 
		lgract,
		SUM(CY_PD1_Balance) as CY_PD1_Balance,
		SUM(CY_PD2_Balance) as CY_PD2_Balance,
		SUM(CY_PD3_Balance) as CY_PD3_Balance,
		SUM(CY_PD4_Balance) as CY_PD4_Balance,
		SUM(CY_PD5_Balance) as CY_PD5_Balance,
		SUM(CY_PD6_Balance) as CY_PD6_Balance,
		SUM(CY_PD7_Balance) as CY_PD7_Balance,
		SUM(CY_PD8_Balance) as CY_PD8_Balance,
		SUM(CY_PD9_Balance) as CY_PD9_Balance,
		SUM(CY_PD10_Balance) as CY_PD10_Balance,
		SUM(CY_PD11_Balance) as CY_PD11_Balance,
		SUM(CY_PD12_Balance) as CY_PD12_Balance,
		SUM(PY_PD1_Balance) as PY_PD1_Balance,
		SUM(PY_PD2_Balance) as PY_PD2_Balance,
		SUM(PY_PD3_Balance) as PY_PD3_Balance,
		SUM(PY_PD4_Balance) as PY_PD4_Balance,
		SUM(PY_PD5_Balance) as PY_PD5_Balance,
		SUM(PY_PD6_Balance) as PY_PD6_Balance,
		SUM(PY_PD7_Balance) as PY_PD7_Balance,
		SUM(PY_PD8_Balance) as PY_PD8_Balance,
		SUM(PY_PD9_Balance) as PY_PD9_Balance,
		SUM(PY_PD10_Balance) as PY_PD10_Balance,
		SUM(PY_PD11_Balance) as PY_PD11_Balance,
		SUM(PY_PD12_Balance) as PY_PD12_Balance,
		SUM(CY_PD1_Budget) as CY_PD1_Budget,
		SUM(CY_PD2_Budget) as CY_PD2_Budget,
		SUM(CY_PD3_Budget) as CY_PD3_Budget,
		SUM(CY_PD4_Budget) as CY_PD4_Budget,
		SUM(CY_PD5_Budget) as CY_PD5_Budget,
		SUM(CY_PD6_Budget) as CY_PD6_Budget,
		SUM(CY_PD7_Budget) as CY_PD7_Budget,
		SUM(CY_PD8_Budget) as CY_PD8_Budget,
		SUM(CY_PD9_Budget) as CY_PD9_Budget,
		SUM(CY_PD10_Budget) as CY_PD10_Budget,
		SUM(CY_PD11_Budget) as CY_PD11_Budget,
		SUM(CY_PD12_Budget) as CY_PD12_Budget,
		SUM(PY_PD1_Budget) as PY_PD1_Budget,
		SUM(PY_PD2_Budget) as PY_PD2_Budget,
		SUM(PY_PD3_Budget) as PY_PD3_Budget,
		SUM(PY_PD4_Budget) as PY_PD4_Budget,
		SUM(PY_PD5_Budget) as PY_PD5_Budget,
		SUM(PY_PD6_Budget) as PY_PD6_Budget,
		SUM(PY_PD7_Budget) as PY_PD7_Budget,
		SUM(PY_PD8_Budget) as PY_PD8_Budget,
		SUM(PY_PD9_Budget) as PY_PD9_Budget,
		SUM(PY_PD10_Budget) as PY_PD10_Budget,
		SUM(PY_PD11_Budget) as PY_PD11_Budget,
		SUM(PY_PD12_Budget) as PY_PD12_Budget
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
			WHERE DATEPART(YEAR,DATEADD(YEAR,-1,GETDATE())) >= postyr
		) q1
		GROUP BY lgract, current_year, actprd
	) q2
	GROUP BY lgract
) ab on ab.lgract = a.recnum ')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Purchase_Orders'), '(
	purchase_order_id BIGINT,
	purchase_order_number NVARCHAR(20),
	purchase_order_description NVARCHAR(50),
	purchase_order_date DATE,
	delivery_date DATE,
	purchase_order_type NVARCHAR(50),
	purchase_order_status NVARCHAR(7),
	equipment BIGINT,
	received DECIMAL(12,2),
	current_value DECIMAL(12,2),
	canceled DECIMAL(12,2),
	subtotal DECIMAL(12,2),
	sales_tax DECIMAL(12,2),
	total DECIMAL(12,2),
	balance DECIMAL(12,2),
	job_number BIGINT,
	hot_list BIT,
	vendor_id BIGINT,
	vendor_name NVARCHAR(75),
	vendor_account_number NVARCHAR(30),
	vendor_type NVARCHAR(50),
	vendor_email NVARCHAR(75),
	vendor_phone_number NVARCHAR(14)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Purchase_Orders'),' 

SELECT
	p.recnum as purchase_order_id,
	ordnum as purchase_order_number,
	p.dscrpt as purchase_order_description,
	orddte as purchase_order_date,
	deldte as delivery_date,
	pt.typnme as purchase_order_type,
	CASE
		WHEN p.status = 1 THEN ''Open''
		WHEN p.status = 2 THEN ''Review''
		WHEN p.status = 3 THEN ''Dispute''
		WHEN p.status = 4 THEN ''Closed''
		WHEN p.status = 5 THEN ''Void''
		WHEN p.status = 6 THEN ''Master''
	END as purchase_order_status,
	e.eqpnme as equipment,
	p.rcvdte as received,
	p.currnt as current_value,
	p.cancel as canceled,
	p.subttl as subtotal,
	p.slstax as sales_tax,
	p.pchttl as total,
	p.pchbal as balance,
	p.jobnum as job_number,
	p.hotlst as hot_list,
	a.recnum as vendor_id,
	a.vndnme as vendor_name,
	a.actnum as vendor_account_number,
	vt.typnme as vendor_type,
	a.e_mail as vendor_email,
	a.phnnum as vendor_phone_number
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.pchord p
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actpay a on a.recnum = p.vndnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndtyp vt on vt.recnum = a.vndtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.eqpmnt e on e.recnum = p.eqpmnt
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.pchtyp pt on pt.recnum = p.ordtyp')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Vendor_Contacts'), '(
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
	cost_type NVARCHAR(30)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Vendor_Contacts'),' 

SELECT
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
	ct.typnme as cost_type
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actpay AS act 
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndcnt AS c ON act.recnum = c.recnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.cstcde cst on cst.recnum = act.cdedft
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = act.typdft
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndtyp vt on vt.recnum = act.vndtyp')

EXECUTE sp_executesql @SqlInsertCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Jobs'), '(
	job_number BIGINT,	
	job_name NVARCHAR(75),
	job_status NVARCHAR(8),
	client_id BIGINT,
	client_name NVARCHAR(75),
	job_type NVARCHAR(50),
	contract_amount DECIMAL(14,2),
	invoice_total DECIMAL(14,2),
	invoice_amount_paid DECIMAL(14,2),
	invoice_sales_tax DECIMAL(14,2),
	supervisor_id BIGINT,
	supervisor NVARCHAR(100),
	salesperson_id BIGINT,
	salesperson NVARCHAR(100),
	estimator_id BIGINT,	
	estimator NVARCHAR(100),
	contact NVARCHAR(50),
	address1 NVARCHAR(50),
	address2 NVARCHAR(50),
	city NVARCHAR(50),
	state NVARCHAR(2),
	zip_code NVARCHAR(10),
	phone_number NVARCHAR(14),
	job_contact_phone_number NVARCHAR(14),
	bid_opening_date DATE,
	plans_received_date DATE,
	bid_completed_date DATE,
	contract_signed_date DATE,
	pre_lien_filed_date DATE,
	project_start_date DATE,
	project_complete_date DATE,
	lien_release_date DATE,
	material_cost DECIMAL(14,2),
	labor_cost DECIMAL(14,2),
	equipment_cost DECIMAL(14,2),
	other_cost DECIMAL(14,2),
	job_cost_overhead DECIMAL(14,2),
	change_order_approved_amount DECIMAL(14,2),
	retention DECIMAL(14,2),
	invoice_balance DECIMAL(14,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Jobs'), ' 

SELECT
	a.recnum as job_number,	
	a.jobnme as job_name,
	CASE a.status
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status,
	r.recnum as client_id,
	r.clnnme as client_name,
	j.typnme as job_type,
	a.cntrct as contract_amount,
	i.invttl as invoice_total,
	i.amtpad as invoice_amount_paid,
	i.slstax as invoice_sales_tax,
	a.sprvsr as supervisor_id,
	CONCAT(es.fstnme, '' '', es.lstnme) as supervisor,
	a.slsemp as salesperson_id,
	CONCAT(e.fstnme, '' '', e.lstnme) as salesperson,
	a.estemp as estimator_id,
	CONCAT(est.fstnme, '' '', est.lstnme) as estimator,
	a.contct as contact,
	a.addrs1 as address1,
	a.addrs2 as address2,
	a.ctynme as city,
	a.state_ as state,
	a.zipcde as zip_code,
	a.phnnum as phone_number,
	jctct.phnnum as job_contact_phone_number,
	a.biddte as bid_opening_date,
	a.plnrcv as plans_received_date,
	a.actbid as bid_completed_date,
	a.ctcdte as contract_signed_date,
	a.prelen as pre_lien_filed_date,
	a.sttdte as project_start_date,
	a.cmpdte as project_complete_date,
	a.lenrls as lien_release_date,
	jc.material_cost,
	jc.labor_cost,
	jc.equipment_cost,
	jc.other_cost,
	jc.overhead_amount as job_cost_overhead,
	co.appamt as change_order_approved_amount,
	i.retain as retention,
	i.invnet as invoice_balance
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.jobtyp j on j.recnum = a.jobtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.reccln r on r.recnum = a.clnnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ es on es.recnum = a.sprvsr 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = a.slsemp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.employ est on est.recnum = a.estemp
LEFT JOIN (
	SELECT
		recnum,
		phnnum
	FROM ',QUOTENAME(@Client_DB_Name),M'.dbo.jobcnt 
	WHERE linnum = 1
) jctct on jctct.recnum = a.recnum
LEFT JOIN (
	SELECT
		jobnum,
		SUM(CASE 
			WHEN ct.typnme = ''Material'' THEN cstamt 
			ELSE 0 
		END) as material_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Labor'' THEN cstamt 
			ELSE 0 
		END) as labor_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Equipment'' THEN cstamt 
			ELSE 0 
		END) as equipment_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Other'' THEN cstamt 
			ELSE 0 
		END) as other_cost,
		SUM(jcst.ovhamt) as overhead_amount
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst jcst
	INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = jcst.csttyp
	WHERE jcst.status = 1
	GROUP BY jobnum
) jc on jc.jobnum = a.recnum
INNER JOIN (
	SELECT 
		jobnum,
		SUM(invttl) as invttl,
		SUM(amtpad) as amtpad,
		SUM(slstax) as slstax,
		SUM(retain) as retain,
		SUM(invnet) as invnet
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv 
	WHERE 
		invtyp = 1
		AND status != 5
	GROUP BY jobnum
) as i on a.recnum = i.jobnum
LEFT JOIN 
(
	SELECT 
		jobnum,
		sum(appamt) as appamt
	FROM
		',QUOTENAME(@Client_DB_Name),'.dbo.prmchg
	WHERE
		status < 5
	GROUP BY jobnum
) co on co.jobnum = j.recnum
')

EXECUTE sp_executesql @SqlInsertCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost_Waterfall'), '(
	job_number BIGINT,	
	waterfall_category NVARCHAR(50),
	waterfall_value DECIMAL(14,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand

DECLARE @SQLinsertWFtable NVARCHAR(MAX);
SET @SQLinsertWFtable = CONCAT(N'
DECLARE @wf_table TABLE (
	job_number BIGINT, contract_amount DECIMAL(14,2), 
	invoice_total DECIMAL(14,2), invoice_amount_paid DECIMAL(14,2), 
	invoice_sales_tax DECIMAL(14,2),material_cost DECIMAL(14,2),
	labor_cost DECIMAL(14,2), equipment_cost DECIMAL(14,2),
	other_cost DECIMAL(14,2), overhead_cost DECIMAL(14,2),
	approved_amount DECIMAL(14,2)
);

INSERT INTO @wf_table 
SELECT
	a.recnum as job_number,	
	a.cntrct as contract_amount,
	i.invttl as invoice_total,
	i.amtpad as invoice_amount_paid,
	i.slstax * -1 as invoice_sales_tax,
	jc.material_cost * -1 as material_cost,
	jc.labor_cost * -1 as labor_cost,
	jc.equipment_cost * -1 as equipment_cost,
	jc.other_cost * -1 as other_cost,
	jc.overhead_amount * -1 as overhead_cost,
	c.appamt as approved_amount
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
LEFT JOIN (
	SELECT
		jobnum,
		SUM(CASE 
			WHEN ct.typnme = ''Material'' THEN cstamt 
			ELSE 0 
		END) as material_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Labor'' THEN cstamt 
			ELSE 0 
		END) as labor_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Equipment'' THEN cstamt 
			ELSE 0 
		END) as equipment_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Other'' THEN cstamt 
			ELSE 0 
		END) as other_cost,
		SUM(jcst.ovhamt) as overhead_amount
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst jcst
	INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = jcst.csttyp
	WHERE jcst.status = 1
	GROUP BY jobnum
) jc on jc.jobnum = a.recnum
INNER JOIN (
	SELECT 
		jobnum,
		SUM(invttl) as invttl,
		SUM(amtpad) as amtpad,
		SUM(slstax) as slstax
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv 
	WHERE 
		invtyp = 1
		AND status != 5
		GROUP BY jobnum
) as i on a.recnum = i.jobnum
LEFT JOIN 
(SELECT 
	jobnum,
	SUM(appamt) as appamt,
	sum(ovhamt) as ovhamt
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg 
WHERE status < 5
GROUP BY jobnum) c on c.jobnum = a.recnum

INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost_Waterfall'), ' 

SELECT
	job_number,
	waterfall_category,
	waterfall_value 
FROM (
	SELECT 
		job_number,
		''Contract Amount'' as waterfall_category,
		contract_amount as waterfall_value
	FROM @wf_table
	UNION ALL 
	SELECT 
		job_number,
		''Invoice Total'' as waterfall_category,
		invoice_total as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Invoice Amount Paid'' as waterfall_category,
		invoice_amount_paid as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Invoice Sales Tax'' as waterfall_category,
		invoice_sales_tax as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Material Cost'' as waterfall_category,
		material_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Labor Cost'' as waterfall_category,
		labor_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Equipment Cost'' as waterfall_category,
		equipment_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Other Cost'' as waterfall_category,
		other_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Overhead Cost'' as waterfall_category,
		overhead_cost as waterfall_value
	FROM @wf_table
	UNION ALL
	SELECT 
		job_number,
		''Approved Amount'' as waterfall_category,
		approved_amount as waterfall_value
	FROM @wf_table
) wf 
WHERE waterfall_value < 0 OR waterfall_value > 0
')

EXECUTE sp_executesql @SQLinsertWFtable



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

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Transaction_Lines'), ' 

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
