import '../models/scan_report.dart';
import '../models/scan_job.dart';

abstract interface class ScanService {
  Future<ScanReport> scan(String url);
  Stream<ScanJob> watchScan(String url);
}