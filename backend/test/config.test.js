import assert from 'node:assert/strict';
import test from 'node:test';

import { loadConfig } from '../src/config.js';

test('uses production-safe defaults for asynchronous scans', () => {
  const config = loadConfig({ MOCK_MODE: 'true' });

  assert.equal(config.host, '0.0.0.0');
  assert.equal(config.port, 8080);
  assert.equal(config.evidenceTimeoutMs, 90000);
  assert.equal(config.virusTotalReportMaxAgeMs, 86400000);
  assert.equal(config.urlscanReportMaxAgeMs, 86400000);
  assert.equal(config.jobTtlMs, 86400000);
  assert.equal(config.scanRequestsPerMinute, 20);
});

test('reads deployment host, port, and job settings from the supplied env', () => {
  const config = loadConfig({
    MOCK_MODE: 'true',
    HOST: '127.0.0.1',
    PORT: '9090',
    EVIDENCE_TIMEOUT_MS: '45000',
    JOB_TTL_SECONDS: '120',
    SCAN_REQUESTS_PER_MINUTE: '12',
  });

  assert.equal(config.host, '127.0.0.1');
  assert.equal(config.port, 9090);
  assert.equal(config.evidenceTimeoutMs, 45000);
  assert.equal(config.jobTtlMs, 120000);
  assert.equal(config.scanRequestsPerMinute, 12);
});
