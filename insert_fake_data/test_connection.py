import pyodbc
from faker import Faker
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# Number of rows to generate
num_rows = 1000

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
connection = pyodbc.connect(connection_string)
cursor = connection.cursor()

# Helper function to generate random dates
def random_date(start, end):
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

# Helper function to map job status to corresponding number
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
    # Step 1: Populate Jobs
    for i in range(3000, num_rows + 3001):
        job_number = i
        job_name = fake.company()
        job_status, job_status_number = get_job_status()
        client_id = random.randint(1000, 9999)
        client_name = fake.company()
        job_type = random.choice(['Commercial', 'Residential', 'Government'])
        contract_amount = round(random.uniform(10000, 500000), 2)
        invoice_total = round(random.uniform(1000, 50000), 2)
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
            contract_amount, invoice_total, invoice_amount_paid, invoice_sales_tax, supervisor_id, supervisor, 
            salesperson_id, salesperson, estimator_id, estimator, contact, address1, address2, city, state, zip_code, 
            phone_number, job_contact_phone_number, bid_opening_date, plans_received_date, bid_completed_date, 
            contract_signed_date, pre_lien_filed_date, project_start_date, project_complete_date, lien_release_date, 
            material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, change_order_approved_amount, 
            retention, invoice_net_due, invoice_balance, created_date, last_updated_date, is_deleted, deleted_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        cursor.execute(job_insert_sql, (
            job_number, job_name, job_status, job_status_number, client_id, client_name, job_type,
            contract_amount, invoice_total, invoice_amount_paid, invoice_sales_tax, supervisor_id, supervisor,
            salesperson_id, salesperson, estimator_id, estimator, contact, address1, address2, city, state, zip_code,
            phone_number, job_contact_phone_number, bid_opening_date, plans_received_date, bid_completed_date,
            contract_signed_date, pre_lien_filed_date, project_start_date, project_complete_date, lien_release_date,
            material_cost, labor_cost, equipment_cost, other_cost, job_cost_overhead, change_order_approved_amount,
            retention, invoice_net_due, invoice_balance, created_date, last_updated_date, is_deleted, deleted_date
        ))

    # Commit all changes
    connection.commit()

except Exception as e:
    print(f"An error occurred: {e}")

finally:
    cursor.close()
    connection.close()