import assert from 'node:assert/strict';
import test from 'node:test';

import { TtlCache } from '../src/ttl-cache.js';

test('expires cached values after their TTL', () => {
  let now = 1000;
  const cache = new TtlCache({
    ttlMs: 500,
    now: () => now,
  });

  cache.set('url', 'report');
  assert.equal(cache.get('url'), 'report');

  now = 1500;
  assert.equal(cache.get('url'), undefined);
});
