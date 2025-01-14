import pyodbc
from faker import Faker
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# Number of rows to generate
num_jobs = 5
num_job_costs_per_job = 2
num_ar_invoices_per_job = 2

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
        "Refused": 2,
        "Bid": 1,
    }
    status = random.choice(list(status_mapping.keys()))
    return status, status_mapping[status]

try:
    # Establish database connection
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Step 1: Populate Jobs
    for job_number in range(3000, num_jobs + 3001):
        # Generate data for Jobs table
        job_name = fake.company()
        job_status, job_status_number = get_job_status()
        client_id = random.randint(1000, 9999)
        client_name = fake.company()
        job_type = random.choice(['Commercial', 'Residential', 'Government'])

        # Populate key fields with meaningful random data
        total_contract_amount = round(random.uniform(100000, 5000000), 2)
        original_budget_amount = round(total_contract_amount * random.uniform(0.8, 1.0), 2)
        total_budget_amount = round(original_budget_amount + random.uniform(10000, 50000), 2)
        invoice_billed = round(total_contract_amount * random.uniform(0.6, 1.0), 2)

        invoice_total = round(invoice_billed * random.uniform(0.8, 1.0), 2)
        invoice_amount_paid = round(invoice_total * random.uniform(0.5, 1.0), 2)
        invoice_sales_tax = round(invoice_total * 0.1, 2)

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
        contract_signed_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        pre_lien_filed_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        project_start_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        project_complete_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        lien_release_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        material_cost = round(random.uniform(500, 10000), 2)
        labor_cost = round(random.uniform(500, 10000), 2)
        equipment_cost = round(random.uniform(500, 10000), 2)
        other_cost = round(random.uniform(500, 10000), 2)
        job_cost_overhead = round(material_cost * 0.1, 2)
        change_order_approved_amount = round(random.uniform(500, 10000), 2)
        retention = round(invoice_total * 0.05, 2)
        invoice_net_due = invoice_total - invoice_amount_paid
        invoice_balance = invoice_total - invoice_amount_paid - retention
        created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        last_updated_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        is_deleted = random.choice([0, 1])
        deleted_date = (
            (datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') if is_deleted else None
        )

        job_insert_sql = """
        INSERT INTO Jobs (
            job_number, job_name, job_status, job_status_number, client_id, client_name, job_type, 
            total_contract_amount, invoice_total, invoice_amount_paid, invoice_sales_tax, supervisor_id, supervisor, 
            salesperson_id, salesperson, estimator_id, estimator, contact, address1, address2, city, state, zip_code, 
            phone_number, job_contact_phone_number, bid_opening_date, plans_received_date, bid_completed_date, 
            contract_signed_date, pre_lien_filed_date, project_start_date, project_complete_date, lien_release_date, 
            material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, change_order_approved_amount, 
            retention, invoice_net_due, invoice_balance, created_date, last_updated_date, is_deleted, deleted_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        cursor.execute(job_insert_sql, (
            job_number, job_name, job_status, job_status_number, client_id, client_name, job_type,
            total_contract_amount, invoice_total, invoice_amount_paid, invoice_sales_tax, supervisor_id, supervisor,
            salesperson_id, salesperson, estimator_id, estimator, contact, address1, address2, city, state, zip_code,
            phone_number, job_contact_phone_number, bid_opening_date, plans_received_date, bid_completed_date,
            contract_signed_date, pre_lien_filed_date, project_start_date, project_complete_date, lien_release_date,
            material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, change_order_approved_amount,
            retention, invoice_net_due, invoice_balance, created_date, last_updated_date, is_deleted, deleted_date
            ))

        # Step 2: Populate Job_Costs for the current job
        for _ in range(num_job_costs_per_job):
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
            cost_amount = round(random.uniform(100.0, 5000.0), 2)
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
                job_number, job_cost_code_name, job_cost_code, work_order_number, transaction_number, 
                job_cost_description, job_cost_source, vendor_id, vendor, cost_type, cost_in_hours, 
                cost_amount, material_cost, labor_cost, equipment_cost, other_cost, subcontract_cost, 
                billing_quantity, billing_amount, overhead_amount, job_cost_status, created_date, 
                last_updated_date, is_deleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            cursor.execute(job_cost_insert_sql, (
                job_number, job_cost_code_name, job_cost_code, work_order_number, transaction_number,
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