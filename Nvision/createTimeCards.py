import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os

# Configure rolling log file with a retention of 5 days
log_file_path = os.path.join(os.path.dirname(__file__), "list_databases.log")
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

# Test SQL query to list all accessible databases
sql_query = """
SELECT name 
FROM sys.databases;
"""

# Temporary SQL file to execute the query
temp_sql_file_path = os.path.join(os.path.dirname(__file__), "temp_list_databases.sql")

try:
    # Write the test query to a temporary SQL file
    with open(temp_sql_file_path, "w") as file:
        file.write(sql_query)

    logger.info("Running query to list all accessible databases.")
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
        logger.info("SQL query executed successfully. List of databases:")
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
