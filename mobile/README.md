# BoboMarket Mobile

Application Flutter de démonstration pour la marketplace BoboMarket.

## Installation

1. Place-toi dans le dossier mobile :
   ```powershell
   cd mobile
   ```
2. Installe les dépendances :
   ```powershell
   flutter pub get
   ```
3. Lance l’application :
   ```powershell
   flutter run
   ```

## Fonctionnalités incluses

- Page d’accueil
- Connexion JWT
- Inscription utilisateur
- Liste des produits depuis l’API Django

## Configuration API

L’application utilise par défaut l’URL :
`http://10.0.2.2:8000/api`

Pour un appareil Android émulé, `10.0.2.2` pointe vers le serveur local Windows.

## Prochaines étapes

- Ajouter le panier et le paiement
- Ajouter la navigation pour boutiques et commandes
- Ajouter le profil client et le suivi de livraison
