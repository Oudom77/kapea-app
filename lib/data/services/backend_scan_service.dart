import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// DTOs
import '../../data/dto/scan_job_dto.dart';

// Models
import '../../models/scan_report.dart';
import '../../models/scan_job.dart';

// Services
import '../../services/scan_service.dart';


class BackendScanService implements ScanService {

  final String baseUrl;
  final Duration pollInterval;
  final Duration scanTimeout;

  const BackendScanService({
    this.baseUrl = "https://kapea-backend-production.up.railway.app", 
    this.pollInterval = const Duration(seconds: 2), 
    this.scanTimeout = const Duration(minutes: 2),
  });

  @override
  Future<ScanReport> scan(String url) async {

    await for (final ScanJob job in watchScan(url)){

      switch (job.status){
      
        case ScanJobStatus.scanning:
        case ScanJobStatus.partial:
          continue;
        case ScanJobStatus.complete:
      
          final ScanReport? report = job.report;
      
          if (report == null){
            throw Exception('Completed scan job has no report.');
          }
      
          return report;
      
        case ScanJobStatus.failed:
          throw Exception(
            job.errorMessage ?? "The scan failed for an unknown reason!!"
          );
      }
    }

    throw StateError("The scan stream closed without a final result.");
  }
  @override
  Stream<ScanJob> watchScan(String url, {bool force = false}) async* {

    ScanJob job = await _createScanJob(url, force: force); // create job if cached result available use that
    final DateTime deadline = DateTime.now().add(scanTimeout);

    yield job; // initial yield for cached result

    while (!job.isFinished){

      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'Scan timed out after ${scanTimeout.inSeconds} seconds.',
        );
      }

      await Future<void>.delayed(pollInterval);

      job = await _getScanJob(job.id);

      yield job; // returns a yield every interval until job is finished
    }
  }

  Future<ScanJob> _createScanJob(String url, {bool force = false}) async {

    final Uri endpoint = Uri.parse(baseUrl).replace(path: "/api/v1/scans");

    final String requestBody = jsonEncode({
      "url": url,
      if (force) "force" : true,
    });

    final http.Response response = await http.post(
      endpoint,
      headers: {
        "Content-Type": "application/json",
      },
      body: requestBody,
    );

    if (response.statusCode < 200 || response.statusCode >= 300){

      throw Exception("Backend Error!! Status code: ${response.statusCode}: ${response.body}");

    }

    final Map<String, dynamic> decodedResponse = jsonDecode(response.body);

    final Map<String, dynamic> json = decodedResponse["data"];

    final ScanJob job = ScanJobDto.fromJson(json);

    return job;

  }

  Future<ScanJob> _getScanJob(String id) async {

    final Uri endpoint = Uri.parse(baseUrl).replace(path: "/api/v1/scans/$id");

    final http.Response response = await http.get(endpoint);

    if (response.statusCode < 200 || response.statusCode >= 300){

      throw Exception("Backend Error!! Status code: ${response.statusCode}: ${response.body}");

    }

    final Map<String, dynamic> decodedResponse = jsonDecode(response.body);

    final Map<String, dynamic> json = decodedResponse["data"];

    final ScanJob job = ScanJobDto.fromJson(json);

    return job;

  }

}
