@echo off
REM Stop NanoClaw (PID-based)
cd /d "%~dp0"

echo Stopping NanoClaw...

if exist nanoclaw.pid (
    set /p PID=<nanoclaw.pid
    taskkill /PID %PID% /F >nul 2>nul
    if %errorlevel% equ 0 (
        echo [OK] NanoClaw stopped (PID: %PID%)
        del nanoclaw.pid
    ) else (
        echo [WARNING] Process not found, cleaning up PID file
        del nanoclaw.pid
    )
) else (
    echo [INFO] No PID file found. NanoClaw may not be running as a service.
    echo [INFO] Use 'tasklist ^| find "node.exe"' to check manually.
)
