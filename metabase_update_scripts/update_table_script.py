import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os
import time

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

# Path to the SQL file
sql_file_path = os.path.join(os.path.dirname(__file__), "update_script_vertex.sql")

try:
    logger.info("Executing SQL script using sqlcmd...")

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

    # Log the output and errors
    if process.returncode == 0:
        logger.info("SQL script executed successfully.")
        logger.info(f"Output:\n{process.stdout}")
    else:
        logger.error("SQL script execution failed.")
        logger.error(f"Error Output:\n{process.stderr}")

except Exception as e:
    logger.error(f"Error occurred while running the SQL script: {e}")
