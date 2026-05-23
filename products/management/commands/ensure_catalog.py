from django.core.management.base import BaseCommand
from django.utils.text import slugify

from products.models import Category


DEFAULT_CATEGORIES = [
    ('Alimentation', 'Produits alimentaires et boissons'),
    ('Mode', 'Vetements, chaussures et accessoires'),
    ('Electronique', 'Telephones, accessoires et appareils'),
    ('Beaute', 'Cosmetiques, parfums et soins'),
    ('Maison', 'Articles de maison et decoration'),
    ('Sport', 'Articles de sport et fitness'),
    ('Enfants', 'Produits pour enfants et bebes'),
    ('Divers', 'Autres articles'),
]


class Command(BaseCommand):
    help = 'Create default product categories when the catalog is empty.'

    def handle(self, *args, **options):
        created = 0
        for name, description in DEFAULT_CATEGORIES:
            _, was_created = Category.objects.get_or_create(
                slug=slugify(name),
                defaults={
                    'name': name,
                    'description': description,
                    'is_active': True,
                },
            )
            if was_created:
                created += 1

        if created:
            self.stdout.write(self.style.SUCCESS(f'Created {created} catalog categories.'))
        else:
            self.stdout.write('Catalog categories already exist.')
