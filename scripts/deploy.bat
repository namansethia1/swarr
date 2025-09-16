@echo off
REM Project Swar Windows Deployment Script
setlocal EnableDelayedExpansion

set "ENVIRONMENT=%~1"
if "%ENVIRONMENT%"=="" set "ENVIRONMENT=development"

echo 🚀 Starting Project Swar deployment...

REM Check dependencies
echo [INFO] Checking dependencies...
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker first.
    exit /b 1
)

where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not installed. Please install Docker Compose first.
    exit /b 1
)

echo [INFO] Dependencies check passed ✓

if "%1"=="stop" (
    echo [INFO] Stopping all services...
    docker-compose down --remove-orphans
    echo [INFO] Services stopped ✓
    goto :end
)

if "%1"=="cleanup" (
    echo [INFO] Cleaning up Docker resources...
    docker-compose down --remove-orphans --volumes
    docker system prune -f
    echo [INFO] Cleanup completed ✓
    goto :end
)

if "%1"=="status" (
    echo [INFO] Service Status:
    docker-compose ps
    echo.
    echo [INFO] Service Logs (last 10 lines):
    echo Backend logs:
    docker-compose logs --tail=10 backend
    echo.
    echo Frontend logs:
    docker-compose logs --tail=10 frontend
    goto :end
)

REM Deploy services
echo [INFO] Deploying locally with Docker Compose...

REM Stop existing containers
echo [INFO] Stopping existing containers...
docker-compose down --remove-orphans

REM Build and start containers
echo [INFO] Building and starting containers...
if "%ENVIRONMENT%"=="production" (
    docker-compose --profile production up --build -d
) else (
    docker-compose up --build -d
)

REM Wait for services to be healthy
echo [INFO] Waiting for services to be healthy...
timeout /t 30 /nobreak >nul

REM Check service health
echo [INFO] Checking service health...
curl -s -o nul -w "%%{http_code}" http://localhost:8000/health >temp_backend.txt 2>nul
set /p backend_health=<temp_backend.txt
del temp_backend.txt

curl -s -o nul -w "%%{http_code}" http://localhost:3000/health >temp_frontend.txt 2>nul
set /p frontend_health=<temp_frontend.txt
del temp_frontend.txt

if "%backend_health%"=="200" (
    echo [INFO] Backend service is healthy ✓
) else (
    echo [ERROR] Backend service is not healthy (HTTP %backend_health%^)
)

if "%frontend_health%"=="200" (
    echo [INFO] Frontend service is healthy ✓
) else (
    echo [ERROR] Frontend service is not healthy (HTTP %frontend_health%^)
)

echo [INFO] Deployment completed! 🎉
echo [INFO] Frontend: http://localhost:3000
echo [INFO] Backend API: http://localhost:8000
echo [INFO] API Docs: http://localhost:8000/docs

:end
endlocal