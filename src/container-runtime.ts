/**
 * Container runtime abstraction for NanoClaw.
 * All runtime-specific logic lives here so swapping runtimes means changing one file.
 */
import { execSync } from 'child_process';
import path from 'path';

import { logger } from './logger.js';

/** The container runtime binary name. */
export const CONTAINER_RUNTIME_BIN = 'docker';

/**
 * Convert Windows path to Docker-compatible format.
 * On Windows, Docker Desktop requires forward slashes and proper path format.
 */
function toDockerPath(hostPath: string): string {
  if (process.platform === 'win32') {
    // Normalize the path first
    let dockerPath = path.normalize(hostPath);
    // Convert backslashes to forward slashes
    dockerPath = dockerPath.replace(/\\/g, '/');
    // Convert drive letter format: C:/path -> /c/path for Docker Desktop
    if (dockerPath.match(/^[A-Za-z]:/)) {
      const driveLetter = dockerPath[0].toLowerCase();
      const pathWithoutDrive = dockerPath.slice(2); // Remove "C:"
      dockerPath = '/' + driveLetter + pathWithoutDrive;
    }
    return dockerPath;
  }
  return hostPath;
}

/** Returns CLI args for a readonly bind mount. */
export function readonlyMountArgs(hostPath: string, containerPath: string): string[] {
  return ['-v', `${toDockerPath(hostPath)}:${containerPath}:ro`];
}

/** Returns CLI args for a read-write bind mount. */
export function readWriteMountArgs(hostPath: string, containerPath: string): string[] {
  return ['-v', `${toDockerPath(hostPath)}:${containerPath}`];
}

/** Returns the shell command to stop a container by name. */
export function stopContainer(name: string): string {
  return `${CONTAINER_RUNTIME_BIN} stop ${name}`;
}

/** Ensure the container runtime is running, starting it if needed. */
export function ensureContainerRuntimeRunning(): void {
  try {
    execSync(`${CONTAINER_RUNTIME_BIN} info`, { stdio: 'pipe', timeout: 10000 });
    logger.debug('Container runtime already running');
  } catch (err) {
    logger.error({ err }, 'Failed to reach container runtime');
    console.error(
      '\n╔════════════════════════════════════════════════════════════════╗',
    );
    console.error(
      '║  FATAL: Container runtime failed to start                      ║',
    );
    console.error(
      '║                                                                ║',
    );
    console.error(
      '║  Agents cannot run without a container runtime. To fix:        ║',
    );
    console.error(
      '║  1. Ensure Docker is installed and running                     ║',
    );
    console.error(
      '║  2. Run: docker info                                           ║',
    );
    console.error(
      '║  3. Restart NanoClaw                                           ║',
    );
    console.error(
      '╚════════════════════════════════════════════════════════════════╝\n',
    );
    throw new Error('Container runtime is required but failed to start');
  }
}

/** Kill orphaned NanoClaw containers from previous runs. */
export function cleanupOrphans(): void {
  try {
    const output = execSync(
      `${CONTAINER_RUNTIME_BIN} ps --filter name=nanoclaw- --format '{{.Names}}'`,
      { stdio: ['pipe', 'pipe', 'pipe'], encoding: 'utf-8' },
    );
    const orphans = output.trim().split('\n').filter(Boolean);
    for (const name of orphans) {
      try {
        execSync(stopContainer(name), { stdio: 'pipe' });
      } catch { /* already stopped */ }
    }
    if (orphans.length > 0) {
      logger.info({ count: orphans.length, names: orphans }, 'Stopped orphaned containers');
    }
  } catch (err) {
    logger.warn({ err }, 'Failed to clean up orphaned containers');
  }
}
