import os
import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler

# Configure logging
log_file_path = os.path.join(os.path.dirname(__file__), "update_git_repo.log")
file_handler = TimedRotatingFileHandler(
    log_file_path, when="midnight", interval=1, backupCount=5
)
formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
file_handler.setFormatter(formatter)

# Set up logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)

console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# Specify the directory of the Git repository
repo_dir = "/path/to/your/repo"  # Replace with your actual path

try:
    # Check if the directory exists
    if not os.path.exists(repo_dir):
        logger.error(f"Repository directory does not exist: {repo_dir}")
        exit(1)

    # Navigate to the repository directory
    logger.info(f"Navigating to repository directory: {repo_dir}")
    os.chdir(repo_dir)

    # Pull the latest changes from the remote repository
    logger.info("Pulling the latest changes from the repository...")
    result = subprocess.run(
        ["git", "pull"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Log the result
    if result.returncode == 0:
        logger.info("Git pull successful.")
        logger.info(f"Output:\n{result.stdout}")
    else:
        logger.error("Git pull failed.")
        logger.error(f"Error Output:\n{result.stderr}")

except Exception as e:
    logger.error(f"An error occurred: {e}")
