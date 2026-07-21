import { ProviderError } from '../errors.js';
import { requestJson, wait } from '../provider-http.js';

const apiBaseUrl = 'https://urlscan.io/api/v1/';
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export class UrlscanClient {
  constructor({
    apiKey,
    visibility = 'unlisted',
    fetchImpl = globalThis.fetch,
    providerTimeoutMs,
    pollIntervalMs,
    reportMaxAgeMs,
    now = Date.now,
  }) {
    this.apiKey = apiKey;
    this.visibility = visibility;
    this.fetchImpl = fetchImpl;
    this.providerTimeoutMs = providerTimeoutMs;
    this.pollIntervalMs = pollIntervalMs;
    this.reportMaxAgeMs = reportMaxAgeMs;
    this.now = now;
  }

  async scan(url, { signal } = {}) {
    const existing = await this.#findExisting(url, signal);
    if (existing) {
      return existing;
    }

    return this.#submitAndWait(url, signal);
  }

  async #findExisting(url, signal) {
    const searchUrl = new URL('search/', apiBaseUrl);
    searchUrl.searchParams.set(
      'q',
      `task.url:"${escapeSearchPhrase(url)}" AND apikey:me`,
    );
    searchUrl.searchParams.set('size', '10');

    const search = await requestJson({
      fetchImpl: this.fetchImpl,
      provider: 'urlscan.io',
      url: searchUrl,
      timeoutMs: this.providerTimeoutMs,
      signal,
      options: {
        headers: {
          'API-Key': this.apiKey,
        },
      },
    });

    const results = search.data?.results;
    if (!Array.isArray(results)) {
      throw invalidResponse();
    }

    const expectedUrl = comparableUrl(url);
    for (const candidate of results) {
      const uuid = candidate?._id || candidate?.task?.uuid;
      const candidateUrl = comparableUrl(candidate?.task?.url);
      const scannedAt = Date.parse(candidate?.task?.time || '');

      if (
        !uuidPattern.test(uuid || '') ||
        candidateUrl !== expectedUrl ||
        Number.isNaN(scannedAt) ||
        this.now() - scannedAt > this.reportMaxAgeMs
      ) {
        continue;
      }

      const existing = await this.#getResult(uuid, url, signal, [404]);
      if (existing) {
        return {
          ...existing,
          source: 'existing',
        };
      }
    }

    return null;
  }

  async #submitAndWait(url, signal) {
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
    if (!uuidPattern.test(uuid || '')) {
      throw invalidResponse();
    }

    while (true) {
      const result = await this.#getResult(uuid, url, signal, [404]);
      if (result) {
        return {
          ...result,
          source: 'fresh',
        };
      }

      await wait(this.pollIntervalMs, signal);
    }
  }

  async #getResult(uuid, originalUrl, signal, allowedStatuses = []) {
    const result = await requestJson({
      fetchImpl: this.fetchImpl,
      provider: 'urlscan.io',
      url: new URL(`result/${encodeURIComponent(uuid)}/`, apiBaseUrl),
      timeoutMs: this.providerTimeoutMs,
      signal,
      allowedStatuses,
      options: {
        headers: {
          'API-Key': this.apiKey,
        },
      },
    });

    if (result.response.status === 404) {
      return null;
    }

    if (!result.data || typeof result.data !== 'object') {
      throw invalidResponse();
    }

    return {
      redirectChain: extractRedirectChain(originalUrl, result.data),
      screenshotUrl: extractScreenshotUrl(uuid, result.data),
    };
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

function escapeSearchPhrase(value) {
  return value.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

function invalidResponse() {
  return new ProviderError({
    provider: 'urlscan.io',
    code: 'PROVIDER_INVALID_RESPONSE',
    message: 'urlscan.io returned an unexpected response.',
  });
}
