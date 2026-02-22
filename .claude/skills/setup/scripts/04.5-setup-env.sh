#!/bin/bash
set -euo pipefail

# 04.5-setup-env.sh — Configure environment variables for Windows

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/setup.log"

mkdir -p "$PROJECT_ROOT/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [setup-env] $*" >> "$LOG_FILE"; }

# Only run on Windows
case "$(uname -s)" in
  CYGWIN*|MINGW*|MSYS*) ;;
  *) exit 0 ;;
esac

log "Setting up Windows environment variables"

cd "$PROJECT_ROOT"

ENV_FILE=".env"

# If .env doesn't exist but .env.example exists, copy it
if [ ! -f "$ENV_FILE" ] && [ -f ".env.example" ]; then
  cp .env.example .env
  log "Created .env from .env.example"
fi

# If still doesn't exist, create a basic one
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" << 'EOF'
# Claude API Configuration for cc-switch proxy
ANTHROPIC_API_KEY=sk-dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# Assistant Configuration
ASSISTANT_NAME=nex
ASSISTANT_HAS_OWN_NUMBER=false

# Telegram Configuration
TELEGRAM_BOT_TOKEN=
TELEGRAM_ONLY=true
EOF
  log "Created basic .env file"
fi

# Source the env file to check values (allow failures)
set +e
source "$ENV_FILE" 2>/dev/null || true
set -e

# Validate ANTHROPIC_BASE_URL format for Windows Docker compatibility
validate_anthropic_url() {
  local url="$1"

  # Check if URL is set
  if [ -z "$url" ]; then
    echo "ERROR: ANTHROPIC_BASE_URL is not set"
    return 1
  fi

  # Check format: http://host.docker.internal:PORT
  if [[ ! "$url" =~ ^http://host\.docker\.internal:[0-9]+$ ]]; then
    cat <<EOF
ERROR: Invalid ANTHROPIC_BASE_URL format

Current value: $url
Expected format: http://host.docker.internal:PORT

On Windows, Docker containers must use 'host.docker.internal' to access the host machine.
The URL must use http:// (not https://) and include a valid port number.

Examples:
  ✓ http://host.docker.internal:15721
  ✓ http://host.docker.internal:8080
  ✗ https://host.docker.internal:15721 (wrong scheme)
  ✗ http://host.docker.internal: (missing port)
  ✗ http://localhost:15721 (won't work in container)
  ✗ http://127.0.0.1:15721 (won't work in container)

Please update your .env file with the correct URL.
EOF
    return 1
  fi

  # Extract and validate port
  local port=$(echo "$url" | grep -oP ':\K[0-9]+')
  if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "ERROR: Port number out of range: $port (must be 1-65535)"
    return 1
  fi

  log "URL validation passed: $url"
  return 0
}

# Check ANTHROPIC_BASE_URL
if [ -n "$ANTHROPIC_BASE_URL" ]; then
  if ! validate_anthropic_url "$ANTHROPIC_BASE_URL"; then
    cat <<EOF
=== NANOCLAW SETUP: SETUP_ENV ===
ENV_FILE: $ENV_FILE
STATUS: warning
WARNING: invalid_anthropic_base_url
MESSAGE: ANTHROPIC_BASE_URL format is invalid for Windows Docker compatibility
CURRENT_VALUE: $ANTHROPIC_BASE_URL
RECOMMENDED: http://host.docker.internal:15721
LOG: logs/setup.log
=== END ===
EOF
  fi
fi

# Check TELEGRAM_BOT_TOKEN
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" = "your-telegram-bot-token-here" ]; then
  log "TELEGRAM_BOT_TOKEN not set"
  TELEGRAM_CONFIGURED="false"
else
  TELEGRAM_CONFIGURED="true"
fi

# Check ASSISTANT_NAME
if [ -z "$ASSISTANT_NAME" ]; then
  ASSISTANT_NAME="nex"
fi

# Create data/env directory and sync
mkdir -p data/env
cp "$ENV_FILE" data/env/env
log "Synced .env to data/env/env"

log "Environment setup complete"

cat <<EOF
=== NANOCLAW SETUP: SETUP_ENV ===
ENV_FILE: $ENV_FILE
DATA_ENV_SYNCED: true
TELEGRAM_CONFIGURED: $TELEGRAM_CONFIGURED
ASSISTANT_NAME: $ASSISTANT_NAME
ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL
STATUS: success
LOG: logs/setup.log
=== END ===
EOF
