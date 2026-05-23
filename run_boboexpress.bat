@echo off
rem -------------------------------------------------
rem BoboExpress launch script - Docker Compose
rem -------------------------------------------------

rem 1. Build and start containers
docker compose up -d --build

rem 2. Wait for MySQL to be ready
echo Waiting for MySQL to be ready...
:wait_mysql
docker compose exec db mysqladmin ping -h"db" --silent
if errorlevel 1 (
    timeout /t 2 >nul
    goto wait_mysql
)

rem 3. Apply migrations and collect static files
docker compose exec web bash -c "python manage.py migrate && python manage.py collectstatic --noinput"

rem 4. Create a superuser (interactive, run when needed)
echo If you need a superuser, run the following command:
echo   docker compose exec web python manage.py createsuperuser

rem 5. Show container status
docker compose ps

echo.
echo BoboExpress is now running at http://localhost:8000
echo For a physical phone, use your PC LAN IP, for example:
echo   flutter run --dart-define=BASE_URL=http://YOUR_PC_IP:8000/api
