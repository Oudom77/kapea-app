import { errorPayload } from './errors.js';
import { classifyRisk } from './risk.js';
import { mockScan } from './mock-scan.js';
import { normalizePublicUrl } from './url-validation.js';

const emptyEvidence = Object.freeze({
  redirectChain: [],
  screenshotUrl: null,
  source: null,
});

export class ScanService {
  constructor({
    mockMode,
    virusTotalClient,
    urlscanClient,
    cache,
    maliciousEngineThreshold,
    scanTimeoutMs,
    evidenceTimeoutMs = scanTimeoutMs,
    now = Date.now,
  }) {
    this.mockMode = mockMode;
    this.virusTotalClient = virusTotalClient;
    this.urlscanClient = urlscanClient;
    this.cache = cache;
    this.maliciousEngineThreshold = maliciousEngineThreshold;
    this.scanTimeoutMs = scanTimeoutMs;
    this.evidenceTimeoutMs = evidenceTimeoutMs;
    this.now = now;
    this.inFlight = new Map();
  }

  normalize(input) {
    return normalizePublicUrl(input);
  }

  getCached(input) {
    return this.cache.get(this.normalize(input));
  }

  async scan(input, { onProgress, force = false } = {}) {
    const url = this.normalize(input);
    const cached = force ? undefined : this.cache.get(url);

    if (cached !== undefined) {
      onProgress?.(cached);
      return cached;
    }

    const existing = force ? undefined : this.inFlight.get(url);
    if (existing) {
      return existing;
    }

    const pending = this.#performScan(url, onProgress, force);
    this.inFlight.set(url, pending);

    try {
      const report = await pending;
      this.cache.set(url, report);
      return report;
    } finally {
      this.inFlight.delete(url);
    }
  }

  async #performScan(url, onProgress, force) {
    if (this.mockMode) {
      const result = await mockScan(url);
      return this.#buildReport({
        url,
        verdict: { ...result, source: 'mock', analyzedAt: null },
        evidence: result,
        evidenceStatus: 'complete',
        warnings: [],
      });
    }

    const verdictDeadline = createDeadline(this.scanTimeoutMs);
    const evidenceDeadline = createDeadline(this.evidenceTimeoutMs);
    const evidencePending = settle(
      this.urlscanClient.scan(url, {
        force,
        signal: evidenceDeadline.controller.signal,
      }),
    );

    try {
      const verdict = await this.virusTotalClient.scan(url, {
        force,
        signal: verdictDeadline.controller.signal,
      });
      verdictDeadline.stop();

      const scannedAt = new Date(this.now()).toISOString();
      const partialReport = this.#buildReport({
        url,
        verdict,
        evidence: emptyEvidence,
        evidenceStatus: 'pending',
        warnings: [],
        scannedAt,
      });
      onProgress?.(partialReport);

      const evidenceResult = await evidencePending;
      if (evidenceResult.status === 'fulfilled') {
        return this.#buildReport({
          url,
          verdict,
          evidence: evidenceResult.value,
          evidenceStatus: 'complete',
          warnings: [],
          scannedAt,
        });
      }

      return this.#buildReport({
        url,
        verdict,
        evidence: emptyEvidence,
        evidenceStatus: 'unavailable',
        warnings: [toWarning(evidenceResult.reason)],
        scannedAt,
      });
    } catch (error) {
      evidenceDeadline.controller.abort();
      await evidencePending;
      throw error;
    } finally {
      verdictDeadline.stop();
      evidenceDeadline.stop();
    }
  }

  #buildReport({
    url,
    verdict,
    evidence,
    evidenceStatus,
    warnings,
    scannedAt = new Date(this.now()).toISOString(),
  }) {
    const risk = classifyRisk(
      verdict.stats,
      this.maliciousEngineThreshold,
    );
    const redirectChain = Array.isArray(evidence.redirectChain)
      ? evidence.redirectChain
      : [];

    if (redirectChain.length > 0) {
      risk.reasons.push(
        `The page redirected through ${redirectChain.length} destination${redirectChain.length === 1 ? '' : 's'}`,
      );
    }

    return {
      url,
      tier: risk.tier,
      scannedAt,
      redirectChain,
      reasons: risk.reasons,
      enginesFlagged: risk.enginesFlagged,
      totalEngines: risk.totalEngines,
      screenshotUrl:
        typeof evidence.screenshotUrl === 'string'
          ? evidence.screenshotUrl
          : null,
      evidenceStatus,
      verdictAnalyzedAt: verdict.analyzedAt || null,
      sources: {
        verdict: verdict.source || null,
        evidence: evidence.source || null,
      },
      warnings,
    };
  }
}

function settle(promise) {
  return promise.then(
    (value) => ({ status: 'fulfilled', value }),
    (reason) => ({ status: 'rejected', reason }),
  );
}

function createDeadline(milliseconds) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), milliseconds);

  return {
    controller,
    stop() {
      clearTimeout(timeout);
    },
  };
}

function toWarning(error) {
  return errorPayload(error).payload.error;
}
