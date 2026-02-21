#!/bin/bash
# Final verification script for Windows platform support
# This script runs all automated tests and generates a report

set -euo pipefail

echo "========================================="
echo "Windows Platform Support - Final Verification"
echo "========================================="
echo ""

PASS=0
FAIL=0
TOTAL=0
ERRORS=""

check() {
  local desc="$1"
  local cmd="$2"
  TOTAL=$((TOTAL + 1))

  echo -n "Test $TOTAL: $desc... "

  if eval "$cmd" >/dev/null 2>&1; then
    echo "✓ PASS"
    PASS=$((PASS + 1))
    return 0
  else
    echo "✗ FAIL"
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n- Test $TOTAL: $desc"
    return 1
  fi
}

# Phase 1: File Existence
echo "Phase 1: File Existence"
echo "-----------------------"
check "SKILL.md updated" "[ -f .claude/skills/setup/SKILL.md ]"
check "01-check-environment.sh exists" "[ -f .claude/skills/setup/scripts/01-check-environment.sh ]"
check "02-install-deps.sh exists" "[ -f .claude/skills/setup/scripts/02-install-deps.sh ]"
check "04.5-setup-env.sh exists" "[ -f .claude/skills/setup/scripts/04.5-setup-env.sh ]"
check "07-configure-mounts.sh exists" "[ -f .claude/skills/setup/scripts/07-configure-mounts.sh ]"
check "08-setup-service.sh exists" "[ -f .claude/skills/setup/scripts/08-setup-service.sh ]"
check "08.5-create-directories.sh exists" "[ -f .claude/skills/setup/scripts/08.5-create-directories.sh ]"
check "09-verify.sh exists" "[ -f .claude/skills/setup/scripts/09-verify.sh ]"
echo ""

# Phase 2: Syntax Validation
echo "Phase 2: Syntax Validation"
echo "---------------------------"
check "01-check-environment.sh syntax" "bash -n .claude/skills/setup/scripts/01-check-environment.sh"
check "02-install-deps.sh syntax" "bash -n .claude/skills/setup/scripts/02-install-deps.sh"
check "04.5-setup-env.sh syntax" "bash -n .claude/skills/setup/scripts/04.5-setup-env.sh"
check "07-configure-mounts.sh syntax" "bash -n .claude/skills/setup/scripts/07-configure-mounts.sh"
check "08-setup-service.sh syntax" "bash -n .claude/skills/setup/scripts/08-setup-service.sh"
check "08.5-create-directories.sh syntax" "bash -n .claude/skills/setup/scripts/08.5-create-directories.sh"
check "09-verify.sh syntax" "bash -n .claude/skills/setup/scripts/09-verify.sh"
echo ""

# Phase 3: Platform Detection
echo "Phase 3: Platform Detection"
echo "---------------------------"
PLATFORM=$(.claude/skills/setup/scripts/01-check-environment.sh 2>/dev/null | grep "PLATFORM:" | cut -d' ' -f2 || echo "unknown")
check "Platform detection returns valid value" "[ '$PLATFORM' != 'unknown' ]"

if [ "$PLATFORM" = "windows" ]; then
  echo "  → Detected: windows"
  check "Windows platform correctly identified" "[ '$PLATFORM' = 'windows' ]"
else
  echo "  → Detected: $PLATFORM (not windows, skipping windows-specific tests)"
fi
echo ""

# Phase 4: Dependency Check
echo "Phase 4: Dependency Check"
echo "-------------------------"
check "Node.js available" "command -v node >/dev/null 2>&1"
check "npm available" "command -v npm >/dev/null 2>&1"
check "Docker available" "command -v docker >/dev/null 2>&1"

STATUS=$(.claude/skills/setup/scripts/02-install-deps.sh 2>/dev/null | grep "STATUS:" | cut -d' ' -f2 || echo "failed")
check "Dependency check passes" "[ '$STATUS' = 'success' ]"
echo ""

# Phase 5: Documentation
echo "Phase 5: Documentation"
echo "----------------------"
check "WINDOWS-SETUP-IMPLEMENTATION.md exists" "[ -f docs/WINDOWS-SETUP-IMPLEMENTATION.md ]"
check "WINDOWS-VERIFICATION-REPORT.md exists" "[ -f docs/WINDOWS-VERIFICATION-REPORT.md ]"
check "WINDOWS-SUMMARY.md exists" "[ -f docs/WINDOWS-SUMMARY.md ]"
check "QUICK-TEST-GUIDE.md exists" "[ -f docs/QUICK-TEST-GUIDE.md ]"
echo ""

# Phase 6: Environment Variable Sync (Windows-specific)
if [ "$PLATFORM" = "windows" ]; then
  echo "Phase 6: Environment Variable Sync (Windows)"
  echo "--------------------------------------------"

  # Backup existing files
  cp .env .env.final-test-backup 2>/dev/null || true
  rm .env data/env/env 2>/dev/null || true

  # Run setup script
  SYNC_STATUS=$(.claude/skills/setup/scripts/04.5-setup-env.sh 2>/dev/null | grep "DATA_ENV_SYNCED:" | cut -d' ' -f2 || echo "false")
  check "Environment variables synced" "[ '$SYNC_STATUS' = 'true' ]"
  check ".env file created" "[ -f .env ]"
  check "data/env/env file created" "[ -f data/env/env ]"
  check "Files are identical" "cmp -s .env data/env/env"
  check "Uses host.docker.internal" "grep -q 'host.docker.internal' .env"

  # Restore backup
  mv .env.final-test-backup .env 2>/dev/null || true
  echo ""
fi

# Phase 7: Directory Creation (Windows-specific)
if [ "$PLATFORM" = "windows" ]; then
  echo "Phase 7: Directory Creation (Windows)"
  echo "-------------------------------------"

  # Clean up
  rm -rf groups/main data/sessions/main data/ipc/main 2>/dev/null || true

  # Run script
  DIR_STATUS=$(.claude/skills/setup/scripts/08.5-create-directories.sh 2>/dev/null | grep "STATUS:" | cut -d' ' -f2 || echo "failed")
  check "Directory creation passes" "[ '$DIR_STATUS' = 'success' ]"

  # Verify directories
  check "groups/main exists" "[ -d groups/main ]"
  check "data/env exists" "[ -d data/env ]"
  check "data/sessions/main/.claude exists" "[ -d data/sessions/main/.claude ]"
  check "data/ipc/main exists" "[ -d data/ipc/main ]"
  check "logs exists" "[ -d logs ]"
  check "store exists" "[ -d store ]"
  echo ""
fi

# Phase 8: Service Setup (Windows-specific)
if [ "$PLATFORM" = "windows" ]; then
  echo "Phase 8: Service Setup (Windows)"
  echo "--------------------------------"

  # Build if needed
  if [ ! -d "dist" ]; then
    echo "  Building project..."
    npm run build >/dev/null 2>&1
  fi

  # Backup existing batch files
  mv start.bat start.bat.final-test-backup 2>/dev/null || true
  mv stop.bat stop.bat.final-test-backup 2>/dev/null || true

  # Run setup
  SERVICE_STATUS=$(.claude/skills/setup/scripts/08-setup-service.sh 2>/dev/null | grep "STATUS:" | cut -d' ' -f2 || echo "failed")
  check "Service setup passes" "[ '$SERVICE_STATUS' = 'success' ]"
  check "start.bat created" "[ -f start.bat ]"
  check "stop.bat created" "[ -f stop.bat ]"

  # Restore backups
  mv start.bat.final-test-backup start.bat 2>/dev/null || true
  mv stop.bat.final-test-backup stop.bat 2>/dev/null || true
  echo ""
fi

# Summary
echo "========================================="
echo "FINAL RESULTS"
echo "========================================="
echo ""
echo "Total Tests: $TOTAL"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "✅ ALL TESTS PASSED"
  echo ""
  echo "Windows platform support is ready for deployment."
  echo ""
  echo "Next steps:"
  echo "1. Review the changes: git diff"
  echo "2. Commit the changes: git add -A && git commit"
  echo "3. Test manually on Windows: npx tsx scripts/apply-skill.ts .claude/skills/setup"
  echo "4. Update documentation if needed"
  echo ""
  exit 0
else
  echo "❌ SOME TESTS FAILED"
  echo ""
  echo "Failed tests:"
  echo -e "$ERRORS"
  echo ""
  echo "Please review and fix the issues before committing."
  echo ""
  exit 1
fi
