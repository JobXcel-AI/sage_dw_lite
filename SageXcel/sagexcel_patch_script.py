import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "SageXcel"
CUSTOMER_DB_NAMES = ["SageXcel~Demo"]  # Now an array
SQL_SERVER = "mike.servernova.net"
SQL_INSTANCE = "SN-33307"
SQL_PORT = "49732"
SQL_USERNAME = "jobxcel"
SQL_PASSWORD = "wKif7qZiTxmsWXw.ebL9"
USE_SSH_TUNNEL = False
SQL_FILENAME = "Debug view recreate.sql"

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