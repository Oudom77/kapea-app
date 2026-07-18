# Kapea — Design Decisions

## Guiding principle: actionability

Every screen must answer: **"what should the user do next?"**

A feature earns its place only if the user can act on it, or if it directly
informs a decision the user is about to make. Information that changes no
decision is noise and gets cut.

- Passes: evidence feeding the open/don't-open decision (screenshot preview,
  redirect chain, reasons for flagging), action buttons gated by risk.
- Fails: vanity metrics (scan counters), passive lists, buttons with no real
  effect behind them.

## Risk tiers → behavior

| Tier       | Verdict message              | Primary action                | Open allowed? |
|------------|------------------------------|-------------------------------|---------------|
| Safe       | No threats detected          | Open Link                     | Yes           |
| Suspicious | Caution — some engines flag  | Proceed with caution (friction step) | Yes, with friction |
| Malicious  | Do not open                  | Delete / Share warning        | No — button absent |

Gating the Open button by tier removes the contradiction of offering a
dangerous action next to a danger warning.

## Result screen structure (single scroll, no tabs)

1. Verdict banner — tier color + one-line recommendation
2. Primary action (tier-gated)
3. Screenshot preview of destination (urlscan.io), tap to zoom — see the page
   without visiting it
4. Redirect chain — each hop listed, final destination highlighted — shows
   *why* a shortened/cloaked link is untrustworthy
5. "Why flagged" reasons
6. Collapsed technical details (engine counts, sources)
7. Secondary actions: Share warning, Rescan, Delete

Rationale: a bare verdict asks for trust; verdict + evidence lets the user
verify. Tabs were removed because they hid the evidence behind extra taps.

## Local threat context: Cambodia

Kapea targets the dominant local attack vector: phishing spread through
Telegram — scam links and malicious APK files. Most Telegram scams begin as
shortened or cloaked links, which is why URL scanning with redirect-chain
evidence is the core feature. File scanning (hash lookup against VirusTotal
for known scam APKs) is a planned stretch goal building on the same result
screen and risk tiers.

## Key decisions and rationale

**QR preview intercept (differentiator).** Phones normally open QR links
instantly. Kapea intercepts: the user sees the URL and evidence before
anything opens, turning an automatic action into an informed decision.

**Scan-first home.** Scanning is the app's single core action, so it owns the
home screen. Stats cards were removed: a count of past clean/malicious scans
changes no decision.

**History hidden, "Needs Attention" surfaced.** All scans auto-save (manual
saving risks losing results), but a browseable history list is passive. The
stored data instead powers a Needs Attention list showing only items that
demand a decision: suspicious/malicious results and rescans whose status
changed (`previous_status` vs current).

**Risk engine.** VirusTotal engine vote counts map directly to tiers — no
separate heuristics that could disagree with the backend data.

**Backend proxy.** The app never holds API keys; a server-side proxy calls
VirusTotal and urlscan.io and returns one combined report, with caching to
respect rate limits.

**Guest-only.** Accounts add no value to the core scan-decide loop and were
scoped out.

**Report button removed.** With no reporting backend it would be a fake
action. Share warning replaces it — forwarding the verdict to whoever sent
the link is a real, useful action.

**Actionable errors.** Failures state what to do next ("Rate limit reached —
retry in 30s [Retry]"), never bare error codes.
