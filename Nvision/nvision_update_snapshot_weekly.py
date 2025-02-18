import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "Nvision"
CUSTOMER_DB_NAME = "Nvision"
SQL_SERVER = "nvisionglass.servernova.net"
SQL_PORT = "50366"
SQL_USERNAME = "jobxcel"
SQL_PASSWORD = "bH2RqTYVPgtF4bH9LTD!"
USE_SSH_TUNNEL = False
SQL_FILENAME = "Weekly Snapshot.sql"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_snapshot_weekly.py")

# Command to execute the centralized script with connection details
command = [
    "python3", 
    central_script_path,
    CUSTOMER_NAME,
    CUSTOMER_DB_NAME,
    SQL_SERVER,
    SQL_PORT,
    SQL_USERNAME,
    SQL_PASSWORD,
    str(USE_SSH_TUNNEL),
    SQL_FILENAME
]

# Execute the script
try:
    result = subprocess.run(command, text=True)

    # Log output or errors
    if result.returncode == 0:
        print("Script executed successfully.")
        print(result.stdout)
    else:
        print("Script execution failed.")
        print("Standard Output:", result.stdout)
        print("Standard Error:", result.stderr)

except Exception as e:
    print(f"Error occurred while running the script: {e}")
