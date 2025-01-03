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
if len(sys.argv) < 8:
    logger.error("Usage: python update_table_script.py <CUSTOMER_NAME> <CUSTOMER_DB_NAME> <SQL_SERVER> <SQL_PORT> <SQL_USERNAME> <SQL_PASSWORD>")
    sys.exit(1)

# Extract arguments
CUSTOMER_NAME = sys.argv[1]
CUSTOMER_DB_NAME = sys.argv[2]
SQL_SERVER = sys.argv[3]
SQL_PORT = sys.argv[4]
SQL_USERNAME = sys.argv[5]
SQL_PASSWORD = sys.argv[6]

# Paths to the SQL files
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
sql_file_path = os.path.join(
    base_dir, "SQL Tables", "Update Tables", "Update All Reporting Tables.sql"
)

try:
    # Check if the SQL file exists
    if not os.path.exists(sql_file_path):
        logger.error(f"SQL file not found: {sql_file_path}")
        sys.exit(1)

    logger.info(f"Executing SQL script for customer: {CUSTOMER_NAME}")
    logger.info(f"Using database: {CUSTOMER_DB_NAME}")
    logger.info(f"SQL Server: {SQL_SERVER}, Port: {SQL_PORT}")

    # Command to run sqlcmd
    command = [
        "/opt/mssql-tools/bin/sqlcmd",
        "-S", f"{SQL_SERVER},{SQL_PORT}",  # Server and port
        "-U", SQL_USERNAME,               # Username
        "-P", SQL_PASSWORD,               # Password
        "-i", sql_file_path               # Input file
    ]

    # Run the command and capture output
    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Log the result
    if process.returncode == 0:
        logger.info("SQL script executed successfully.")
        logger.info(f"Output:\n{process.stdout}")
    else:
        logger.error("SQL script execution failed.")
        logger.error(f"Error Output:\n{process.stderr}")

except Exception as e:
    logger.error(f"Error occurred while running the SQL script: {e}")
