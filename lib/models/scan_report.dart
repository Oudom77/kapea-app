enum RiskTier { safe, suspicious, malicious }

class ScanReport {

  // What was scanned? The verdict? When? What evidence?

  final String url;
  final RiskTier tier;
  final DateTime scannedAt;
  final List<String> redirectChain;
  final List<String> reasons;
  final int enginesFlagged;
  final int totalEngines;
  final String? screenshotUrl;

  const ScanReport({
    required this.url,
    required this.tier,
    required this.scannedAt,
    required this.redirectChain,
    required this.reasons,
    required this.enginesFlagged,
    this.totalEngines = 72,
    this.screenshotUrl,
  });
}
