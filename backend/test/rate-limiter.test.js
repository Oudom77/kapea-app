import assert from 'node:assert/strict';
import test from 'node:test';

import { FixedWindowRateLimiter } from '../src/rate-limiter.js';

test('allows requests up to the configured fixed-window limit', () => {
  const limiter = new FixedWindowRateLimiter({
    limit: 2,
    windowMs: 60000,
    now: () => 30000,
  });

  assert.deepEqual(limiter.consume('client'), {
    allowed: true,
    remaining: 1,
  });
  assert.deepEqual(limiter.consume('client'), {
    allowed: true,
    remaining: 0,
  });
  assert.deepEqual(limiter.consume('client'), {
    allowed: false,
    retryAfterSeconds: 30,
  });
});

test('starts a fresh allowance in the next time window', () => {
  let now = 59000;
  const limiter = new FixedWindowRateLimiter({
    limit: 1,
    windowMs: 60000,
    now: () => now,
  });

  assert.equal(limiter.consume('client').allowed, true);
  assert.equal(limiter.consume('client').allowed, false);
  now = 60000;
  assert.equal(limiter.consume('client').allowed, true);
});
