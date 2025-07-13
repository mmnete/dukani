Dukani Backend (Django REST Framework)
This is the backend service for the Dukani application, built with Django REST Framework. It provides the API endpoints for managing shops, workers, products, stock, sales, and analytics.

🚀 How to Launch
The backend is designed to run using Docker Compose for easy setup and consistency across environments.

Prerequisites:
Docker installed and running.

docker-compose (usually comes with Docker Desktop).

Steps:
Navigate to the backend directory:

cd path/to/your/dukani/backend

Build the Docker images (first time setup or after changes to Dockerfile):

docker-compose build

Start the services (database and Django app):

docker-compose up -d

This will start the PostgreSQL database and the Django application in detached mode.

Apply database migrations:
After the services are up, you need to apply the database migrations to set up your database schema.

docker-compose exec backend python manage.py migrate

Create a superuser (for Django Admin access):

docker-compose exec backend python manage.py createsuperuser

Follow the prompts to create your admin user.

Access the API:
The backend API will typically be accessible at http://localhost:8000/api/ (or http://127.0.0.1:8000/api/).

Django Admin: http://localhost:8000/admin/

🧪 How to Run Unit Tests
Unit tests are crucial for ensuring the backend's functionality.

Steps:
Ensure your Docker services are running:

cd path/to/your/dukani/backend
docker-compose up -d

Execute the tests within the Docker container:

docker-compose exec backend python manage.py test api

This command runs all tests within the api Django app.


Another way you can build is: 
docker-compose down
docker-compose build backend
docker-compose up -d

then to run tests
docker-compose exec backend python manage.py test api

If you ever do a model change:
python manage.py makemigrations
python manage.py migrate