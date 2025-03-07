import os
import subprocess
# Customer-specific variables
CUSTOMER_NAME = "ASG"
CUSTOMER_DB_NAMES = "Bryan~-~S100~Ultimate,Andy-~S100~Ultimate~1,Craig~-~S100~Ultimate,Danielle~-~S100~Ultimate,Catie~-~S100~Ultimate,Home~Builders~of~FL,Jennifer~-~S100~Ultimate,JS-Ultimate~Demonstration~Data,MH-Ultimate~Demonstration~Data,Nate~-~S100~Ultimate,Nick~-~S100~Ultimate,Pat~-~S100~Ultimate,Sarah~-~Ultimate,Tanya~-~S100~Ultimate,Trish~-~Ultimate,ZB~-~Ultimate"
SQL_SERVER = "asgdemo.servernova.net"
SQL_INSTANCE= "SN-20202"
SQL_PORT = "65288"
SQL_USERNAME = "jobxcel"
SQL_PASSWORD = "jobxcel"
USE_SSH_TUNNEL = False
SQL_FILENAME = "2025-03-07 patch.sql"

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
