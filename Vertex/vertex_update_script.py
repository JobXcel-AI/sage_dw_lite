import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "Vertex"
CUSTOMER_DB_NAME = "Vertex Coatings"
SQL_SERVER = "vertexcoatings.servernova.net\\SN-30147"
SQL_PORT = "50285"
SQL_USERNAME = "jobxcel"
SQL_PASSWORD = "qn_uJYszjd4NCJuBcwFB"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_table_script.py")

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
subprocess.run(command)
