"""
Script pour ajouter 50 produits variés dans toutes les catégories BoboExpress.
Usage: python manage.py shell < scripts/seed_products.py
"""

import os, django, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BoboExpress.settings')
django.setup()

from products.models import Product, Category
from stores.models import Store
from django.utils.text import slugify

store = Store.objects.first()
if not store:
    print("❌ Aucune boutique trouvée !")
    exit()

print(f"✅ Boutique: {store.name}")

cat_femmes = Category.objects.get(slug='femmes')
cat_hommes = Category.objects.get(slug='hommes')
cat_enfants = Category.objects.get(slug='enfants')
cat_chaussures = Category.objects.get(slug='chaussures')
cat_sacs = Category.objects.get(slug='sacs')
cat_maison = Category.objects.get(slug='maison')

produits = [
    # ===== FEMMES (10 produits) =====
    {
        "name": "Robe Wax Élégante",
        "category": cat_femmes,
        "price": 15000,
        "stock": 25,
        "description": "Belle robe en tissu wax aux couleurs vives, idéale pour toutes les occasions.",
        "image_url": "https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400",
    },
    {
        "name": "Chemisier Floral Léger",
        "category": cat_femmes,
        "price": 8500,
        "stock": 30,
        "description": "Chemisier fluide à motifs floraux, parfait pour un look décontracté.",
        "image_url": "https://images.unsplash.com/photo-1581338834647-b0fb40704e21?w=400",
    },
    {
        "name": "Jupe Longue Bohème",
        "category": cat_femmes,
        "price": 12000,
        "stock": 20,
        "description": "Jupe longue style bohème en coton léger, disponible en plusieurs coloris.",
        "image_url": "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400",
    },
    {
        "name": "Ensemble Tailleur Africain",
        "category": cat_femmes,
        "price": 22000,
        "stock": 15,
        "description": "Tailleur 2 pièces en tissu kente, élégant et moderne.",
        "image_url": "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400",
    },
    {
        "name": "T-shirt Femme Premium",
        "category": cat_femmes,
        "price": 5500,
        "stock": 50,
        "description": "T-shirt en coton 100% doux, coupe ajustée pour femme.",
        "image_url": "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=400",
    },
    {
        "name": "Combinaison Pantalon",
        "category": cat_femmes,
        "price": 18000,
        "stock": 18,
        "description": "Combinaison pantalon chic en tissu satiné, parfaite pour les soirées.",
        "image_url": "https://images.unsplash.com/photo-1566206091558-7f218b696731?w=400",
    },
    {
        "name": "Robe de Soirée Dorée",
        "category": cat_femmes,
        "price": 28000,
        "stock": 10,
        "description": "Robe de soirée élégante aux reflets dorés, idéale pour les mariages.",
        "image_url": "https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=400",
    },
    {
        "name": "Legging Sportif Femme",
        "category": cat_femmes,
        "price": 7000,
        "stock": 40,
        "description": "Legging taille haute ultra-confortable pour le sport ou le quotidien.",
        "image_url": "https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=400",
    },
    {
        "name": "Veste Courte Tendance",
        "category": cat_femmes,
        "price": 16000,
        "stock": 22,
        "description": "Veste courte style blazer, un must-have pour toute garde-robe moderne.",
        "image_url": "https://images.unsplash.com/photo-1551803091-e20673f15770?w=400",
    },
    {
        "name": "Pyjama Satiné Femme",
        "category": cat_femmes,
        "price": 9500,
        "stock": 35,
        "description": "Ensemble pyjama en satin doux 2 pièces, confort absolu pour la nuit.",
        "image_url": "https://images.unsplash.com/photo-1615397349754-cfa2066a298e?w=400",
    },

    # ===== HOMMES (9 produits) =====
    {
        "name": "Chemise Africaine Dashiki",
        "category": cat_hommes,
        "price": 11000,
        "stock": 30,
        "description": "Chemise dashiki colorée, tradition et modernité en harmonie.",
        "image_url": "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400",
    },
    {
        "name": "Pantalon Chino Slim",
        "category": cat_hommes,
        "price": 13500,
        "stock": 25,
        "description": "Pantalon chino coupe slim, élégant et polyvalent pour toutes occasions.",
        "image_url": "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400",
    },
    {
        "name": "Polo Homme Classique",
        "category": cat_hommes,
        "price": 7500,
        "stock": 45,
        "description": "Polo manches courtes en coton piqué, look décontracté et soigné.",
        "image_url": "https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?w=400",
    },
    {
        "name": "Costume 3 Pièces Homme",
        "category": cat_hommes,
        "price": 45000,
        "stock": 8,
        "description": "Costume élégant 3 pièces pour les grandes occasions.",
        "image_url": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400",
    },
    {
        "name": "Jean Slim Homme",
        "category": cat_hommes,
        "price": 14000,
        "stock": 35,
        "description": "Jean slim stretch très confortable, coupe moderne et tendance.",
        "image_url": "https://images.unsplash.com/photo-1542272604-787c3835535d?w=400",
    },
    {
        "name": "Boubou Grand Seigneur",
        "category": cat_hommes,
        "price": 25000,
        "stock": 12,
        "description": "Grand boubou brodé à la main, symbole d'élégance africaine.",
        "image_url": "https://images.unsplash.com/photo-1529391409740-59f2cea08bc5?w=400",
    },
    {
        "name": "T-shirt Graphique Homme",
        "category": cat_hommes,
        "price": 6000,
        "stock": 60,
        "description": "T-shirt imprimé graphique tendance, 100% coton de qualité supérieure.",
        "image_url": "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=400",
    },
    {
        "name": "Short Sport Homme",
        "category": cat_hommes,
        "price": 5500,
        "stock": 40,
        "description": "Short sportif léger et respirant, idéal pour le jogging ou la gym.",
        "image_url": "https://images.unsplash.com/photo-1591195853828-11db59a44f43?w=400",
    },
    {
        "name": "Veste en Jean Homme",
        "category": cat_hommes,
        "price": 19500,
        "stock": 20,
        "description": "Veste en jean délavé style casual, indémodable et versatile.",
        "image_url": "https://images.unsplash.com/photo-1578587018452-892bacefd3f2?w=400",
    },

    # ===== ENFANTS (7 produits) =====
    {
        "name": "Ensemble Bébé 0-6 mois",
        "category": cat_enfants,
        "price": 7500,
        "stock": 20,
        "description": "Ensemble body + pantalon doux pour bébé, 100% coton hypoallergénique.",
        "image_url": "https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400",
    },
    {
        "name": "Robe Princesse Fille",
        "category": cat_enfants,
        "price": 9000,
        "stock": 25,
        "description": "Robe de princesse avec tulle et strass, parfaite pour les anniversaires.",
        "image_url": "https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?w=400",
    },
    {
        "name": "Costume Petit Homme",
        "category": cat_enfants,
        "price": 12500,
        "stock": 15,
        "description": "Petit costume élégant pour garçon, idéal pour les fêtes et cérémonies.",
        "image_url": "https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=400",
    },
    {
        "name": "Pyjama Enfant Animaux",
        "category": cat_enfants,
        "price": 6500,
        "stock": 30,
        "description": "Pyjama amusant avec motifs d'animaux, en coton doux pour une nuit confortable.",
        "image_url": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400",
    },
    {
        "name": "Ensemble Sport Enfant",
        "category": cat_enfants,
        "price": 8000,
        "stock": 28,
        "description": "Survêtement sport léger pour enfant 4-12 ans, confort et liberté de mouvement.",
        "image_url": "https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=400",
    },
    {
        "name": "Tenue Africaine Enfant",
        "category": cat_enfants,
        "price": 10000,
        "stock": 18,
        "description": "Belle tenue en tissu wax pour enfant, parfaite pour les cérémonies.",
        "image_url": "https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=400",
    },
    {
        "name": "Manteau Hiver Enfant",
        "category": cat_enfants,
        "price": 14000,
        "stock": 15,
        "description": "Manteau chaud doublé pour les nuits fraîches, avec capuche.",
        "image_url": "https://images.unsplash.com/photo-1545048702-79362596cdc9?w=400",
    },

    # ===== CHAUSSURES (8 produits) =====
    {
        "name": "Sandales Plateformes Femme",
        "category": cat_chaussures,
        "price": 12000,
        "stock": 20,
        "description": "Sandales à plateforme tendance, idéales pour l'été et les sorties.",
        "image_url": "https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400",
    },
    {
        "name": "Baskets Homme Urbaines",
        "category": cat_chaussures,
        "price": 18500,
        "stock": 25,
        "description": "Baskets urbaines confortables et stylées pour homme, semelle amortissante.",
        "image_url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400",
    },
    {
        "name": "Escarpins Élégants",
        "category": cat_chaussures,
        "price": 16000,
        "stock": 18,
        "description": "Escarpins à talon 7cm, chic et confortables pour toutes les occasions.",
        "image_url": "https://images.unsplash.com/photo-1518049362265-d5b2a6467637?w=400",
    },
    {
        "name": "Mocassins Cuir Homme",
        "category": cat_chaussures,
        "price": 22000,
        "stock": 15,
        "description": "Mocassins en cuir véritable, finition soignée et confort exceptionnel.",
        "image_url": "https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=400",
    },
    {
        "name": "Tongs Plage Colorées",
        "category": cat_chaussures,
        "price": 3500,
        "stock": 60,
        "description": "Tongs légères et résistantes, disponibles en 8 coloris vifs.",
        "image_url": "https://images.unsplash.com/photo-1603487742131-4160ec999306?w=400",
    },
    {
        "name": "Bottines Femme Mode",
        "category": cat_chaussures,
        "price": 24000,
        "stock": 12,
        "description": "Bottines montantes à lacets style western, très tendance cette saison.",
        "image_url": "https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=400",
    },
    {
        "name": "Chaussures Bébé Premiers Pas",
        "category": cat_chaussures,
        "price": 5500,
        "stock": 22,
        "description": "Chaussures souples pour bébé qui apprend à marcher, sécurisées.",
        "image_url": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400",
    },
    {
        "name": "Sneakers Running Unisex",
        "category": cat_chaussures,
        "price": 21000,
        "stock": 30,
        "description": "Chaussures de running légères pour homme et femme, technologie amorti.",
        "image_url": "https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=400",
    },

    # ===== SACS (8 produits) =====
    {
        "name": "Sac à Main Cuir Femme",
        "category": cat_sacs,
        "price": 19000,
        "stock": 15,
        "description": "Sac à main en cuir PU de qualité, plusieurs compartiments pratiques.",
        "image_url": "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400",
    },
    {
        "name": "Sac à Dos Urbain",
        "category": cat_sacs,
        "price": 14500,
        "stock": 25,
        "description": "Sac à dos anti-vol avec port USB, idéal pour le bureau et les voyages.",
        "image_url": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400",
    },
    {
        "name": "Tote Bag Canvas Imprimé",
        "category": cat_sacs,
        "price": 5000,
        "stock": 50,
        "description": "Tote bag en toile résistante avec imprimé africain, éco-responsable.",
        "image_url": "https://images.unsplash.com/photo-1544816155-12df9643f363?w=400",
    },
    {
        "name": "Pochette Soirée Dorée",
        "category": cat_sacs,
        "price": 8500,
        "stock": 20,
        "description": "Pochette de soirée dorée avec chaîne, parfaite pour les grandes occasions.",
        "image_url": "https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?w=400",
    },
    {
        "name": "Sac Gym Sport",
        "category": cat_sacs,
        "price": 9000,
        "stock": 30,
        "description": "Sac de sport léger et spacieux avec poche à chaussures séparée.",
        "image_url": "https://images.unsplash.com/photo-1547949003-9792a18a2601?w=400",
    },
    {
        "name": "Sac Bandoulière Homme",
        "category": cat_sacs,
        "price": 12000,
        "stock": 20,
        "description": "Sac bandoulière compact en tissu résistant, style décontracté.",
        "image_url": "https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=400",
    },
    {
        "name": "Sac de Voyage Cabine",
        "category": cat_sacs,
        "price": 22000,
        "stock": 12,
        "description": "Sac de voyage format cabine 40L, résistant à l'eau et léger.",
        "image_url": "https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=400",
    },
    {
        "name": "Mini Sac Ceinture",
        "category": cat_sacs,
        "price": 6500,
        "stock": 35,
        "description": "Banane moderne style urbain, pratique pour garder l'essentiel.",
        "image_url": "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400",
    },

    # ===== MAISON (8 produits) =====
    {
        "name": "Housse de Coussin Wax",
        "category": cat_maison,
        "price": 4500,
        "stock": 40,
        "description": "Housse de coussin 45x45cm en tissu wax authentique, décoration africaine.",
        "image_url": "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400",
    },
    {
        "name": "Natte en Raphia Artisanale",
        "category": cat_maison,
        "price": 8000,
        "stock": 20,
        "description": "Natte tissée à la main en fibres de raphia, taille 120x180cm.",
        "image_url": "https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=400",
    },
    {
        "name": "Set de Table Africain (6 pcs)",
        "category": cat_maison,
        "price": 12000,
        "stock": 18,
        "description": "Ensemble 6 sets de table en coton imprimé, style africain moderne.",
        "image_url": "https://images.unsplash.com/photo-1490735891913-40897cdaafd1?w=400",
    },
    {
        "name": "Lanterne Décorative",
        "category": cat_maison,
        "price": 7500,
        "stock": 25,
        "description": "Lanterne en métal ajouré avec bougie LED, parfaite pour l'ambiance.",
        "image_url": "https://images.unsplash.com/photo-1507652313519-d4e9174996dd?w=400",
    },
    {
        "name": "Panier de Rangement Osier",
        "category": cat_maison,
        "price": 9500,
        "stock": 22,
        "description": "Panier tressé en osier naturel, idéal pour le rangement et la décoration.",
        "image_url": "https://images.unsplash.com/photo-1532499016263-f2c3e89de9cd?w=400",
    },
    {
        "name": "Rideau Voilage Blanc",
        "category": cat_maison,
        "price": 11000,
        "stock": 30,
        "description": "Paire de rideaux voilage 140x260cm, effet lumineux et aérien.",
        "image_url": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400",
    },
    {
        "name": "Miroir Mural Rotin",
        "category": cat_maison,
        "price": 18500,
        "stock": 12,
        "description": "Miroir encadré de rotin naturel, tendance bohème pour votre intérieur.",
        "image_url": "https://images.unsplash.com/photo-1564078516393-cf04bd966897?w=400",
    },
    {
        "name": "Tableau Batik Décoratif",
        "category": cat_maison,
        "price": 15000,
        "stock": 10,
        "description": "Tableau en tissu batik encadré 40x60cm, art africain authentique.",
        "image_url": "https://images.unsplash.com/photo-1513519245088-0e12902e35a6?w=400",
    },
]

created = 0
skipped = 0
for p in produits:
    slug = slugify(p['name'])
    # Éviter les doublons de slug
    base_slug = slug
    counter = 1
    while Product.objects.filter(slug=slug).exists():
        slug = f"{base_slug}-{counter}"
        counter += 1
    
    Product.objects.create(
        store=store,
        category=p['category'],
        name=p['name'],
        slug=slug,
        description=p['description'],
        price=p['price'],
        stock=p['stock'],
        image_url=p['image_url'],
        is_active=True,
    )
    created += 1
    print(f"  ✅ Créé: {p['name']}")

print(f"\n🎉 Terminé ! {created} produits ajoutés, {skipped} ignorés.")
