--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlInsertQuery NVARCHAR(MAX);

--Update Change_Order_Lines Table
SET @SqlInsertQuery = CONCAT(
--Step 1. Temp table containing reporting table
N'SELECT * INTO #TempTbl FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines;
SELECT * INTO #DeletedRecords FROM #TempTbl WHERE is_deleted = 1;
DELETE FROM #TempTbl WHERE is_deleted = 1;
ALTER TABLE #TempTbl
DROP COLUMN IF EXISTS is_deleted, deleted_date;',
--Step 2. delete existing reporting table data and replace with updated values
'DELETE FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines;
INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines
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
	s.cstcde as cost_code,	
	s.total_change_amount,
	s.material, 
	s.other, 
	s.subcontract, 
	s.equipment,
	s.labor,
	s.user_defined6,
	s.user_defined7,
	s.user_defined8,
	s.user_defined9,
	c.insdte as created_date,
	c.upddte as last_updated_date,
	0 as is_deleted,
	null as deleted_date
FROM ',QUOTENAME(@Client_DB_Name),'.dbo.prmchg c
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.actrec a on a.recnum = c.jobnum
LEFT JOIN ',QUOTENAME(@Client_DB_Name),'.dbo.chgtyp ct on ct.recnum = c.chgtyp
LEFT JOIN (
	SELECT 
	recnum, 
	cstcde, 
	SUM(Material) as material, 
	SUM(Other) as other, 
	SUM(Subcontract) as subcontract, 
	SUM(Equipment) as equipment,
	SUM(Labor) as labor,
	SUM(user_defined6) as user_defined6,
	SUM(user_defined7) as user_defined7,
	SUM(user_defined8) as user_defined8,
	SUM(user_defined9) as user_defined9,
	SUM(Material) + SUM(Other) + SUM(Subcontract) + SUM(Equipment) + SUM(Labor) + SUM(user_defined6) + SUM(user_defined7) + SUM(user_defined8) + SUM(user_defined9) as total_change_amount
	FROM (
		SELECT
		recnum, 
		ISNULL(cstcde,0) as cstcde,
		CASE WHEN csttyp = 1 THEN SUM(bdgprc) ELSE 0 END as Material,
		CASE WHEN csttyp = 2 THEN SUM(bdgprc) ELSE 0 END as Labor,
		CASE WHEN csttyp = 3 THEN SUM(bdgprc) ELSE 0 END as Equipment,
		CASE WHEN csttyp = 4 THEN SUM(bdgprc) ELSE 0 END as Subcontract,
		CASE WHEN csttyp = 5 THEN SUM(bdgprc) ELSE 0 END as Other,
		CASE WHEN csttyp = 6 THEN SUM(bdgprc) ELSE 0 END as user_defined6,
		CASE WHEN csttyp = 7 THEN SUM(bdgprc) ELSE 0 END as user_defined7,
		CASE WHEN csttyp = 8 THEN SUM(bdgprc) ELSE 0 END as user_defined8,
		CASE WHEN csttyp = 9 THEN SUM(bdgprc) ELSE 0 END as user_defined9
		FROM ',QUOTENAME(@Client_DB_Name),'.dbo.sbcgln 
		GROUP BY recnum, ISNULL(cstcde,0), csttyp
  ) s2 
  group by recnum, cstcde
) s ON c.recnum = s.recnum
;',
--Step 3. Find any values in Temp Table not in Reporting Table, insert them as records flagged as deleted
'INSERT INTO ',@Reporting_DB_Name,N'.dbo.Change_Orders
SELECT *, 
	1 as is_deleted,
	GETDATE() as deleted_date
FROM #TempTbl t 
WHERE t.change_order_id NOT IN (SELECT change_order_id FROM ',@Reporting_DB_Name,N'.dbo.Change_Order_Lines)
UNION ALL 
SELECT * FROM #DeletedRecords
')
EXECUTE sp_executesql @SqlInsertQuery