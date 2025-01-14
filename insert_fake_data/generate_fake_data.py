import pyodbc
from faker import Faker
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# Number of rows to generate
num_jobs = 55
num_job_costs_per_job = 12
num_ar_invoices_per_job = 12

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
        job_number_job_name = f"{job_number} - {job_name}"
        job_status, job_status_number = get_job_status()
        client_id = random.randint(1000, 9999)
        client_name = fake.company()
        job_type = random.choice(['Commercial', 'Residential', 'Government'])

        # Contract and budget details
        total_contract_amount = round(random.uniform(100000, 5000000), 2)
        original_budget_amount = round(total_contract_amount * random.uniform(0.7, 0.9), 2)
        total_budget_amount = round(original_budget_amount + random.uniform(10000, 50000), 2)
        estimated_gross_profit = round(total_contract_amount - total_budget_amount, 2)

        # Percent Complete based on random progress
        percent_complete = round(random.uniform(0.05, 1.0), 2)  # 5% to 100% progress
        costs = round(original_budget_amount * percent_complete, 2)
        billed = round(total_contract_amount * percent_complete, 2)

        # Earned Revenue calculation
        earned_revenue = round(total_contract_amount * percent_complete, 2)

        # Overbilled and underbilled calculation
        overbilled = max(0, billed - earned_revenue)
        underbilled = max(0, earned_revenue - billed)

        # Other financial details
        invoice_total = round(billed * 1.05, 2)  # Include retention
        invoice_amount_paid = round(invoice_total * random.uniform(0.5, 1.0), 2)
        retention = round(invoice_total * 0.05, 2)

        # Costs
        cost_of_revenue = costs
        gross_profit = round(earned_revenue - cost_of_revenue, 2)

        # Dates
        project_start_date = random_date(datetime(2022, 1, 1), datetime(2024, 12, 31))
        project_complete_date = random_date(
            project_start_date + timedelta(days=1),
            min(project_start_date + timedelta(days=random.randint(30, 365)), datetime(2024, 12, 31))
        )

        # Job insertion
        job_insert_sql = """
            INSERT INTO Jobs (
                job_number_job_name, job_number, job_name, job_status, job_status_number, client_id, client_name, job_type, 
                total_contract_amount, original_budget_amount, total_budget_amount, estimated_gross_profit, 
                percent_complete, billed, costs, earned_revenue, overbilled, underbilled, 
                project_start_date, project_complete_date
            ) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        cursor.execute(job_insert_sql, (
            job_number_job_name, job_number, job_name, job_status, job_status_number, client_id, client_name, job_type,
            total_contract_amount, original_budget_amount, total_budget_amount, estimated_gross_profit,
            percent_complete, billed, costs, earned_revenue, overbilled, underbilled,
            project_start_date, project_complete_date
        ))

        # Step 2: Populate Job_Costs for the current job
        for _ in range(num_job_costs_per_job):
            job_cost_id = random.randint(10000, 99999)
            cost_type = random.choice(["Material", "Labor", "Equipment", "Other"])
            cost_amount = round(costs / num_job_costs_per_job, 2)

            job_cost_insert_sql = """
                INSERT INTO Job_Cost (
                    job_number, job_cost_id, cost_type, cost_amount
                ) 
                VALUES (?, ?, ?, ?)
            """
            cursor.execute(job_cost_insert_sql, (job_number, job_cost_id, cost_type, cost_amount))

        # Step 3: Populate AR_Invoices for the current job
        for _ in range(num_ar_invoices_per_job):
            ar_invoice_id = random.randint(10000, 99999)
            ar_invoice_total = round(billed / num_ar_invoices_per_job, 2)

            ar_invoice_insert_sql = """
                INSERT INTO AR_Invoices (
                    job_number, ar_invoice_id, ar_invoice_total
                ) 
                VALUES (?, ?, ?)
            """
            cursor.execute(ar_invoice_insert_sql, (job_number, ar_invoice_id, ar_invoice_total))

    # Commit all changes
    conn.commit()
    print("Jobs, Job_Cost, and AR_Invoices data successfully inserted into the database.")

except Exception as e:
    print(f"An error occurred: {e}")

finally:
    # Close the connection
    if conn:
        conn.close()