# BoboExpress

Plateforme complète de commandes et livraisons en ligne, inspirée d'Uber Eats, Glovo, Jumia Food.

## Structure du projet

- `BoboExpress/` : backend Django + Django REST Framework
- `mobile/` : frontend Flutter responsive mobile + web

## Modules backend

- `users` : gestion des profils, rôles, adresses, inscription, OTP
- `stores` : boutiques, catégories, promotions
- `products` : catégories de produits, produits, avis, codes promo
- `orders` : commandes, items, suivi
- `payments` : paiements, wallet, transactions
- `delivery` : missions, suivi GPS, attribution de livreur
- `notifications` : push, email, SMS (gestion et logs)
- `analytics` : statistiques et dashboard admin

## Installation backend

1. Crée et active un environnement virtuel :
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   ```
2. Installe les dépendances :
   ```powershell
   pip install -r requirements.txt
   ```
3. Configure la base de données MySQL :
   - `MYSQL_DATABASE`
   - `MYSQL_USER`
   - `MYSQL_PASSWORD`
   - `MYSQL_HOST`
   - `MYSQL_PORT`
   - `DJANGO_SECRET_KEY`
   - `DJANGO_DEBUG=False`

4. Applique les migrations :
   ```powershell
   python manage.py makemigrations
   python manage.py migrate
   ```
5. Crée un superutilisateur :
   ```powershell
   python manage.py createsuperuser
   ```
6. Lance le serveur :
   ```powershell
   python manage.py runserver 0.0.0.0:8000
   ```

## API REST

- `POST /api/users/auth/register/` : inscription
- `POST /api/auth/token/` : connexion JWT
- `POST /api/auth/token/refresh/` : rafraîchir token
- `GET /api/users/users/me/` : profil connecté
- `GET /api/stores/stores/` : boutiques
- `POST /api/stores/stores/` : créer boutique (vendeur)
- `GET /api/products/products/` : produits
- `POST /api/products/products/` : ajouter produit (vendeur)
- `GET /api/orders/orders/` : commandes
- `POST /api/orders/orders/` : créer commande
- `POST /api/orders/orders/{id}/accept/` : commerçant accepte la commande
- `POST /api/orders/orders/{id}/reject/` : commerçant refuse la commande
- `POST /api/orders/orders/{id}/mark_preparing/` : commande en préparation
- `POST /api/orders/orders/{id}/mark_ready/` : commande prête pour livraison
- `POST /api/orders/orders/{id}/assign_driver/` : admin assigne manuellement un livreur
- `GET /api/payments/payments/` : transactions utilisateur
- `GET /api/delivery/missions/` : missions livreur
- `POST /api/delivery/missions/{id}/accept/` : livreur accepte la mission
- `POST /api/delivery/missions/{id}/start/` : livreur démarre la livraison
- `POST /api/delivery/missions/{id}/update_location/` : mise à jour GPS du livreur
- `POST /api/delivery/missions/{id}/deliver/` : confirmation de livraison
- `POST /api/delivery/missions/{id}/assign/` : admin assigne un livreur à une mission
- `GET /api/notifications/notifications/` : notifications utilisateur
- `GET /api/analytics/dashboard/` : statistiques admin

## Frontend Flutter

- responsive pour mobile Android/iOS et web
- design moderne et jeu de couleurs premium
- navigation role-based : client, livreur, marchand, admin
- pages : splash, onboarding, login, inscription, recherche, panier, paiement, suivi, profil, admin

## Déploiement

- Prêt pour production avec MySQL et `gunicorn`
- API documentation disponible à : `/api/docs/` et `/api/redoc/`
- Configure un reverse proxy (Nginx/Apache) pour exposer le backend

## Notes

Ce projet est structuré pour être extensible, facile à modifier et opérationnel immédiatement en environnement de développement.
