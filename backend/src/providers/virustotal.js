import { ProviderError } from '../errors.js';
import { requestJson, wait } from '../provider-http.js';

const apiBaseUrl = 'https://www.virustotal.com/api/v3/';

export class VirusTotalClient {
  constructor({
    apiKey,
    fetchImpl = globalThis.fetch,
    providerTimeoutMs,
    pollIntervalMs,
    reportMaxAgeMs,
    now = Date.now,
  }) {
    this.apiKey = apiKey;
    this.fetchImpl = fetchImpl;
    this.providerTimeoutMs = providerTimeoutMs;
    this.pollIntervalMs = pollIntervalMs;
    this.reportMaxAgeMs = reportMaxAgeMs;
    this.now = now;
  }

  async scan(url, { signal, force = false } = {}) {
    const existing = force ? null : await this.#getExistingReport(url, signal);
    if (existing) {
      return existing;
    }

    return this.#submitAndWait(url, signal);
  }

  async #getExistingReport(url, signal) {
    const urlId = Buffer.from(url, 'utf8').toString('base64url');
    const result = await requestJson({
      fetchImpl: this.fetchImpl,
      provider: 'VirusTotal',
      url: new URL(`urls/${urlId}`, apiBaseUrl),
      timeoutMs: this.providerTimeoutMs,
      signal,
      allowedStatuses: [404],
      options: {
        headers: {
          'x-apikey': this.apiKey,
        },
      },
    });

    if (result.response.status === 404) {
      return null;
    }

    const attributes = result.data?.data?.attributes;
    const analyzedAtSeconds = attributes?.last_analysis_date;
    const stats = attributes?.last_analysis_stats;

    if (
      !Number.isSafeInteger(analyzedAtSeconds) ||
      !stats ||
      typeof stats !== 'object'
    ) {
      return null;
    }

    const analyzedAtMs = analyzedAtSeconds * 1000;
    if (this.now() - analyzedAtMs > this.reportMaxAgeMs) {
      return null;
    }

    return {
      stats,
      source: 'existing',
      analyzedAt: new Date(analyzedAtMs).toISOString(),
    };
  }

  async #submitAndWait(url, signal) {
    const body = new URLSearchParams({ url });
    const submission = await requestJson({
      fetchImpl: this.fetchImpl,
      provider: 'VirusTotal',
      url: new URL('urls', apiBaseUrl),
      timeoutMs: this.providerTimeoutMs,
      signal,
      options: {
        method: 'POST',
        headers: {
          'content-type': 'application/x-www-form-urlencoded',
          'x-apikey': this.apiKey,
        },
        body,
      },
    });

    const analysisId = submission.data?.data?.id;
    if (typeof analysisId !== 'string' || analysisId === '') {
      throw invalidResponse();
    }

    const analysisUrl = new URL(
      `analyses/${encodeURIComponent(analysisId)}`,
      apiBaseUrl,
    );

    while (true) {
      const analysis = await requestJson({
        fetchImpl: this.fetchImpl,
        provider: 'VirusTotal',
        url: analysisUrl,
        timeoutMs: this.providerTimeoutMs,
        signal,
        options: {
          headers: {
            'x-apikey': this.apiKey,
          },
        },
      });

      const attributes = analysis.data?.data?.attributes;
      if (!attributes || typeof attributes.status !== 'string') {
        throw invalidResponse();
      }

      if (attributes.status === 'completed') {
        if (!attributes.stats || typeof attributes.stats !== 'object') {
          throw invalidResponse();
        }

        return {
          stats: attributes.stats,
          source: 'fresh',
          analyzedAt: new Date(this.now()).toISOString(),
        };
      }

      if (!['queued', 'in-progress'].includes(attributes.status)) {
        throw invalidResponse();
      }

      await wait(this.pollIntervalMs, signal);
    }
  }
}

function invalidResponse() {
  return new ProviderError({
    provider: 'VirusTotal',
    code: 'PROVIDER_INVALID_RESPONSE',
    message: 'VirusTotal returned an unexpected response.',
  });
}
