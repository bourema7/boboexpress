# Nginx Reverse Proxy

Le fichier `boboexpress.conf` est un template.

## À changer

- `server_name your-domain.com;`
- `ssl_certificate`
- `ssl_certificate_key`

Remplacer `your-domain.com` par ton vrai domaine.

## Frontend

Nginx sert le build Flutter Web depuis :

```text
mobile/build/web
```

Créer ce build avec :

```bash
cd mobile
flutter build web --release --dart-define=BASE_URL=https://your-domain.com/api
```

## API

Les requêtes `/api/` sont envoyées vers le service Docker `web:8000`.

## Certbot

Le challenge Let's Encrypt utilise :

```text
deploy/certbot/www
```
