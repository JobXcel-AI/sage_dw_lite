--Version 1.0.0
USE [[CLIENT_DB_NAME] Reporting]
GO
--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = '[CLIENT_DB_NAME]';
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlPatchQuery NVARCHAR(MAX);
DECLARE @SqlPatchQuery1 NVARCHAR(MAX);
DECLARE @SqlPatchQuery2 NVARCHAR(MAX);


--Create Updated vw_committed_costs
--Drop view if it exists then create it
SET @SqlPatchQuery = N' 
	IF OBJECT_ID(''[vw_committed_costs]'',''V'') IS NOT NULL
	BEGIN
		DROP VIEW vw_committed_costs;
	END'
EXECUTE sp_executesql @SqlPatchQuery

SET @SqlPatchQuery1 = N' 
DECLARE @NestedSql NVARCHAR(MAX);
DECLARE @NestedSql1 NVARCHAR(MAX);
DECLARE @NestedSql2 NVARCHAR(MAX);
SET @NestedSQL1 = N''
CREATE VIEW vw_committed_costs
AS
SELECT 
	*, 
	CASE 
		WHEN "balance_remaining" < 0 THEN "revised_budget" - "balance_remaining" 
		ELSE "revised_budget" 
	END AS "projected_costs"
FROM (
	SELECT 
		COALESCE("jbl_col_jc_po"."job_number","scl"."job_number") AS "job_number",
		"jbl_col_jc_po"."cost_code_name",
		COALESCE("jbl_col_jc_po"."cost_code","scl"."cost_code") AS "cost_code",
		COALESCE("jbl_col_jc_po"."cost_type","scl"."cost_type") AS "cost_type",
		MAX(ISNULL("jbl_col_jc_po"."budget",0)) AS "budget",
		MAX(ISNULL("jbl_col_jc_po"."approved_change_amount",0)) AS "approved_change_amount",
		MAX(ISNULL("jbl_col_jc_po"."revised_budget",0)) AS "revised_budget",
		MAX(ISNULL("jbl_col_jc_po"."budget_hours",0)) AS "budget_hours",
		MAX(ISNULL("jbl_col_jc_po"."approved_change_hours",0)) AS "approved_change_hours",
		MAX(ISNULL("jbl_col_jc_po"."revised_budget_hours",0)) AS "revised_budget_hours",
		MAX(ISNULL("jbl_col_jc_po"."job_cost_amount",0)) AS "job_cost_amount",
		MAX(ISNULL("jbl_col_jc_po"."committed_po",0)) AS "committed_purchase_orders",
		SUM(ISNULL("scl"."committed_amount",0)) as "committed_subcontracts",
		MAX(ISNULL("jbl_col_jc_po"."revised_budget",0)) - 
			MAX(ISNULL("jbl_col_jc_po"."job_cost_amount",0)) -
			MAX(ISNULL("jbl_col_jc_po"."committed_po",0)) - 
			SUM(ISNULL("scl"."committed_amount",0)) as "balance_remaining"
	FROM (
		SELECT 
			MAX(ISNULL("jbl_col_jc"."approved_change_amount",0)) AS "approved_change_amount",
			MAX(ISNULL("jbl_col_jc"."budget",0)) AS "budget",
			MAX(ISNULL("jbl_col_jc"."revised_budget",0)) AS "revised_budget",
			MAX(ISNULL("jbl_col_jc"."approved_change_hours",0)) AS "approved_change_hours",
			MAX(ISNULL("jbl_col_jc"."budget_hours",0)) AS "budget_hours",
			MAX(ISNULL("jbl_col_jc"."revised_budget_hours",0)) AS "revised_budget_hours",
			"jbl_col_jc"."cost_code_name",
			COALESCE("jbl_col_jc"."cost_code","pol"."cost_code") AS "cost_code",
			COALESCE("jbl_col_jc"."cost_type","pol"."cost_type") AS "cost_type",
			COALESCE("jbl_col_jc"."job_number","pol"."job_number") AS "job_number",
			MAX(ISNULL("jbl_col_jc"."cost_amount",0)) AS "job_cost_amount",
			SUM(ISNULL("pol"."committed_total",0)) AS "committed_po"
		FROM (
			SELECT
				MAX(ISNULL("jbl_col"."approved_change_amount",0)) AS "approved_change_amount",
				MAX(ISNULL("jbl_col"."budget",0)) AS "budget",
				MAX(ISNULL("jbl_col"."revised_budget",0)) AS "revised_budget",
				MAX(ISNULL("jbl_col"."approved_change_hours",0)) AS "approved_change_hours",
				MAX(ISNULL("jbl_col"."budget_hours",0)) AS "budget_hours",
				MAX(ISNULL("jbl_col"."revised_budget_hours",0)) AS "revised_budget_hours",
				COALESCE("jbl_col"."cost_code_name","jc"."job_cost_code_name") AS "cost_code_name",
				COALESCE("jbl_col"."cost_code","jc"."job_cost_code") AS "cost_code",
				COALESCE("jbl_col"."cost_type","jc"."cost_type") AS "cost_type",
				COALESCE("jbl_col"."job_number","jc"."job_number") AS "job_number",
				SUM(ISNULL("jc"."cost_amount",0)) AS "cost_amount"
			FROM
			(
				SELECT
					COALESCE("jbl"."cost_code_name", "co"."cost_code_name") AS "cost_code_name",
					COALESCE("jbl"."cost_code", "co"."cost_code") AS "cost_code",
					COALESCE("jbl"."cost_type", "co"."cost_type") AS "cost_type",
					COALESCE("co"."job_number","jbl"."job_number") AS "job_number",
					MAX(ISNULL("jbl"."budget",0)) AS "budget",
					MAX(ISNULL("jbl"."budget_hours",0)) AS "budget_hours",
''
SET @NestedSql2 = N''
'
SET @SqlPatchQuery2 = N'
					SUM(ISNULL("co"."approved_change_amount",0)) AS "approved_change_amount",
					SUM(ISNULL("co"."approved_change_hours",0)) AS "approved_change_hours",
					MAX(ISNULL("jbl"."budget",0)) + SUM(ISNULL("co"."approved_change_amount",0)) as "revised_budget",
					MAX(ISNULL("jbl"."budget_hours",0)) + SUM(ISNULL("co"."approved_change_hours",0)) as "revised_budget_hours"
				FROM (
					SELECT 
						cost_code_name,
						cost_code,
						cost_type,
						job_number,
						sum(budget) as budget,
						sum(budget_hours) as budget_hours
					FROM "Job_Budget_Lines"
					GROUP BY cost_code_name,
						cost_code,
						cost_type,
						job_number
					) as "jbl"
				FULL JOIN "Change_Order_Lines" AS "co" ON 
					"jbl"."job_number" = "co"."job_number" AND 
					"jbl"."cost_code" = "co"."cost_code" AND
					"jbl"."cost_type" = "co"."cost_type"
				WHERE "co"."status" NOT IN (''''Rejected'''',''''Void'''')
				GROUP BY COALESCE("jbl"."cost_code_name", "co"."cost_code_name"),
					COALESCE("jbl"."cost_code", "co"."cost_code"),
					COALESCE("jbl"."cost_type", "co"."cost_type"),
					COALESCE("co"."job_number","jbl"."job_number")
			) AS "jbl_col"
			FULL JOIN "Job_Cost" AS "jc" ON 
				"jbl_col"."job_number" = "jc"."job_number" AND
				"jbl_col"."cost_code" = "jc"."job_cost_code" AND
				"jbl_col"."cost_Type" = "jc"."cost_type"
			GROUP BY COALESCE("jbl_col"."cost_code_name","jc"."job_cost_code_name"),
				COALESCE("jbl_col"."cost_code","jc"."job_cost_code"),
				COALESCE("jbl_col"."cost_type","jc"."cost_type"),
				COALESCE("jbl_col"."job_number","jc"."job_number")
		) AS "jbl_col_jc"
		FULL JOIN "Purchase_Order_Lines" AS "pol" ON 
			"jbl_col_jc"."job_number" = "pol"."job_number" AND
			"jbl_col_jc"."cost_type" = "pol"."cost_type" AND
			"jbl_col_jc"."cost_code" = "pol"."cost_code"
		GROUP BY "jbl_col_jc"."cost_code_name",
			COALESCE("jbl_col_jc"."cost_code","pol"."cost_code"),
			COALESCE("jbl_col_jc"."cost_type","pol"."cost_type"),
			COALESCE("jbl_col_jc"."job_number","pol"."job_number")
	) AS "jbl_col_jc_po"
	LEFT JOIN "Subcontract_Lines" AS "scl" ON 
		"jbl_col_jc_po"."job_number" = "scl"."job_number" AND
		"jbl_col_jc_po"."cost_code" = "scl"."cost_code" AND 
		"jbl_col_jc_po"."cost_type" = "scl"."cost_type"
	GROUP BY COALESCE("jbl_col_jc_po"."job_number","scl"."job_number"),
		"jbl_col_jc_po"."cost_code_name",
		COALESCE("jbl_col_jc_po"."cost_code","scl"."cost_code"),
		COALESCE("jbl_col_jc_po"."cost_type","scl"."cost_type")
) "source"	
''
SET @NestedSql = @NestedSQL1 + @NestedSQL2
IF (SELECT [Name] FROM [Version]) = ''0.0.0'' 
BEGIN
--SELECT @NestedSQL
EXECUTE sp_executesql @NestedSQL
END
'
SET @SqlPatchQuery = @SqlPatchQuery1 + @SqlPatchQuery2
EXECUTE sp_executesql @SqlPatchQuery
