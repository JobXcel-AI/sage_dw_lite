--Version 1.0.1

-- Specify Rollup DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = 'SageXcel Rollup Reporting';

-- Create DB SQL Command
DECLARE @SqlCommand NVARCHAR(MAX);
SET @SqlCommand = CONCAT(
        N'CREATE DATABASE ', QUOTENAME(@Reporting_DB_Name), ';',

    -- Ensure AUTO_SHRINK is enabled
        'ALTER DATABASE ', QUOTENAME(@Reporting_DB_Name), ' SET AUTO_SHRINK ON;',

    -- Ensure database recovery model is FULL (to enable transaction logging)
        'ALTER DATABASE ', QUOTENAME(@Reporting_DB_Name), ' SET RECOVERY FULL;'
);

-- Execute the SQL Command
USE master;
EXEC sp_executesql @SqlCommand;



-- Sql Create Table Command
DECLARE @SqlCreateTableCommand NVARCHAR(MAX);

SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name), '.dbo.', QUOTENAME('AR_Invoices'), '(
    db_source NVARCHAR(100),
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
    last_date_worked DATE,
    created_date DATETIME,
    last_updated_date DATETIME,
    is_deleted BIT DEFAULT 0,
    deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Change_Orders'), '(
	db_source NVARCHAR(100),
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
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Employees'), '(
	db_source NVARCHAR(100),
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


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Inventory'), '(
	db_source NVARCHAR(100),
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



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Job_Cost'), '(
	db_source NVARCHAR(100),
	job_cost_id BIGINT,
	job_number BIGINT,
	job_name NVARCHAR(75),
	job_status NVARCHAR(8),
	job_cost_code_name NVARCHAR(50),
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
	subcontract_cost DECIMAL(12,2),
	billing_quantity DECIMAL(7,2),
	billing_amount DECIMAL(12,2),
	overhead_amount DECIMAL(12,2),
	job_cost_status NVARCHAR(4),
	supervisor_id BIGINT,
	supervisor NVARCHAR(100),
	salesperson_id BIGINT,
	salesperson NVARCHAR(100),
	estimator_id BIGINT,	
	estimator NVARCHAR(100), 
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Ledger_Accounts'), '(
	db_source NVARCHAR(100),
	ledger_account_id BIGINT,
	ledger_account NVARCHAR(50),
	subsidiary_type NVARCHAR(12),
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


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Purchase_Orders'), '(
	db_source NVARCHAR(100),
	purchase_order_id BIGINT,
	purchase_order_number NVARCHAR(20),
	purchase_order_description NVARCHAR(50),
	purchase_order_date DATE,
	delivery_date DATE,
	purchase_order_type NVARCHAR(50),
	purchase_order_status NVARCHAR(7),
	equipment NVARCHAR(50),
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


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Vendor_Contacts'), '(
	db_source NVARCHAR(100),
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


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Jobs'), '(
	db_source NVARCHAR(100),
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
	first_date_worked DATE,
	last_date_worked DATE,
	invoice_billed DECIMAL(14,2), 
	job_number_job_name NVARCHAR(100), 
	total_contract_amount DECIMAL(14,2),
	original_budget_amount DECIMAL(14,2),
	total_budget_amount DECIMAL(14,2),
	estimated_gross_profit DECIMAL(14,2),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Job_Cost_Waterfall'), '(
	db_source NVARCHAR(100),
	job_number BIGINT,	
	waterfall_category NVARCHAR(50),
	waterfall_value DECIMAL(14,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Ledger_Transaction_Lines'), '(
	db_source NVARCHAR(100),
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
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand

SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Payroll_Records'), '(
	db_source NVARCHAR(100),
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
	comp_type NVARCHAR(50),
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

SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Job_Status_History'), '(
	db_source NVARCHAR(100),
	job_number BIGINT,
	job_status_number INT,
	job_status NVARCHAR(8),
	valid_from_date DATETIME,
	valid_to_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Jobs_Active_History'), '(
	db_source NVARCHAR(100),
	job_active_date DATETIME,
	job_number BIGINT
)')

EXECUTE sp_executesql @SqlCreateTableCommand



--Sql Create Table Command
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Change_Order_History'), '(
	db_source NVARCHAR(100),
	record_number BIGINT,
	job_number BIGINT,
	change_order_status_number INT,
	change_order_status NVARCHAR(8),
	valid_from_date DATETIME,
	valid_to_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Change_Order_Open_History'), '(
	db_source NVARCHAR(100),
	change_order_open_date DATETIME,
	record_number BIGINT,
	job_number BIGINT
)')

EXECUTE sp_executesql @SqlCreateTableCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Purchase_Order_Lines'), '(
	db_source NVARCHAR(100),
	purchase_order_id BIGINT,
	purchase_order_line_number INT,
	purchase_order_number NVARCHAR(20),
	purchase_order_description NVARCHAR(50),
	purchase_order_date DATE,
	delivery_date DATE,
	purchase_order_type NVARCHAR(50),
	purchase_order_status NVARCHAR(7),
	equipment NVARCHAR(50),
	cost_code NVARCHAR(50),
	cost_type NVARCHAR(30),
	committed_total DECIMAL(12,2),
	total DECIMAL(12,2),
	price DECIMAL(12,2),
	quantity DECIMAL(12,2),
	received_to_date DECIMAL(12,2),
	canceled DECIMAL(12,2),
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


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Change_Order_Lines'), '(
	db_source NVARCHAR(100),
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
	cost_code NVARCHAR(50),
	cost_code_name NVARCHAR(50),
	cost_type NVARCHAR(30),
	approved_change_amount DECIMAL(12,2),
	change_amount DECIMAL(12,2),
	approved_change_hours DECIMAL(12,2),
	approved_change_units DECIMAL(10,4),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand



SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Subcontract_Lines'), '(
	db_source NVARCHAR(100),
	subcontract_id BIGINT,
	subcontract_number NVARCHAR(20),
	subcontract_date DATE,
	scheduled_start_date DATE,
	scheduled_finish_date DATE,
	actual_start_date DATE,
	actual_finish_date DATE,
	subcontract_status NVARCHAR(8),
	job_number BIGINT,
	cost_code NVARCHAR(50),
	cost_type NVARCHAR(30),
	committed_amount DECIMAL(12,2),
	remaining_amount DECIMAL(12,2),
	hot_list BIT,
	vendor_id BIGINT,
	vendor_name NVARCHAR(75),
	vendor_account_number NVARCHAR(30),
	vendor_type NVARCHAR(50),
	vendor_email NVARCHAR(75),
	vendor_phone_number NVARCHAR(14),
	created_date DATETIME,
	last_updated_date DATETIME,
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Job_Budget_Lines'), '(
	db_source NVARCHAR(100),
	job_number BIGINT,
	cost_code NVARCHAR(50),
	cost_code_name NVARCHAR(50),
	cost_type NVARCHAR(30),
	budget DECIMAL(12,2),
	budget_hours DECIMAL(12,2)
)')

EXECUTE sp_executesql @SqlCreateTableCommand


SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ', QUOTENAME(@Reporting_DB_Name),'.dbo.',QUOTENAME('Timecards'), '(
	db_source NVARCHAR(100),
	payroll_record_id BIGINT,
	timecard_line_number BIGINT,
	employee_id BIGINT,
	employee_full_name NVARCHAR(100),
	employee_status NVARCHAR(12),
	check_number NVARCHAR(20),
	check_date DATE,
	period_start DATE,
	period_end DATE,
	date_worked DATE,
	day_worked NVARCHAR(10),
	description NVARCHAR(50),
	service_order_number NVARCHAR(20),
	service_order_invoice_number NVARCHAR(20),
	client_id BIGINT,
	client_name NVARCHAR(100),
	job_number BIGINT,
	job_name NVARCHAR(100),
	job_status NVARCHAR(8),
	job_status_number INT,
	job_type NVARCHAR(50),
	equipment_number_repaired BIGINT,
	equipment_name_repaired NVARCHAR(100),
	job_phase_number INT,
	job_phase_name NVARCHAR(50),
	cost_code_number DECIMAL(11,3),
	cost_code_name NVARCHAR(50),
	pay_type_number INT,
	pay_type_name NVARCHAR(9),
	pay_group_number INT,
	pay_group_name NVARCHAR(50),
	pay_rate DECIMAL(9,4),
	hours_worked DECIMAL(7,2),
	comp_code BIGINT,
	workers_compensation_name NVARCHAR(50),
	department_id BIGINT,
	department_name NVARCHAR(50),
	is_deleted BIT DEFAULT 0,
	deleted_date DATETIME
)')

EXECUTE sp_executesql @SqlCreateTableCommand


SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N';
SELECT * INTO dbo.Weekly_Snapshot_Jobs FROM dbo.Jobs;
DELETE FROM dbo.Weekly_Snapshot_Jobs;
ALTER TABLE dbo.Weekly_Snapshot_Jobs ADD snapshot_date DATETIME;';

EXECUTE sp_executesql @SqlCreateTableCommand

-- Build the dynamic SQL string
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' + -- Switch to the target DB
        N'SELECT * INTO dbo.' + QUOTENAME('Weekly_Snapshot_AR_Invoices') + N'
FROM dbo.' + QUOTENAME('AR_Invoices') + N'; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Weekly_Snapshot_AR_Invoices') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Weekly_Snapshot_AR_Invoices') + N'
ADD snapshot_date DATETIME;';

EXECUTE sp_executesql @SqlCreateTableCommand

-- Build the SQL command dynamically
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' +  -- Switch to the correct database
        N'SELECT * INTO dbo.' + QUOTENAME('Weekly_Snapshot_Job_Cost') + N'
FROM dbo.' + QUOTENAME('Job_Cost') + N'; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Weekly_Snapshot_Job_Cost') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Weekly_Snapshot_Job_Cost') + N'
ADD snapshot_date DATETIME;';

EXECUTE sp_executesql @SqlCreateTableCommand

-- Process Weekly_Snapshot_Change_Orders
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' +
        N'SELECT * INTO dbo.' + QUOTENAME('Weekly_Snapshot_Change_Orders') + N'
FROM dbo.' + QUOTENAME('Change_Orders') + N'; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Weekly_Snapshot_Change_Orders') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Weekly_Snapshot_Change_Orders') + N'
ADD snapshot_date DATETIME;';

EXEC sp_executesql @SqlCreateTableCommand;

-- Process Monthly_Snapshot_Jobs
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' +
        N'SELECT * INTO dbo.' + QUOTENAME('Monthly_Snapshot_Jobs') + N'
FROM dbo.Jobs; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Monthly_Snapshot_Jobs') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Monthly_Snapshot_Jobs') + N'
ADD snapshot_date DATETIME;';

EXEC sp_executesql @SqlCreateTableCommand;

-- Process Monthly_Snapshot_AR_Invoices
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' +
        N'SELECT * INTO dbo.' + QUOTENAME('Monthly_Snapshot_AR_Invoices') + N'
FROM dbo.' + QUOTENAME('AR_Invoices') + N'; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Monthly_Snapshot_AR_Invoices') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Monthly_Snapshot_AR_Invoices') + N'
ADD snapshot_date DATETIME;';

EXEC sp_executesql @SqlCreateTableCommand;

-- Process Monthly_Snapshot_Job_Cost
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' +
        N'SELECT * INTO dbo.' + QUOTENAME('Monthly_Snapshot_Job_Cost') + N'
FROM dbo.' + QUOTENAME('Job_Cost') + N'; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Monthly_Snapshot_Job_Cost') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Monthly_Snapshot_Job_Cost') + N'
ADD snapshot_date DATETIME;';

EXEC sp_executesql @SqlCreateTableCommand;

-- Process Monthly_Snapshot_Change_Orders
SET @SqlCreateTableCommand =
        N'USE ' + QUOTENAME(@Reporting_DB_Name) + N'; ' +
        N'SELECT * INTO dbo.' + QUOTENAME('Monthly_Snapshot_Change_Orders') + N'
FROM dbo.' + QUOTENAME('Change_Orders') + N'; ' +
        N'DELETE FROM dbo.' + QUOTENAME('Monthly_Snapshot_Change_Orders') + N'; ' +
        N'ALTER TABLE dbo.' + QUOTENAME('Monthly_Snapshot_Change_Orders') + N'
ADD snapshot_date DATETIME;';

EXEC sp_executesql @SqlCreateTableCommand;

--Sql Create Ledger_Accounts_by_Month
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.',QUOTENAME('Ledger_Accounts_by_Month'), '(
	db_source NVARCHAR(100),
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

--Create Version Table
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.[Version] (
	db_source NVARCHAR(100),
	name NVARCHAR(10),
	update_date DATETIME NOT NULL DEFAULT GETDATE(),
	update_user CHAR(50) NOT NULL DEFAULT CURRENT_USER
	);
')

EXECUTE sp_executesql @SqlCreateTableCommand

--Create Update Log Table
SET @SqlCreateTableCommand = CONCAT(N'
CREATE TABLE ',@Reporting_DB_Name,'.dbo.[Update_Log] (
	db_source NVARCHAR(100),
	version_name NVARCHAR(10),
	run_date DATETIME NOT NULL DEFAULT GETDATE(),
	update_user CHAR(50) NOT NULL DEFAULT CURRENT_USER
	);
')

EXECUTE sp_executesql @SqlCreateTableCommand


