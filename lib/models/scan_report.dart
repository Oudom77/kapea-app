enum RiskTier { safe, suspicious, malicious }

class ScanReport {

  // What was scanned? The verdict? When? What evidence?

  final String url;
  final RiskTier tier;
  final DateTime scannedAt;
  final List<String> redirectChain;
  final List<String> reasons;
  final int engineFlagged;
  final int totalEngines;

  const ScanReport({
    required this.url,
    required this.tier,
    required this.scannedAt,
    required this.redirectChain,
    required this.reasons,
    required this.engineFlagged,
    this.totalEngines = 72,
  });
}
