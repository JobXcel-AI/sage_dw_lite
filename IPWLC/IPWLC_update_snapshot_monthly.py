import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "IPWLC"
CUSTOMER_DB_NAMES = "Industrial Piping & Welding llc"
SQL_SERVER = "206.71.70.141"
SQL_INSTANCE = "SN-33307"
SQL_PORT = "50422"
SQL_USERNAME = "sagexcel"
SQL_PASSWORD = "nJVvYLeax%ALv^9sWpv@"
USE_SSH_TUNNEL = False
SQL_FILENAME = "Monthly Snapshot.sql"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_sql_script.py")

# Command to execute the centralized script with connection details
command = [
    "python3", 
    central_script_path,
    CUSTOMER_NAME,
    CUSTOMER_DB_NAMES,
    SQL_SERVER,
    SQL_INSTANCE,
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
