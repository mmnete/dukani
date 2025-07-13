import uuid

# In-memory token store: {token_str: {'id': user_or_worker_id, 'role': 'worker'/'manager'}}
TOKENS = {}

def generate_token_for(user_or_worker):
    token = uuid.uuid4().hex
    role = 'worker' if hasattr(user_or_worker, 'phone_number') else 'manager'
    TOKENS[token] = {'id': user_or_worker.id, 'role': role}
    return token

def get_user_or_worker_by_token(token):
    from api.models import Worker
    from django.contrib.auth.models import User

    data = TOKENS.get(token)
    if not data:
        return None
    if data['role'] == 'worker':
        return Worker.objects.filter(id=data['id']).first()
    elif data['role'] == 'manager':
        return User.objects.filter(id=data['id']).first()
    return None

def remove_token(token):
    TOKENS.pop(token, None)
