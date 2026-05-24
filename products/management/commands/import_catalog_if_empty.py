from pathlib import Path
import shutil
from zipfile import ZipFile

from django.conf import settings
from django.core.management import BaseCommand, call_command

from products.models import Product


class Command(BaseCommand):
    help = 'Import the bundled Render catalog when Render has an incomplete catalog.'

    def handle(self, *args, **options):
        expected_products = 184
        current_products = Product.objects.count()
        fixture_path = Path(settings.BASE_DIR) / 'deploy' / 'render_seed_184_products.json'
        media_zip_path = Path(settings.BASE_DIR) / 'deploy' / 'render_media_products.zip'

        if current_products >= expected_products:
            self.stdout.write(
                f'Catalog already has {current_products} products; skipping fixture import.'
            )
            self._extract_media(media_zip_path)
            return

        self.stdout.write(
            f'Catalog has only {current_products}/{expected_products} products. '
            f'Importing fixture: {fixture_path}'
        )
        if not fixture_path.exists():
            self.stdout.write(self.style.WARNING(f'Catalog fixture missing: {fixture_path}'))
            self._extract_media(media_zip_path)
            return

        call_command('loaddata', str(fixture_path))
        self._extract_media(media_zip_path)

        visible_count = Product.objects.filter(is_active=True, stock__gt=0).count()
        self.stdout.write(
            self.style.SUCCESS(
                f'Catalog import complete: {Product.objects.count()} products, '
                f'{visible_count} visible.'
            )
        )

    def _extract_media(self, media_zip_path):
        if media_zip_path.exists():
            media_root = Path(settings.MEDIA_ROOT)
            media_root.mkdir(parents=True, exist_ok=True)
            self.stdout.write(f'Extracting product media to: {media_root}')
            with ZipFile(media_zip_path) as archive:
                extracted = 0
                for member in archive.infolist():
                    target = media_root / member.filename
                    if member.is_dir() or target.exists():
                        continue
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with archive.open(member) as source, target.open('wb') as destination:
                        shutil.copyfileobj(source, destination)
                    extracted += 1
                self.stdout.write(f'Extracted {extracted} missing media file(s).')
        else:
            self.stdout.write(self.style.WARNING(f'Product media archive missing: {media_zip_path}'))
