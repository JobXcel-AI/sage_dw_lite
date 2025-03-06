import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "Brekhus"
CUSTOMER_DB_NAMES = ["Brekhus~Marble~&~Granite", "Brekhus~Tile~&~Stone"]  # Now an array
SQL_SERVER = "50.169.189.130"
SQL_INSTANCE = "BTSSRV"
SQL_PORT = "1433"
SQL_USERNAME = "sagexcel"
SQL_PASSWORD = "qkJt>X@%iLtrR"
USE_SSH_TUNNEL = True
SQL_FILENAME = "Update SageXcel Rollup Reporting Tables.sql"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_sql_script.py")

# Ensure central_script_path is a string
central_script_path = str(central_script_path)

# Convert CUSTOMER_DB_NAMES list to a single string with properly quoted names
formatted_db_names = ",".join(CUSTOMER_DB_NAMES)  # Convert list to comma-separated string

# Command to execute the centralized script with connection details
command = [
    "python3",
    central_script_path,
    CUSTOMER_NAME,
    formatted_db_names,  # Pass as a string instead of a list
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