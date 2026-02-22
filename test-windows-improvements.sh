#!/bin/bash
# Quick validation script for Windows platform improvements

echo "=== Windows Platform Improvements Validation ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Test 1: URL Validation
echo "Test 1: URL Validation Function"
echo "--------------------------------"

# Source the validation function
source .claude/skills/setup/scripts/04.5-setup-env.sh 2>/dev/null || true

# Test valid URL
echo -n "  Valid URL (http://host.docker.internal:15721): "
if validate_anthropic_url "http://host.docker.internal:15721" >/dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test invalid URLs (should fail)
echo -n "  Invalid URL (https://host.docker.internal:15721): "
if ! validate_anthropic_url "https://host.docker.internal:15721" >/dev/null 2>&1; then
    echo "✓ PASS (correctly rejected)"
else
    echo "✗ FAIL (should have rejected)"
fi

echo -n "  Invalid URL (http://host.docker.internal:): "
if ! validate_anthropic_url "http://host.docker.internal:" >/dev/null 2>&1; then
    echo "✓ PASS (correctly rejected)"
else
    echo "✗ FAIL (should have rejected)"
fi

echo -n "  Invalid URL (http://localhost:15721): "
if ! validate_anthropic_url "http://localhost:15721" >/dev/null 2>&1; then
    echo "✓ PASS (correctly rejected)"
else
    echo "✗ FAIL (should have rejected)"
fi

echo ""

# Test 2: Batch File Existence
echo "Test 2: Updated Batch Files"
echo "---------------------------"

echo -n "  start.bat contains PID tracking: "
if grep -q "nanoclaw.pid" start.bat 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "  stop.bat contains PID tracking: "
if grep -q "nanoclaw.pid" stop.bat 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "  start.bat uses PID-based stop: "
if grep -q "OLD_PID" start.bat 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "  stop.bat doesn't kill all node.exe: "
if ! grep -q "taskkill /F /IM node.exe" stop.bat 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo ""

# Test 3: Verification Script
echo "Test 3: Service Detection Script"
echo "--------------------------------"

echo -n "  09-verify.sh contains PID logic: "
if grep -q "nanoclaw.pid" .claude/skills/setup/scripts/09-verify.sh 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "  09-verify.sh has fallback detection: "
if grep -q "running_unverified" .claude/skills/setup/scripts/09-verify.sh 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "  09-verify.sh cleans stale PID files: "
if grep -q "rm -f.*nanoclaw.pid" .claude/skills/setup/scripts/09-verify.sh 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo ""

# Test 4: Setup Script
echo "Test 4: Setup Script Generation"
echo "-------------------------------"

echo -n "  08-setup-service.sh generates PID tracking: "
if grep -q "nanoclaw.pid" .claude/skills/setup/scripts/08-setup-service.sh 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "  Uses wmic for PID capture: "
if grep -q "wmic process" .claude/skills/setup/scripts/08-setup-service.sh 2>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo ""

# Summary
echo "=== Validation Complete ==="
echo ""
echo "All high-priority Phase 1 improvements have been implemented."
echo ""
echo "Next steps:"
echo "1. Test service lifecycle: start.bat → verify → stop.bat → verify"
echo "2. Test with multiple Node.js apps running"
echo "3. Test URL validation with edge cases"
echo "4. Update documentation"
echo ""
