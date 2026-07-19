export class TtlCache {
  constructor({ ttlMs, now = Date.now }) {
    this.ttlMs = ttlMs;
    this.now = now;
    this.entries = new Map();
  }

  get(key) {
    const entry = this.entries.get(key);
    if (!entry) {
      return undefined;
    }

    if (entry.expiresAt <= this.now()) {
      this.entries.delete(key);
      return undefined;
    }

    return entry.value;
  }

  set(key, value) {
    this.entries.set(key, {
      expiresAt: this.now() + this.ttlMs,
      value,
    });
  }

  clear() {
    this.entries.clear();
  }
}
