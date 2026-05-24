from pathlib import Path
from zipfile import ZipFile

from django.conf import settings
from django.core.management import BaseCommand, call_command

from products.models import Product


class Command(BaseCommand):
    help = 'Import the bundled Render catalog only when no products exist.'

    def handle(self, *args, **options):
        if Product.objects.exists():
            self.stdout.write('Products already exist; skipping catalog import.')
            return

        fixture_path = Path(settings.BASE_DIR) / 'deploy' / 'render_seed_184_products.json'
        media_zip_path = Path(settings.BASE_DIR) / 'deploy' / 'render_media_products.zip'

        if not fixture_path.exists():
            self.stdout.write(self.style.WARNING(f'Catalog fixture missing: {fixture_path}'))
            return

        self.stdout.write(f'Importing catalog fixture: {fixture_path}')
        call_command('loaddata', str(fixture_path))

        if media_zip_path.exists():
            media_root = Path(settings.MEDIA_ROOT)
            media_root.mkdir(parents=True, exist_ok=True)
            self.stdout.write(f'Extracting product media to: {media_root}')
            with ZipFile(media_zip_path) as archive:
                archive.extractall(media_root)
        else:
            self.stdout.write(self.style.WARNING(f'Product media archive missing: {media_zip_path}'))

        visible_count = Product.objects.filter(is_active=True, stock__gt=0).count()
        self.stdout.write(
            self.style.SUCCESS(
                f'Catalog import complete: {Product.objects.count()} products, '
                f'{visible_count} visible.'
            )
        )
