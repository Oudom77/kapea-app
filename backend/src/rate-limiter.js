export class FixedWindowRateLimiter {
  constructor({ limit, windowMs, now = Date.now }) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.now = now;
    this.entries = new Map();
  }

  consume(key) {
    const now = this.now();
    const windowStart = Math.floor(now / this.windowMs) * this.windowMs;
    const existing = this.entries.get(key);
    const entry =
      existing?.windowStart === windowStart
        ? existing
        : { windowStart, count: 0 };

    if (entry.count >= this.limit) {
      return {
        allowed: false,
        retryAfterSeconds: Math.max(
          1,
          Math.ceil((windowStart + this.windowMs - now) / 1000),
        ),
      };
    }

    entry.count += 1;
    this.entries.set(key, entry);
    return {
      allowed: true,
      remaining: this.limit - entry.count,
    };
  }
}
