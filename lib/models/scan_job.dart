import './scan_report.dart';

enum ScanJobStatus {
  scanning,
  partial,
  complete,
  failed,
}

class ScanJob {

  // The status? report(result)? errors?

  final String id;
  final ScanJobStatus status;
  final ScanReport? report;
  final String? errorMessage;

  const ScanJob({
    required this.id,
    required this.status,
    required this.report,
    required this.errorMessage,
  });
}