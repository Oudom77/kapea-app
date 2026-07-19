import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import test from 'node:test';

import { createRequestHandler } from '../src/app.js';

async function withServer(scanService, callback) {
  const server = createServer(
    createRequestHandler({
      scanService,
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

test('POST /api/v1/scans wraps reports in data', async () => {
  const report = {
    url: 'https://example.com/',
    tier: 'safe',
  };

  await withServer(
    {
      async scan(url) {
        assert.equal(url, 'example.com');
        return report;
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

      assert.equal(response.status, 200);
      assert.deepEqual(await response.json(), { data: report });
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
