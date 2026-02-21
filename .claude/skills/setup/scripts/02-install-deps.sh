#!/bin/bash
set -euo pipefail

# 02-install-deps.sh — Run npm install and verify key packages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/setup.log"

mkdir -p "$PROJECT_ROOT/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [install-deps] $*" >> "$LOG_FILE"; }

cd "$PROJECT_ROOT"

# Detect platform
case "$(uname -s)" in
  Darwin*) PLATFORM="macos" ;;
  Linux*)  PLATFORM="linux" ;;
  CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
  *)       PLATFORM="unknown" ;;
esac

log "Platform: $PLATFORM"

# Windows-specific dependency checks
if [ "$PLATFORM" = "windows" ]; then
  log "Checking Windows dependencies"

  # Check Node.js
  if ! command -v node >/dev/null 2>&1; then
    log "Node.js not found"
    cat <<EOF
=== NANOCLAW SETUP: INSTALL_DEPS ===
PACKAGES: failed
STATUS: failed
ERROR: node_not_installed
PLATFORM: windows
MESSAGE: Please install Node.js v22+ from https://nodejs.org/ or use winget: winget install OpenJS.NodeJS.LTS
LOG: logs/setup.log
=== END ===
EOF
    exit 2
  fi

  # Check Docker Desktop
  if ! command -v docker >/dev/null 2>&1; then
    log "Docker Desktop not found"
    cat <<EOF
=== NANOCLAW SETUP: INSTALL_DEPS ===
PACKAGES: failed
STATUS: failed
ERROR: docker_not_installed
PLATFORM: windows
MESSAGE: Please install Docker Desktop from https://www.docker.com/products/docker-desktop
LOG: logs/setup.log
=== END ===
EOF
    exit 2
  fi

  # Check if Docker is running
  if ! docker info >/dev/null 2>&1; then
    log "Docker Desktop not running"
    cat <<EOF
=== NANOCLAW SETUP: INSTALL_DEPS ===
PACKAGES: failed
STATUS: failed
ERROR: docker_not_running
PLATFORM: windows
MESSAGE: Docker Desktop is installed but not running. Please start Docker Desktop and wait for it to fully initialize.
LOG: logs/setup.log
=== END ===
EOF
    exit 2
  fi

  log "Windows dependencies verified: Node.js and Docker Desktop running"
fi

log "Running npm install"

if npm install >> "$LOG_FILE" 2>&1; then
  log "npm install succeeded"
else
  log "npm install failed"
  cat <<EOF
=== NANOCLAW SETUP: INSTALL_DEPS ===
PACKAGES: failed
STATUS: failed
ERROR: npm_install_failed
LOG: logs/setup.log
=== END ===
EOF
  exit 1
fi

# Verify key packages
MISSING=""
for pkg in @whiskeysockets/baileys better-sqlite3 pino qrcode; do
  if [ ! -d "$PROJECT_ROOT/node_modules/$pkg" ]; then
    MISSING="$MISSING $pkg"
  fi
done

if [ -n "$MISSING" ]; then
  log "Missing packages after install:$MISSING"
  cat <<EOF
=== NANOCLAW SETUP: INSTALL_DEPS ===
PACKAGES: failed
STATUS: failed
ERROR: missing_packages:$MISSING
LOG: logs/setup.log
=== END ===
EOF
  exit 1
fi

log "All key packages verified"

cat <<EOF
=== NANOCLAW SETUP: INSTALL_DEPS ===
PACKAGES: installed
STATUS: success
LOG: logs/setup.log
=== END ===
EOF
