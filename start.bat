@echo off
REM Start NanoClaw (background mode)
cd /d "%~dp0"

echo Starting NanoClaw...

REM Create logs directory
if not exist logs mkdir logs

REM Start in background
start /B node dist/index.js > logs\nanoclaw.log 2>&1

echo NanoClaw started in background.
echo.
echo Log file: logs\nanoclaw.log
echo View log: type logs\nanoclaw.log
echo Stop service: stop.bat
echo.

timeout /t 3 /nobreak >nul
type logs\nanoclaw.log
echo.
pause
