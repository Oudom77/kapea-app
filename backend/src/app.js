import { AppError, errorPayload } from './errors.js';

const maxBodyBytes = 16 * 1024;

export function createRequestHandler({
  scanJobService,
  scanRateLimiter,
  mode,
  allowedOrigin = '*',
  logger = console,
  now = Date.now,
}) {
  return async function requestHandler(request, response) {
    setCommonHeaders(response, allowedOrigin);

    if (request.method === 'OPTIONS') {
      response.writeHead(204);
      response.end();
      return;
    }

    try {
      const url = new URL(request.url, 'http://localhost');

      if (url.pathname === '/health') {
        assertMethod(request, 'GET');
        sendJson(response, 200, {
          data: {
            status: 'ok',
            mode,
            timestamp: new Date(now()).toISOString(),
          },
        });
        return;
      }

      if (url.pathname === '/api/v1/scans') {
        assertMethod(request, 'POST');
        enforceScanRateLimit(request, scanRateLimiter);
        const body = await readJsonBody(request);
        const result = scanJobService.create(body.url);
        const status = result.job.status === 'complete' ? 200 : 202;
        sendJob(response, status, result.job);
        return;
      }

      const scanId = scanIdFromPath(url.pathname);
      if (scanId !== null) {
        assertMethod(request, 'GET');
        const job = scanJobService.get(scanId);
        if (!job) {
          throw new AppError({
            status: 404,
            code: 'SCAN_NOT_FOUND',
            message: 'The scan job was not found or has expired.',
          });
        }
        sendJob(response, 200, job);
        return;
      }

      throw new AppError({
        status: 404,
        code: 'NOT_FOUND',
        message: 'Route not found.',
      });
    } catch (error) {
      const result = errorPayload(error);

      if (result.status >= 500) {
        logger.error?.(error);
      }

      if (result.retryAfterSeconds !== undefined) {
        response.setHeader(
          'retry-after',
          String(result.retryAfterSeconds),
        );
      }

      sendJson(response, result.status, result.payload);
    }
  };
}

function setCommonHeaders(response, allowedOrigin) {
  response.setHeader('access-control-allow-origin', allowedOrigin);
  response.setHeader('access-control-allow-methods', 'GET, POST, OPTIONS');
  response.setHeader(
    'access-control-allow-headers',
    'content-type',
  );
  response.setHeader(
    'access-control-expose-headers',
    'location, retry-after',
  );
  response.setHeader('cache-control', 'no-store');
  response.setHeader('x-content-type-options', 'nosniff');
}

function assertMethod(request, expected) {
  if (request.method !== expected) {
    throw new AppError({
      status: 405,
      code: 'METHOD_NOT_ALLOWED',
      message: `Use ${expected} for this route.`,
    });
  }
}

async function readJsonBody(request) {
  const contentType = request.headers['content-type'] || '';
  if (!contentType.toLowerCase().startsWith('application/json')) {
    throw new AppError({
      status: 415,
      code: 'UNSUPPORTED_MEDIA_TYPE',
      message: 'Content-Type must be application/json.',
    });
  }

  const declaredLength = Number.parseInt(
    request.headers['content-length'] || '0',
    10,
  );
  if (declaredLength > maxBodyBytes) {
    throw payloadTooLarge();
  }

  const chunks = [];
  let size = 0;

  for await (const chunk of request) {
    size += chunk.length;
    if (size > maxBodyBytes) {
      throw payloadTooLarge();
    }
    chunks.push(chunk);
  }

  let body;
  try {
    body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw new AppError({
      status: 400,
      code: 'INVALID_JSON',
      message: 'Request body must contain valid JSON.',
    });
  }

  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new AppError({
      status: 400,
      code: 'INVALID_JSON',
      message: 'Request body must be a JSON object.',
    });
  }

  return body;
}

function payloadTooLarge() {
  return new AppError({
    status: 413,
    code: 'PAYLOAD_TOO_LARGE',
    message: 'Request body is too large.',
  });
}

function scanIdFromPath(pathname) {
  const match = pathname.match(/^\/api\/v1\/scans\/([^/]+)$/);
  if (!match) {
    return null;
  }

  try {
    return decodeURIComponent(match[1]);
  } catch {
    throw new AppError({
      status: 400,
      code: 'INVALID_SCAN_ID',
      message: 'The scan ID is invalid.',
    });
  }
}

function enforceScanRateLimit(request, limiter) {
  if (!limiter) {
    return;
  }

  const forwardedFor = request.headers['x-forwarded-for'];
  const clientAddress =
    (typeof forwardedFor === 'string'
      ? forwardedFor.split(',')[0].trim()
      : null) || request.socket.remoteAddress || 'unknown';
  const result = limiter.consume(clientAddress);

  if (!result.allowed) {
    throw new AppError({
      status: 429,
      code: 'RATE_LIMITED',
      message: 'Too many scan requests. Try again shortly.',
      retryAfterSeconds: result.retryAfterSeconds,
    });
  }
}

function sendJob(response, status, job) {
  const headers = {
    location: `/api/v1/scans/${encodeURIComponent(job.id)}`,
  };

  if (!['complete', 'failed'].includes(job.status)) {
    headers['retry-after'] = '2';
  }

  sendJson(response, status, { data: job }, headers);
}

function sendJson(response, status, payload, headers = {}) {
  const body = JSON.stringify(payload);
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(body),
    ...headers,
  });
  response.end(body);
}
