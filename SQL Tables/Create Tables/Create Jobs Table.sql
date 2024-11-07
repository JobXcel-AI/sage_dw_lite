--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));

--Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);
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
	takeoff_ext_cost DECIMAL(14,2) DEFAULT 0, 
	takeoff_sales_tax DECIMAL(14,2) DEFAULT 0, 
	takeoff_overhead_amount DECIMAL(14,2) DEFAULT 0, 
	takeoff_profit_amount DECIMAL(14,2) DEFAULT 0, 
	takeoff_ext_price DECIMAL(14,2) DEFAULT 0,
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

--SQL data insertion Query
DECLARE @SqlInsertCommand1 NVARCHAR(MAX);
DECLARE @SqlInsertCommand2 NVARCHAR(MAX);
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
	ISNULL(tkof.ext_cost_excl_labor,0) as takeoff_ext_cost_excl_labor, 
	ISNULL(tkof.sales_tax_excl_labor,0) as takeoff_sales_tax_excl_labor, 
	ISNULL(tkof.overhead_amount_excl_labor,0) as takeoff_overhead_amount_excl_labor, 
	ISNULL(tkof.profit_amount_excl_labor,0) as takeoff_profit_amount_excl_labor, 
	ISNULL(tkof.ext_price_excl_labor,0) as takeoff_ext_price_excl_labor,
	ISNULL(tkof.ext_cost,0) as takeoff_ext_cost, 
	ISNULL(tkof.sales_tax,0) as takeoff_sales_tax, 
	ISNULL(tkof.overhead_amount,0) as takeoff_overhead_amount, 
	ISNULL(tkof.profit_amount,0) as takeoff_profit_amount, 
	ISNULL(tkof.ext_price,0) as takeoff_ext_price,
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
(SELECT
	recnum,
	SUM(ext_cost) as ext_cost, 
	SUM(sales_tax) as sales_tax, 
	SUM(overhead_amount) as overhead_amount, 
	SUM(profit_amount) as profit_amount, 
	SUM(ext_price) as ext_price,
	SUM(ext_cost_excl_labor) as ext_cost_excl_labor, 
	SUM(sales_tax_excl_labor) as sales_tax_excl_labor, 
	SUM(overhead_amount_excl_labor) as overhead_amount_excl_labor, 
	SUM(profit_amount_excl_labor) as profit_amount_excl_labor, 
	SUM(ext_price_excl_labor) as ext_price_excl_labor
FROM (
	SELECT 
		recnum,
		prtdsc,
		SUM(extttl) as ext_cost, 
		SUM(slstax) as sales_tax, 
		SUM(ovhamt) as overhead_amount, 
		SUM(pftamt) as profit_amount, 
		SUM(bidprc) as ext_price,
		CASE WHEN prtdsc NOT LIKE ''%labor%'' THEN SUM(extttl) ELSE 0 END as ext_cost_excl_labor, 
		CASE WHEN prtdsc NOT LIKE ''%labor%'' THEN SUM(slstax) ELSE 0 END as sales_tax_excl_labor, 
		CASE WHEN prtdsc NOT LIKE ''%labor%'' THEN SUM(ovhamt) ELSE 0 END as overhead_amount_excl_labor, 
		CASE WHEN prtdsc NOT LIKE ''%labor%'' THEN SUM(pftamt) ELSE 0 END as profit_amount_excl_labor, 
		CASE WHEN prtdsc NOT LIKE ''%labor%'' THEN SUM(bidprc) ELSE 0 END as ext_price_excl_labor 

	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.tkflin 
	GROUP BY recnum, prtdsc
) tkof2
GROUP BY recnum
) tkof on tkof.recnum = a.recnum
')
DECLARE @SqlInsertCommand NVARCHAR(MAX);
SET @SqlInsertCommand = @SqlInsertCommand1 + @SqlInsertCommand2
EXECUTE sp_executesql @SqlInsertCommand