import 'package:flutter_test/flutter_test.dart';
import 'package:kapea_app/data/services/backend_scan_service.dart';

void main() {
  test(
    'scans a URL through the local backend',
    () async {
      const service = BackendScanService(
        baseUrl: 'http://127.0.0.1:8080',
      );

      final report = await service.scan('netacad.com');

      expect(report.url, isNotEmpty);
      expect(report.totalEngines, greaterThanOrEqualTo(report.enginesFlagged));

      print('URL: ${report.url}');
      print('Risk: ${report.tier.name}');
      print('Engines: ${report.enginesFlagged}/${report.totalEngines}');
      print('Reasons: ${report.reasons}');
      print('Redirects: ${report.redirectChain}');
      print('Screenshot: ${report.screenshotUrl}');
      print('Scanned at: ${report.scannedAt}');
      
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}