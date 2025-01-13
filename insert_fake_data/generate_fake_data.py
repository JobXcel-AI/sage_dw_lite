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

# SQL insert statement template
insert_sql = """
INSERT INTO AR_Invoices (
  job_number, job_name, job_phone_number, job_notes, job_address1, job_address2, job_city, job_state, job_zip_code,
  job_tax_district, job_type, job_status, ar_invoice_id, ar_invoice_date, ar_invoice_description, ar_invoice_number,
  ar_invoice_status, ar_invoice_tax_district, tax_entity1, tax_entity1_rate, tax_entity2, tax_entity2_rate,
  ar_invoice_due_date, ar_invoice_total, ar_invoice_sales_tax, ar_invoice_amount_paid, ar_invoice_balance,
  ar_invoice_retention, ar_invoice_type, client_name, job_supervisor, job_salesperson,
  ar_invoice_payments_payment_amount, ar_invoice_payments_discount_taken, ar_invoice_payments_credit_taken,
  last_payment_received_date, last_date_worked, created_date, last_updated_date, is_deleted, deleted_date
) VALUES (
  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
)
"""

# Helper function to generate random dates
def random_date(start, end):
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

try:
    # Generate and insert rows
    for i in range(1, num_rows + 1):
        job_number = i
        job_name = fake.company()
        job_phone_number = fake.phone_number()[:12]
        job_notes = fake.sentence()
        job_address1 = fake.street_address()
        job_address2 = fake.secondary_address()
        job_city = fake.city()
        job_state = fake.state_abbr()
        job_zip_code = fake.zipcode()
        job_tax_district = f"{job_state} District {random.randint(1, 5)}"
        job_type = random.choice(['Commercial', 'Residential', 'Government'])
        job_status = random.choice(['Complete', 'Current', 'Pending'])
        ar_invoice_id = random.randint(10000, 99999)
        ar_invoice_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        ar_invoice_description = fake.text(max_nb_chars=50)
        ar_invoice_number = f"INV-{random.randint(100000, 999999)}"
        ar_invoice_status = random.choice(['Paid', 'Unpaid', 'Overdue'])
        ar_invoice_tax_district = f"{job_state} District {random.randint(1, 5)}"
        tax_entity1 = fake.company()
        tax_entity1_rate = round(random.uniform(0.05, 0.10), 2)
        tax_entity2 = fake.company()
        tax_entity2_rate = round(random.uniform(0.05, 0.10), 2)
        ar_invoice_due_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        ar_invoice_total = round(random.uniform(1000, 50000), 2)
        ar_invoice_sales_tax = round(ar_invoice_total * 0.1, 2)
        ar_invoice_amount_paid = round(ar_invoice_total * random.uniform(0.0, 1.0), 2)
        ar_invoice_balance = ar_invoice_total - ar_invoice_amount_paid
        ar_invoice_retention = round(random.uniform(0, 500), 2)
        ar_invoice_type = random.choice(['Contract', 'T&M', 'Other'])
        client_name = fake.company()
        job_supervisor = fake.name()
        job_salesperson = fake.name()
        ar_invoice_payments_payment_amount = round(ar_invoice_total * random.uniform(0.0, 0.9), 2)
        ar_invoice_payments_discount_taken = round(random.uniform(0, 100), 2)
        ar_invoice_payments_credit_taken = round(random.uniform(0, 50), 2)
        last_payment_received_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        last_date_worked = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31)).strftime('%Y-%m-%d')
        created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        last_updated_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        is_deleted = random.choice([0, 1])
        deleted_date = (
            (datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') if is_deleted else None
        )

        parameters = (
            job_number, job_name, job_phone_number, job_notes, job_address1, job_address2, job_city, job_state, job_zip_code,
            job_tax_district, job_type, job_status, ar_invoice_id, ar_invoice_date, ar_invoice_description, ar_invoice_number,
            ar_invoice_status, ar_invoice_tax_district, tax_entity1, tax_entity1_rate, tax_entity2, tax_entity2_rate,
            ar_invoice_due_date, ar_invoice_total, ar_invoice_sales_tax, ar_invoice_amount_paid, ar_invoice_balance,
            ar_invoice_retention, ar_invoice_type, client_name, job_supervisor, job_salesperson,
            ar_invoice_payments_payment_amount, ar_invoice_payments_discount_taken, ar_invoice_payments_credit_taken,
            last_payment_received_date, last_date_worked, created_date, last_updated_date, is_deleted,
            deleted_date
        )

        cursor.execute(insert_sql, parameters)

    # Commit changes
    connection.commit()

except Exception as e:
    # Print parameters and the error message
    print(f"An error occurred: {e}")
    print("Parameters:", parameters)

finally:
    # Close the cursor and connection
    cursor.close()
    connection.close()