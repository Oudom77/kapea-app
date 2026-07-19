# Kapea backend

Small Node.js proxy used by the Flutter app. API keys remain on this server;
the mobile app sends only the URL it wants to scan.

## Requirements

- Node.js 20 or newer
- VirusTotal and urlscan.io API keys for live mode

The project uses only Node.js built-ins, so there are no packages to install.

## Run in mock mode

Mock mode is the default and does not make external requests:

```bash
cd backend
npm start
```

Try it:

```bash
curl http://127.0.0.1:8080/health

curl -X POST http://127.0.0.1:8080/api/v1/scans \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
```

Use a URL containing `login` or `suspicious` for a suspicious mock verdict,
and one containing `malicious`, `phishing`, or `malware` for a malicious
verdict.

## Run with live providers

Copy `.env.example` to `.env`, add both API keys, and set:

```env
MOCK_MODE=false
```

Then start the server:

```bash
npm start
```

Do not commit `.env`.

## API

### `GET /health`

```json
{
  "data": {
    "status": "ok",
    "mode": "mock",
    "timestamp": "2026-07-19T06:00:00.000Z"
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

Response:

```json
{
  "data": {
    "url": "https://example.com/",
    "tier": "safe",
    "scannedAt": "2026-07-19T06:00:00.000Z",
    "redirectChain": [],
    "reasons": [
      "No security engines flagged this URL"
    ],
    "enginesFlagged": 0,
    "totalEngines": 72,
    "screenshotUrl": null
  }
}
```

Errors use one shape:

```json
{
  "error": {
    "code": "INVALID_URL",
    "message": "Enter a valid URL."
  }
}
```

## Tests

```bash
npm test
```
