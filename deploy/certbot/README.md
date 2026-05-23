# Let’s Encrypt (Certbot)

Ce projet ne déploie pas automatiquement Let’s Encrypt : il faut exécuter certbot sur la machine hôte.

## Étapes rapides
1. Ouvrir les ports 80 et 443 sur le firewall.
2. Mettre `server_name` et les chemins cert dans `deploy/nginx/conf.d/boboexpress.conf`.
3. Lancer certbot (exemple nginx standalone ou webroot).

### Option webroot (recommandée)
Assurez-vous que le dossier `/var/www/certbot` existe et est accessible.

Commande (à adapter) :
- `certbot certonly --webroot -w /var/www/certbot -d your-domain.com`

Ensuite, Nginx chargera :
- `/etc/letsencrypt/live/your-domain.com/fullchain.pem`
- `/etc/letsencrypt/live/your-domain.com/privkey.pem`

