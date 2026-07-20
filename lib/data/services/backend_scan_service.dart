import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kapea_app/data/dto/scan_report_dto.dart';

import '../../models/scan_report.dart';
import '../../services/scan_service.dart';


class BackendScanService implements ScanService {
  const BackendScanService({
    // this.baseUrl = 'http://127.0.0.1:8080',
    this.baseUrl = "https://kapea-backend-production.up.railway.app",
  });

  final String baseUrl;

  @override
  Future<ScanReport> scan(String url) async {

    final Uri endpoint = Uri.parse(baseUrl).replace(path: "/api/v1/scans");

    final String requestBody = jsonEncode({
      "url": url,
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

    print(json);

    final ScanReport report = ScanReportDto.fromJson(json);

    return report;
  }
}
