import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "Vertex"
CUSTOMER_DB_NAME = "Vertex Coatings"
SQL_SERVER = "vertexcoatings.servernova.net\\SN-30147"
SQL_PORT = "50285"
SQL_USERNAME = "jobxcel"
SQL_PASSWORD = "qn_uJYszjd4NCJuBcwFB"
USE_SSH_TUNNEL = False
SQL_FILENAME = "Update All Reporting Tables.sql"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_sql_script.py")

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
        print("Standard Output:")
        print(result.stdout)
    else:
        print("Script execution failed.")
        print("Standard Output:")
        print(result.stdout)
        print("Standard Error:")
        print(result.stderr)

except Exception as e:
    print(f"Error occurred while running the script: {e}")
