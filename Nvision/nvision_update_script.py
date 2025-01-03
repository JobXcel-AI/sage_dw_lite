import os
import subprocess

# Customer-specific variables
CUSTOMER_NAME = "Nvision"
CUSTOMER_DB_NAME = "Nvision"

# Path to the centralized script
base_dir = os.path.dirname(os.path.dirname(__file__))  # Move up to the base directory
central_script_path = os.path.join(base_dir, "metabase_update_scripts", "update_table_script.py")

# Command to execute the centralized script
command = [
    "python3",
    central_script_path,
    CUSTOMER_NAME,
    CUSTOMER_DB_NAME
]

# Execute the script
subprocess.run(command)
