import 'package:flutter/material.dart';
import '../ui/themes/kapea_theme.dart';
enum RiskTier {
  malicious(
    label: 'Malicious',
    color: kMaliciousColor,
    icon: Icons.error,
  ),
  suspicious(
    label: 'Suspicious',
    color: kSuspiciousColor,
    icon: Icons.error,
  ),
  safe(
    label: 'No threats found',
    color: kSafeColor,
    icon: Icons.check_circle,
  );

  const RiskTier({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

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
  final String? evidenceStatus;
  final List<String> warnings;

  const ScanReport({
    required this.url,
    required this.tier,
    required this.scannedAt,
    required this.redirectChain,
    required this.reasons,
    required this.enginesFlagged,
    this.totalEngines = 72,
    this.screenshotUrl, 
    this.evidenceStatus, 
    this.warnings = const [],
  });
}
