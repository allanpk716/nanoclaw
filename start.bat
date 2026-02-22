@echo off
REM Start NanoClaw (background mode)
cd /d "%~dp0"

echo Starting NanoClaw...

REM Create logs directory
if not exist logs mkdir logs

REM Start in a new minimized window
start "NanoClaw" /MIN node dist/index.js > logs\nanoclaw.log 2>&1

echo NanoClaw started in background.
echo.
echo Log file: logs\nanoclaw.log
echo View log: type logs\nanoclaw.log
echo Stop service: stop.bat
echo.
pause
