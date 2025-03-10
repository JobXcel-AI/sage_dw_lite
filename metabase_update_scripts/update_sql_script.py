import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os
import sys
import time

# Configure rolling log file
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

# Log to console as well
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# Ensure required arguments are passed
if len(sys.argv) < 9:
    logger.error("Usage: python update_sql_script.py <CUSTOMER_NAME> <CUSTOMER_DB_NAMES> <SQL_SERVER> <SQL_INSTANCE> <SQL_PORT> <SQL_USERNAME> <SQL_PASSWORD> <USE_SSH_TUNNEL> <SQL_FILENAME>")
    sys.exit(1)

# Extract arguments
CUSTOMER_NAME = sys.argv[1]
CUSTOMER_DB_NAMES = sys.argv[2].split(",")  # Convert comma-separated list to array
SQL_SERVER = sys.argv[3]
SQL_INSTANCE = sys.argv[4]
SQL_PORT = sys.argv[5]
SQL_USERNAME = sys.argv[6]
SQL_PASSWORD = sys.argv[7]
USE_SSH_TUNNEL = sys.argv[8]
SQL_FILENAME = sys.argv[9]

# Debugging log
logger.info(f"Extracted arguments: CUSTOMER_NAME={CUSTOMER_NAME}, SQL_SERVER={SQL_SERVER}, SQL_PORT={SQL_PORT}, SQL_USERNAME={SQL_USERNAME}, USE_SSH_TUNNEL={USE_SSH_TUNNEL}, SQL_FILENAME={SQL_FILENAME}")
logger.info(f"Databases to update: {', '.join(CUSTOMER_DB_NAMES)}")

# Set up SSH Tunnel if needed
tunnel_process = None
TUNNEL_PORT = 50005
REMOTE_SQL_HOST = SQL_SERVER

if USE_SSH_TUNNEL.lower() == "true":
    try:
        logger.info("Starting SSH tunnel...")
        ssh_command = [
            "ssh",
            "-L", f"{TUNNEL_PORT}:{REMOTE_SQL_HOST}:{SQL_PORT}",
            "-N", "-C", "-q",
            "-o", "ExitOnForwardFailure=yes",
            f"{SQL_USERNAME}@{REMOTE_SQL_HOST}"
        ]

        tunnel_process = subprocess.Popen(ssh_command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(3)  # Give time for the tunnel to establish

        # Change SQL_SERVER to localhost
        SQL_SERVER = "127.0.0.1"
        SQL_PORT = str(TUNNEL_PORT)

        logger.info("SSH tunnel established successfully.")

    except Exception as e:
        logger.error(f"Failed to establish SSH tunnel: {e}")
        sys.exit(1)

# Paths to the SQL files
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to base directory
sql_file_path = os.path.join(base_dir, "SQL Tables", "Update Tables", SQL_FILENAME)
modified_sql_file_path = os.path.join(base_dir, "SQL Tables", "Update Tables", "temp_update_sql.sql")

# Placeholder replacements
client_db_placeholder = "[CLIENT_DB_NAME]"

try:
    # Read the SQL file
    with open(sql_file_path, "r") as file:
        sql_content = file.read()

    # Ensure the placeholder is matched exactly
    if client_db_placeholder not in sql_content:
        logger.error(f"Placeholder {client_db_placeholder} not found in {sql_file_path}.")
        sys.exit(1)

    # Locate sqlcmd
    try:
        sqlcmd_path = "/opt/mssql-tools/bin/sqlcmd"
    except subprocess.CalledProcessError:
        logger.error("sqlcmd not found. Ensure it's installed and in PATH.")
        sys.exit(1)

    # Append instance name if provided
    if SQL_INSTANCE:
        SQL_SERVER = f"{SQL_SERVER}\\{SQL_INSTANCE}"

    # Execute for each database
    for db_name in CUSTOMER_DB_NAMES:
        logger.info(f"Processing SQL script for database: {db_name}")
        # replace ~ with a space
        db_name = db_name.replace("~", " ")

        # Replace placeholders with actual database name
        modified_sql_content = sql_content.replace(client_db_placeholder, db_name)

        # Save the modified SQL file
        with open(modified_sql_file_path, "w") as file:
            file.write(modified_sql_content)

        logger.info(f"SQL script modified for database: {db_name}")
        logger.info(modified_sql_content)

        command = [
            sqlcmd_path,
            "-S", f"{SQL_SERVER},{SQL_PORT}",
            "-U", SQL_USERNAME,
            "-P", SQL_PASSWORD,  # Ensure no unnecessary quotes around password
            "-i", modified_sql_file_path
        ]

        logger.info(f"Executing SQL script for database {db_name} with command: {' '.join(command)}")

        # Run the command and capture output
        process = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        # Log output and errors
        logger.info(f"Process Return Code: {process.returncode}")
        logger.info(f"Process STDOUT:\n{process.stdout}")
        if process.returncode != 0:
            logger.error(f"SQL script execution failed for database: {db_name}")
            logger.error(f"Error Output:\n{process.stderr}")
        else:
            logger.info(f"SQL script executed successfully for database: {db_name}")

except Exception as e:
    logger.error(f"Error occurred while running the SQL script: {e}")

finally:
    # Clean up temp SQL file
    if os.path.exists(modified_sql_file_path):
        os.remove(modified_sql_file_path)
        logger.info("Temporary modified SQL file removed.")

    # Close SSH tunnel
    if tunnel_process:
        tunnel_process.terminate()
        logger.info("SSH tunnel closed.")