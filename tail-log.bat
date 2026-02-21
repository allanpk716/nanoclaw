@echo off
REM View NanoClaw log in real-time
cd /d "%~dp0"

if not exist logs\nanoclaw.log (
    echo Log file not found
    echo Please start NanoClaw first: start.bat
    pause
    exit /b 1
)

echo Displaying NanoClaw log (Ctrl+C to exit)
echo ========================================
echo.

powershell -Command "Get-Content logs\nanoclaw.log -Wait"
