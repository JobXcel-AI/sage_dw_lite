import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os
import sys

# Configure rolling log file with a retention of 5 days
log_file_path = os.path.join(os.path.dirname(__file__), "update_table_script.log")
file_handler = TimedRotatingFileHandler(
    log_file_path, when="midnight", interval=1, backupCount=5
)
formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
file_handler.setFormatter(formatter)

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)

# Also log to console
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# Ensure required arguments are passed
if len(sys.argv) < 3:
    logger.error("Usage: python update_table_script.py <CUSTOMER_NAME> <CUSTOMER_DB_NAME>")
    sys.exit(1)

# Extract arguments
CUSTOMER_NAME = sys.argv[1]
CUSTOMER_DB_NAME = sys.argv[2]

# Paths to the SQL files
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
sql_file_path = os.path.join(
    base_dir, "SQL Tables", "Update Tables", "Update All Reporting Tables.sql"
)
modified_sql_file_path = os.path.join(
    base_dir, "SQL Tables", "Update Tables", "temp_Update_All_Reporting_Tables.sql"
)

# Placeholder replacements
client_db_placeholder = "[CLIENT_DB_NAME]"

try:
    # Read and modify the SQL file
    logger.info(f"Processing SQL script for customer: {CUSTOMER_NAME}")
    with open(sql_file_path, "r") as file:
        sql_content = file.read()
    
    # Ensure the placeholder is matched exactly
    if client_db_placeholder not in sql_content:
        logger.error(f"Placeholder {client_db_placeholder} not found in {sql_file_path}.")
        sys.exit(1)

    # Replace placeholders with actual values
    modified_sql_content = sql_content.replace(client_db_placeholder, f"'{CUSTOMER_DB_NAME}'")

    logger.info("Original SQL content:")
    logger.info(sql_content)

    logger.info("Modified SQL content:")
    logger.info(modified_sql_content)

    # Save the modified SQL file
    with open(modified_sql_file_path, "w") as file:
        file.write(modified_sql_content)

    logger.info(f"SQL script modified for customer: {CUSTOMER_NAME}")

    # Command to run sqlcmd
    command = [
        "/opt/mssql-tools/bin/sqlcmd",  # Full path to sqlcmd
        "-S", "206.71.70.82,50285",  # Server and port
        "-U", "jobxcel",              # Username
        "-P", "qn_uJYszjd4NCJuBcwFB", # Password
        "-i", modified_sql_file_path  # Input file
    ]

    logger.info("Executing SQL script using sqlcmd...")
    # Run the command and capture output
    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Log the output and errors
    if process.returncode == 0:
        logger.info("SQL script executed successfully.")
        logger.info(f"Output:\n{process.stdout}")
    else:
        logger.error("SQL script execution failed.")
        logger.error(f"Error Output:\n{process.stderr}")

except Exception as e:
    logger.error(f"Error occurred while running the SQL script: {e}")

finally:
    # Clean up the temporary modified file
    if os.path.exists(modified_sql_file_path):
        os.remove(modified_sql_file_path)
        logger.info(f"Temporary modified SQL file removed for customer: {CUSTOMER_NAME}")
