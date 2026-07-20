import fs from 'node:fs';

import { AppError } from './errors.js';

export function loadEnvFile(filePath, env = process.env) {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const contents = fs.readFileSync(filePath, 'utf8');

  for (const rawLine of contents.split(/\r?\n/)) {
    const line = rawLine.trim();

    if (!line || line.startsWith('#')) {
      continue;
    }

    const separator = line.indexOf('=');
    if (separator < 1) {
      continue;
    }

    const key = line.slice(0, separator).trim();
    let value = line.slice(separator + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (env[key] === undefined) {
      env[key] = value;
    }
  }
}

function readBoolean(value, fallback) {
  if (value === undefined || value === '') {
    return fallback;
  }

  if (value === 'true') {
    return true;
  }

  if (value === 'false') {
    return false;
  }

  throw new AppError({
    status: 500,
    code: 'CONFIGURATION_ERROR',
    message: 'A boolean environment value must be true or false.',
  });
}

function readPositiveInteger(value, fallback, name) {
  if (value === undefined || value === '') {
    return fallback;
  }

  const parsed = Number.parseInt(value, 10);
  if (!Number.isSafeInteger(parsed) || parsed <= 0) {
    throw new AppError({
      status: 500,
      code: 'CONFIGURATION_ERROR',
      message: `${name} must be a positive integer.`,
    });
  }

  return parsed;
}

export function loadConfig(env = process.env) {
  const mockMode = readBoolean(env.MOCK_MODE, false);
  const visibility = env.URLSCAN_VISIBILITY || 'unlisted';

  if (!['public', 'unlisted', 'private'].includes(visibility)) {
    throw new AppError({
      status: 500,
      code: 'CONFIGURATION_ERROR',
      message: 'URLSCAN_VISIBILITY must be public, unlisted, or private.',
    });
  }

  if (!mockMode && (!env.VIRUSTOTAL_API_KEY || !env.URLSCAN_API_KEY)) {
    throw new AppError({
      status: 500,
      code: 'CONFIGURATION_ERROR',
      message:
        'VIRUSTOTAL_API_KEY and URLSCAN_API_KEY are required when MOCK_MODE=false.',
    });
  }

  return Object.freeze({
    // host: env.HOST || '127.0.0.1',
    // port: readPositiveInteger(env.PORT, 8080, 'PORT'),
    host: process.env.HOST || "0.0.0.0",
    port: Number(process.env.PORT) || 8080,
    allowedOrigin: env.ALLOWED_ORIGIN || '*',
    cacheTtlMs:
      readPositiveInteger(
        env.CACHE_TTL_SECONDS,
        3600,
        'CACHE_TTL_SECONDS',
      ) * 1000,
    providerTimeoutMs: readPositiveInteger(
      env.PROVIDER_TIMEOUT_MS,
      15000,
      'PROVIDER_TIMEOUT_MS',
    ),
    scanTimeoutMs: readPositiveInteger(
      env.SCAN_TIMEOUT_MS,
      60000,
      'SCAN_TIMEOUT_MS',
    ),
    pollIntervalMs: readPositiveInteger(
      env.POLL_INTERVAL_MS,
      2500,
      'POLL_INTERVAL_MS',
    ),
    maliciousEngineThreshold: readPositiveInteger(
      env.MALICIOUS_ENGINE_THRESHOLD,
      10,
      'MALICIOUS_ENGINE_THRESHOLD',
    ),
    mockMode,
    virusTotalApiKey: env.VIRUSTOTAL_API_KEY || '',
    urlscanApiKey: env.URLSCAN_API_KEY || '',
    urlscanVisibility: visibility,
  });
}
