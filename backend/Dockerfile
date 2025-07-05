# Use an official Python runtime as a parent image
# Option 1: Most current stable Debian for 3.12
FROM python:3.12-slim-bookworm

# OR Option 2: A slightly older but still very common and stable Debian for 3.12
# FROM python:3.12-slim-bullseye

# OR Option 3: The generic "slim" tag, which currently points to bookworm
# FROM python:3.12-slim

# Set environment variables for non-interactive installs
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

# Set the working directory in the container
WORKDIR /app/backend

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    # Add any other system dependencies needed for psycopg2 or other packages if they fail
    # For example: libpq-dev (if psycopg2-binary has issues, though it's usually self-contained)
    # libjpeg-dev zlib1g-dev (for Pillow if you handle image processing directly)
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the working directory
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code to the container
COPY . .

# Expose port 8000
EXPOSE 8000

# Command to run the application (Gunicorn for production-like server)
# In development, we'll override this with manage.py runserver via docker-compose
CMD ["gunicorn", "dukani_backend.wsgi:application", "--bind", "0.0.0.0:8000"]
