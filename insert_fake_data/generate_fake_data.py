import pyodbc
from faker import Faker
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# Number of rows to generate
num_jobs = 348
num_job_costs_per_job = 27
num_ar_invoices_per_job = 22

# Database connection configuration
db_config = {
    "driver": "ODBC Driver 17 for SQL Server",
    "server": "mike.servernova.net\\SN-33307,49732",
    "database": "SageXcel Demo Reporting",
    "username": "jobxcel",
    "password": "wKif7qZiTxmsWXw.ebL9"
}

# Establish the connection
connection_string = (
    f"DRIVER={db_config['driver']};"
    f"SERVER={db_config['server']};"
    f"DATABASE={db_config['database']};"
    f"UID={db_config['username']};"
    f"PWD={db_config['password']};"
)

# Helper functions
def random_date(start, end):
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

def get_job_status():
    status_mapping = {
        "Closed": 6,
        "Complete": 5,
        "Current": 4,
        "Contract": 3,
        # "Refused": 2,
        # "Bid": 1,
    }
    status = random.choice(list(status_mapping.keys()))
    return status, status_mapping[status]

# Helper function to adjust costs to budget
def adjust_costs_to_budget(material_cost, labor_cost, equipment_cost, other_cost, overhead, budget):
    """Ensure total costs do not exceed the budget."""
    total_cost = material_cost + labor_cost + equipment_cost + other_cost + overhead
    if total_cost > budget:
        scale_factor = budget / total_cost
        material_cost *= scale_factor
        labor_cost *= scale_factor
        equipment_cost *= scale_factor
        other_cost *= scale_factor
        overhead *= scale_factor
        total_cost = material_cost + labor_cost + equipment_cost + other_cost + overhead
    return material_cost, labor_cost, equipment_cost, other_cost, overhead, total_cost


try:
    # Establish database connection
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Step 1: Populate Jobs
    for job_number in range(3000, num_jobs + 3001):
        # Generate data for Jobs table
        job_name = fake.company()
        job_number_job_name = f"{job_number} - {job_name}"
        job_status, job_status_number = get_job_status()
        client_id = random.randint(1000, 9999)
        client_name = fake.company()
        job_type = random.choice(['Commercial', 'Residential', 'Government'])
        supervisor_id = random.randint(1, 100)
        supervisor = fake.name()
        salesperson_id = random.randint(1, 100)
        salesperson = fake.name()
        estimator_id = random.randint(1, 100)
        estimator = fake.name()
        contact = fake.name()
        address1 = fake.street_address()
        address2 = fake.secondary_address()
        city = fake.city()
        state = fake.state_abbr()
        zip_code = fake.zipcode()
        phone_number = fake.phone_number()[:12]
        job_contact_phone_number = fake.phone_number()[:12]
        bid_opening_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        plans_received_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        bid_completed_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')

        # Populate key fields with meaningful random data

        # Contract and Budget
        contract_amount = round(random.uniform(100000, 5000000), 2)
        total_contract_amount = contract_amount
        original_budget_amount = round(total_contract_amount * random.uniform(0.8, 0.95), 2)
        total_budget_amount = round(original_budget_amount + random.uniform(1000, 5000), 2)
        estimated_gross_profit = round(total_contract_amount - total_budget_amount, 2)

        # Invoice Details
        invoice_total = round(total_contract_amount * random.uniform(0.8, 1.4), 2)
        invoice_billed = round(invoice_total * random.uniform(0.61, 1), 2)
        invoice_sales_tax = round(invoice_total * 0.1, 2)
        invoice_amount_paid = round(invoice_total * random.uniform(0.5, 1.0), 2)
        retention = round(invoice_total * 0.05, 2)
        invoice_net_due = round(invoice_total - invoice_amount_paid, 2)
        invoice_balance = round(invoice_total - invoice_amount_paid - retention, 2)
        change_order_approved_amount = round(random.uniform(0, 900), 2)

        # Generate costs
        material_cost = round(random.uniform(0.2, 0.4) * original_budget_amount, 2)
        labor_cost = round(random.uniform(0.3, 0.5) * original_budget_amount, 2)
        equipment_cost = round(random.uniform(0.1, 0.3) * original_budget_amount, 2)
        other_cost = round(random.uniform(0.05, 0.15) * original_budget_amount, 2)
        job_cost_overhead = round((material_cost + labor_cost) * 0.1, 2)

        # Adjust costs to fit budget
        material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, total_cost = adjust_costs_to_budget(
            material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, original_budget_amount
        )

        profit = round(total_contract_amount - total_cost, 2)
        # Ensure profitability 80% of the time
        is_profitable = profit > 0 and random.random() < 0.8
        if not is_profitable:
            # Adjust costs to simulate loss
            total_cost = total_contract_amount + random.uniform(500, 5000)
            profit = round(total_contract_amount - total_cost, 2)
            profit_margin = round(profit / total_contract_amount, 2)

        created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        last_updated_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        is_deleted = random.choice([0, 1])
        deleted_date = (
            (datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') if is_deleted else None
        )
        # Ensure dates are logically consistent
        project_start_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31))
        project_complete_date = random_date(
            project_start_date + timedelta(days=1),
            min(project_start_date + timedelta(days=random.randint(30, 365)), datetime(2024, 12, 31))
        )
        # Ensure contract_signed_date is earlier than or equal to project start date
        contract_signed_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31))
        if contract_signed_date > project_start_date:
            contract_signed_date = project_start_date - timedelta(days=10)

        # Ensure project_complete_date does not exceed the overall limit
        if project_complete_date > datetime(2024, 12, 31):
            project_complete_date = datetime(2024, 12, 31)

        first_date_worked = random_date(
            project_start_date + timedelta(days=1),
            max(project_complete_date - timedelta(days=1), project_start_date + timedelta(days=1))
        )

        last_date_worked = random_date(
            project_start_date + timedelta(days=1),
            max(project_complete_date - timedelta(days=1), project_start_date + timedelta(days=1))
        )

        # Ensure first_date_worked is earlier than or equal to last_date_worked
        if first_date_worked > last_date_worked:
            first_date_worked, last_date_worked = last_date_worked, first_date_worked

        # Handle last_payment_received_date
        start_date = project_complete_date + timedelta(days=1)
        end_date = datetime(2024, 12, 31)
        # Ensure valid range for last_payment_received_date
        if start_date > end_date:
            start_date = end_date  # Adjust start_date to avoid invalid range
        last_payment_received_date = random_date(start_date, end_date).strftime('%Y-%m-%d')

        # Handle pre_lien_filed_date
        start_date = project_complete_date + timedelta(days=60)
        end_date = datetime(2024, 12, 31)
        # Ensure valid range for pre_lien_filed_date
        if start_date > end_date:
            start_date = end_date  # Adjust start_date to avoid invalid range
        pre_lien_filed_date = random_date(start_date, end_date).strftime('%Y-%m-%d')


        # Handle lien_release_date > pre_lien_filed_date
        lien_release_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31))
        if lien_release_date < datetime.strptime(pre_lien_filed_date, '%Y-%m-%d'):
            lien_release_date = datetime.strptime(pre_lien_filed_date, '%Y-%m-%d') + timedelta(days=random.randint(1, 30))
        lien_release_date = lien_release_date.strftime('%Y-%m-%d')

        job_insert_sql = """
            INSERT INTO Jobs (
                job_number_job_name, job_number, job_name, job_status, job_status_number, client_id, client_name, job_type, 
                contract_amount, total_contract_amount, invoice_total, invoice_billed, original_budget_amount, invoice_amount_paid,
                total_budget_amount, estimated_gross_profit, invoice_sales_tax, supervisor_id, supervisor, 
                salesperson_id, salesperson, estimator_id, estimator, contact, address1, address2, city, state, zip_code, 
                phone_number, job_contact_phone_number, bid_opening_date, plans_received_date, bid_completed_date, 
                contract_signed_date, pre_lien_filed_date, project_start_date, project_complete_date, lien_release_date, 
                material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, change_order_approved_amount, 
                retention, invoice_net_due, invoice_balance, created_date, last_updated_date, is_deleted, deleted_date, first_date_worked, last_date_worked, last_payment_received_date
            ) 
            VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
        """

        cursor.execute(job_insert_sql, (
            job_number_job_name, job_number, job_name, job_status, job_status_number, client_id, client_name, job_type,
            contract_amount, total_contract_amount, invoice_total, invoice_billed, original_budget_amount, invoice_amount_paid,
            total_budget_amount, estimated_gross_profit, invoice_sales_tax, supervisor_id, supervisor, salesperson_id, salesperson, estimator_id, estimator,
            contact, address1, address2, city, state, zip_code, phone_number, job_contact_phone_number, bid_opening_date,
            plans_received_date, bid_completed_date, contract_signed_date, pre_lien_filed_date, project_start_date,
            project_complete_date, lien_release_date, material_cost, labor_cost, equipment_cost, other_cost,
            job_cost_overhead, change_order_approved_amount, retention, invoice_net_due, invoice_balance,
            created_date, last_updated_date, is_deleted, deleted_date, first_date_worked, last_date_worked, last_payment_received_date
        ))

        # Step 2: Populate Job_Costs for the current job
        for _ in range(num_job_costs_per_job):
            job_cost_id = random.randint(10000, 99999)
            job_cost_code_name = fake.bs()
            job_cost_code = fake.ean(length=8)
            work_order_number = fake.ean(length=13)
            transaction_number = fake.uuid4()[:10]
            job_cost_description = fake.sentence(nb_words=3)
            job_cost_source = random.choice(["Material", "Labor", "Equipment", "Other"])
            vendor_id = random.randint(1000, 9999)
            vendor = fake.company()
            cost_type = random.choice(["Material", "Labor", "Equipment", "Other"])
            cost_in_hours = round(random.uniform(1, 100), 2)
            cost_amount = round(total_contract_amount * random.uniform((1 /num_job_costs_per_job), (1/(num_job_costs_per_job-3))), 2)
            material_cost = round(cost_amount if cost_type == "Material" else 0, 2)
            labor_cost = round(cost_amount if cost_type == "Labor" else 0, 2)
            equipment_cost = round(cost_amount if cost_type == "Equipment" else 0, 2)
            other_cost = round(cost_amount if cost_type == "Other" else 0, 2)
            subcontract_cost = round(random.uniform(0, 1000), 2)
            billing_quantity = round(random.uniform(1, 20), 2)
            billing_amount = round(random.uniform(500, 10000), 2)
            overhead_amount = round(random.uniform(50, 500), 2)
            job_cost_status = random.choice(["Open", "Void"])
            created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            last_updated_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            is_deleted = 0

            job_cost_insert_sql = """
            INSERT INTO Job_Cost (
                job_number, job_cost_id, job_name, job_status, job_cost_code_name, job_cost_code, work_order_number, transaction_number, 
                job_cost_description, job_cost_source, vendor_id, vendor, cost_type, cost_in_hours, 
                cost_amount, material_cost, labor_cost, equipment_cost, other_cost, subcontract_cost, 
                billing_quantity, billing_amount, overhead_amount, job_cost_status, created_date, 
                last_updated_date, is_deleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?)
            """
            cursor.execute(job_cost_insert_sql, (
                job_number, job_cost_id, job_name, job_status, job_cost_code_name, job_cost_code, work_order_number, transaction_number,
                job_cost_description, job_cost_source, vendor_id, vendor, cost_type, cost_in_hours,
                cost_amount, material_cost, labor_cost, equipment_cost, other_cost, subcontract_cost,
                billing_quantity, billing_amount, overhead_amount, job_cost_status, created_date,
                last_updated_date, is_deleted
            ))

        # Step 3: Populate AR_Invoices for the current job
        for _ in range(num_ar_invoices_per_job):
            ar_invoice_id = random.randint(10000, 99999)
            ar_invoice_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
            ar_invoice_description = fake.text(max_nb_chars=50)
            ar_invoice_number = f"INV-{random.randint(100000, 999999)}"
            ar_invoice_status = random.choice(['Paid', 'Unpaid', 'Overdue'])
            ar_invoice_total = round(random.uniform(1000, 50000), 2)
            ar_invoice_sales_tax = round(ar_invoice_total * 0.1, 2)
            ar_invoice_amount_paid = round(ar_invoice_total * random.uniform(0.0, 1.0), 2)
            ar_invoice_balance = ar_invoice_total - ar_invoice_amount_paid
            ar_invoice_due_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
            created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            last_updated_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            is_deleted = 0

            ar_invoice_insert_sql = """
            INSERT INTO AR_Invoices (
                job_number, ar_invoice_id, ar_invoice_date, ar_invoice_description, ar_invoice_number, 
                ar_invoice_status, ar_invoice_total, ar_invoice_sales_tax, ar_invoice_amount_paid, 
                ar_invoice_balance, ar_invoice_due_date, created_date, last_updated_date, is_deleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            cursor.execute(ar_invoice_insert_sql, (
                job_number, ar_invoice_id, ar_invoice_date, ar_invoice_description, ar_invoice_number,
                ar_invoice_status, ar_invoice_total, ar_invoice_sales_tax, ar_invoice_amount_paid,
                ar_invoice_balance, ar_invoice_due_date, created_date, last_updated_date, is_deleted
            ))

    # Commit all changes
    conn.commit()
    print("Jobs, Job_Cost, and AR_Invoices data successfully inserted into the database.")

except Exception as e:
    print(f"An error occurred: {e}")

finally:
    # Close the connection
    if conn:
        conn.close()