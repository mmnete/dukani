# dukani/backend/Dockerfile
FROM python:3.12-slim-bookworm

# Set environment variables for non-interactive installs and Python behavior
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

# Set the working directory inside the container.
# This is crucial for Django to find manage.py and your project modules.
# Since your local 'backend' directory is mounted to '/app/backend' by docker-compose,
# and 'manage.py' and the 'dukani' project folder are directly inside 'backend',
# the WORKDIR should be '/app/backend'.
WORKDIR /app/backend

# Install system dependencies required for database client and Python packages like psycopg2 and Pillow
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    libpq-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your backend application code into the working directory
# This will copy 'manage.py', 'dukani/' (your project), 'api/', etc., into /app/backend
COPY . .

# Expose the port Django will run on
EXPOSE 8000

# Command to run the application (Gunicorn for production-like server)
# In development, this will be overridden by docker-compose.yml to run manage.py runserver
CMD ["gunicorn", "dukani.wsgi:application", "--bind", "0.0.0.0:8000"]
