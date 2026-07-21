import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import test from 'node:test';

import { createRequestHandler } from '../src/app.js';

async function withServer(scanJobService, callback, options = {}) {
  const server = createServer(
    createRequestHandler({
      scanJobService,
      scanRateLimiter: options.scanRateLimiter,
      mode: 'mock',
      logger: { error() {} },
      now: () => Date.parse('2026-07-19T06:00:00.000Z'),
    }),
  );

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();

  try {
    await callback(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
}

test('GET /health reports the active mode', async () => {
  await withServer({}, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/health`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.data.status, 'ok');
    assert.equal(body.data.mode, 'mock');
  });
});

test('POST /api/v1/scans creates an asynchronous scan job', async () => {
  const job = {
    id: 'scan-id',
    url: 'https://example.com/',
    status: 'scanning',
    report: null,
    error: null,
  };

  await withServer(
    {
      create(url) {
        assert.equal(url, 'example.com');
        return { job, created: true };
      },
    },
    async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/v1/scans`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
        },
        body: JSON.stringify({ url: 'example.com' }),
      });

      assert.equal(response.status, 202);
      assert.equal(response.headers.get('location'), '/api/v1/scans/scan-id');
      assert.equal(response.headers.get('retry-after'), '2');
      assert.deepEqual(await response.json(), { data: job });
    },
  );
});

test('POST returns a completed cached job immediately', async () => {
  const job = {
    id: 'cached-id',
    status: 'complete',
    report: { tier: 'safe' },
  };

  await withServer(
    {
      create() {
        return { job, created: true };
      },
    },
    async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/v1/scans`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ url: 'example.com' }),
      });

      assert.equal(response.status, 200);
      assert.equal(response.headers.get('retry-after'), null);
    },
  );
});

test('GET /api/v1/scans/:id returns the latest job state', async () => {
  const job = {
    id: 'scan-id',
    status: 'partial',
    report: { tier: 'safe', evidenceStatus: 'pending' },
  };

  await withServer(
    {
      get(id) {
        assert.equal(id, 'scan-id');
        return job;
      },
    },
    async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/v1/scans/scan-id`);

      assert.equal(response.status, 200);
      assert.equal(response.headers.get('retry-after'), '2');
      assert.deepEqual(await response.json(), { data: job });
    },
  );
});

test('GET returns a structured error for an expired scan job', async () => {
  await withServer(
    { get: () => null },
    async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/v1/scans/missing`);
      const body = await response.json();

      assert.equal(response.status, 404);
      assert.equal(body.error.code, 'SCAN_NOT_FOUND');
    },
  );
});

test('POST rate limits scan creation without blocking job polling', async () => {
  await withServer(
    {
      create() {
        assert.fail('rate-limited requests must not create jobs');
      },
      get() {
        return { id: 'existing', status: 'complete', report: {} };
      },
    },
    async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/v1/scans`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ url: 'example.com' }),
      });
      const body = await response.json();

      assert.equal(response.status, 429);
      assert.equal(response.headers.get('retry-after'), '15');
      assert.equal(body.error.code, 'RATE_LIMITED');

      const pollResponse = await fetch(
        `${baseUrl}/api/v1/scans/existing`,
      );
      assert.equal(pollResponse.status, 200);
    },
    {
      scanRateLimiter: {
        consume() {
          return { allowed: false, retryAfterSeconds: 15 };
        },
      },
    },
  );
});

test('scan route rejects malformed JSON with a structured error', async () => {
  await withServer({}, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/v1/scans`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
      },
      body: '{',
    });
    const body = await response.json();

    assert.equal(response.status, 400);
    assert.equal(body.error.code, 'INVALID_JSON');
    assert.equal(typeof body.error.message, 'string');
  });
});

test('unknown routes return JSON instead of HTML', async () => {
  await withServer({}, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/missing`);
    const body = await response.json();

    assert.equal(response.status, 404);
    assert.equal(body.error.code, 'NOT_FOUND');
  });
});
