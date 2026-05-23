# Cahier des charges - BoboExpress

## 1. Présentation du projet

**Nom du projet :** BoboExpress  
**Type :** Plateforme web et mobile de commande, livraison et gestion commerciale  
**Technologies principales :** Django REST Framework, Flutter, JWT, SQLite/MySQL

BoboExpress est une application inspirée de services comme Glovo, Uber Eats ou Jumia Food. Elle permet aux clients de commander des produits auprès de boutiques locales, aux marchands de gérer leurs produits et commandes, aux livreurs de gérer leurs missions, et aux administrateurs de superviser toute la plateforme.

## 2. Objectifs

- Permettre aux clients de créer un compte, parcourir les produits, commander et suivre la livraison.
- Permettre aux marchands de gérer leurs boutiques, produits et commandes.
- Permettre aux livreurs de consulter, accepter et finaliser des missions.
- Permettre aux administrateurs de gérer les utilisateurs, boutiques, commandes, livreurs, paiements et statistiques.
- Fournir une API sécurisée et documentée pour l'application mobile et web.

## 3. Utilisateurs et rôles

### Client

- Créer un compte et se connecter.
- Consulter les catégories, boutiques et produits.
- Ajouter des produits au panier.
- Passer une commande.
- Choisir une adresse de livraison.
- Initier un paiement.
- Suivre le statut de la commande.
- Donner un avis sur un produit.

### Marchand

- Créer et gérer une boutique.
- Ajouter, modifier ou supprimer des produits.
- Gérer les variantes de produits.
- Voir les commandes reçues.
- Mettre à jour les statuts de commande.
- Consulter ses ventes.

### Livreur

- Se connecter à son espace livreur.
- Voir les missions disponibles ou assignées.
- Accepter une livraison.
- Mettre à jour sa disponibilité.
- Mettre à jour sa position.
- Confirmer la livraison avec un code OTP.

### Administrateur

- Se connecter à un tableau de bord admin.
- Voir les statistiques globales.
- Gérer les utilisateurs et leurs rôles.
- Bloquer, débloquer ou vérifier un utilisateur.
- Gérer les boutiques et catégories.
- Assigner un livreur à une commande.
- Consulter les commandes, paiements et notifications.

## 4. Fonctionnalités principales

### Authentification

- Inscription utilisateur.
- Connexion par JWT.
- Rafraîchissement du token.
- Gestion du profil utilisateur.
- Changement de mot de passe.
- Gestion des rôles : client, marchand, livreur, administrateur.

### Catalogue

- Liste des catégories.
- Liste des produits.
- Recherche de produits.
- Détail produit.
- Images produit.
- Prix, promotions, stock et variantes.

### Panier

- Ajout au panier.
- Suppression d'un article.
- Modification des quantités.
- Calcul du total.

### Commandes

- Création d'une commande.
- Historique des commandes.
- Suivi de statut.
- Statuts attendus : en attente, acceptée, préparation, prête, livraison, livrée, annulée.
- Assignation d'un livreur.

### Paiements

- Initialisation du paiement.
- Paiement mobile money ou wallet.
- Vérification OTP si nécessaire.
- Historique des transactions.

### Livraison

- Liste des missions.
- Acceptation d'une mission.
- Départ en livraison.
- Mise à jour GPS.
- Confirmation de livraison.

### Notifications

- Notifications liées aux commandes.
- Notifications pour livreurs et marchands.
- Diffusion admin vers un rôle cible.

### Analytics

- Nombre total d'utilisateurs.
- Nombre de commandes.
- Chiffre d'affaires.
- Commandes par statut.
- Livreurs disponibles.
- Statistiques des livreurs.

## 5. Exigences techniques

### Backend

- Framework : Django + Django REST Framework.
- Authentification : JWT avec SimpleJWT.
- Base de données en développement : SQLite.
- Base de données en production : MySQL.
- Documentation API : Swagger et ReDoc.
- Gestion des médias : dossier `media/`.
- Variables d'environnement : `.env`.

### Frontend mobile/web

- Framework : Flutter.
- Interface responsive.
- Navigation selon le rôle utilisateur.
- Gestion du token sécurisé.
- Appels API vers le backend Django.
- Support français et anglais.

### API principales

- `POST /api/auth/register/`
- `POST /api/auth/token/`
- `POST /api/auth/token/refresh/`
- `GET /api/users/me/`
- `PATCH /api/users/me/`
- `GET /api/products/products/`
- `GET /api/products/categories/`
- `GET /api/stores/stores/`
- `GET /api/orders/orders/`
- `POST /api/orders/orders/`
- `GET /api/delivery/missions/`
- `GET /api/analytics/dashboard/`

## 6. Sécurité

- Authentification obligatoire sur les endpoints sensibles.
- Permissions selon le rôle utilisateur.
- Interdiction de créer un administrateur depuis l'inscription publique.
- Protection des secrets dans `.env`.
- Validation des données côté backend.
- Tokens JWT avec durée de vie limitée.
- Possibilité de bloquer un utilisateur.

## 7. Contraintes non fonctionnelles

- Interface simple, moderne et lisible.
- Temps de réponse API cible : moins de 300 ms en local ou réseau stable.
- Application compatible mobile et web.
- Code maintenable et organisé par modules.
- Documentation claire pour l'installation et le lancement.
- Gestion propre des erreurs utilisateur.

## 8. Environnement de développement

### Backend

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:USE_SQLITE='True'
python manage.py migrate
python manage.py runserver 127.0.0.1:8000
```

### Frontend Flutter

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

## 9. Déploiement

Le déploiement prévu peut utiliser Docker Compose avec :

- Service `web` pour Django.
- Service `db` pour MySQL.
- Serveur applicatif Gunicorn.
- Reverse proxy recommandé : Nginx ou Apache.
- Collecte des fichiers statiques avec `collectstatic`.

Commande de référence :

```powershell
docker compose up -d --build
```

## 10. Tests attendus

- Test de connexion JWT.
- Test d'inscription.
- Test de création de commande.
- Test d'ajout au panier.
- Test de changement de statut commande.
- Test d'assignation livreur.
- Test d'accès admin.
- Test Flutter avec `flutter analyze`.
- Test Django avec `python manage.py check`.

## 11. Livrables

- Code backend Django.
- Code frontend Flutter.
- Base de données de développement.
- Documentation API Swagger/ReDoc.
- Cahier des charges.
- Guide d'installation.
- Guide d'utilisation admin.

## 12. Critères d'acceptation

- Un utilisateur peut créer un compte et se connecter.
- Un client peut consulter les produits et passer commande.
- Un marchand peut gérer ses produits.
- Un livreur peut voir et finaliser ses missions.
- Un administrateur peut gérer les utilisateurs et consulter les statistiques.
- Les images produits s'affichent correctement.
- Les API principales répondent sans erreur.
- L'application Flutter ne présente aucune erreur avec `flutter analyze`.
- Le backend passe `python manage.py check`.

## 13. Évolutions possibles

- Paiement réel mobile money.
- Chat client-livreur.
- Géolocalisation en temps réel.
- Notifications push.
- Factures PDF.
- Tableau de bord marchand avancé.
- Application livreur séparée.
- Déploiement cloud.
