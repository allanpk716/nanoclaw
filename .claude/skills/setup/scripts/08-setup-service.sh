#!/bin/bash
set -euo pipefail

# 08-setup-service.sh — Generate and load service manager config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/setup.log"

mkdir -p "$PROJECT_ROOT/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [setup-service] $*" >> "$LOG_FILE"; }

cd "$PROJECT_ROOT"

# Parse args
PLATFORM=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform) PLATFORM="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Auto-detect platform
if [ -z "$PLATFORM" ]; then
  case "$(uname -s)" in
    Darwin*) PLATFORM="macos" ;;
    Linux*)  PLATFORM="linux" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *)       PLATFORM="unknown" ;;
  esac
fi

NODE_PATH=$(which node)
PROJECT_PATH="$PROJECT_ROOT"
HOME_PATH="$HOME"

log "Setting up service: platform=$PLATFORM node=$NODE_PATH project=$PROJECT_PATH"

# Build first
log "Building TypeScript"
if ! npm run build >> "$LOG_FILE" 2>&1; then
  log "Build failed"
  cat <<EOF
=== NANOCLAW SETUP: SETUP_SERVICE ===
SERVICE_TYPE: unknown
NODE_PATH: $NODE_PATH
PROJECT_PATH: $PROJECT_PATH
STATUS: failed
ERROR: build_failed
LOG: logs/setup.log
=== END ===
EOF
  exit 1
fi

# Create logs directory
mkdir -p "$PROJECT_PATH/logs"

case "$PLATFORM" in

  macos)
    PLIST_PATH="$HOME_PATH/Library/LaunchAgents/com.nanoclaw.plist"
    log "Generating launchd plist at $PLIST_PATH"

    mkdir -p "$HOME_PATH/Library/LaunchAgents"

    cat > "$PLIST_PATH" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nanoclaw</string>
    <key>ProgramArguments</key>
    <array>
        <string>${NODE_PATH}</string>
        <string>${PROJECT_PATH}/dist/index.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${PROJECT_PATH}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:${HOME_PATH}/.local/bin</string>
        <key>HOME</key>
        <string>${HOME_PATH}</string>
    </dict>
    <key>StandardOutPath</key>
    <string>${PROJECT_PATH}/logs/nanoclaw.log</string>
    <key>StandardErrorPath</key>
    <string>${PROJECT_PATH}/logs/nanoclaw.error.log</string>
</dict>
</plist>
PLISTEOF

    log "Loading launchd service"
    if launchctl load "$PLIST_PATH" >> "$LOG_FILE" 2>&1; then
      log "launchctl load succeeded"
    else
      log "launchctl load failed (may already be loaded)"
    fi

    # Verify
    SERVICE_LOADED="false"
    if launchctl list 2>/dev/null | grep -q "com.nanoclaw"; then
      SERVICE_LOADED="true"
      log "Service verified as loaded"
    else
      log "Service not found in launchctl list"
    fi

    cat <<EOF
=== NANOCLAW SETUP: SETUP_SERVICE ===
SERVICE_TYPE: launchd
NODE_PATH: $NODE_PATH
PROJECT_PATH: $PROJECT_PATH
PLIST_PATH: $PLIST_PATH
SERVICE_LOADED: $SERVICE_LOADED
STATUS: success
LOG: logs/setup.log
=== END ===
EOF
    ;;

  linux)
    UNIT_DIR="$HOME_PATH/.config/systemd/user"
    UNIT_PATH="$UNIT_DIR/nanoclaw.service"
    mkdir -p "$UNIT_DIR"
    log "Generating systemd unit at $UNIT_PATH"

    cat > "$UNIT_PATH" <<UNITEOF
[Unit]
Description=NanoClaw Personal Assistant
After=network.target

[Service]
Type=simple
ExecStart=${NODE_PATH} ${PROJECT_PATH}/dist/index.js
WorkingDirectory=${PROJECT_PATH}
Restart=always
RestartSec=5
Environment=HOME=${HOME_PATH}
Environment=PATH=/usr/local/bin:/usr/bin:/bin:${HOME_PATH}/.local/bin
StandardOutput=append:${PROJECT_PATH}/logs/nanoclaw.log
StandardError=append:${PROJECT_PATH}/logs/nanoclaw.error.log

[Install]
WantedBy=default.target
UNITEOF

    log "Enabling and starting systemd service"
    systemctl --user daemon-reload >> "$LOG_FILE" 2>&1 || true
    systemctl --user enable nanoclaw >> "$LOG_FILE" 2>&1 || true
    systemctl --user start nanoclaw >> "$LOG_FILE" 2>&1 || true

    # Verify
    SERVICE_LOADED="false"
    if systemctl --user is-active nanoclaw >/dev/null 2>&1; then
      SERVICE_LOADED="true"
      log "Service verified as active"
    else
      log "Service not active"
    fi

    cat <<EOF
=== NANOCLAW SETUP: SETUP_SERVICE ===
SERVICE_TYPE: systemd
NODE_PATH: $NODE_PATH
PROJECT_PATH: $PROJECT_PATH
UNIT_PATH: $UNIT_PATH
SERVICE_LOADED: $SERVICE_LOADED
STATUS: success
LOG: logs/setup.log
=== END ===
EOF
    ;;

  windows)
    log "Setting up Windows service with batch scripts"
    # Windows uses batch scripts instead of service managers
    # Just verify build succeeded and output instructions

    # Create batch scripts if they don't exist
    if [ ! -f "start.bat" ]; then
      log "Creating start.bat"
      cat > start.bat << 'BATEOF'
@echo off
REM Start NanoClaw (background mode)
cd /d "%~dp0"

echo Starting NanoClaw...

REM Stop existing instances
taskkill /F /IM node.exe >nul 2>nul
timeout /t 2 /nobreak >nul

REM Create logs directory
if not exist logs mkdir logs

REM Start in background with environment variables from .env
start /B node --import dotenv/config dist/index.js > logs\nanoclaw.log 2>&1

echo.
echo [OK] NanoClaw started in background
echo Log file: logs\nanoclaw.log
echo.
echo View log: type logs\nanoclaw.log
echo Stop service: taskkill /F /IM node.exe
echo.

timeout /t 3 /nobreak >nul
type logs\nanoclaw.log
BATEOF
    fi

    if [ ! -f "stop.bat" ]; then
      log "Creating stop.bat"
      cat > stop.bat << 'BATEOF'
@echo off
REM Stop NanoClaw
echo Stopping NanoClaw...
taskkill /F /IM node.exe >nul 2>nul

if %errorlevel% equ 0 (
    echo [OK] NanoClaw stopped
) else (
    echo No running NanoClaw process found
)
BATEOF
    fi

    if [ ! -f "tail-log.bat" ]; then
      log "Creating tail-log.bat"
      cat > tail-log.bat << 'BATEOF'
@echo off
REM View NanoClaw logs
if not exist logs\nanoclaw.log (
    echo Log file not found: logs\nanoclaw.log
    exit /b 1
)

echo Following logs (Ctrl+C to stop)...
echo ========================================
type logs\nanoclaw.log
BATEOF
    fi

    SERVICE_LOADED="true"
    log "Windows batch scripts ready"

    cat <<EOF
=== NANOCLAW SETUP: SETUP_SERVICE ===
SERVICE_TYPE: windows_batch
NODE_PATH: $NODE_PATH
PROJECT_PATH: $PROJECT_PATH
SERVICE_LOADED: $SERVICE_LOADED
STATUS: success
MESSAGE: Windows batch scripts created. Use start.bat to launch, stop.bat to stop.
LOG: logs/setup.log
=== END ===
EOF
    ;;

  *)
    log "Unsupported platform: $PLATFORM"
    cat <<EOF
=== NANOCLAW SETUP: SETUP_SERVICE ===
SERVICE_TYPE: unknown
NODE_PATH: $NODE_PATH
PROJECT_PATH: $PROJECT_PATH
STATUS: failed
ERROR: unsupported_platform
LOG: logs/setup.log
=== END ===
EOF
    exit 1
    ;;
esac
