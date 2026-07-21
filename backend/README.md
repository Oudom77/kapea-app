# Kapea backend

Node.js backend for the Kapea Flutter application. It keeps provider API keys
off the client and combines a VirusTotal verdict with optional urlscan.io
evidence.

## Requirements

- Node.js 20 or newer
- VirusTotal and urlscan.io API keys for live mode

The backend uses only Node.js built-ins, so there are no runtime packages to
install.

## Setup

Copy `.env.example` to `.env`. For deterministic local development, set:

```env
MOCK_MODE=true
```

For live mode, set `MOCK_MODE=false` and provide both API keys. Never commit
`.env`.

Start the server:

```bash
npm start
```

Run the tests:

```bash
npm test
```

## Scan lifecycle

Scanning is asynchronous because fresh VirusTotal and urlscan.io analyses can
take tens of seconds. The API returns a short-lived job immediately instead of
holding one HTTP request open.

Job statuses:

- `scanning`: the required VirusTotal verdict is still running.
- `partial`: the verdict is ready while urlscan evidence is still running.
- `complete`: the verdict and all currently available evidence are ready.
- `failed`: the required verdict could not be produced.

An evidence failure does not discard a valid VirusTotal verdict. A completed
report uses `evidenceStatus: "unavailable"` and includes a structured warning.

## API

### `GET /health`

```json
{
  "data": {
    "status": "ok",
    "mode": "mock",
    "timestamp": "2026-07-21T06:00:00.000Z"
  }
}
```

### `POST /api/v1/scans`

Request:

```json
{
  "url": "https://example.com"
}
```

A new or active scan returns `202 Accepted`, a `Location` header, and:

```json
{
  "data": {
    "id": "5b8dbf09-00e1-4ef5-8231-ecb388689d5a",
    "url": "https://example.com/",
    "status": "scanning",
    "createdAt": "2026-07-21T06:00:00.000Z",
    "updatedAt": "2026-07-21T06:00:00.000Z",
    "report": null,
    "error": null,
    "cacheHit": false
  }
}
```

A fresh backend cache hit returns the same shape with HTTP `200`, status
`complete`, and a populated report.

### `GET /api/v1/scans/:id`

Poll the URL from the `Location` header. While work remains, the response also
contains `Retry-After: 2`.

Partial response:

```json
{
  "data": {
    "id": "5b8dbf09-00e1-4ef5-8231-ecb388689d5a",
    "url": "https://example.com/",
    "status": "partial",
    "createdAt": "2026-07-21T06:00:00.000Z",
    "updatedAt": "2026-07-21T06:00:02.000Z",
    "report": {
      "url": "https://example.com/",
      "tier": "safe",
      "scannedAt": "2026-07-21T06:00:02.000Z",
      "redirectChain": [],
      "reasons": ["No security engines flagged this URL"],
      "enginesFlagged": 0,
      "totalEngines": 72,
      "screenshotUrl": null,
      "evidenceStatus": "pending",
      "verdictAnalyzedAt": "2026-07-21T05:55:00.000Z",
      "sources": {
        "verdict": "existing",
        "evidence": null
      },
      "warnings": []
    },
    "error": null,
    "cacheHit": false
  }
}
```

Failed jobs keep HTTP `200` because the job resource was retrieved
successfully; inspect `data.status` and `data.error`:

```json
{
  "data": {
    "id": "5b8dbf09-00e1-4ef5-8231-ecb388689d5a",
    "status": "failed",
    "report": null,
    "error": {
      "code": "RATE_LIMITED",
      "message": "VirusTotal rate limit reached. Try again shortly.",
      "retryAfterSeconds": 30
    }
  }
}
```

Request-level errors use this shape:

```json
{
  "error": {
    "code": "INVALID_URL",
    "message": "Enter a valid URL."
  }
}
```

## Provider reuse

Before submitting new work, the backend:

1. Requests the existing VirusTotal URL object and reuses recent analysis
   statistics.
2. Searches the authenticated user's recent urlscan.io scans and reuses a
   matching result.
3. Submits and polls only when no sufficiently recent report exists.

Provider report freshness and the backend report cache are configured
independently in `.env.example`.

Only scan creation is rate limited; polling an existing job does not consume
that allowance. The default is 20 new scan requests per client IP per minute.

## Deployment note

Jobs and the final-report cache currently live in the Node.js process. This is
appropriate for the current single-instance Railway deployment, but they are
lost when the process restarts. Before horizontal scaling, replace both stores
with shared durable storage such as Redis or PostgreSQL.
