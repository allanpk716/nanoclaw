#!/bin/bash
set -euo pipefail

# 08.5-create-directories.sh — Create necessary directory structure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/setup.log"

mkdir -p "$PROJECT_ROOT/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [create-directories] $*" >> "$LOG_FILE"; }

log "Creating directory structure"

cd "$PROJECT_ROOT"

# Create main directories
mkdir -p groups/main
mkdir -p data/env
mkdir -p data/sessions/main/.claude
mkdir -p data/ipc/main
mkdir -p logs
mkdir -p store

log "Directory structure created"

# Verify directories
DIRS_OK="true"
for dir in groups/main data/env data/sessions/main/.claude data/ipc/main logs store; do
  if [ ! -d "$dir" ]; then
    log "ERROR: Failed to create $dir"
    DIRS_OK="false"
  fi
done

if [ "$DIRS_OK" = "true" ]; then
  log "All directories verified"
  cat <<EOF
=== NANOCLAW SETUP: CREATE_DIRECTORIES ===
GROUPS_MAIN: exists
DATA_ENV: exists
DATA_SESSIONS_MAIN: exists
DATA_IPC_MAIN: exists
LOGS: exists
STORE: exists
STATUS: success
LOG: logs/setup.log
=== END ===
EOF
else
  cat <<EOF
=== NANOCLAW SETUP: CREATE_DIRECTORIES ===
STATUS: failed
ERROR: directory_creation_failed
LOG: logs/setup.log
=== END ===
EOF
  exit 1
fi
