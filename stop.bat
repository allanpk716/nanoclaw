@echo off
REM Stop NanoClaw via HTTP admin API
cd /d "%~dp0"

echo Stopping NanoClaw...

REM Read ADMIN_TOKEN from .env
set TOKEN=
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr /b "ADMIN_TOKEN=" .env 2^>nul') do set TOKEN=%%a
)

if not defined TOKEN (
    echo [ERROR] ADMIN_TOKEN not found in .env file
    echo Make sure NanoClaw has been started at least once to generate the token.
    pause
    exit /b 1
)

REM Call shutdown endpoint
curl -s -X POST -H "X-Admin-Token: %TOKEN%" http://localhost:9999/shutdown >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Shutdown signal sent to NanoClaw
) else (
    echo [WARNING] Failed to connect to admin interface
    echo NanoClaw may not be running, or admin server is disabled.
)

echo.
pause
