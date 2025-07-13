from django.utils.deprecation import MiddlewareMixin
from .token_store import get_user_or_worker_by_token # Corrected import path
from django.contrib.auth.models import AnonymousUser # Import AnonymousUser
from rest_framework.authentication import get_authorization_header

class TokenAuthenticationMiddleware(MiddlewareMixin):
    """
    Middleware to authenticate users/workers based on a custom token
    (e.g., a simple UUID token) in the Authorization header.
    """
    def process_request(self, request):
        auth_header = get_authorization_header(request).decode('utf-8')
        if auth_header and auth_header.startswith('Token '):
            token = auth_header.split(' ')[1]
            user_or_worker = get_user_or_worker_by_token(token)
            if user_or_worker:
                # If it's a User, assign to request.user
                if isinstance(user_or_worker, type(request.user)): # Check if it's a Django User model instance
                    request.user = user_or_worker
                else: # Assume it's a Worker instance, assign to a custom attribute
                    request.worker = user_or_worker
                    # Optionally, you might want to assign a generic authenticated user
                    # if the worker is considered "authenticated" for DRF's IsAuthenticated
                    # This depends on your exact DRF authentication setup.
                    # For now, we'll let DRF's authentication classes handle the user.
                    # If you have a custom authentication class, it would set request.user.
                    # For simple middleware, we'll just set request.worker.
            else:
                request.user = AnonymousUser() # Set to AnonymousUser if token is invalid
        else:
            request.user = AnonymousUser() # Default to AnonymousUser if no token