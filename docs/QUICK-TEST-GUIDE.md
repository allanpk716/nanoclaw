# Windows Setup Quick Test Guide

## Quick Verification (5 minutes)

Run these commands to verify Windows platform support is working:

```bash
# 1. Platform Detection
.claude/skills/setup/scripts/01-check-environment.sh | grep PLATFORM
# Expected: PLATFORM: windows

# 2. Dependency Check
.claude/skills/setup/scripts/02-install-deps.sh | grep STATUS
# Expected: STATUS: success

# 3. Environment Setup (dry run)
rm .env data/env/env 2>/dev/null
.claude/skills/setup/scripts/04.5-setup-env.sh | grep -E "STATUS|DATA_ENV_SYNCED"
# Expected: DATA_ENV_SYNCED: true, STATUS: success

# 4. Directory Creation
rm -rf groups/main data/sessions/main 2>/dev/null
.claude/skills/setup/scripts/08.5-create-directories.sh | grep STATUS
# Expected: STATUS: success

# 5. Service Setup
npm run build
.claude/skills/setup/scripts/08-setup-service.sh | grep STATUS
# Expected: STATUS: success

# 6. Verify All Components
ls -la start.bat stop.bat tail-log.bat
# Expected: All three files exist

echo "All quick tests passed!"
```

## Expected Output

```
PLATFORM: windows
STATUS: success
DATA_ENV_SYNCED: true
STATUS: success
STATUS: success
-rw-r--r-- 1 user group 600 Feb 22 00:29 start.bat
-rw-r--r-- 1 user group 200 Feb 22 00:29 stop.bat
-rw-r--r-- 1 user group 369 Feb 22 00:29 tail-log.bat
All quick tests passed!
```

## Manual Testing Checklist

### Prerequisites

- [ ] Docker Desktop installed and running
- [ ] Node.js v22+ installed
- [ ] Git Bash installed

### Setup Flow

- [ ] Run `npx tsx scripts/apply-skill.ts .claude/skills/setup`
- [ ] Platform correctly detected as Windows
- [ ] Dependencies installed successfully
- [ ] Environment variables configured
- [ ] Telegram bot token entered
- [ ] Directories created
- [ ] Service scripts generated
- [ ] Setup completed without errors

### Telegram Integration

- [ ] Bot token configured in `.env`
- [ ] Service started with `start.bat`
- [ ] Bot responds to `/chatid` command
- [ ] Chat registered with `register-chat.bat`
- [ ] Bot responds to `@nex <message>`

### Service Management

- [ ] `start.bat` launches service successfully
- [ ] `stop.bat` stops service successfully
- [ ] `tail-log.bat` shows log output
- [ ] Service survives system restart (if using NSSM)

### Container Operations

- [ ] Container builds successfully
- [ ] Container can access environment variables
- [ ] Container can read/write to mounted directories
- [ ] API proxy connection works (`host.docker.internal:15721`)

## Troubleshooting Commands

```bash
# Check if service is running
tasklist | findstr node.exe

# View logs
tail-log.bat
# Or directly:
type logs\nanoclaw.log

# Check Docker status
docker info

# Verify environment variables
type .env
type data\env\env

# Check mount allowlist
type %USERPROFILE%\.config\nanoclaw\mount-allowlist.json

# Test API connection
curl http://host.docker.internal:15721
```

## Success Criteria

✅ All automated tests pass (16/16)
✅ Platform detected as Windows
✅ Environment variables synced to data/env/env
✅ Batch scripts generated
✅ Service starts successfully
✅ Telegram bot responds
✅ Container can access environment variables

## Next Steps After Successful Testing

1. Document any issues encountered
2. Update documentation with user feedback
3. Create video tutorial
4. Release to users
5. Monitor GitHub issues for Windows-specific problems

## Rollback Plan

If testing reveals critical issues:

```bash
# Restore original files
git checkout .claude/skills/setup/

# Remove Windows-specific scripts
rm .claude/skills/setup/scripts/04.5-setup-env.sh
rm .claude/skills/setup/scripts/08.5-create-directories.sh

# Revert documentation
rm docs/WINDOWS-*.md

# Commit rollback
git add -A
git commit -m "Rollback Windows support due to critical issues"
```
