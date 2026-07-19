import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';

import { createRequestHandler } from './app.js';
import { loadConfig, loadEnvFile } from './config.js';
import { ScanService } from './scan-service.js';
import { TtlCache } from './ttl-cache.js';
import { UrlscanClient } from './providers/urlscan.js';
import { VirusTotalClient } from './providers/virustotal.js';

const envPath = fileURLToPath(new URL('../.env', import.meta.url));
loadEnvFile(envPath);

const config = loadConfig();
const cache = new TtlCache({ ttlMs: config.cacheTtlMs });

const virusTotalClient = config.mockMode
  ? null
  : new VirusTotalClient({
      apiKey: config.virusTotalApiKey,
      providerTimeoutMs: config.providerTimeoutMs,
      pollIntervalMs: config.pollIntervalMs,
    });

const urlscanClient = config.mockMode
  ? null
  : new UrlscanClient({
      apiKey: config.urlscanApiKey,
      visibility: config.urlscanVisibility,
      providerTimeoutMs: config.providerTimeoutMs,
      pollIntervalMs: config.pollIntervalMs,
    });

const scanService = new ScanService({
  mockMode: config.mockMode,
  virusTotalClient,
  urlscanClient,
  cache,
  maliciousEngineThreshold: config.maliciousEngineThreshold,
  scanTimeoutMs: config.scanTimeoutMs,
});

const server = createServer(
  createRequestHandler({
    scanService,
    mode: config.mockMode ? 'mock' : 'live',
    allowedOrigin: config.allowedOrigin,
  }),
);

server.listen(config.port, config.host, () => {
  console.log(
    `Kapea backend listening at http://${config.host}:${config.port} (${config.mockMode ? 'mock' : 'live'} mode)`,
  );
});

function shutdown() {
  server.close((error) => {
    if (error) {
      console.error(error);
      process.exitCode = 1;
    }
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
