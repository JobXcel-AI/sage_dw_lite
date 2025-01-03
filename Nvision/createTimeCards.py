import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os

# Configure rolling log file with a retention of 5 days
log_file_path = os.path.join(os.path.dirname(__file__), "create_timecards_table.log")
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

# Hardcoded values for one-time run
CUSTOMER_NAME = "Nvision"
CUSTOMER_DB_NAME = "Nvision"

# Path to the SQL file
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
sql_file_path = os.path.join(
    base_dir, "SQL Tables", "Create Tables", "Create Timecards Table.sql"
)

try:
    # Check if the SQL file exists
    if not os.path.exists(sql_file_path):
        logger.error(f"SQL file not found: {sql_file_path}")
        exit(1)

    logger.info(f"Creating Timecards Table for customer: {CUSTOMER_NAME}")
    logger.info(f"SQL script path: {sql_file_path}")

    # Command to run sqlcmd
    command = [
        "/opt/mssql-tools/bin/sqlcmd",  # Full path to sqlcmd
        "-S", "206.71.70.82,50285",  # Server and port
        "-U", "jobxcel",              # Username
        "-P", "qn_uJYszjd4NCJuBcwFB", # Password
        "-i", sql_file_path           # Input file
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
        logger.info("SQL script executed successfully. Timecards Table created.")
        logger.info(f"Output:\n{process.stdout}")
    else:
        logger.error("SQL script execution failed. Timecards Table not created.")
        logger.error(f"Error Output:\n{process.stderr}")

except Exception as e:
    logger.error(f"Error occurred while running the SQL script: {e}")
