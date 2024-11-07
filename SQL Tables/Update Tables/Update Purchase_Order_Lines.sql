--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

--Update Purchase_Orders Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines
SELECT
	p.recnum as purchase_order_id,
	l.linnum as purchase_order_line_number,
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
	l.cstcde as cost_code,
	l.typnme as cost_type,
	CASE WHEN p.status != 5 THEN ISNULL(l.committed_total,0) ELSE 0 END as committed_total,
	ISNULL(l.total,0) as total,
	ISNULL(l.price,0) as price,
	ISNULL(l.quantity,0) as quantity,
	ISNULL(l.received_to_date,0) as received_to_date,
	ISNULL(l.canceled,0) as canceled,
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
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.pchtyp pt on pt.recnum = p.ordtyp
LEFT JOIN (
	SELECT 
	pl.recnum,
	pl.linnum,
	cstcde,
	typnme,
	SUM(linprc) * (SUM(linqty) - SUM(rcvdte) - SUM(cancel)) as committed_total,
	SUM(extttl) as total,
	SUM(linprc) as price,
	SUM(linqty) as quantity,
	SUM(rcvdte) as received_to_date,
	SUM(cancel) as canceled 
	FROM ',QUOTENAME(@Client_DB_Name),'.dbo.pcorln pl
	LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.csttyp c on c.recnum = pl.csttyp
	GROUP BY pl.recnum, pl.linnum, cstcde, typnme
) l on l.recnum = p.recnum 
;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.purchase_order_id NOT IN (SELECT purchase_order_id FROM ',@Reporting_DB_Name,N'.dbo.Purchase_Order_Lines)
UNION ALL 
SELECT * FROM #DeletedRecords
')
EXECUTE sp_executesql @SqlInsertQuery