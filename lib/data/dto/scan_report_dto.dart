import '../../models/scan_report.dart';

class ScanReportDto {
  static ScanReport fromJson(Map<String, dynamic> json) {
    assert(json['url'] is String);
    assert(json['tier'] is String);
    assert(json['scannedAt'] is String);
    assert(json['redirectChain'] is List);
    assert(json['reasons'] is List);
    assert(json['enginesFlagged'] is int);
    assert(json['totalEngines'] is int);
    assert(json['screenshotUrl'] == null || json['screenshotUrl'] is String);

    final String url = json['url'] as String;

    final String tierName = json['tier'] as String;
    final RiskTier tier = RiskTier.values.byName(tierName);

    final String scannedAtString = json['scannedAt'] as String;
    final DateTime scannedAt = DateTime.parse(scannedAtString);

    final List<String> redirectChain = List<String>.from(
      json['redirectChain'] as List,
    );

    final List<String> reasons = List<String>.from(json['reasons'] as List);

    final int enginesFlagged = json['enginesFlagged'] as int;
    final int totalEngines = json['totalEngines'] as int;
    final String? screenshotUrl = json['screenshotUrl'] as String?;

    final String? evidenceStatus = json["evidenceStatus"] as String?;
    final List<String> warning = json["warning"] is List<String>
        ? List<String>.from(json["warning"] as List)
        : [];

    return ScanReport(
      url: url,
      tier: tier,
      scannedAt: scannedAt,
      redirectChain: redirectChain,
      reasons: reasons,
      enginesFlagged: enginesFlagged,
      totalEngines: totalEngines,
      screenshotUrl: screenshotUrl,
      evidenceStatus: evidenceStatus,
      warnings: warning,
    );
  }

  static Map<String, dynamic> toJson(ScanReport report) {
    return {
      'url': report.url,
      'tier': report.tier.name,
      'scannedAt': report.scannedAt.toIso8601String(),
      'redirectChain': report.redirectChain,
      'reasons': report.reasons,
      'enginesFlagged': report.enginesFlagged,
      'totalEngines': report.totalEngines,
      'screenshotUrl': report.screenshotUrl,
    };
  }
}
