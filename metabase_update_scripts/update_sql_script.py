import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os
import sys
import time

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
if len(sys.argv) < 9:
    logger.error("Usage: python update_sql_script.py <CUSTOMER_NAME> <CUSTOMER_DB_NAME> <SQL_SERVER> <SQL_INSTANCE> <SQL_PORT> <SQL_USERNAME> <SQL_PASSWORD> <USE_SSH_TUNNEL> <SQL_FILENAME>")
    sys.exit(1)

# Extract arguments
CUSTOMER_NAME = sys.argv[1]
CUSTOMER_DB_NAME = sys.argv[2]
SQL_SERVER = sys.argv[3]
SQL_INSTANCE = sys.argv[4]
SQL_PORT = sys.argv[5]
SQL_USERNAME = sys.argv[6]
SQL_PASSWORD = sys.argv[7]
USE_SSH_TUNNEL = sys.argv[8]
SQL_FILENAME = sys.argv[9]

logger.info(f"Extracted arguments: CUSTOMER_NAME={CUSTOMER_NAME}, CUSTOMER_DB_NAME={CUSTOMER_DB_NAME}, SQL_SERVER={SQL_SERVER}, SQL_INSTANCE={SQL_INSTANCE}, SQL_PORT={SQL_PORT}, SQL_USERNAME={SQL_USERNAME}, USE_SSH_TUNNEL={USE_SSH_TUNNEL}, SQL_FILENAME={SQL_FILENAME}")

# Establish SSH Tunnel if required
ssh_tunnel_process = None
local_sql_port = "14330"

if USE_SSH_TUNNEL == "True":
    try:
        logger.info("Starting SSH tunnel...")
        ssh_command = [
            "ssh", "-L", f"{local_sql_port}:127.0.0.1:{SQL_PORT}", "-N", "-C", "-q",
            "-o", "ExitOnForwardFailure=yes", f"{SQL_USERNAME}@{SQL_SERVER}"
        ]
        ssh_tunnel_process = subprocess.Popen(ssh_command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Give SSH tunnel time to establish
        time.sleep(2)
        logger.info("SSH tunnel established successfully.")
        SQL_SERVER = "127.0.0.1"
        SQL_PORT = local_sql_port

    except Exception as e:
        logger.error(f"Failed to establish SSH tunnel: {e}")
        sys.exit(1)

# Paths to the SQL files
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
sql_file_path = os.path.join(base_dir, "SQL Tables", "Update Tables", SQL_FILENAME)
modified_sql_file_path = os.path.join(base_dir, "SQL Tables", "Update Tables", "temp_update_sql.sql")

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

    # Save the modified SQL file
    with open(modified_sql_file_path, "w") as file:
        file.write(modified_sql_content)

    logger.info(f"SQL script modified for customer: {CUSTOMER_NAME}")

    sqlcmd_path = "/opt/homebrew/bin/sqlcmd"  # Default path

    # Try to locate sqlcmd dynamically
    try:
        sqlcmd_path = subprocess.check_output(["which", "sqlcmd"], text=True).strip()
    except subprocess.CalledProcessError:
        logger.error("sqlcmd not found. Please ensure it's installed and accessible in PATH.")
        sys.exit(1)

    # Append instance name if provided
    if SQL_INSTANCE:
        SQL_SERVER = f"{SQL_SERVER}\\{SQL_INSTANCE}"

    command = [
        sqlcmd_path,
        "-S", f"{SQL_SERVER},{SQL_PORT}",
        "-U", SQL_USERNAME,
        "-P", SQL_PASSWORD,
        "-i", modified_sql_file_path
    ]
    logger.info(f"Executing SQL script with command: {' '.join(command)}")

    # Run the command and capture output
    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Log the output and errors
    logger.info(f"Process Return Code: {process.returncode}")
    logger.info(f"Process STDOUT:\n{process.stdout}")
    if process.returncode != 0:
        logger.error("SQL script execution failed.")
        logger.error(f"Error Output:\n{process.stderr}")
    else:
        logger.info("SQL script executed successfully.")

except Exception as e:
    logger.error(f"Error occurred while running the SQL script: {e}")

finally:
    # Clean up the temporary modified file
    if os.path.exists(modified_sql_file_path):
        os.remove(modified_sql_file_path)
        logger.info(f"Temporary modified SQL file removed for customer: {CUSTOMER_NAME}")

    # Terminate the SSH tunnel if it was opened
    if ssh_tunnel_process:
        ssh_tunnel_process.terminate()
        logger.info("SSH tunnel closed.")