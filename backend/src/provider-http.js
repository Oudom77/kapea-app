import { AppError, ProviderError } from './errors.js';

function parseRetryAfter(value) {
  if (!value) {
    return undefined;
  }

  const seconds = Number.parseInt(value, 10);
  if (Number.isSafeInteger(seconds) && seconds >= 0) {
    return seconds;
  }

  const date = Date.parse(value);
  if (Number.isNaN(date)) {
    return undefined;
  }

  return Math.max(0, Math.ceil((date - Date.now()) / 1000));
}

function responseError(provider, response) {
  const retryAfterSeconds = parseRetryAfter(
    response.headers.get('retry-after'),
  );

  if (response.status === 429) {
    return new ProviderError({
      provider,
      status: 429,
      code: 'RATE_LIMITED',
      message: `${provider} rate limit reached. Try again shortly.`,
      retryAfterSeconds,
    });
  }

  if (response.status === 401 || response.status === 403) {
    return new ProviderError({
      provider,
      code: 'PROVIDER_AUTH_ERROR',
      message: `${provider} rejected the configured API key.`,
    });
  }

  return new ProviderError({
    provider,
    code: 'PROVIDER_ERROR',
    message: `${provider} returned an unsuccessful response.`,
  });
}

export async function requestJson({
  fetchImpl,
  provider,
  url,
  options = {},
  timeoutMs,
  signal,
  allowedStatuses = [],
}) {
  const controller = new AbortController();
  let timedOut = false;

  const abortFromParent = () => {
    controller.abort(signal.reason);
  };

  if (signal?.aborted) {
    abortFromParent();
  } else {
    signal?.addEventListener('abort', abortFromParent, { once: true });
  }

  const timeout = setTimeout(() => {
    timedOut = true;
    controller.abort();
  }, timeoutMs);

  let response;
  try {
    response = await fetchImpl(url, {
      ...options,
      signal: controller.signal,
    });
  } catch (error) {
    if (signal?.aborted) {
      throw new AppError({
        status: 504,
        code: 'SCAN_TIMEOUT',
        message: 'The scan took too long. Try again.',
        cause: error,
      });
    }

    if (timedOut) {
      throw new ProviderError({
        provider,
        status: 504,
        code: 'PROVIDER_TIMEOUT',
        message: `${provider} took too long to respond.`,
        cause: error,
      });
    }

    throw new ProviderError({
      provider,
      message: `${provider} could not be reached.`,
      cause: error,
    });
  } finally {
    clearTimeout(timeout);
    signal?.removeEventListener('abort', abortFromParent);
  }

  const text = await response.text();
  let data = null;

  if (text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      throw new ProviderError({
        provider,
        code: 'PROVIDER_INVALID_RESPONSE',
        message: `${provider} returned invalid JSON.`,
        cause: error,
      });
    }
  }

  if (!response.ok && !allowedStatuses.includes(response.status)) {
    throw responseError(provider, response);
  }

  return { data, response };
}

export function wait(milliseconds, signal) {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(
        new AppError({
          status: 504,
          code: 'SCAN_TIMEOUT',
          message: 'The scan took too long. Try again.',
        }),
      );
      return;
    }

    const timeout = setTimeout(() => {
      signal?.removeEventListener('abort', onAbort);
      resolve();
    }, milliseconds);

    const onAbort = () => {
      clearTimeout(timeout);
      reject(
        new AppError({
          status: 504,
          code: 'SCAN_TIMEOUT',
          message: 'The scan took too long. Try again.',
        }),
      );
    };

    signal?.addEventListener('abort', onAbort, { once: true });
  });
}
