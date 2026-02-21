@echo off
REM NanoClaw Quick Start Script

echo ========================================
echo NanoClaw Telegram Bot Manager
echo ========================================
echo.

REM Check Node.js installation
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not installed
    echo Please download from https://nodejs.org/
    pause
    exit /b 1
)

REM Change to project directory
cd /d "%~dp0"

REM Handle command line arguments
if "%1"=="" goto menu
if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="restart" goto restart
if "%1"=="status" goto status
if "%1"=="logs" goto logs
if "%1"=="direct" goto direct
goto menu

:menu
echo Select operation:
echo.
echo 1. Start NanoClaw directly (Recommended, stable)
echo 2. Start with PM2
echo 3. Stop all instances
echo 4. Restart NanoClaw
echo 5. View status
echo 6. View logs
echo 7. Exit
echo.
set /p choice="Enter option (1-7): "

if "%choice%"=="1" goto direct
if "%choice%"=="2" goto start
if "%choice%"=="3" goto stop
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto status
if "%choice%"=="6" goto logs
if "%choice%"=="7" exit /b 0
goto menu

:direct
echo.
echo [START] Starting NanoClaw directly...
echo Log output to: logs\nanoclaw.log
echo Press Ctrl+C to stop
echo.

REM Stop other instances
taskkill /F /IM node.exe >nul 2>nul

REM Create logs directory
if not exist logs mkdir logs

REM Start and output log
node dist/index.js 2>&1 | tee logs\nanoclaw.log
goto end

:start
echo.
echo [START] Starting NanoClaw with PM2...

REM Check PM2 installation
where pm2 >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARNING] PM2 not installed
    echo Installing PM2...
    npm install -g pm2
)

pm2 start ecosystem.config.cjs
pm2 status
echo.
echo [OK] NanoClaw started
goto end

:stop
echo.
echo [STOP] Stopping NanoClaw...

REM Stop PM2 process
pm2 stop nanoclaw >nul 2>nul
pm2 delete nanoclaw >nul 2>nul

REM Stop direct process
taskkill /F /IM node.exe >nul 2>nul

echo.
echo [OK] NanoClaw stopped
goto end

:restart
echo.
echo [RESTART] Restarting NanoClaw...

REM Stop all instances
pm2 stop nanoclaw >nul 2>nul
pm2 delete nanoclaw >nul 2>nul
taskkill /F /IM node.exe >nul 2>nul

timeout /t 2 /nobreak >nul

REM Restart (using last method)
pm2 start ecosystem.config.cjs >nul 2>nul
if %errorlevel% equ 0 (
    pm2 status
    echo.
    echo [OK] NanoClaw restarted (PM2)
) else (
    echo Starting directly...
    node dist/index.js
)
goto end

:status
echo.
echo [STATUS] NanoClaw running status:
echo.

REM Check PM2 status
pm2 status 2>nul

REM Check node processes
echo.
echo Node.js processes:
tasklist /FI "IMAGENAME eq node.exe" 2>nul | findstr /I "node.exe"
if %errorlevel% neq 0 (
    echo No running Node.js processes
)
goto end

:logs
echo.
echo [LOGS] Showing recent logs:
echo.

REM Check which log file exists
if exist logs\nanoclaw.log (
    echo === logs\nanoclaw.log (last 50 lines) ===
    powershell -Command "Get-Content logs\nanoclaw.log -Tail 50"
) else if exist logs\pm2-out.log (
    echo === PM2 logs (last 50 lines) ===
    pm2 logs nanoclaw --lines 50 --nostream
) else (
    echo No log files found
    echo.
    echo Tip: Use "Start directly" mode to generate logs\nanoclaw.log
)
goto end

:end
echo.
pause
