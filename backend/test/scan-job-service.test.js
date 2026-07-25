import assert from 'node:assert/strict';
import test from 'node:test';

import { AppError } from '../src/errors.js';
import { ScanJobService } from '../src/scan-job-service.js';

const normalizedUrl = 'https://example.com/';

function createJobService(scanService, overrides = {}) {
  let id = 0;
  return new ScanJobService({
    scanService: {
      normalize: () => normalizedUrl,
      getCached: () => undefined,
      ...scanService,
    },
    ttlMs: 1000,
    now: () => Date.parse('2026-07-21T06:00:00.000Z'),
    idFactory: () => `job-${++id}`,
    ...overrides,
  });
}

async function waitForStatus(service, id, expected) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const job = service.get(id);
    if (job?.status === expected) {
      return job;
    }
    await new Promise((resolve) => setImmediate(resolve));
  }
  assert.fail(`Job ${id} did not reach ${expected}`);
}

test('moves a scan from partial to complete', async () => {
  let releaseEvidence;
  const evidenceGate = new Promise((resolve) => {
    releaseEvidence = resolve;
  });
  const partial = { tier: 'safe', evidenceStatus: 'pending' };
  const complete = { tier: 'safe', evidenceStatus: 'complete' };
  const service = createJobService({
    async scan(url, { onProgress }) {
      assert.equal(url, normalizedUrl);
      onProgress(partial);
      await evidenceGate;
      return complete;
    },
  });

  const created = service.create('example.com');
  const partialJob = await waitForStatus(
    service,
    created.job.id,
    'partial',
  );
  assert.deepEqual(partialJob.report, partial);

  releaseEvidence();
  const completedJob = await waitForStatus(
    service,
    created.job.id,
    'complete',
  );
  assert.deepEqual(completedJob.report, complete);
});

test('deduplicates active jobs for the same normalized URL', async () => {
  let release;
  const gate = new Promise((resolve) => {
    release = resolve;
  });
  const service = createJobService({
    async scan() {
      await gate;
      return { tier: 'safe' };
    },
  });

  const first = service.create('example.com');
  const second = service.create('https://example.com/');

  assert.equal(second.created, false);
  assert.equal(second.job.id, first.job.id);
  release();
  await waitForStatus(service, first.job.id, 'complete');
});

test('returns cached reports as immediately complete jobs', () => {
  const cached = { tier: 'safe', evidenceStatus: 'complete' };
  const service = createJobService({
    getCached: () => cached,
    async scan() {
      assert.fail('scan should not run for a cached report');
    },
  });

  const result = service.create('example.com');

  assert.equal(result.job.status, 'complete');
  assert.equal(result.job.cacheHit, true);
  assert.deepEqual(result.job.report, cached);
});

test('force creates a fresh job instead of returning cached reports', async () => {
  const cached = { tier: 'safe', evidenceStatus: 'complete' };
  const fresh = { tier: 'suspicious', evidenceStatus: 'complete' };
  let scanCalls = 0;
  const service = createJobService({
    getCached: () => cached,
    async scan(url, { force }) {
      assert.equal(url, normalizedUrl);
      assert.equal(force, true);
      scanCalls += 1;
      return fresh;
    },
  });

  const result = service.create('example.com', { force: true });

  assert.equal(result.job.status, 'scanning');
  assert.equal(result.job.cacheHit, false);
  assert.equal(result.job.force, true);

  const completed = await waitForStatus(
    service,
    result.job.id,
    'complete',
  );
  assert.equal(scanCalls, 1);
  assert.deepEqual(completed.report, fresh);
});

test('stores structured errors on failed jobs', async () => {
  const service = createJobService({
    async scan() {
      throw new AppError({
        status: 429,
        code: 'RATE_LIMITED',
        message: 'Try again later.',
        retryAfterSeconds: 30,
      });
    },
  });

  const created = service.create('example.com');
  const failed = await waitForStatus(service, created.job.id, 'failed');

  assert.deepEqual(failed.error, {
    code: 'RATE_LIMITED',
    message: 'Try again later.',
    retryAfterSeconds: 30,
  });
});

test('removes completed jobs after their TTL', async () => {
  let now = 1000;
  const service = createJobService(
    {
      async scan() {
        return { tier: 'safe' };
      },
    },
    { now: () => now },
  );

  const created = service.create('example.com');
  await waitForStatus(service, created.job.id, 'complete');
  now = 2000;

  assert.equal(service.get(created.job.id), null);
});
