import { classifyRisk } from './risk.js';
import { mockScan } from './mock-scan.js';
import { normalizePublicUrl } from './url-validation.js';

export class ScanService {
  constructor({
    mockMode,
    virusTotalClient,
    urlscanClient,
    cache,
    maliciousEngineThreshold,
    scanTimeoutMs,
    now = Date.now,
  }) {
    this.mockMode = mockMode;
    this.virusTotalClient = virusTotalClient;
    this.urlscanClient = urlscanClient;
    this.cache = cache;
    this.maliciousEngineThreshold = maliciousEngineThreshold;
    this.scanTimeoutMs = scanTimeoutMs;
    this.now = now;
    this.inFlight = new Map();
  }

  async scan(input) {
    const url = normalizePublicUrl(input);
    const cached = this.cache.get(url);

    if (cached !== undefined) {
      return cached;
    }

    const existing = this.inFlight.get(url);
    if (existing) {
      return existing;
    }

    const pending = this.#performScan(url);
    this.inFlight.set(url, pending);

    try {
      const report = await pending;
      this.cache.set(url, report);
      return report;
    } finally {
      this.inFlight.delete(url);
    }
  }

  async #performScan(url) {
    if (this.mockMode) {
      const mockResult = await mockScan(url);
      return this.#buildReport(url, mockResult);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => {
      controller.abort();
    }, this.scanTimeoutMs);

    try {
      const [virusTotalResult, urlscanResult] = await Promise.allSettled([
        this.virusTotalClient.scan(url, { signal: controller.signal }),
        this.urlscanClient.scan(url, { signal: controller.signal }),
      ]);

      if (virusTotalResult.status === 'rejected') {
        throw virusTotalResult.reason;
      }

      const evidence =
        urlscanResult.status === 'fulfilled'
          ? urlscanResult.value
          : {
              redirectChain: [],
              screenshotUrl: null,
            };

      return this.#buildReport(url, {
        stats: virusTotalResult.value.stats,
        ...evidence,
      });
    } finally {
      clearTimeout(timeout);
    }
  }

  #buildReport(url, providerResult) {
    const risk = classifyRisk(
      providerResult.stats,
      this.maliciousEngineThreshold,
    );

    const redirectChain = Array.isArray(providerResult.redirectChain)
      ? providerResult.redirectChain
      : [];

    if (redirectChain.length > 0) {
      risk.reasons.push(
        `The page redirected through ${redirectChain.length} destination${redirectChain.length === 1 ? '' : 's'}`,
      );
    }

    return {
      url,
      tier: risk.tier,
      scannedAt: new Date(this.now()).toISOString(),
      redirectChain,
      reasons: risk.reasons,
      enginesFlagged: risk.enginesFlagged,
      totalEngines: risk.totalEngines,
      screenshotUrl:
        typeof providerResult.screenshotUrl === 'string'
          ? providerResult.screenshotUrl
          : null,
    };
  }
}
