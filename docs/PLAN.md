# Kapea — Implementation Plan

Jury: July 27, 2026. Three progress updates, one every ~3 days.

## Update 1 — Redesigned UI on mock data (days 1–3)

- [ ] 1. Home screen: URL input + QR scan button front and center, Needs
  Attention list below (empty state at first). No stats, no bottom nav,
  no profile.
- [ ] 2. Mock scan service: fake results for all four risk tiers, including
  fake screenshot + redirect chain, so every screen is demoable offline.
- [ ] 3. Result screen (single scroll): verdict banner → tier-gated primary
  action → screenshot preview (tap to zoom) → redirect chain → "why flagged"
  reasons → collapsed technical details → Share warning / Rescan / Delete.
- [ ] 4. Auto-save every scan locally (hidden store — no history screen).
- [ ] 5. Verify: run the app, walk all four tiers end to end.

## Update 2 — Real backend + real scans (days 4–6)

- [ ] 6. Backend proxy (hides API keys), one endpoint: URL in → calls
  VirusTotal (verdict) + urlscan.io (screenshot, redirect chain) → combined
  report out.
- [ ] 7. Risk engine: map VirusTotal vote counts directly to the four tiers.
- [ ] 8. Cache layer: return recent report if not expired.
- [ ] 9. Swap app from mock service to real backend; keep mock as demo
  fallback.
- [ ] 10. Error handling: rate-limit and network errors with retry actions,
  not raw error codes.
- [ ] 11. Verify: scan known-safe and known-malicious test URLs, confirm
  tiers match.

## Update 3 — QR intercept + Needs Attention (days 7–9)

- [ ] 12. QR flow: camera scan → intercept screen (preview URL before
  anything opens) → user decides scan or dismiss.
- [ ] 13. Needs Attention logic: surface only suspicious/malicious scans and
  rescans where `previous_status` changed.
- [ ] 14. Add `previous_status` to data model; rescan compares and highlights
  changes.
- [ ] 15. Polish: updated flow diagram, empty states, demo script with
  pre-picked URLs.
- [ ] 16. Final verify: full rehearsal of the demo path.

## Stretch goal (only if updates 1–2 land on schedule)

- [ ] 17. File scan, lean version: pick file → compute SHA-256 locally →
  query VirusTotal hash database → same result screen (no screenshot/redirect
  section). No upload, no polling. Targets known scam APKs spread via
  Telegram. Cut without hesitation if behind schedule.

## Out of scope

Auth/login, browseable history screen, stats dashboard, Report feature.
See docs/DESIGN.md for rationale.
