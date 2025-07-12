# dukani/backend/settings.py

import os
from pathlib import Path
from storages.backends.s3boto3 import S3Boto3Storage  # Import S3Boto3Storage

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/5.0/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = (
    "django-insecure-@#$!%^&*()_+=-`~"  # Replace with a strong key in production
)

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = (
    os.environ.get("DJANGO_DEBUG", "False") == "True"
)  # Read DEBUG from environment variable

ALLOWED_HOSTS = [
    "*"
]  # Be specific in production, e.g., ['localhost', '127.0.0.1', 'yourdomain.com']


# Application definition

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",  # For CORS
    "api",  # Your API app
    "storages",  # New: Django Storages for S3 integration
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",  # CORS middleware
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "dukani_backend.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "dukani_backend.wsgi.application"


# Database
# https://docs.djangoproject.com/en/5.0/ref/settings/#databases

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "dukanidb"),
        "USER": os.environ.get("POSTGRES_USER", "dukaniuser"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", "dukanipassword"),
        "HOST": os.environ.get("POSTGRES_HOST", "db"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
    }
}


# Password validation
# https://docs.djangoproject.com/en/5.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
# https://docs.djangoproject.com/en/5.0/topics/i18n/

LANGUAGE_CODE = "en-us"

TIME_ZONE = "Africa/Dar_es_Salaam"  # Changed to Tanzania timezone

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.0/howto/static-files/

STATIC_URL = "static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")  # Collect static files here

# Media files (User-uploaded content) - S3/MinIO Configuration (NEW)
# These settings are read from environment variables in docker-compose.yml
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME = os.environ.get("AWS_STORAGE_BUCKET_NAME")
AWS_S3_ENDPOINT_URL = os.environ.get("AWS_S3_ENDPOINT_URL")
AWS_S3_USE_SSL = (
    os.environ.get("AWS_S3_USE_SSL", "True") == "True"
)  # Default to True for production S3
AWS_DEFAULT_ACL = os.environ.get(
    "AWS_DEFAULT_ACL", "private"
)  # Default to private, can be public-read


# Custom S3 Storage Class for Media Files
class MediaStorage(S3Boto3Storage):
    location = "media"  # Files will be stored in a 'media' folder in the bucket
    file_overwrite = False  # Do not overwrite files with the same name


# Configure Django to use S3 for default file storage
DEFAULT_FILE_STORAGE = (
    "dukani_backend.settings.MediaStorage"  # Point to our custom storage class
)

# Default primary key field type
# https://docs.djangoproject.com/en/5.0/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Django REST Framework settings
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.SessionAuthentication",
        "rest_framework.authentication.BasicAuthentication",
        "rest_framework.authentication.TokenAuthentication",  # If you add token auth later
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 10,
}

# CORS settings
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # For React web app
    "http://127.0.0.1:3000",
    "exp://192.168.1.X:8081",  # Example for Expo Go app, replace X with your actual IP part
    "http://localhost:8081",
    "http://127.0.0.1:8081",
    # Add your mobile app's development server URL if different
    # Add your production frontend URLs here
]
CORS_ALLOW_ALL_ORIGINS = True  # For development, set to False in production
CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]
CORS_ALLOW_METHODS = [
    "DELETE",
    "GET",
    "OPTIONS",
    "PATCH",
    "POST",
    "PUT",
]
