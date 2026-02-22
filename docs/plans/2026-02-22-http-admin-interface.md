# HTTP Admin Interface Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace PID-based process management with HTTP admin interface for safe start/stop/restart/update operations.

**Architecture:** Add a local HTTP server (port 9999) with token authentication. Admin endpoints handle shutdown, restart, and self-update. Start/stop scripts simplified to use HTTP API instead of process management.

**Tech Stack:** Node.js built-in `http` module, no external dependencies.

---

## Task 1: Add Admin Config Variables

**Files:**
- Modify: `src/config.ts:8-13`
- Modify: `.env.example:17-18`

**Step 1: Add config variables**

In `src/config.ts`, add `ADMIN_TOKEN` and `ADMIN_PORT` to the envConfig keys array:

```typescript
const envConfig = readEnvFile([
  'ASSISTANT_NAME',
  'ASSISTANT_HAS_OWN_NUMBER',
  'TELEGRAM_BOT_TOKEN',
  'TELEGRAM_ONLY',
  'ADMIN_TOKEN',
  'ADMIN_PORT',
]);
```

**Step 2: Export admin config values**

At the end of `src/config.ts`, add:

```typescript
// Admin interface configuration
export const ADMIN_PORT = parseInt(
  process.env.ADMIN_PORT || envConfig.ADMIN_PORT || '9999',
  10,
);
export const ADMIN_TOKEN =
  process.env.ADMIN_TOKEN || envConfig.ADMIN_TOKEN || '';
```

**Step 3: Update .env.example**

Add to `.env.example`:

```
# Admin Interface (for start/stop/restart/update)
ADMIN_PORT=9999
# ADMIN_TOKEN=  # Optional: set a fixed token, or one will be auto-generated
```

**Step 4: Commit**

```bash
git add src/config.ts .env.example
git commit -m "feat: add ADMIN_PORT and ADMIN_TOKEN config variables"
```

---

## Task 2: Create Admin HTTP Server Module

**Files:**
- Create: `src/admin-server.ts`

**Step 1: Create admin-server.ts with HTTP server skeleton**

```typescript
import http from 'http';
import { randomBytes } from 'crypto';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { ADMIN_PORT, ADMIN_TOKEN } from './config.js';
import { logger } from './logger.js';

export interface AdminServerOptions {
  onShutdown: () => Promise<void>;
  onRestart: () => Promise<void>;
  onUpdate: () => Promise<void>;
}

let adminToken: string;
let server: http.Server | null = null;
let startTime = Date.now();

/**
 * Initialize admin token - use existing or generate new one
 */
function initToken(): string {
  // If token is provided via env, use it
  if (ADMIN_TOKEN) {
    return ADMIN_TOKEN;
  }

  // Check for existing token in .env file
  const envPath = path.join(process.cwd(), '.env');
  try {
    const content = fs.readFileSync(envPath, 'utf-8');
    const match = content.match(/^ADMIN_TOKEN=(.+)$/m);
    if (match) {
      return match[1].trim().replace(/^["']|["']$/g, '');
    }
  } catch {
    // File doesn't exist, will create
  }

  // Generate new token
  const newToken = randomBytes(16).toString('hex');

  // Append to .env file
  try {
    const line = `\n# Auto-generated admin token\nADMIN_TOKEN=${newToken}\n`;
    fs.appendFileSync(envPath, line);
    logger.info({ token: newToken }, 'Generated new admin token, saved to .env');
  } catch (err) {
    logger.warn({ err }, 'Could not save admin token to .env, using in-memory only');
  }

  return newToken;
}

/**
 * Validate auth token from request
 */
function validateAuth(req: http.IncomingMessage): boolean {
  const authHeader = req.headers['x-admin-token'];
  if (!authHeader) return false;
  return authHeader === adminToken;
}

/**
 * Send JSON response
 */
function sendJson(res: http.ServerResponse, status: number, data: object): void {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

/**
 * Handle /health endpoint (no auth required)
 */
function handleHealth(res: http.ServerResponse): void {
  const uptime = Math.floor((Date.now() - startTime) / 1000);
  sendJson(res, 200, { status: 'ok', uptime });
}

/**
 * Handle /shutdown endpoint
 */
async function handleShutdown(
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  sendJson(res, 200, { status: 'shutting down' });
  logger.info('Admin shutdown requested');
  // Delay to allow response to be sent
  setTimeout(() => options.onShutdown(), 100);
}

/**
 * Handle /restart endpoint
 */
async function handleRestart(
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  sendJson(res, 200, { status: 'restarting' });
  logger.info('Admin restart requested');
  setTimeout(() => options.onRestart(), 100);
}

/**
 * Handle /update endpoint
 */
async function handleUpdate(
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  sendJson(res, 200, { status: 'updating' });
  logger.info('Admin update requested');
  setTimeout(() => options.onUpdate(), 100);
}

/**
 * Start the admin HTTP server
 */
export function startAdminServer(options: AdminServerOptions): http.Server | null {
  adminToken = initToken();
  startTime = Date.now();

  server = http.createServer(async (req, res) => {
    const url = req.url?.split('?')[0] || '/';
    const method = req.method || 'GET';

    try {
      if (url === '/health' && method === 'GET') {
        handleHealth(res);
      } else if (url === '/shutdown' && method === 'POST') {
        await handleShutdown(res, options);
      } else if (url === '/restart' && method === 'POST') {
        await handleRestart(res, options);
      } else if (url === '/update' && method === 'POST') {
        await handleUpdate(res, options);
      } else {
        sendJson(res, 404, { error: 'Not found' });
      }
    } catch (err) {
      logger.error({ err, url, method }, 'Admin server error');
      sendJson(res, 500, { error: 'Internal server error' });
    }
  });

  server.listen(ADMIN_PORT, '127.0.0.1', () => {
    logger.info({ port: ADMIN_PORT }, 'Admin server started');
  });

  server.on('error', (err: NodeJS.ErrnoException) => {
    if (err.code === 'EADDRINUSE') {
      logger.warn(
        { port: ADMIN_PORT },
        'Admin port in use, admin interface disabled',
      );
    } else {
      logger.error({ err }, 'Admin server error');
    }
    server = null;
  });

  return server;
}

/**
 * Stop the admin HTTP server
 */
export function stopAdminServer(): Promise<void> {
  return new Promise((resolve) => {
    if (server) {
      server.close(() => {
        logger.info('Admin server stopped');
        resolve();
      });
    } else {
      resolve();
    }
  });
}

/**
 * Get the current admin token (for scripts to use)
 */
export function getAdminToken(): string {
  return adminToken;
}
```

**Step 2: Fix validateAuth call**

The `validateAuth` function needs the request parameter. Fix the handlers:

```typescript
async function handleShutdown(
  req: http.IncomingMessage,
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth(req)) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  // ... rest unchanged
}

// Same fix for handleRestart and handleUpdate
```

And update the server handler calls:

```typescript
} else if (url === '/shutdown' && method === 'POST') {
  await handleShutdown(req, res, options);
} else if (url === '/restart' && method === 'POST') {
  await handleRestart(req, res, options);
} else if (url === '/update' && method === 'POST') {
  await handleUpdate(req, res, options);
}
```

**Step 3: Commit**

```bash
git add src/admin-server.ts
git commit -m "feat: create admin HTTP server module"
```

---

## Task 3: Integrate Admin Server into Main Entry Point

**Files:**
- Modify: `src/index.ts:449-456`

**Step 1: Import admin server**

Add to imports at top of `src/index.ts`:

```typescript
import { startAdminServer, stopAdminServer } from './admin-server.js';
```

**Step 2: Create restart and update handlers**

Add these functions before the `main()` function:

```typescript
/**
 * Self-restart: spawn a new process and exit
 */
function selfRestart(): never {
  const { spawn } = require('child_process');
  logger.info('Spawning replacement process');

  // Spawn new process with same arguments
  const child = spawn(process.execPath, [process.argv[1], ...process.argv.slice(2)], {
    stdio: 'inherit',
    detached: true,
    cwd: process.cwd(),
  });

  child.unref();
  logger.info({ pid: child.pid }, 'Replacement process started');

  // Exit current process
  process.exit(0);
}

/**
 * Self-update: git pull, npm build, then restart
 */
async function selfUpdate(): Promise<void> {
  logger.info('Starting self-update');

  try {
    // Git pull
    logger.info('Running git pull');
    execSync('git pull', { stdio: 'inherit', cwd: process.cwd() });

    // NPM build
    logger.info('Running npm run build');
    execSync('npm run build', { stdio: 'inherit', cwd: process.cwd() });

    logger.info('Build complete, restarting');
    selfRestart();
  } catch (err) {
    logger.error({ err }, 'Self-update failed');
    // Don't exit - keep running with old code
  }
}
```

**Step 3: Modify shutdown handler to include admin server cleanup**

Replace the existing shutdown handler:

```typescript
// Graceful shutdown handlers
const shutdown = async (signal: string) => {
  logger.info({ signal }, 'Shutdown signal received');
  await stopAdminServer();
  await queue.shutdown(10000);
  for (const ch of channels) await ch.disconnect();
  process.exit(0);
};
```

**Step 4: Start admin server in main()**

Add after the channel connections, before `startSchedulerLoop`:

```typescript
// Start admin HTTP server
startAdminServer({
  onShutdown: () => shutdown('admin'),
  onRestart: selfRestart,
  onUpdate: selfUpdate,
});
```

**Step 5: Commit**

```bash
git add src/index.ts
git commit -m "feat: integrate admin server with shutdown/restart/update"
```

---

## Task 4: Rewrite start.bat (Simplified)

**Files:**
- Modify: `start.bat`

**Step 1: Replace entire file content**

```batch
@echo off
REM Start NanoClaw (background mode)
cd /d "%~dp0"

echo Starting NanoClaw...

REM Create logs directory
if not exist logs mkdir logs

REM Start in background
start /B node dist/index.js > logs\nanoclaw.log 2>&1

echo NanoClaw started in background.
echo.
echo Log file: logs\nanoclaw.log
echo View log: type logs\nanoclaw.log
echo Stop service: stop.bat
echo.

timeout /t 3 /nobreak >nul
type logs\nanoclaw.log
echo.
pause
```

**Step 2: Commit**

```bash
git add start.bat
git commit -m "feat: simplify start.bat - remove PID tracking"
```

---

## Task 5: Rewrite stop.bat (Use HTTP API)

**Files:**
- Modify: `stop.bat`

**Step 1: Replace entire file content**

```batch
@echo off
REM Stop NanoClaw via HTTP admin API
cd /d "%~dp0"

echo Stopping NanoClaw...

REM Read ADMIN_TOKEN from .env
set TOKEN=
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr /b "ADMIN_TOKEN=" .env 2^>nul') do set TOKEN=%%a
)

if not defined TOKEN (
    echo [ERROR] ADMIN_TOKEN not found in .env file
    echo Make sure NanoClaw has been started at least once to generate the token.
    pause
    exit /b 1
)

REM Call shutdown endpoint
curl -s -X POST -H "X-Admin-Token: %TOKEN%" http://localhost:9999/shutdown >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Shutdown signal sent to NanoClaw
) else (
    echo [WARNING] Failed to connect to admin interface
    echo NanoClaw may not be running, or admin server is disabled.
)

echo.
pause
```

**Step 2: Commit**

```bash
git add stop.bat
git commit -m "feat: rewrite stop.bat to use HTTP admin API"
```

---

## Task 6: Add restart.bat Utility

**Files:**
- Create: `restart.bat`

**Step 1: Create restart.bat**

```batch
@echo off
REM Restart NanoClaw via HTTP admin API
cd /d "%~dp0"

echo Restarting NanoClaw...

REM Read ADMIN_TOKEN from .env
set TOKEN=
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr /b "ADMIN_TOKEN=" .env 2^>nul') do set TOKEN=%%a
)

if not defined TOKEN (
    echo [ERROR] ADMIN_TOKEN not found in .env file
    pause
    exit /b 1
)

REM Call restart endpoint
curl -s -X POST -H "X-Admin-Token: %TOKEN%" http://localhost:9999/restart >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Restart signal sent to NanoClaw
) else (
    echo [WARNING] Failed to connect to admin interface
)

echo.
pause
```

**Step 2: Commit**

```bash
git add restart.bat
git commit -m "feat: add restart.bat utility using HTTP admin API"
```

---

## Task 7: Manual Testing

**Step 1: Build the project**

```bash
npm run build
```

**Step 2: Start the service**

```bash
start.bat
```

Expected: NanoClaw starts, log shows "Admin server started" with port number.

**Step 3: Check health endpoint**

```bash
curl http://localhost:9999/health
```

Expected: `{"status":"ok","uptime":<seconds>}`

**Step 4: Stop the service**

```bash
stop.bat
```

Expected: "Shutdown signal sent to NanoClaw", service stops gracefully.

**Step 5: Start again and test restart**

```bash
start.bat
restart.bat
```

Expected: Service restarts (new PID), continues running.

---

## Summary

After completing all tasks:

- `start.bat`: Simple background launch, no PID management
- `stop.bat`: HTTP API call with token auth
- `restart.bat`: HTTP API call with token auth
- Admin token: Auto-generated on first run, stored in `.env`
- Update flow: `/update` → git pull → npm build → restart

No more process hunting, no more risk of killing wrong node.exe processes.
