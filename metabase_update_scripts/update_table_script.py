import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os

# Configure rolling log file with a retention of 5 days
log_file_path = os.path.join(os.path.dirname(__file__), "vertex_update.log")
file_handler = TimedRotatingFileHandler(
    log_file_path, when="midnight", interval=1, backupCount=5  # Rotate daily, keep 5 days of logs
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

# Full path to the original and modified SQL files
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up one level to locate the base directory
sql_file_path = os.path.join(
    base_dir, "SQL Tables", "Update Tables", "Update All Reporting Tables.sql"
)
modified_sql_file_path = os.path.join(
    base_dir, "SQL Tables", "Update Tables", "temp_Update_All_Reporting_Tables.sql"
)

# Placeholder and replacement for database name
placeholder = "[CLIENT_DB_NAME]"
client_db_name = "'Vertex Coatings'"

try:
    # Read the original SQL file
    logger.info("Reading and modifying the SQL script...")
    with open(sql_file_path, "r") as file:
        sql_content = file.read()

    # Replace the placeholder with the client DB name
    modified_sql_content = sql_content.replace(placeholder, client_db_name)

    # Save the modified SQL file
    with open(modified_sql_file_path, "w") as file:
        file.write(modified_sql_content)

    logger.info("Modified SQL script saved.")

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
        logger.info("Temporary modified SQL file removed.")
