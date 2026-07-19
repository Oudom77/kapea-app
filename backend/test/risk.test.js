import assert from 'node:assert/strict';
import test from 'node:test';

import { classifyRisk } from '../src/risk.js';

test('classifies an unflagged result as safe', () => {
  const result = classifyRisk({
    harmless: 64,
    malicious: 0,
    suspicious: 0,
    undetected: 8,
  });

  assert.equal(result.tier, 'safe');
  assert.equal(result.enginesFlagged, 0);
  assert.equal(result.totalEngines, 72);
});

test('classifies a small number of flags as suspicious', () => {
  const result = classifyRisk({
    harmless: 65,
    malicious: 1,
    suspicious: 2,
    undetected: 4,
  });

  assert.equal(result.tier, 'suspicious');
  assert.equal(result.enginesFlagged, 3);
});

test('uses the configured malicious threshold', () => {
  const result = classifyRisk(
    {
      harmless: 60,
      malicious: 3,
      suspicious: 0,
      undetected: 9,
    },
    3,
  );

  assert.equal(result.tier, 'malicious');
});
