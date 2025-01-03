import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os

# Configure rolling log file with a retention of 5 days
log_file_path = os.path.join(os.path.dirname(__file__), "test_jobs_query.log")
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

# Hardcoded values for one-time test
CUSTOMER_NAME = "Nvision"
CUSTOMER_DB_NAME = "Nvision"

# Test SQL query template
sql_query = f"""
--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = '{CUSTOMER_DB_NAME}';  
--Specify Reporting DB Name
DECLARE @Reporting_DB_Name NVARCHAR(50) = QUOTENAME(CONCAT(@Client_DB_Name, ' Reporting'));
--Initial variable declaration
DECLARE @SqlQuery NVARCHAR(MAX);

--Query: Select TOP 1 row from Jobs table in the specified Client DB
SET @SqlQuery = CONCAT(
    N'SELECT TOP 1 * FROM ', @Client_DB_Name, N'.dbo.Jobs;'
);

--Execute the query
EXEC sp_executesql @SqlQuery;
"""

# Temporary SQL file to execute the query
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
temp_sql_file_path = os.path.join(base_dir, "temp_test_jobs_query.sql")

try:
    # Write the test query to a temporary SQL file
    with open(temp_sql_file_path, "w") as file:
        file.write(sql_query)

    logger.info(f"Running test query for customer: {CUSTOMER_NAME}")
    logger.info(f"Query: \n{sql_query.strip()}")

    # Command to run sqlcmd
    command = [
        "/opt/mssql-tools/bin/sqlcmd",  # Full path to sqlcmd
        "-S", "206.71.70.82,50285",  # Server and port
        "-U", "jobxcel",              # Username
        "-P", "qn_uJYszjd4NCJuBcwFB", # Password
        "-i", temp_sql_file_path      # Input file
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
        logger.info("SQL query executed successfully.")
        logger.info(f"Output:\n{process.stdout}")
    else:
        logger.error("SQL query execution failed.")
        logger.error(f"Error Output:\n{process.stderr}")

except Exception as e:
    logger.error(f"Error occurred while running the SQL query: {e}")

finally:
    # Clean up the temporary SQL file
    if os.path.exists(temp_sql_file_path):
        os.remove(temp_sql_file_path)
        logger.info("Temporary SQL file removed.")
