import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "Burbach"
CUSTOMER_DB_NAMES = ["BC Master", "RES", "RBB", "CES", "Enhanced", "BEL", "BP"]  # Now an array
SQL_SERVER = "33.3.55.2"
SQL_INSTANCE = "SN-34003"
SQL_PORT = "49750"
SQL_USERNAME = "sagexcel"
SQL_PASSWORD = "!7j!ewCcihpS!5icnPP5"
USE_SSH_TUNNEL = False
SQL_FILENAME = "SageXcel Rollup Reporting Table Clear.sql"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_sql_script.py")

# Convert CUSTOMER_DB_NAMES list to a single string with properly quoted names
formatted_db_names = ",".join(CUSTOMER_DB_NAMES)  # Convert list to comma-separated string

# Command to execute the centralized script with connection details
command = [
    "python3", 
    central_script_path,
    CUSTOMER_NAME,
    formatted_db_names,
    SQL_SERVER,
    SQL_INSTANCE,
    SQL_PORT,
    SQL_USERNAME,
    SQL_PASSWORD,
    str(USE_SSH_TUNNEL),
    SQL_FILENAME,
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
