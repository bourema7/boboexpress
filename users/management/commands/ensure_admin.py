import os

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from users.models import UserProfile


class Command(BaseCommand):
    help = 'Create or update an admin account from ADMIN_* environment variables.'

    def handle(self, *args, **options):
        username = os.getenv('ADMIN_USERNAME')
        email = os.getenv('ADMIN_EMAIL', '')
        password = os.getenv('ADMIN_PASSWORD')

        if not username or not password:
            self.stdout.write('ADMIN_USERNAME or ADMIN_PASSWORD missing; skipping admin creation.')
            return

        user, created = User.objects.get_or_create(
            username=username,
            defaults={'email': email},
        )
        user.email = email or user.email
        user.is_staff = True
        user.is_superuser = True
        user.is_active = True
        user.set_password(password)
        user.save()

        UserProfile.objects.update_or_create(
            user=user,
            defaults={
                'role': 'admin',
                'is_verified': True,
                'accepted_terms': True,
            },
        )

        action = 'Created' if created else 'Updated'
        self.stdout.write(self.style.SUCCESS(f'{action} admin user: {username}'))
