from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.contrib.auth.models import User
from .token_store import get_user_id

class DummyTokenAuthentication(BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Token '):
            return None

        token = auth_header.replace('Token ', '')
        user_id = get_user_id(token)
        if not user_id:
            raise exceptions.AuthenticationFailed('Invalid token')

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            raise exceptions.AuthenticationFailed('User not found')

        return (user, None)