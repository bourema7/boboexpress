import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BoboExpress.settings')
django.setup()

from django.contrib.auth.models import User
from users.models import UserProfile

def seed_drivers():
    drivers_data = [
        {'username': 'moussa_fast', 'first_name': 'Moussa', 'last_name': 'Traoré', 'phone': '+226 70 12 34 56', 'rating': 4.8},
        {'username': 'ali_delivery', 'first_name': 'Ali', 'last_name': 'Ouédraogo', 'phone': '+226 71 22 33 44', 'rating': 4.9},
        {'username': 'souleymane_express', 'first_name': 'Souleymane', 'last_name': 'Koné', 'phone': '+226 65 00 11 22', 'rating': 4.7},
        {'username': 'ibrahim_moto', 'first_name': 'Ibrahim', 'last_name': 'Sangaré', 'phone': '+226 75 99 88 77', 'rating': 4.5},
        {'username': 'yacouba_flash', 'first_name': 'Yacouba', 'last_name': 'Barry', 'phone': '+226 60 44 55 66', 'rating': 5.0},
    ]

    for data in drivers_data:
        username = data['username']
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': f"{username}@example.com",
                'first_name': data['first_name'],
                'last_name': data['last_name'],
            }
        )
        if created:
            user.set_password('password123')
            user.save()
            print(f"User {username} created.")
        else:
            print(f"User {username} already exists.")

        profile, p_created = UserProfile.objects.get_or_create(user=user)
        profile.role = 'delivery'
        profile.is_available = True
        profile.is_verified = True
        profile.phone = data['phone']
        profile.rating = data['rating']
        profile.city = 'Bobo-Dioulasso'
        profile.total_deliveries = random.randint(10, 150)
        # Add profile image URL
        profile.profile_image = None # ImageField doesn't take URL directly easily without more logic, but we can store it in a field or just leave it.
        # Actually, let's just use a trick if the app supports it, or just use the avatar icon.
        profile.save()
        print(f"Profile for {username} updated as available driver.")

if __name__ == '__main__':
    seed_drivers()
