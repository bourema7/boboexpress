import json

base_url = "http://127.0.0.1:8000/api"

# Get token (assuming admin/password exists from previous context or common defaults)
# If not, we can just check the endpoint without auth if it allowed it, but it doesn't.
# Wait, I'll use django shell to get a token or just call the view directly.

import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BoboExpress.settings')
django.setup()

from django.contrib.auth.models import User
from users.views import AvailableDriversView
from rest_framework.test import APIRequestFactory, force_authenticate

factory = APIRequestFactory()
request = factory.get('/api/users/available-drivers/')
user = User.objects.filter(is_staff=True).first()
force_authenticate(request, user=user)

view = AvailableDriversView.as_view()
response = view(request)
print(f"Status Code: {response.status_code}")
print(f"Data: {json.dumps(response.data, indent=2)}")
