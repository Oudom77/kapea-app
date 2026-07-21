import { randomUUID } from 'node:crypto';

import { errorPayload } from './errors.js';

const terminalStatuses = new Set(['complete', 'failed']);

export class ScanJobService {
  constructor({
    scanService,
    ttlMs,
    now = Date.now,
    idFactory = randomUUID,
  }) {
    this.scanService = scanService;
    this.ttlMs = ttlMs;
    this.now = now;
    this.idFactory = idFactory;
    this.jobs = new Map();
    this.activeByUrl = new Map();
  }

  create(input) {
    this.#cleanup();
    const url = this.scanService.normalize(input);
    const activeId = this.activeByUrl.get(url);

    if (activeId) {
      const active = this.jobs.get(activeId);
      if (active) {
        return { job: this.#snapshot(active), created: false };
      }
      this.activeByUrl.delete(url);
    }

    const cached = this.scanService.getCached(url);
    if (cached !== undefined) {
      const job = this.#newJob(url, {
        status: 'complete',
        report: cached,
        cacheHit: true,
      });
      this.jobs.set(job.id, job);
      return { job: this.#snapshot(job), created: true };
    }

    const job = this.#newJob(url, {
      status: 'scanning',
      cacheHit: false,
    });
    this.jobs.set(job.id, job);
    this.activeByUrl.set(url, job.id);
    void this.#run(job);

    return { job: this.#snapshot(job), created: true };
  }

  get(id) {
    this.#cleanup();
    const job = this.jobs.get(id);
    return job ? this.#snapshot(job) : null;
  }

  async #run(job) {
    try {
      const report = await this.scanService.scan(job.url, {
        onProgress: (partialReport) => {
          if (terminalStatuses.has(job.status)) {
            return;
          }
          job.status = 'partial';
          job.report = partialReport;
          this.#touch(job);
        },
      });

      job.status = 'complete';
      job.report = report;
      job.error = null;
      this.#touch(job);
    } catch (error) {
      job.status = 'failed';
      job.error = errorPayload(error).payload.error;
      this.#touch(job);
    } finally {
      if (this.activeByUrl.get(job.url) === job.id) {
        this.activeByUrl.delete(job.url);
      }
    }
  }

  #newJob(url, { status, report = null, cacheHit }) {
    const timestamp = new Date(this.now()).toISOString();
    return {
      id: this.idFactory(),
      url,
      status,
      createdAt: timestamp,
      updatedAt: timestamp,
      report,
      error: null,
      cacheHit,
      expiresAt: this.now() + this.ttlMs,
    };
  }

  #touch(job) {
    const now = this.now();
    job.updatedAt = new Date(now).toISOString();
    job.expiresAt = now + this.ttlMs;
  }

  #cleanup() {
    const now = this.now();
    for (const [id, job] of this.jobs) {
      if (terminalStatuses.has(job.status) && job.expiresAt <= now) {
        this.jobs.delete(id);
      }
    }
  }

  #snapshot(job) {
    return structuredClone({
      id: job.id,
      url: job.url,
      status: job.status,
      createdAt: job.createdAt,
      updatedAt: job.updatedAt,
      report: job.report,
      error: job.error,
      cacheHit: job.cacheHit,
    });
  }
}
