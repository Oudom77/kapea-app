import assert from 'node:assert/strict';
import test from 'node:test';

import { UrlscanClient } from '../src/providers/urlscan.js';
import { VirusTotalClient } from '../src/providers/virustotal.js';

const now = Date.parse('2026-07-21T06:00:00.000Z');

function jsonResponse(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json',
      ...headers,
    },
  });
}

test('VirusTotal reuses a recent existing URL report', async () => {
  const calls = [];
  const stats = {
    harmless: 70,
    malicious: 1,
    suspicious: 0,
    undetected: 1,
  };
  const client = new VirusTotalClient({
    apiKey: 'test-key',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    reportMaxAgeMs: 86400000,
    now: () => now,
    async fetchImpl(url, options) {
      calls.push({ url: url.toString(), options });
      return jsonResponse({
        data: {
          attributes: {
            last_analysis_date: Math.floor(now / 1000) - 60,
            last_analysis_stats: stats,
          },
        },
      });
    },
  });

  const result = await client.scan('https://example.com/');

  assert.equal(calls.length, 1);
  assert.match(calls[0].url, /\/api\/v3\/urls\//);
  assert.equal(calls[0].options.headers['x-apikey'], 'test-key');
  assert.equal(result.source, 'existing');
  assert.deepEqual(result.stats, stats);
});

test('VirusTotal submits and polls when an existing report is stale', async () => {
  const calls = [];
  const responses = [
    jsonResponse({
      data: {
        attributes: {
          last_analysis_date: Math.floor(now / 1000) - 172800,
          last_analysis_stats: { harmless: 72 },
        },
      },
    }),
    jsonResponse({ data: { id: 'analysis-id' } }),
    jsonResponse({
      data: { attributes: { status: 'queued', stats: {} } },
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
    reportMaxAgeMs: 86400000,
    now: () => now,
    async fetchImpl(url, options) {
      calls.push({ url: url.toString(), options });
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/');

  assert.equal(calls.length, 4);
  assert.equal(calls[1].options.method, 'POST');
  assert.equal(
    calls[1].options.body.toString(),
    'url=https%3A%2F%2Fexample.com%2F',
  );
  assert.equal(result.source, 'fresh');
  assert.equal(result.stats.malicious, 1);
});

test('VirusTotal force skips existing URL report lookup', async () => {
  const calls = [];
  const responses = [
    jsonResponse({ data: { id: 'analysis-id' } }),
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
    reportMaxAgeMs: 86400000,
    now: () => now,
    async fetchImpl(url, options) {
      calls.push({ url: url.toString(), options });
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/', { force: true });

  assert.equal(calls.length, 2);
  assert.match(calls[0].url, /\/api\/v3\/urls$/);
  assert.equal(calls[0].options.method, 'POST');
  assert.equal(result.source, 'fresh');
});

test('urlscan reuses a recent matching result', async () => {
  const uuid = '0e37e828-a9d9-45c0-ac50-1ca579b86c72';
  const responses = [
    jsonResponse({
      results: [
        {
          _id: uuid,
          task: {
            url: 'https://example.com/',
            time: '2026-07-21T05:55:00.000Z',
          },
        },
      ],
    }),
    jsonResponse({
      task: {
        screenshotURL: `https://urlscan.io/screenshots/${uuid}.png`,
      },
      page: { url: 'https://destination.example/account' },
      data: { requests: [] },
    }),
  ];
  const calls = [];
  const client = new UrlscanClient({
    apiKey: 'test-key',
    visibility: 'unlisted',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    reportMaxAgeMs: 86400000,
    now: () => now,
    async fetchImpl(url) {
      calls.push(url.toString());
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/');

  assert.equal(calls.length, 2);
  assert.match(calls[0], /\/api\/v1\/search\//);
  assert.equal(result.source, 'existing');
  assert.equal(
    result.screenshotUrl,
    `https://urlscan.io/screenshots/${uuid}.png`,
  );
});

test('urlscan force skips existing result lookup', async () => {
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
      data: { requests: [] },
    }),
  ];
  const calls = [];
  const client = new UrlscanClient({
    apiKey: 'test-key',
    visibility: 'unlisted',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    reportMaxAgeMs: 86400000,
    now: () => now,
    async fetchImpl(url, options) {
      calls.push({ url: url.toString(), options });
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/', { force: true });

  assert.equal(calls.length, 3);
  assert.match(calls[0].url, /\/api\/v1\/scan\//);
  assert.equal(calls[0].options.method, 'POST');
  assert.equal(result.source, 'fresh');
});

test('urlscan submits, polls, and extracts evidence when no result exists', async () => {
  const uuid = '0e37e828-a9d9-45c0-ac50-1ca579b86c72';
  const responses = [
    jsonResponse({ results: [] }),
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
              request: { url: 'https://redirect.example/' },
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
    reportMaxAgeMs: 86400000,
    now: () => now,
    async fetchImpl() {
      return responses.shift();
    },
  });

  const result = await client.scan('https://example.com/');

  assert.deepEqual(result.redirectChain, [
    'https://redirect.example/',
    'https://destination.example/account',
  ]);
  assert.equal(result.source, 'fresh');
});

test('provider rate limits become structured application errors', async () => {
  const client = new VirusTotalClient({
    apiKey: 'test-key',
    providerTimeoutMs: 1000,
    pollIntervalMs: 1,
    reportMaxAgeMs: 86400000,
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
