import assert from 'node:assert/strict';
import test from 'node:test';

import { UrlscanClient } from '../src/providers/urlscan.js';
import { VirusTotalClient } from '../src/providers/virustotal.js';

function jsonResponse(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json',
      ...headers,
    },
  });
}

test('VirusTotal submits a URL and polls until completion', async () => {
  const calls = [];
  const responses = [
    jsonResponse({ data: { id: 'analysis-id' } }),
    jsonResponse({
      data: {
        attributes: {
          status: 'queued',
          stats: {},
        },
      },
    }),
    jsonResponse({
      data: {
        attributes: {
          status: 'completed',
          stats: {
            harmless: 70,
            malicious: 1,
            suspicious: 0,
            undetected: 1,
          },
        },
      },
    }),
  ];

  const client = new VirusTotalClient({
    apiKey: 'test-key',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    async fetchImpl(url, options) {
      calls.push({ url: url.toString(), options });
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/');

  assert.equal(calls.length, 3);
  assert.equal(calls[0].options.headers['x-apikey'], 'test-key');
  assert.equal(
    calls[0].options.body.toString(),
    'url=https%3A%2F%2Fexample.com%2F',
  );
  assert.equal(result.stats.malicious, 1);
});

test('urlscan polls a queued result and extracts page evidence', async () => {
  const uuid = '0e37e828-a9d9-45c0-ac50-1ca579b86c72';
  const responses = [
    jsonResponse({ uuid }),
    jsonResponse({}, 404),
    jsonResponse({
      task: {
        screenshotURL: `https://urlscan.io/screenshots/${uuid}.png`,
      },
      page: {
        url: 'https://destination.example/account',
      },
      data: {
        requests: [
          {
            request: {
              type: 'Document',
              request: {
                url: 'https://redirect.example/',
              },
            },
          },
        ],
      },
    }),
  ];

  const client = new UrlscanClient({
    apiKey: 'test-key',
    visibility: 'unlisted',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    async fetchImpl() {
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/');

  assert.deepEqual(result.redirectChain, [
    'https://redirect.example/',
    'https://destination.example/account',
  ]);
  assert.equal(
    result.screenshotUrl,
    `https://urlscan.io/screenshots/${uuid}.png`,
  );
});

test('provider rate limits become structured application errors', async () => {
  const client = new VirusTotalClient({
    apiKey: 'test-key',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    async fetchImpl() {
      return jsonResponse(
        { error: { message: 'quota exceeded' } },
        429,
        { 'retry-after': '30' },
      );
    },
  });

  await assert.rejects(
    () => client.scan('https://example.com/'),
    (error) =>
      error.code === 'RATE_LIMITED' &&
      error.status === 429 &&
      error.retryAfterSeconds === 30,
  );
});
