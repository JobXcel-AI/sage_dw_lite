--Version 1.0.3

--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);
DECLARE @SqlInsertQuery1 NVARCHAR(MAX);
DECLARE @SqlInsertQuery2 NVARCHAR(MAX);
DECLARE @SqlInsertQuery3 NVARCHAR(MAX);

--Update Jobs Table
SET @SqlInsertQuery1 = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Jobs;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Jobs;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Jobs
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
	ISNULL(j.typnme,''None Specified'') as job_type,
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
	i.max_chkdte as last_payment_received_date,
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
	tc.first_date_worked,
	tc.last_date_worked,
	ISNULL(i.invttl,0) - ISNULL(i.slstax,0) as invoice_billed,
	CONCAT(a.recnum,'' - '',a.jobnme) as job_number_job_name,
	ISNULL(a.cntrct,0) + ISNULL(co.appamt,0) as total_contract_amount,
	ISNULL(jb.budget,0) as original_budget_amount,
	ISNULL(jb.budget,0) + ISNULL(co.approved_budget,0) as total_budget_amount,
	ISNULL(a.cntrct,0) + ISNULL(co.appamt,0) - ISNULL(jb.budget,0) - ISNULL(co.approved_budget,0) as estimated_gross_profit,
	i.first_invoice_id,
	i.first_invoice_date,
	i.first_invoice_paid_date,
	i.final_invoice_id,
	i.final_invoice_date,
	i.final_invoice_paid_date,
	ISNULL(jc.subcontract_cost,0) as subcontract_cost,
	ISNULL(jc.type_6_cost,0) as type_6_cost,
	ISNULL(jc.type_6_cost,0) as type_7_cost,
	ISNULL(jc.type_7_cost,0) as type_8_cost,
	ISNULL(jc.type_9_cost,0) as type_9_cost,
	ISNULL(jc.type_6_cost,0) + ISNULL(jc.type_7_cost,0) + ISNULL(jc.type_8_cost,0) + ISNULL(jc.type_9_cost,0) + ISNULL(jc.subcontract_cost,0) + 
	ISNULL(jc.other_cost,0) + ISNULL(jc.material_cost,0) + ISNULL(jc.labor_cost,0) + ISNULL(jc.equipment_cost,0) as total_cost,
	a.insdte as created_date,
	a.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date 
')
SET @SqlInsertQuery2 = CONCAT(N'
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.jobtyp j on j.recnum = a.jobtyp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.reccln r on r.recnum = a.clnnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ es on es.recnum = a.sprvsr 
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = a.slsemp
LEFT JOIN ',QUOTENAME(@Client_DB_Name),N'.dbo.employ est on est.recnum = a.estemp
LEFT JOIN (
	SELECT
		recnum,
		SUM(ISNULL(matbdg,0)) +
		SUM(ISNULL(laborg,0)) +
		SUM(ISNULL(eqpbdg,0)) +
		SUM(ISNULL(subbdg,0)) +
		SUM(ISNULL(othbdg,0)) +
		SUM(ISNULL(usrcs6,0)) +
		SUM(ISNULL(usrcs7,0)) +
		SUM(ISNULL(usrcs8,0)) +
		SUM(ISNULL(usrcs9,0)) as budget
	FROM ',QUOTENAME(@Client_DB_Name),N'.dbo.bdglin
	GROUP BY recnum
) jb on jb.recnum = a.recnum
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
			WHEN ct.typnme = ''Subcontract'' THEN cstamt 
			ELSE 0 
		END) as subcontract_cost,
		SUM(CASE 
			WHEN ct.typnme = ''Other'' THEN cstamt 
			ELSE 0 
		END) as other_cost,
		SUM(CASE 
			WHEN ct.recnum = 6 THEN cstamt 
			ELSE 0 
		END) as type_6_cost,
		SUM(CASE 
			WHEN ct.recnum = 7 THEN cstamt 
			ELSE 0 
		END) as type_7_cost,
		SUM(CASE 
			WHEN ct.recnum = 8 THEN cstamt 
			ELSE 0 
		END) as type_8_cost,
		SUM(CASE 
			WHEN ct.recnum = 9 THEN cstamt 
			ELSE 0 
		END) as type_9_cost,
		SUM(jcst.ovhamt) as overhead_amount
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.jobcst jcst
	INNER JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp ct on ct.recnum = jcst.csttyp
	WHERE jcst.status = 1
	GROUP BY jobnum
) jc on jc.jobnum = a.recnum
')
SET @SqlInsertCommand3 = CONCAT(N'
LEFT JOIN (
	SELECT 
		acrinv.jobnum,
		MIN(acrinv.recnum) as first_invoice_id,
		MIN(first_acrinv.invdte) as first_invoice_date,
		MIN(first_acrinv_pmt.chkdte) as first_invoice_paid_date,
		MAX(acrinv.recnum) as final_invoice_id,
		MIN(final_acrinv.invdte) as final_invoice_date,
		MIN(final_acrinv_pmt.chkdte) as final_invoice_paid_date,
		SUM(acrinv.invttl) as invttl,
		SUM(acrinv.amtpad) as amtpad,
		SUM(acrinv.slstax) as slstax,
		SUM(acrinv.retain) as retain,
		SUM(acrinv.invnet) as invnet,
		SUM(acrinv.invbal) as invbal,
		MAX(payments.max_chkdte) as max_chkdte
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv acrinv
	LEFT JOIN (
		SELECT
			recnum,
			MAX(chkdte) as max_chkdte
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrpmt
		GROUP BY recnum
	) payments on payments.recnum = acrinv.recnum
	LEFT JOIN (
		SELECT
			jobnum,
			MIN(recnum) as min_recnum,
			MAX(recnum) as max_recnum
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv
		WHERE invtyp = 1 AND status != 5
		GROUP BY jobnum
	) invoice_ids on invoice_ids.jobnum = acrinv.jobnum
	LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv first_acrinv on first_acrinv.recnum = invoice_ids.min_recnum
	LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.acrinv final_acrinv on final_acrinv.recnum = invoice_ids.max_recnum
	LEFT JOIN (
		SELECT
			recnum,
			MAX(chkdte) as chkdte
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrpmt
		GROUP BY recnum
	) first_acrinv_pmt on first_acrinv_pmt.recnum = first_acrinv.recnum
	LEFT JOIN (
		SELECT
			recnum,
			MAX(chkdte) as chkdte
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.acrpmt
		GROUP BY recnum
	) final_acrinv_pmt on final_acrinv_pmt.recnum = final_acrinv.recnum
	WHERE 
		acrinv.invtyp = 1
		AND acrinv.status != 5 
	GROUP BY acrinv.jobnum, acrinv.status
) as i on a.recnum = i.jobnum
LEFT JOIN 
(
	SELECT 
		jobnum, 
		SUM(appamt) as appamt, 
		SUM(approved_budget) as approved_budget
	FROM
	(	
		SELECT 
			p.jobnum,
			SUM(p.appamt) as appamt,
			CASE p.status WHEN 1 THEN SUM(ISNULL(l.bdgprc,0)) ELSE 0 END as approved_budget
		FROM
			',QUOTENAME(@Client_DB_Name),'.dbo.prmchg p
		LEFT JOIN (
			SELECT recnum, SUM(bdgprc) as bdgprc
			FROM ',QUOTENAME(@Client_DB_Name),'.dbo.sbcgln
			GROUP BY recnum
		) l on l.recnum = p.recnum 
		WHERE
			p.status < 5
		GROUP BY p.jobnum, p.status
	) changes
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
LEFT JOIN (
	SELECT
		jobnum,
		MIN(dtewrk) as first_date_worked,
		MAX(dtewrk) as last_date_worked
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.tmcdln
	GROUP BY jobnum
) tc on tc.jobnum = a.recnum
;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Jobs
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.job_number NOT IN (SELECT job_number FROM ',@Reporting_DB_Name,N'.dbo.Jobs)
UNION ALL 
SELECT * FROM #DeletedRecords
')
SET @SqlInsertQuery = @SqlInsertQuery1 + @SqlInsertQuery2 + @SqlInsertQuery3
EXECUTE sp_executesql @SqlInsertQuery