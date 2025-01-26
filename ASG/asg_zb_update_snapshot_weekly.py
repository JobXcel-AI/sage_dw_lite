import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "ASG - ZB"
CUSTOMER_DB_NAME = "ZB - Ultimate"
SQL_SERVER = "asgdemo.servernova.net"
SQL_PORT = "65288"
SQL_USERNAME = "jobxcel"
SQL_PASSWORD = "*Fr33B1rd77$Y@nk33*"

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
    SQL_PASSWORD
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
