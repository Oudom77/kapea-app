import assert from 'node:assert/strict';
import test from 'node:test';

import { ScanService } from '../src/scan-service.js';
import { TtlCache } from '../src/ttl-cache.js';

function createService(overrides = {}) {
  return new ScanService({
    mockMode: false,
    virusTotalClient: {
      async scan() {
        return {
          stats: {
            harmless: 70,
            malicious: 0,
            suspicious: 0,
            undetected: 2,
          },
        };
      },
    },
    urlscanClient: {
      async scan() {
        return {
          redirectChain: [],
          screenshotUrl: 'https://urlscan.io/screenshots/test.png',
        };
      },
    },
    cache: new TtlCache({ ttlMs: 1000 }),
    maliciousEngineThreshold: 3,
    scanTimeoutMs: 1000,
    now: () => Date.parse('2026-07-19T06:00:00.000Z'),
    ...overrides,
  });
}

test('returns the JSON fields expected by the Flutter DTO', async () => {
  const report = await createService().scan('example.com');

  assert.deepEqual(Object.keys(report), [
    'url',
    'tier',
    'scannedAt',
    'redirectChain',
    'reasons',
    'enginesFlagged',
    'totalEngines',
    'screenshotUrl',
  ]);
  assert.equal(report.url, 'https://example.com/');
  assert.equal(report.scannedAt, '2026-07-19T06:00:00.000Z');
});

test('deduplicates concurrent scans and caches the report', async () => {
  let virusTotalCalls = 0;
  const service = createService({
    virusTotalClient: {
      async scan() {
        virusTotalCalls += 1;
        await new Promise((resolve) => setTimeout(resolve, 5));
        return {
          stats: {
            harmless: 72,
            malicious: 0,
            suspicious: 0,
            undetected: 0,
          },
        };
      },
    },
  });

  await Promise.all([
    service.scan('example.com'),
    service.scan('https://example.com/'),
  ]);
  await service.scan('example.com');

  assert.equal(virusTotalCalls, 1);
});

test('returns a verdict when urlscan evidence is unavailable', async () => {
  const service = createService({
    urlscanClient: {
      async scan() {
        throw new Error('temporary failure');
      },
    },
  });

  const report = await service.scan('example.com');
  assert.equal(report.tier, 'safe');
  assert.deepEqual(report.redirectChain, []);
  assert.equal(report.screenshotUrl, null);
});

test('mock mode produces deterministic malicious reports', async () => {
  const service = createService({
    mockMode: true,
  });

  const report = await service.scan('malicious.example');
  assert.equal(report.tier, 'malicious');
  assert.equal(report.enginesFlagged, 68);
});
