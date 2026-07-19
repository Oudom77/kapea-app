import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizePublicUrl } from '../src/url-validation.js';

test('normalizes a public URL and removes its fragment', () => {
  assert.equal(
    normalizePublicUrl(' Example.COM/path#section '),
    'https://example.com/path',
  );
});

test('keeps an explicit HTTP scheme', () => {
  assert.equal(
    normalizePublicUrl('http://example.com'),
    'http://example.com/',
  );
});

test('rejects unsupported URL schemes', () => {
  assert.throws(
    () => normalizePublicUrl('ftp://example.com/file'),
    (error) => error.code === 'INVALID_URL',
  );
});

test('rejects localhost and local network hostnames', () => {
  for (const value of [
    'http://localhost',
    'http://api.internal',
    'http://printer.local',
  ]) {
    assert.throws(
      () => normalizePublicUrl(value),
      (error) => error.code === 'INVALID_URL',
    );
  }
});

test('rejects private and reserved IP addresses', () => {
  for (const value of [
    'http://127.0.0.1',
    'http://10.0.0.1',
    'http://192.168.1.5',
    'http://[::1]',
  ]) {
    assert.throws(
      () => normalizePublicUrl(value),
      (error) => error.code === 'INVALID_URL',
    );
  }
});

test('rejects URLs containing credentials', () => {
  assert.throws(
    () => normalizePublicUrl('https://user:password@example.com'),
    (error) => error.code === 'INVALID_URL',
  );
});
