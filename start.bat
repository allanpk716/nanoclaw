@echo off
REM Start NanoClaw (background mode) with PID tracking
cd /d "%~dp0"

echo Starting NanoClaw...

REM Stop existing instances (PID-based)
if exist nanoclaw.pid (
    set /p OLD_PID=<nanoclaw.pid
    taskkill /PID %OLD_PID% /F >nul 2>nul
    timeout /t 2 /nobreak >nul
    del nanoclaw.pid
)

REM Create logs directory
if not exist logs mkdir logs

REM Start in background with environment variables from .env
start /B node --import dotenv/config dist/index.js > logs\nanoclaw.log 2>&1

REM Capture PID (find most recent node.exe running NanoClaw)
timeout /t 1 /nobreak >nul
for /f "tokens=2 delims=," %%a in ('wmic process where "name='node.exe'" get ProcessId^,CommandLine /format:csv 2^>nul ^| find "dist/index.js"') do (
    set NEW_PID=%%a
)

if defined NEW_PID (
    echo %NEW_PID% > nanoclaw.pid
    echo.
    echo [OK] NanoClaw started (PID: %NEW_PID%)
) else (
    echo [WARNING] Could not capture PID - process may have failed to start
    echo Check logs\nanoclaw.log for errors
)

echo Log file: logs\nanoclaw.log
echo.
echo View log: type logs\nanoclaw.log
echo Stop service: stop.bat
echo.

timeout /t 3 /nobreak >nul
type logs\nanoclaw.log
