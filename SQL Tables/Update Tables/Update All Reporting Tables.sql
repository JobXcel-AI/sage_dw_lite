--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery1 NVARCHAR(MAX);
DECLARE @SqlInsertQuery2 NVARCHAR(MAX);
DECLARE @SqlInsertQuery NVARCHAR(MAX);
DECLARE @SqlDeleteCommand NVARCHAR(100);
DECLARE @TranName VARCHAR(20);



--Update AR_Invoices Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.AR_Invoices
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.employ e on e.recnum = a.slsemp;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.AR_Invoices
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.job_number NOT IN (SELECT job_number FROM ',@Reporting_DB_Name,N'.dbo.AR_Invoices)
UNION ALL 
SELECT * FROM #DeletedRecords
')

SELECT @TranName = 'AR_Invoices';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Change Orders
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Change_Orders;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Orders;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Orders
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.chgtyp ct on ct.recnum = c.chgtyp;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Orders
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.change_order_id NOT IN (SELECT change_order_id FROM ',@Reporting_DB_Name,N'.dbo.Change_Orders)
UNION ALL 
SELECT * FROM #DeletedRecords
')
SELECT @TranName = 'Change_Orders';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Change Order History
SELECT @TranName = 'Change_Order_History';
BEGIN TRY
	BEGIN TRANSACTION @TranName;
--Clear existing History Table
SET @SqlDeleteCommand = CONCAT('DELETE FROM ',@Reporting_DB_Name,'.dbo.Change_Order_History;')
EXECUTE sp_executesql @SqlDeleteCommand;

--Recreate History Table

SET @SqlInsertQuery1 = CONCAT(N'
DECLARE @ChangeOrderHistory TABLE (record_number BIGINT, job_number BIGINT, version_date DATETIME, change_order_status_number INT, change_order_status NVARCHAR(8), deleted_date DATETIME)
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
	END as change_order_status,
	b.deleted_date
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
SELECT record_number, job_number, version_date, change_order_status_number, change_order_status, deleted_date 
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
		b.deleted_date,
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
	status as change_order_status,
	deleted_date
FROM ',@Reporting_DB_Name,'.dbo.Change_Orders
WHERE last_updated_date IS NOT NULL

DECLARE @ChangeOrderHistory2 TABLE (id BIGINT, record_number BIGINT, job_number BIGINT, version_date DATETIME, change_order_status_number INT, change_order_status NVARCHAR(8), can_be_removed BIT, deleted_date DATETIME)
INSERT INTO @ChangeOrderHistory2 
	
SELECT 
	ROW_NUMBER() OVER (PARTITION BY record_number ORDER BY record_number, version_date) as id,
	record_number, job_number, version_date, change_order_status_number, change_order_status,
	CASE WHEN 
		LAG(change_order_status) OVER(PARTITION BY record_number ORDER BY record_number, version_date) = change_order_status AND 
		LEAD(change_order_status) OVER(PARTITION BY record_number ORDER BY record_number, version_date) = change_order_status
	THEN 1
	ELSE 0
	END as can_be_removed,
	deleted_date
FROM @ChangeOrderHistory 
')
SET @SqlInsertQuery2 = CONCAT(N'
INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Change_Order_History'), ' 

SELECT DISTINCT
	record_number,
	job_number,
	change_order_status_number,
	change_order_status,
	CASE WHEN prior_version_date IS NULL THEN first_version_date ELSE version_date END as valid_from_date,
	CASE WHEN next_version_date IS NULL THEN CASE WHEN deleted_date IS NOT NULL THEN deleted_date ELSE DATEADD(YEAR,100,version_date) END ELSE next_version_date END as valid_to_date
FROM
(
	SELECT
		record_number,
		job_number,
		version_date,
		change_order_status_number,
		change_order_status,
		deleted_date,
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

SET @SqlInsertQuery = @SqlInsertQuery1 + @SqlInsertQuery2
EXECUTE sp_executesql @SqlInsertQuery

COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Change Order Open History
--Clear existing History Table
SET @SqlDeleteCommand = CONCAT('DELETE FROM ',@Reporting_DB_Name,'.dbo.Change_Order_Open_History;')
EXECUTE sp_executesql @SqlDeleteCommand;

--Recreate History Table

SET @SqlInsertQuery = CONCAT(N'
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
SELECT @TranName = 'Change_Order_Open_History';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Employees
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Employees;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Employees;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Employees
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.dptmnt d ON d.recnum = p.dptmnt;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Employees
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.employee_id NOT IN (SELECT employee_id FROM ',@Reporting_DB_Name,N'.dbo.Employees)
UNION ALL 
SELECT * FROM #DeletedRecords
')
SELECT @TranName = 'Employee';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Inventory
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Inventory;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Inventory;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Inventory
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
;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Inventory
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.part_number NOT IN (SELECT part_number FROM ',@Reporting_DB_Name,N'.dbo.Inventory)
UNION ALL 
SELECT * FROM #DeletedRecords
')
SELECT @TranName = 'Inventory';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Jobs
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
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.tkflin 
	WHERE prtdsc NOT LIKE ''%labor%''
	GROUP BY recnum
) tkof on tkof.recnum = a.recnum;',
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
SET @SqlInsertQuery = @SqlInsertQuery1 + @SqlInsertQuery2
SELECT @TranName = 'Jobs';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Job Cost
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Cost
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec ar on ar.recnum = j.jobnum;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Job_Cost
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.job_cost_id NOT IN (SELECT job_cost_id FROM ',@Reporting_DB_Name,N'.dbo.Job_Cost)
UNION ALL 
SELECT * FROM #DeletedRecords
')

SELECT @TranName = 'Job_Cost';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Job Status History
SELECT @TranName = 'Job_Status_History';
BEGIN TRY
	BEGIN TRANSACTION @TranName;
--Clear existing History Table
SET @SqlDeleteCommand = CONCAT('DELETE FROM ',@Reporting_DB_Name,'.dbo.Job_Status_History;')
EXECUTE sp_executesql @SqlDeleteCommand;

SET @SqlInsertQuery = CONCAT(N'
DECLARE @JobHistory TABLE (job_number BIGINT, version_date DATETIME, job_status_number INT, job_status NVARCHAR(8), deleted_date DATETIME)
INSERT INTO @JobHistory 

SELECT DISTINCT
	coalesce(a.recnum,b.job_number) as job_number,
	coalesce(a._Date, b.last_updated_date) as version_date,
	coalesce(a.status, b.job_status_number) as job_status_number,
	CASE coalesce(a.status, b.job_status_number)
		WHEN 1 THEN ''Bid''
		WHEN 2 THEN ''Refused''
		WHEN 3 THEN ''Contract''
		WHEN 4 THEN ''Current''
		WHEN 5 THEN ''Complete''
		WHEN 6 THEN ''Closed''
		ELSE ''Other''
	END as job_status,
	b.deleted_date
FROM (
	SELECT 
		recnum,
		status,
		_Date,
		jobnme
	FROM ',QUOTENAME(@Client_DB_Name),N'.[dbo_Audit].[actrec]
) a
RIGHT JOIN ',@Reporting_DB_Name,'.dbo.Jobs b on a.recnum = b.job_number
UNION ALL 
SELECT job_number, version_date, job_number, job_status, deleted_date 
FROM (
	SELECT 
		coalesce(a.recnum,b.job_number) as job_number,
		b.created_date as version_date,
		coalesce(a.status, b.job_status_number) as job_status_number,
		CASE coalesce(a.status, b.job_status_number)
			WHEN 1 THEN ''Bid''
			WHEN 2 THEN ''Refused''
			WHEN 3 THEN ''Contract''
			WHEN 4 THEN ''Current''
			WHEN 5 THEN ''Complete''
			WHEN 6 THEN ''Closed''
			ELSE ''Other''
		END as job_status,
		b.deleted_date,
		ROW_NUMBER() OVER (PARTITION BY coalesce(a.recnum,b.job_number) ORDER BY coalesce(a.recnum,b.job_number), b.created_date, coalesce(a.status, b.job_status_number)) as row_num
	FROM (
		SELECT 
			recnum,
			status,
			_Date,
			jobnme
		FROM ',QUOTENAME(@Client_DB_Name),'.[dbo_Audit].[actrec]
	) a
	RIGHT JOIN ',@Reporting_DB_Name,'.dbo.Jobs b on a.recnum = b.job_number
) q2 
WHERE row_num = 1
UNION ALL 
SELECT
	job_number,
	DATEADD(SECOND,1,last_updated_date) as version_date,
	job_status_number, 
	job_status,
	deleted_date
FROM ',@Reporting_DB_Name,'.dbo.Jobs
WHERE last_updated_date IS NOT NULL

DECLARE @JobHistory2 TABLE (id BIGINT, job_number BIGINT, version_date DATETIME, job_status_number INT, job_status NVARCHAR(8), can_be_removed BIT, deleted_date DATETIME)
INSERT INTO @JobHistory2 
	
SELECT 
	ROW_NUMBER() OVER (PARTITION BY job_number ORDER BY job_number, version_date) as id,
	job_number, version_date, job_status_number, job_status,
	CASE WHEN 
		LAG(job_status) OVER(PARTITION BY job_number ORDER BY job_number, version_date) = job_status AND 
		LEAD(job_status) OVER(PARTITION BY job_number ORDER BY job_number, version_date) = job_status
	THEN 1
	ELSE 0
	END as can_be_removed,
	deleted_date
FROM @JobHistory 

INSERT INTO ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Job_Status_History'), ' 
SELECT DISTINCT
	job_number,
	job_status_number,
	job_status,
	CASE WHEN prior_version_date IS NULL THEN first_version_date ELSE version_date END as valid_from_date,
	CASE WHEN next_version_date IS NULL THEN CASE WHEN deleted_date IS NOT NULL THEN deleted_date ELSE DATEADD(YEAR,100,version_date) END ELSE next_version_date END as valid_to_date
FROM
(
	SELECT
		job_number,
		version_date,
		job_status_number,
		job_status,
		deleted_date,
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

EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Jobs Active History
SELECT @TranName = 'Jobs_Active';
BEGIN TRY
	BEGIN TRANSACTION @TranName;
--Clear existing History Table
SET @SqlDeleteCommand = CONCAT('DELETE FROM ',@Reporting_DB_Name,'.dbo.Jobs_Active_History;')
EXECUTE sp_executesql @SqlDeleteCommand;

--Recreate History Table
SET @SqlInsertQuery = CONCAT(N'
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

EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Job Cost Waterfall
SELECT @TranName = 'Job_Cost_Waterfall';
BEGIN TRY
	BEGIN TRANSACTION @TranName;
--Clear existing waterfall Table
SET @SqlDeleteCommand = CONCAT('DELETE FROM ',@Reporting_DB_Name,'.dbo.Job_Cost_Waterfall;')
EXECUTE sp_executesql @SqlDeleteCommand;

--Recreate waterfall table
SET @SqlInsertQuery = CONCAT(N'
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
INNER JOIN ',@Reporting_DB_Name,'.dbo.Jobs jobs on jobs.job_number = a.recnum
LEFT JOIN 
(SELECT 
	jobnum,
	SUM(appamt) as appamt,
	sum(ovhamt) as ovhamt
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg 
WHERE status < 5
GROUP BY jobnum) c on c.jobnum = a.recnum
WHERE jobs.is_deleted = 0

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

EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Ledger Accounts
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
	a.upddte as last_updated_date,
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
SELECT @TranName = 'Ledger_Accounts';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Ledger Transaction Lines
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

SELECT @TranName = 'Ledger_Transaction_Lines';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Payroll Records
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Payroll_Records;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Payroll_Records;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Payroll_Records
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
;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Payroll_Records
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.payroll_record_id NOT IN (SELECT payroll_record_id FROM ',@Reporting_DB_Name,N'.dbo.Payroll_Records)
UNION ALL 
SELECT * FROM #DeletedRecords
')

SELECT @TranName = 'Payroll_Records';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Purchase Orders
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Orders;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Orders;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Purchase_Orders
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.pchtyp pt on pt.recnum = p.ordtyp;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Purchase_Orders
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.purchase_order_id NOT IN (SELECT purchase_order_id FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Orders)
UNION ALL 
SELECT * FROM #DeletedRecords
')

SELECT @TranName = 'Purchase_Orders';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH



--Update Vendor Contacts
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.vndtyp vt on vt.recnum = act.vndtyp;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.vendor_contact_id NOT IN (SELECT vendor_contact_id FROM ',@Reporting_DB_Name,N'.dbo.Vendor_Contacts)
UNION ALL 
SELECT * FROM #DeletedRecords
')

SELECT @TranName = 'Vendor_Contacts';
BEGIN TRY
	BEGIN TRANSACTION @TranName;

	EXECUTE sp_executesql @SqlInsertQuery

	COMMIT TRANSACTION @TranName
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION @TranName
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	SELECT   
	@TranName as Transaction_Name,
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE();  
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); 
END CATCH