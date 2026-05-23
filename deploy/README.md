# Déploiement BoboExpress

Déploiement de l'API Django, du frontend Flutter Web, de MySQL et de Nginx avec HTTPS.

## Prérequis

- Un VPS Ubuntu/Debian.
- Un nom de domaine pointant vers l'IP du VPS.
- Docker et Docker Compose installés sur le VPS.
- Ports `80` et `443` ouverts.

## 1. Variables de production

Copier l'exemple :

```bash
cp .env.prod.example .env
```

Modifier au minimum :

- `DJANGO_SECRET_KEY`
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`
- `DJANGO_ALLOWED_HOSTS`
- `CORS_ALLOWED_ORIGINS`
- `CSRF_TRUSTED_ORIGINS`

Exemple :

```env
DJANGO_ALLOWED_HOSTS=boboexpress.com,www.boboexpress.com
CORS_ALLOWED_ORIGINS=https://boboexpress.com,https://www.boboexpress.com
CSRF_TRUSTED_ORIGINS=https://boboexpress.com,https://www.boboexpress.com
```

## 2. Build Flutter Web

Depuis la racine du projet :

```bash
cd mobile
flutter build web --release --dart-define=BASE_URL=https://boboexpress.onrender.com/api
cd ..
```

Le conteneur Nginx sert `mobile/build/web`.

## 3. Configurer Nginx

La configuration fournie cible déjà `boboexpress.com` et `www.boboexpress.com` :

```nginx
server_name boboexpress.com www.boboexpress.com;
ssl_certificate     /etc/letsencrypt/live/boboexpress.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/boboexpress.com/privkey.pem;
```

## 4. Certificat HTTPS

Créer les dossiers attendus :

```bash
mkdir -p deploy/certbot/www deploy/nginx/certs
```

Exemple Certbot sur l'hôte :

```bash
sudo certbot certonly --webroot \
  -w /chemin/vers/BoboExpress/deploy/certbot/www \
  -d boboexpress.com \
  -d www.boboexpress.com
```

Ensuite, assure-toi que les certificats Let's Encrypt sont disponibles dans `deploy/nginx/certs/live/boboexpress.com/`, car ce dossier est monté dans Nginx à `/etc/letsencrypt`.

## 5. Lancer

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

## 6. Vérifier

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f web
docker compose -f docker-compose.prod.yml logs -f nginx
```

URLs :

- Site : `https://boboexpress.com/`
- API docs : `https://boboexpress.com/api/docs/`
- Admin Django : `https://boboexpress.com/admin/`

## Notes

- Le service `web` lance automatiquement `migrate` et `collectstatic`.
- Le frontend doit être rebuildé à chaque changement d'URL API.
- Pour l'application Android physique, utiliser aussi l'URL publique :

```bash
flutter run --dart-define=BASE_URL=https://boboexpress.onrender.com/api
```
