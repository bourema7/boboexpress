# Importer la base locale vers Render

Ce fichier explique comment charger dans Render le catalogue local exporte dans :

- `deploy/render_seed_184_products.json`
- `deploy/render_media_products.zip`

Le fichier JSON contient les comptes, profils, boutiques, categories, produits et variantes
necessaires pour reconstruire le catalogue local de 184 produits.

## 1. Verifier le disque Render

Dans Render, ouvre le service `boboexpress`, puis verifie qu'un disque persistant existe :

```text
Mount path: /var/data
```

Sans disque persistant, les comptes et produits peuvent disparaitre apres un redeploiement.

## 2. Verifier les variables Render

Dans `Environment`, garde au minimum :

```env
USE_SQLITE=True
SQLITE_NAME=/var/data/db.sqlite3
MEDIA_ROOT=/var/data/media
```

## 3. Deployer ces fichiers

Commit puis push ces fichiers vers le repo utilise par Render :

```bash
git add render.yaml deploy/render_seed_184_products.json deploy/render_media_products.zip deploy/IMPORT_RENDER_CATALOG.md
git commit -m "Add Render catalog import"
git push
```

Attends que Render termine le redeploiement.

## 4. Charger les donnees dans Render Shell

Dans Render, ouvre `Shell` et lance :

```bash
python manage.py migrate
python manage.py loaddata deploy/render_seed_184_products.json
python -m zipfile -e deploy/render_media_products.zip /var/data/media
python manage.py shell -c "from django.contrib.auth.models import User; from products.models import Product; print('Comptes:', User.objects.count()); print('Produits:', Product.objects.count()); print('Produits visibles:', Product.objects.filter(is_active=True, stock__gt=0).count())"
```

Si Render contient deja des categories ou produits avec les memes slugs mais des IDs differents,
`loaddata` peut echouer avec une erreur `UNIQUE constraint failed`. Dans ce cas, et seulement si
tu veux remplacer la base Render par la base locale, lance avant l'import :

```bash
python manage.py flush --noinput
python manage.py migrate
python manage.py loaddata deploy/render_seed_184_products.json
python -m zipfile -e deploy/render_media_products.zip /var/data/media
python manage.py ensure_admin
```

Attention : `flush` supprime les donnees deja presentes sur Render.
