from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.template.defaultfilters import slugify

from shop.models import Address, Category, Product, Profile, Store


class Command(BaseCommand):
    help = 'Seed sample data for BoboMarket'

    def handle(self, *args, **options):
        categories = [
            'Électronique',
            'Vêtements',
            'Chaussures',
            'Cosmétiques',
            'Accessoires',
            'Fournitures scolaires',
            'Pièces auto/moto',
            'Maison & décoration',
            'Téléphones',
            'Supermarché',
        ]

        self.stdout.write('Création des catégories...')
        category_map = {}
        for name in categories:
            slug = slugify(name)
            category, _ = Category.objects.get_or_create(name=name, slug=slug)
            category_map[name] = category

        self.stdout.write('Création des utilisateurs de test...')
        seller_user, _ = User.objects.get_or_create(
            username='seller1',
            defaults={'email': 'seller1@bobomarket.local'},
        )
        if not seller_user.password:
            seller_user.set_password('seller123')
            seller_user.save()

        customer_user, _ = User.objects.get_or_create(
            username='customer1',
            defaults={'email': 'customer1@bobomarket.local'},
        )
        if not customer_user.password:
            customer_user.set_password('customer123')
            customer_user.save()

        delivery_user, _ = User.objects.get_or_create(
            username='delivery1',
            defaults={'email': 'delivery1@bobomarket.local'},
        )
        if not delivery_user.password:
            delivery_user.set_password('delivery123')
            delivery_user.save()

        self.stdout.write('Création des profils...')
        Profile.objects.update_or_create(
            user=seller_user,
            defaults={'role': 'seller', 'phone': '+22670000001', 'city': 'Ouagadougou', 'is_verified': True},
        )
        Profile.objects.update_or_create(
            user=customer_user,
            defaults={'role': 'customer', 'phone': '+22670000002', 'city': 'Ouagadougou', 'is_verified': True},
        )
        Profile.objects.update_or_create(
            user=delivery_user,
            defaults={'role': 'delivery', 'phone': '+22670000003', 'city': 'Ouagadougou', 'is_verified': True},
        )

        self.stdout.write('Création de la boutique de démonstration...')
        store, _ = Store.objects.get_or_create(
            owner=seller_user.profile,
            slug='bo-vente',
            defaults={
                'name': 'Bo Vente',
                'description': 'Boutique de test BoboMarket',
                'category': category_map['Supermarché'],
                'city': 'Ouagadougou',
                'is_active': True,
                'is_approved': True,
                'commission_rate': 5.0,
            },
        )

        self.stdout.write('Création des produits de démonstration...')
        sample_products = [
            ('Smartphone Android', 'Électronique', 120000.00, 12),
            ('T-shirt BoboMarket', 'Vêtements', 8000.00, 30),
            ('Chaussures sport', 'Chaussures', 22000.00, 18),
            ('Ordinateur portable', 'Électronique', 450000.00, 5),
            ('Sac école', 'Fournitures scolaires', 9500.00, 20),
        ]

        for name, category_name, price, stock in sample_products:
            slug = slugify(name)
            Product.objects.get_or_create(
                store=store,
                category=category_map[category_name],
                name=name,
                slug=slug,
                defaults={
                    'description': f'Produit de démonstration: {name}',
                    'price': price,
                    'stock': stock,
                    'is_active': True,
                },
            )

        self.stdout.write('Création d’une adresse client...')
        Address.objects.get_or_create(
            user=customer_user,
            label='Adresse principale',
            defaults={
                'street': 'Rue des marchés',
                'city': 'Ouagadougou',
                'gps_lat': 12.3657,
                'gps_lng': -1.5339,
                'is_primary': True,
            },
        )

        self.stdout.write(self.style.SUCCESS('Données de test BoboMarket créées avec succès.'))
