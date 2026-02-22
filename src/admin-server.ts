import http from 'http';
import { randomBytes } from 'crypto';
import fs from 'fs';
import path from 'path';
import { ADMIN_PORT, ADMIN_TOKEN } from './config.js';
import { logger } from './logger.js';

export interface AdminServerOptions {
  onShutdown: () => Promise<void>;
  onRestart: () => Promise<void>;
  onUpdate: () => Promise<void>;
}

let adminToken: string = '';
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
  if (typeof authHeader !== 'string') return false;
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
  req: http.IncomingMessage,
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth(req)) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  sendJson(res, 200, { status: 'shutting down' });
  logger.info('Admin shutdown requested');
  setTimeout(async () => {
    try {
      await options.onShutdown();
    } catch (err) {
      logger.error({ err }, 'Shutdown callback failed');
    }
  }, 100);
}

/**
 * Handle /restart endpoint
 */
async function handleRestart(
  req: http.IncomingMessage,
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth(req)) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  sendJson(res, 200, { status: 'restarting' });
  logger.info('Admin restart requested');
  setTimeout(async () => {
    try {
      await options.onRestart();
    } catch (err) {
      logger.error({ err }, 'Restart callback failed');
    }
  }, 100);
}

/**
 * Handle /update endpoint
 */
async function handleUpdate(
  req: http.IncomingMessage,
  res: http.ServerResponse,
  options: AdminServerOptions
): Promise<void> {
  if (!validateAuth(req)) {
    sendJson(res, 401, { error: 'Unauthorized' });
    return;
  }
  sendJson(res, 200, { status: 'updating' });
  logger.info('Admin update requested');
  setTimeout(async () => {
    try {
      await options.onUpdate();
    } catch (err) {
      logger.error({ err }, 'Update callback failed');
    }
  }, 100);
}

/**
 * Start the admin HTTP server
 */
export function startAdminServer(options: AdminServerOptions): http.Server | null {
  // Prevent multiple starts from regenerating token
  if (server) {
    logger.warn('Admin server already running');
    return server;
  }

  // Only initialize token once
  if (!adminToken) {
    adminToken = initToken();
  }
  startTime = Date.now();

  server = http.createServer(async (req, res) => {
    const url = req.url?.split('?')[0] || '/';
    const method = req.method || 'GET';

    try {
      if (url === '/health' && method === 'GET') {
        handleHealth(res);
      } else if (url === '/shutdown' && method === 'POST') {
        await handleShutdown(req, res, options);
      } else if (url === '/restart' && method === 'POST') {
        await handleRestart(req, res, options);
      } else if (url === '/update' && method === 'POST') {
        await handleUpdate(req, res, options);
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
