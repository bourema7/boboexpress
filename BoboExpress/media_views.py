import mimetypes
from pathlib import Path
from zipfile import ZipFile

from django.conf import settings
from django.http import FileResponse, Http404, HttpResponse
from django.utils._os import safe_join


def serve_media_file(request, path):
    try:
        file_path = Path(safe_join(settings.MEDIA_ROOT, path))
    except ValueError as exc:
        raise Http404('Invalid media path') from exc

    content_type = mimetypes.guess_type(path)[0] or 'application/octet-stream'
    if file_path.exists() and file_path.is_file():
        return FileResponse(file_path.open('rb'), content_type=content_type)

    archive_path = Path(settings.BASE_DIR) / 'deploy' / 'render_media_products.zip'
    archive_name = path.replace('\\', '/')
    if archive_path.exists():
        with ZipFile(archive_path) as archive:
            if archive_name in archive.namelist():
                return HttpResponse(
                    archive.read(archive_name),
                    content_type=content_type,
                )

    raise Http404('Media file not found')
