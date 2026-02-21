@echo off
REM Register a Telegram chat to the database
cd /d "%~dp0"

echo.
echo === Register Telegram Chat ===
echo.

set /p CHAT_ID="Enter Chat ID (e.g., tg:123456789): "
set /p CHAT_NAME="Enter Chat Name (e.g., MyChat): "

echo.
echo Registering chat...
echo.

node register-chat.mjs

echo.
pause
