# dukani/backend/wait_for_db.py

import os
import time
import django  # Import django
from django.db import connections
from django.db.utils import OperationalError

# Configure Django settings for standalone script usage
django.setup()

# Get database connection details from environment variables
# These are now correctly accessed after django.setup()
DB_HOST = os.environ.get("POSTGRES_HOST", "db")
DB_PORT = os.environ.get("POSTGRES_PORT", "5432")

print("Waiting for database to be ready...")
db_conn = None
while not db_conn:
    try:
        # Attempt to get a connection to the 'default' database
        # This will raise OperationalError if the database is not ready
        connections["default"].ensure_connection()
        db_conn = True
        print("Database ready!")
    except OperationalError:
        print("Database unavailable, waiting 1 second...")
        time.sleep(1)

# This script exits successfully when the database connection is established.
# The `sh -c` command in docker-compose.yml will then proceed to the next step.
