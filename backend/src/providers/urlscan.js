import { ProviderError } from '../errors.js';
import { requestJson, wait } from '../provider-http.js';

const apiBaseUrl = 'https://urlscan.io/api/v1/';

export class UrlscanClient {
  constructor({
    apiKey,
    visibility = 'unlisted',
    fetchImpl = globalThis.fetch,
    providerTimeoutMs,
    pollIntervalMs,
  }) {
    this.apiKey = apiKey;
    this.visibility = visibility;
    this.fetchImpl = fetchImpl;
    this.providerTimeoutMs = providerTimeoutMs;
    this.pollIntervalMs = pollIntervalMs;
  }

  async scan(url, { signal } = {}) {
    const submission = await requestJson({
      fetchImpl: this.fetchImpl,
      provider: 'urlscan.io',
      url: new URL('scan/', apiBaseUrl),
      timeoutMs: this.providerTimeoutMs,
      signal,
      options: {
        method: 'POST',
        headers: {
          'API-Key': this.apiKey,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          url,
          visibility: this.visibility,
        }),
      },
    });

    const uuid = submission.data?.uuid;
    if (
      typeof uuid !== 'string' ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        uuid,
      )
    ) {
      throw invalidResponse();
    }

    const resultUrl = new URL(
      `result/${encodeURIComponent(uuid)}/`,
      apiBaseUrl,
    );

    while (true) {
      const result = await requestJson({
        fetchImpl: this.fetchImpl,
        provider: 'urlscan.io',
        url: resultUrl,
        timeoutMs: this.providerTimeoutMs,
        signal,
        allowedStatuses: [404],
      });

      if (result.response.status === 404) {
        await wait(this.pollIntervalMs, signal);
        continue;
      }

      if (!result.data || typeof result.data !== 'object') {
        throw invalidResponse();
      }

      return {
        redirectChain: extractRedirectChain(url, result.data),
        screenshotUrl: extractScreenshotUrl(uuid, result.data),
      };
    }
  }
}

function extractScreenshotUrl(uuid, result) {
  if (typeof result.task?.screenshotURL === 'string') {
    return result.task.screenshotURL;
  }

  return `https://urlscan.io/screenshots/${uuid}.png`;
}

function extractRedirectChain(originalUrl, result) {
  const candidates = [];

  for (const entry of result.data?.requests || []) {
    const request = entry?.request;
    const requestUrl = request?.request?.url;
    const requestType = request?.type;

    if (
      typeof requestUrl === 'string' &&
      requestType?.toLowerCase() === 'document'
    ) {
      candidates.push(requestUrl);
    }
  }

  if (typeof result.page?.url === 'string') {
    candidates.push(result.page.url);
  }

  const original = comparableUrl(originalUrl);
  const unique = [];
  const seen = new Set([original]);

  for (const candidate of candidates) {
    const comparable = comparableUrl(candidate);
    if (!comparable || seen.has(comparable)) {
      continue;
    }

    seen.add(comparable);
    unique.push(candidate);
  }

  return unique;
}

function comparableUrl(value) {
  try {
    const url = new URL(value);
    url.hash = '';
    return url.toString();
  } catch {
    return null;
  }
}

function invalidResponse() {
  return new ProviderError({
    provider: 'urlscan.io',
    code: 'PROVIDER_INVALID_RESPONSE',
    message: 'urlscan.io returned an unexpected response.',
  });
}
