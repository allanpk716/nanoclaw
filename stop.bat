@echo off
REM Stop NanoClaw
echo Stopping NanoClaw...
taskkill /F /IM node.exe >nul 2>nul

if %errorlevel% equ 0 (
    echo [OK] NanoClaw stopped
) else (
    echo No running NanoClaw process found
)
