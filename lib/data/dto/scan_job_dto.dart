import '../../models/scan_report.dart';
import '../../models/scan_job.dart';
import './scan_report_dto.dart';


class ScanJobDto {

  static ScanJob fromJson(Map<String, dynamic> json) {
    final Object? reportJson = json['report'];
    final Object? errorJson = json['error'];

    final String id = json["id"] as String;
    final ScanJobStatus status = ScanJobStatus.values.byName(json['status'] as String);
    final ScanReport? report =  (reportJson is Map<String, dynamic>) ? ScanReportDto.fromJson(reportJson) : null;
    final String? error = (errorJson is Map<String, dynamic>) ? errorJson["message"] as String? : null;

    return ScanJob(
      id: id,
      status: status,
      report: report,
      errorMessage: error
    );
  }

}