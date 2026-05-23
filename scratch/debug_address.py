import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BoboExpress.settings')
django.setup()

from django.contrib.auth.models import User
from users.serializers import AddressSerializer
from rest_framework.test import APIRequestFactory

factory = APIRequestFactory()
user = User.objects.filter(is_superuser=True).first()

data = {
    'label': 'Maison Test',
    'type': 'home',
    'street': 'Rue 123',
    'city': 'Bobo',
    'latitude': 12.3456789,
    'longitude': -4.5678901,
    'is_primary': True
}

request = factory.post('/api/users/addresses/', data, format='json')
request.user = user

serializer = AddressSerializer(data=data, context={'request': request})
if serializer.is_valid():
    print("Serializer is valid!")
else:
    print("Serializer errors:", serializer.errors)
