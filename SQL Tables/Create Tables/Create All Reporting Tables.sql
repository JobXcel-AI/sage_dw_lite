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
	ar_invoice_balance DECIMAL(14,2),
	ar_invoice_retention DECIMAL(14,2),
	ar_invoice_type NVARCHAR(8),
	client_name NVARCHAR(75),
	job_supervisor NVARCHAR(50),
	job_salesperson NVARCHAR(50),
	ar_invoice_payments_payment_amount DECIMAL(14,2),
	ar_invoice_payments_discount_taken DECIMAL(14,2),
	ar_invoice_payments_credit_taken DECIMAL(14,2),
	last_payment_received_date DATE,
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
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
	ISNULL(acrinv.invttl,0) as ar_invoice_total,
	ISNULL(acrinv.slstax,0) as ar_invoice_sales_tax,
	ISNULL(acrinv.amtpad,0) as ar_invoice_amount_paid,
	ISNULL(acrinv.invbal,0) as ar_invoice_balance,
	ISNULL(acrinv.retain,0) as ar_invoice_retention,
	CASE acrinv.invtyp 
		WHEN 1 THEN ''Contract''
		WHEN 2 THEN ''Memo''
		ELSE ''Other''
	END as ar_invoice_type,
	r.clnnme as client_name,
	CONCAT(es.fstnme, '' '', es.lstnme) as job_supervisor,
	CONCAT(e.fstnme, '' '', e.lstnme) as job_salesperson,
	ISNULL(pmt.amount,0) as ar_invoice_payments_payment_amount,
	ISNULL(pmt.dsctkn,0) as ar_invoice_payments_discount_taken,
	ISNULL(pmt.aplcrd,0) as ar_invoice_payments_credit_taken,
	pmt.chkdte as last_payment_received_date,
	a.insdte as created_date,
	a.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv acrinv on acrinv.jobnum = a.recnum
LEFT JOIN (
	SELECT
		recnum,
		sum(amount) as amount,
		sum(dsctkn) as dsctkn,
		sum(aplcrd) as aplcrd,
		max(chkdte) as chkdte
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrpmt
	GROUP BY recnum
) pmt on pmt.recnum = acrinv.recnum
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
	status_number INT,
	change_order_description NVARCHAR(50),
	change_type NVARCHAR(50),
	reason NVARCHAR(50),
	submitted_date DATE,
	approved_date DATE,
	invoice_date DATE,
	purchase_order_number NVARCHAR(30),
	requested_amount DECIMAL(12,2),
	approved_amount DECIMAL(12,2),
	overhead_amount DECIMAL(12,2),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
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
	c.status as status_number,
	dscrpt as change_order_description,
	ct.typnme as change_type,
	reason,
	subdte as submitted_date,
	aprdte as approved_date,
	invdte as invoice_date,
	c.pchord as purchase_order_number,
	ISNULL(reqamt,0) as requested_amount,
	ISNULL(appamt,0) as approved_amount,
	ISNULL(ovhamt,0) as overhead_amount,
	c.insdte as created_date,
	c.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
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
	date_inactive DATE,
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
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
	dteina as date_inactive,
	e.insdte as created_date,
	e.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date 
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
	part_notes NVARCHAR(MAX),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Inventory'),' 

SELECT
	q.prtnum as part_number,
	l.locnme as location,
	dl.locnme as default_location,
	ISNULL(q.qtyohn,0) as quantity_on_hand,
	ISNULL(q.qtyavl,0) as quantity_available,
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
	p.ntetxt as part_notes,
	q.insdte as created_date,
	q.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
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
	job_cost_id BIGINT,
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
	job_cost_status NVARCHAR(4),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Cost'),' 

SELECT 
	j.recnum as job_cost_id,
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
	ISNULL(csthrs,0) as cost_in_hours,
	ISNULL(cstamt,0) as cost_amount,
	CASE 
		WHEN ct.typnme = ''Material'' THEN ISNULL(cstamt,0)
		ELSE 0 
	END as material_cost,
	CASE 
		WHEN ct.typnme = ''Labor'' THEN ISNULL(cstamt,0)
		ELSE 0 
	END as labor_cost,
	CASE 
		WHEN ct.typnme = ''Equipment'' THEN ISNULL(cstamt,0)
		ELSE 0 
	END as equipment_cost,
	CASE 
		WHEN ct.typnme = ''Other'' THEN ISNULL(cstamt,0)
		ELSE 0 
	END as other_cost,
	ISNULL(j.blgqty,0) as billing_quantity,
	ISNULL(j.blgamt,0) as billing_amount,
	ISNULL(j.ovhamt,0) as overhead_amount,
	CASE j.status
		WHEN 1 THEN ''Open''
		WHEN 2 THEN ''Void''
	END as job_cost_status,
	j.insdte as created_date,
	j.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
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
	PY_PD12_Budget DECIMAL(14,2),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

DECLARE @SqlInsertCommand1 NVARCHAR(MAX)
DECLARE @SqlInsertCommand2 NVARCHAR(MAX)
SET @SqlInsertCommand1 = CONCAT(N'
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
	ab.PY_PD12_Budget,
	a.insdte as created_date,
	a.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date	
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.lgract a 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.lgract pa on pa.recnum = a.sumact
LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.csttyp ct on ct.recnum = a.csttyp
')
SET @SqlInsertCommand2 = CONCAT(N'
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
) ab on ab.lgract = a.recnum ')

SET @SqlInsertCommand = @SqlInsertCommand1 + @SqlInsertCommand2
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
	vendor_phone_number NVARCHAR(14),
	delivery_via NVARCHAR(30),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
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
	ISNULL(p.rcvdte,0) as received,
	ISNULL(p.currnt,0) as current_value,
	ISNULL(p.cancel,0) as canceled,
	ISNULL(p.subttl,0) as subtotal,
	ISNULL(p.slstax,0) as sales_tax,
	ISNULL(p.pchttl,0) as total,
	ISNULL(p.pchbal,0) as balance,
	p.jobnum as job_number,
	p.hotlst as hot_list,
	a.recnum as vendor_id,
	a.vndnme as vendor_name,
	a.actnum as vendor_account_number,
	vt.typnme as vendor_type,
	a.e_mail as vendor_email,
	a.phnnum as vendor_phone_number,
	p.delvia as delivery_via,
	p.insdte as created_date,
	p.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.pchord p
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actpay a on a.recnum = p.vndnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndtyp vt on vt.recnum = a.vndtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.eqpmnt e on e.recnum = p.eqpmnt
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.pchtyp pt on pt.recnum = p.ordtyp')

EXECUTE sp_executesql @SqlInsertCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Vendor_Contacts'), '(
	vendor_contact_id NVARCHAR(20),
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
	cost_type NVARCHAR(30),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Vendor_Contacts'),' 

SELECT
	CONCAT(act.recnum,''-'',c.linnum) as vendor_contact_id,
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
	ct.typnme as cost_type,
	c.insdte as created_date,
	c.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
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
	job_status_number INT,
	client_id BIGINT,
	client_name NVARCHAR(75),
	job_type NVARCHAR(50),
	contract_amount DECIMAL(14,2) DEFAULT 0,
	invoice_total DECIMAL(14,2) DEFAULT 0,
	invoice_amount_paid DECIMAL(14,2) DEFAULT 0,
	invoice_sales_tax DECIMAL(14,2) DEFAULT 0,
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
	material_cost DECIMAL(14,2) DEFAULT 0,
	labor_cost DECIMAL(14,2) DEFAULT 0,
	equipment_cost DECIMAL(14,2) DEFAULT 0,
	other_cost DECIMAL(14,2) DEFAULT 0,
	job_cost_overhead DECIMAL(14,2) DEFAULT 0,
	change_order_approved_amount DECIMAL(14,2) DEFAULT 0,
	retention DECIMAL(14,2) DEFAULT 0,
	invoice_net_due DECIMAL(14,2) DEFAULT 0,
	invoice_balance DECIMAL(14,2) DEFAULT 0,
	last_payment_received_date DATE,
	takeoff_ext_cost_excl_labor DECIMAL(14,2) DEFAULT 0, 
	takeoff_sales_tax_excl_labor DECIMAL(14,2) DEFAULT 0, 
	takeoff_overhead_amount_excl_labor DECIMAL(14,2) DEFAULT 0, 
	takeoff_profit_amount_excl_labor DECIMAL(14,2) DEFAULT 0, 
	takeoff_ext_price_excl_labor DECIMAL(14,2) DEFAULT 0,
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
SET @SqlInsertCommand1 = CONCAT(N'
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
	a.status as job_status_number,
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
	ISNULL(jc.material_cost,0) as material_cost,
	ISNULL(jc.labor_cost,0) as labor_cost,
	ISNULL(jc.equipment_cost,0) as equipment_cost,
	ISNULL(jc.other_cost,0) as other_cost,
	ISNULL(jc.overhead_amount,0) as job_cost_overhead,
	ISNULL(co.appamt,0) as change_order_approved_amount,
	ISNULL(i.retain,0) as retention,
	ISNULL(i.invnet,0) as invoice_net_due,
	ISNULL(i.invbal,0) as invoice_balance,
	i.chkdte as last_payment_received_date,
	ISNULL(tkof.ext_cost,0) as takeoff_ext_cost_excl_labor, 
	ISNULL(tkof.sales_tax,0) as takeoff_sales_tax_excl_labor, 
	ISNULL(tkof.overhead_amount,0) as takeoff_overhead_amount_excl_labor, 
	ISNULL(tkof.profit_amount,0) as takeoff_profit_amount_excl_labor, 
	ISNULL(tkof.ext_price,0) as takeoff_ext_price_excl_labor,
	a.insdte as created_date,
	a.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date 
')
SET @SqlInsertCommand2 = CONCAT(N'
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
	FROM ',QUOTENAME(@Client_DB_Name),N'.dbo.jobcnt 
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
LEFT JOIN (
	SELECT 
		jobnum,
		SUM(acrinv.invttl) as invttl,
		SUM(acrinv.amtpad) as amtpad,
		SUM(acrinv.slstax) as slstax,
		SUM(acrinv.retain) as retain,
		SUM(acrinv.invnet) as invnet,
		SUM(acrinv.invbal) as invbal,
		MAX(payments.chkdte) as chkdte
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv acrinv
	LEFT JOIN (
		SELECT
			recnum,
			MAX(chkdte) as chkdte
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrpmt
		GROUP BY recnum
	) payments on payments.recnum = acrinv.recnum
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
) co on co.jobnum = a.recnum
LEFT JOIN 
(
	SELECT 
		recnum,
		SUM(extttl) as ext_cost, 
		SUM(slstax) as sales_tax, 
		SUM(ovhamt) as overhead_amount, 
		SUM(pftamt) as profit_amount, 
		SUM(bidprc) as ext_price 
	FROM tkflin 
	WHERE prtdsc NOT LIKE ''%labor%''
	GROUP BY recnum
) tkof on tkof.recnum = a.recnum
')
SET @SqlInsertCommand = @SqlInsertCommand1 + @SqlInsertCommand2
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
	ISNULL(a.cntrct,0) as contract_amount,
	ISNULL(i.invttl,0) as invoice_total,
	ISNULL(i.amtpad,0) as invoice_amount_paid,
	ISNULL(i.slstax,0) * -1 as invoice_sales_tax,
	ISNULL(jc.material_cost,0) * -1 as material_cost,
	ISNULL(jc.labor_cost,0) * -1 as labor_cost,
	ISNULL(jc.equipment_cost,0) * -1 as equipment_cost,
	ISNULL(jc.other_cost,0) * -1 as other_cost,
	ISNULL(jc.overhead_amount,0) * -1 as overhead_cost,
	ISNULL(c.appamt,0) as approved_amount
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
	vendor_name NVARCHAR(100),
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
	posting_year INT,
	created_date DATE,
	is_deleted BIT DEFAULT 0,
	deleted_date DATE
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.source s on s.recnum = lt.srcnum
')

EXECUTE sp_executesql @SqlInsertCommand



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
	comp_type NVARCHAR(30),
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

SET @SqlInsertCommand = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Payroll_Records'), ' 

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



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Status_History'), '(
	job_number BIGINT,
	job_status_number INT,
	job_status NVARCHAR(8),
	valid_from_date DATETIME,
	valid_to_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

DECLARE @SQLinsertJobHistory NVARCHAR(MAX);
SET @SQLinsertJobHistory = CONCAT(N'
DECLARE @JobHistory TABLE (job_number BIGINT, version_date DATETIME, job_status_number INT, job_status NVARCHAR(8))
INSERT INTO @JobHistory 

SELECT DISTINCT
	coalesce(a.recnum,b.recnum) as job_number,
	coalesce(a._Date, b.upddte) as version_date,
	coalesce(a.status, b.status) as job_status_number,
	CASE coalesce(a.status, b.status)
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status
FROM (
	SELECT 
		recnum,
		status,
		_Date,
		jobnme
	FROM ',QUOTENAME(@Client_DB_Name),N'.[dbo_Audit].[actrec]
) a
RIGHT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec b on a.recnum = b.recnum
UNION ALL 
SELECT job_number, version_date, job_status_number, job_status 
FROM (
	SELECT 
		coalesce(a.recnum,b.recnum) as job_number,
		b.insdte as version_date,
		coalesce(a.status, b.status) as job_status_number,
		CASE coalesce(a.status, b.status)
			WHEN 1 THEN ''Bid''
			WHEN 2 THEN ''Refused''
			WHEN 3 THEN ''Contract''
			WHEN 4 THEN ''Current''
			WHEN 5 THEN ''Complete''
			WHEN 6 THEN ''Closed''
			ELSE ''Other''
		END as job_status,
		ROW_NUMBER() OVER (PARTITION BY coalesce(a.recnum,b.recnum) ORDER BY coalesce(a.recnum,b.recnum), b.insdte, a.status) as row_num
	FROM (
		SELECT 
			recnum,
			status,
			_Date,
			jobnme
		FROM ',QUOTENAME(@Client_DB_Name),'.[dbo_Audit].[actrec]
	) a
	RIGHT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.actrec b on a.recnum = b.recnum
) q2 
WHERE row_num = 1
UNION ALL 
SELECT
	recnum as job_number,
	DATEADD(SECOND,1,upddte) as version_date,
	status as job_status_number, 
	CASE status
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status
FROM ',QUOTENAME(@Client_DB_Name),N'.dbo.actrec
WHERE upddte IS NOT NULL

DECLARE @JobHistory2 TABLE (id BIGINT, job_number BIGINT, version_date DATETIME, job_status_number INT, job_status NVARCHAR(8), can_be_removed BIT)
INSERT INTO @JobHistory2 
	
SELECT 
	ROW_NUMBER() OVER (PARTITION BY job_number ORDER BY job_number, version_date) as id,
	job_number, version_date, job_status_number, job_status,
	CASE WHEN 
		LAG(job_status) OVER(PARTITION BY job_number ORDER BY job_number, version_date) = job_status AND 
		LEAD(job_status) OVER(PARTITION BY job_number ORDER BY job_number, version_date) = job_status
	THEN 1
	ELSE 0
	END as can_be_removed
FROM @JobHistory 

INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Status_History'), ' 
SELECT DISTINCT
	job_number,
	job_status_number,
	job_status,
	CASE WHEN prior_version_date IS NULL THEN first_version_date ELSE version_date END as valid_from_date,
	CASE WHEN next_version_date IS NULL THEN DATEADD(YEAR,100,version_date) ELSE next_version_date END as valid_to_date
FROM
(
	SELECT
		job_number,
		version_date,
		job_status_number,
		job_status,
		FIRST_VALUE(version_date) OVER(PARTITION BY job_number, job_status ORDER BY job_number, version_date) as first_version_date,
		LAG(version_date) OVER(PARTITION BY job_number ORDER BY job_number, version_date) as prior_version_date,
		LEAD(version_date) OVER(PARTITION BY job_number ORDER BY job_number, version_date) as next_version_date,
		DATEADD(SECOND,-1,LAST_VALUE(version_date) OVER(PARTITION BY job_number, job_status ORDER BY job_number, version_date RANGE BETWEEN CURRENT ROW
					AND UNBOUNDED FOLLOWING)) as last_version_date,
		record_count = COUNT(*) OVER(PARTITION BY job_number ORDER BY job_number, version_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
		ROW_NUMBER() OVER (PARTITION BY job_number ORDER BY job_number, version_date) as record_number
	FROM @JobHistory2 
	WHERE version_date IS NOT NULL AND can_be_removed = 0
) q
')

EXECUTE sp_executesql @SQLinsertJobHistory



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Jobs_Active_History'), '(
	job_active_date DATETIME,
	job_number BIGINT
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlInsertCommand = CONCAT(N'
DECLARE @DateVal DATETIME
SET @DateVal = CAST(CAST(DATEPART(YEAR,GETDATE()) -1 as NVARCHAR) + ''-01-01'' as datetime)
WHILE (@DateVal < GETDATE())
BEGIN
	INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Jobs_Active_History'), ' 
	SELECT @DateVal as job_active_date, job_number 
	FROM ',@Reporting_DB_Name,'.dbo.Job_Status_History
	WHERE 
		job_status_number BETWEEN 3 AND 5
		AND valid_from_date < @DateVal 
		AND valid_to_date >= @DateVal
	SET @DateVal = DATEADD(MONTH,1,@DateVal)
END
')

EXECUTE sp_executesql @SqlInsertCommand




--Sql Create Table Command
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_History'), '(
	record_number BIGINT,
	job_number BIGINT,
	change_order_status_number INT,
	change_order_status NVARCHAR(8),
	valid_from_date DATETIME,
	valid_to_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

DECLARE @SQLinsertChangeOrderHistory1 NVARCHAR(MAX);
DECLARE @SQLinsertChangeOrderHistory2 NVARCHAR(MAX);
SET @SQLinsertChangeOrderHistory1 = CONCAT(N'
DECLARE @ChangeOrderHistory TABLE (record_number BIGINT, job_number BIGINT, version_date DATETIME, change_order_status_number INT, change_order_status NVARCHAR(8))
INSERT INTO @ChangeOrderHistory 

SELECT DISTINCT
	coalesce(a.recnum,b.change_order_id) as record_number,
	coalesce(a.jobnum,b.job_number) as job_number,
	coalesce(a._Date, b.last_updated_date) as version_date,
	coalesce(a.status, b.status_number) as change_order_status_number,
	CASE coalesce(a.status, b.status_number)
		WHEN 1 THEN ''Approved''
		WHEN 2 THEN ''Open''
		WHEN 3 THEN ''Review''
		WHEN 4 THEN ''Disputed''
		WHEN 5 THEN ''Void''
		WHEN 6 THEN ''Rejected''
		ELSE ''Other''
	END as change_order_status
FROM (
	SELECT 
		recnum,
		status,
		_Date,
		jobnum
	FROM ',QUOTENAME(@Client_DB_Name),N'.[dbo_Audit].[prmchg]
) a
RIGHT JOIN ',@Reporting_DB_Name,'.dbo.Change_Orders b on a.recnum = b.change_order_id
UNION ALL 
SELECT record_number, job_number, version_date, change_order_status_number, change_order_status 
FROM (
	SELECT 
		coalesce(a.recnum,b.change_order_id) as record_number,
		coalesce(a.jobnum,b.job_number) as job_number,
		b.created_date as version_date,
		coalesce(a.status, b.status_number) as change_order_status_number,
		CASE coalesce(a.status, b.status_number)
			WHEN 1 THEN ''Approved''
			WHEN 2 THEN ''Open''
			WHEN 3 THEN ''Review''
			WHEN 4 THEN ''Disputed''
			WHEN 5 THEN ''Void''
			WHEN 6 THEN ''Rejected''
			ELSE ''Other''
		END as change_order_status,
		ROW_NUMBER() OVER (PARTITION BY coalesce(a.recnum,b.change_order_id) ORDER BY coalesce(a.recnum,b.change_order_id), b.created_date, coalesce(a.status, b.status_number)) as row_num
	FROM (
		SELECT 
			recnum,
			status,
			_Date,
			jobnum
		FROM ',QUOTENAME(@Client_DB_Name),'.[dbo_Audit].[prmchg]
	) a
	RIGHT JOIN ',@Reporting_DB_Name,'.dbo.Change_Orders b on a.recnum = b.change_order_id
) q2 
WHERE row_num = 1
UNION ALL 
SELECT
	change_order_id as record_number,
	job_number,
	DATEADD(SECOND,1,last_updated_date) as version_date,
	status_number as change_order_status_number, 
	status as change_order_status
FROM ',@Reporting_DB_Name,'.dbo.Change_Orders
WHERE last_updated_date IS NOT NULL

DECLARE @ChangeOrderHistory2 TABLE (id BIGINT, record_number BIGINT, job_number BIGINT, version_date DATETIME, change_order_status_number INT, change_order_status NVARCHAR(8), can_be_removed BIT)
INSERT INTO @ChangeOrderHistory2 
	
SELECT 
	ROW_NUMBER() OVER (PARTITION BY record_number ORDER BY record_number, version_date) as id,
	record_number, job_number, version_date, change_order_status_number, change_order_status,
	CASE WHEN 
		LAG(change_order_status) OVER(PARTITION BY record_number ORDER BY record_number, version_date) = change_order_status AND 
		LEAD(change_order_status) OVER(PARTITION BY record_number ORDER BY record_number, version_date) = change_order_status
	THEN 1
	ELSE 0
	END as can_be_removed
FROM @ChangeOrderHistory 

')
SET @SQLinsertChangeOrderHistory2 = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_History'), ' 

SELECT DISTINCT
	record_number,
	job_number,
	change_order_status_number,
	change_order_status,
	CASE WHEN prior_version_date IS NULL THEN first_version_date ELSE version_date END as valid_from_date,
	CASE WHEN next_version_date IS NULL THEN DATEADD(YEAR,100,version_date) ELSE next_version_date END as valid_to_date
FROM
(
	SELECT
		record_number,
		job_number,
		version_date,
		change_order_status_number,
		change_order_status,
		FIRST_VALUE(version_date) OVER(PARTITION BY record_number, change_order_status ORDER BY record_number, version_date) as first_version_date,
		LAG(version_date) OVER(PARTITION BY record_number ORDER BY record_number, version_date) as prior_version_date,
		LEAD(version_date) OVER(PARTITION BY record_number ORDER BY record_number, version_date) as next_version_date,
		DATEADD(SECOND,-1,LAST_VALUE(version_date) OVER(PARTITION BY record_number, change_order_status ORDER BY record_number, version_date RANGE BETWEEN CURRENT ROW
					AND UNBOUNDED FOLLOWING)) as last_version_date,
		record_count = COUNT(*) OVER(PARTITION BY record_number ORDER BY record_number, version_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
		ROW_NUMBER() OVER (PARTITION BY record_number ORDER BY record_number, version_date) as record_row_number
	FROM @ChangeOrderHistory2 
	WHERE version_date IS NOT NULL AND can_be_removed = 0
) q
')
DECLARE @SQLinsertChangeOrderHistory NVARCHAR(MAX);
SET @SQLinsertChangeOrderHistory = @SQLinsertChangeOrderHistory1 + @SQLinsertChangeOrderHistory2
EXECUTE sp_executesql @SQLinsertChangeOrderHistory




SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_Open_History'), '(
	change_order_open_date DATETIME,
	record_number BIGINT,
	job_number BIGINT
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
SET @SqlInsertCommand = CONCAT(N'
DECLARE @DateVal DATETIME
SET @DateVal = CAST(CAST(DATEPART(YEAR,GETDATE()) -1 as NVARCHAR) + ''-01-01'' as datetime)
WHILE (@DateVal < GETDATE())
BEGIN
	INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_Open_History'), ' 
	SELECT @DateVal as change_order_open_date, record_number, job_number 
	FROM ',@Reporting_DB_Name,'.dbo.Change_Order_History
	WHERE 
		change_order_status_number BETWEEN 2 AND 4
		AND valid_from_date < @DateVal 
		AND valid_to_date >= @DateVal
	SET @DateVal = DATEADD(MONTH,1,@DateVal)
END
')

EXECUTE sp_executesql @SqlInsertCommand