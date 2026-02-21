@echo off
REM Start NanoClaw (background mode)
cd /d "%~dp0"

echo Starting NanoClaw...

REM Stop existing instances
taskkill /F /IM node.exe >nul 2>nul
timeout /t 2 /nobreak >nul

REM Create logs directory
if not exist logs mkdir logs

REM Start in background
start /B node dist/index.js > logs\nanoclaw.log 2>&1

echo.
echo [OK] NanoClaw started in background
echo Log file: logs\nanoclaw.log
echo.
echo View log: type logs\nanoclaw.log
echo Stop service: taskkill /F /IM node.exe
echo.

timeout /t 3 /nobreak >nul
type logs\nanoclaw.log
