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

# Check ANTHROPIC_BASE_URL
if [ -n "$ANTHROPIC_BASE_URL" ] && [[ ! "$ANTHROPIC_BASE_URL" =~ "host.docker.internal" ]]; then
  log "ANTHROPIC_BASE_URL not using host.docker.internal"
  cat <<EOF
=== NANOCLAW SETUP: SETUP_ENV ===
ENV_FILE: $ENV_FILE
STATUS: warning
WARNING: anthropic_base_url_not_windows_compatible
MESSAGE: ANTHROPIC_BASE_URL should use host.docker.internal instead of 127.0.0.1 on Windows
CURRENT_VALUE: $ANTHROPIC_BASE_URL
RECOMMENDED: http://host.docker.internal:15721
LOG: logs/setup.log
=== END ===
EOF
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
