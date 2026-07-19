import net from 'node:net';

import { AppError } from './errors.js';

const blockedHostSuffixes = [
  '.localhost',
  '.local',
  '.internal',
  '.home',
  '.lan',
];

function isBlockedIpv4(address) {
  const octets = address.split('.').map(Number);
  const [first, second, third] = octets;

  return (
    first === 0 ||
    first === 10 ||
    first === 127 ||
    (first === 100 && second >= 64 && second <= 127) ||
    (first === 169 && second === 254) ||
    (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 0 && third === 0) ||
    (first === 192 && second === 0 && third === 2) ||
    (first === 192 && second === 168) ||
    (first === 198 && (second === 18 || second === 19)) ||
    (first === 198 && second === 51 && third === 100) ||
    (first === 203 && second === 0 && third === 113) ||
    first >= 224
  );
}

function isBlockedIpv6(address) {
  const normalized = address
    .replace(/^\[/, '')
    .replace(/\]$/, '')
    .toLowerCase();

  if (
    normalized === '::' ||
    normalized === '::1' ||
    normalized.startsWith('fc') ||
    normalized.startsWith('fd') ||
    /^fe[89ab]/.test(normalized) ||
    normalized.startsWith('ff') ||
    normalized.startsWith('2001:db8:')
  ) {
    return true;
  }

  const mappedIpv4 = normalized.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/);
  return mappedIpv4 ? isBlockedIpv4(mappedIpv4[1]) : false;
}

function assertPublicHostname(hostname) {
  const normalized = hostname
    .replace(/^\[/, '')
    .replace(/\]$/, '')
    .replace(/\.$/, '')
    .toLowerCase();

  if (
    normalized === 'localhost' ||
    blockedHostSuffixes.some((suffix) => normalized.endsWith(suffix))
  ) {
    throw invalidUrl('Local network addresses cannot be scanned.');
  }

  const ipVersion = net.isIP(normalized);
  if (
    (ipVersion === 4 && isBlockedIpv4(normalized)) ||
    (ipVersion === 6 && isBlockedIpv6(normalized))
  ) {
    throw invalidUrl('Private or reserved network addresses cannot be scanned.');
  }

  if (ipVersion === 0 && !normalized.includes('.')) {
    throw invalidUrl('Enter a public hostname.');
  }
}

function invalidUrl(message) {
  return new AppError({
    status: 400,
    code: 'INVALID_URL',
    message,
  });
}

export function normalizePublicUrl(input) {
  if (typeof input !== 'string' || input.trim() === '') {
    throw invalidUrl('A URL is required.');
  }

  const candidate = input.trim();
  const withScheme = /^[a-z][a-z\d+.-]*:\/\//i.test(candidate)
    ? candidate
    : `https://${candidate}`;

  let url;
  try {
    url = new URL(withScheme);
  } catch {
    throw invalidUrl('Enter a valid URL.');
  }

  if (!['http:', 'https:'].includes(url.protocol)) {
    throw invalidUrl('Only HTTP and HTTPS URLs can be scanned.');
  }

  if (url.username || url.password) {
    throw invalidUrl('URLs containing credentials cannot be scanned.');
  }

  assertPublicHostname(url.hostname);
  url.hash = '';

  return url.toString();
}
