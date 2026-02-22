@echo off
REM Restart NanoClaw via HTTP admin API
cd /d "%~dp0"

echo Restarting NanoClaw...

REM Read ADMIN_TOKEN from .env
set TOKEN=
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr /b "ADMIN_TOKEN=" .env 2^>nul') do set TOKEN=%%a
)

if not defined TOKEN (
    echo [ERROR] ADMIN_TOKEN not found in .env file
    pause
    exit /b 1
)

REM Call restart endpoint
curl -s -X POST -H "X-Admin-Token: %TOKEN%" http://localhost:9999/restart >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Restart signal sent to NanoClaw
) else (
    echo [WARNING] Failed to connect to admin interface
)

echo.
pause
