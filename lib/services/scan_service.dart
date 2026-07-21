import '../models/scan_report.dart';

abstract interface class ScanService {
  Future<ScanReport> scan(String url);
}

// class MockScanService implements ScanService{

//   final Duration delay;

//   const MockScanService({
//     this.delay = const Duration(milliseconds: 500)
//   });

//   String _normalizedUrl(String input){ // Add https:// if no protocol

//     final url = input.trim().toLowerCase();
    

//     if (url.startsWith(RegExp(r'https?://'))){
//       return url;
//     }

//     return "https://$url";
//   }

//   bool _looksMalicious(String url){

//     return (url.contains("bit.ly")
//       || url.contains("malicious"));

//   }

//   bool _looksSuspicious(String url){

//     return (url.contains("login")
//       || url.contains("suspicious"));

//   }

//   @override
//   Future<ScanReport> scan(String input) async {

//     await Future<void>.delayed(delay);

//     final url = _normalizedUrl(input);

//     if (_looksMalicious(url)){
//       return ScanReport(
//         url: url,
//         tier: RiskTier.malicious,
//         scannedAt: DateTime.now(),
//         redirectChain: const [
//           'capy.koala.example',
//           'aba-verify-kh.top',
//         ],
//         reasons: const [
//           'Impersonates a bank login page',
//           'Hidden redirects through 2 domains',
//           'Domain registered 67 days ago',
//         ],
//         enginesFlagged: 67,
//       );
//     }

//     if (_looksSuspicious(url)) {
//       return ScanReport(
//         url: url,
//         tier: RiskTier.suspicious,
//         scannedAt: DateTime.now(),
//         redirectChain: const [
//           'denn-check.example',
//         ],
//         reasons: const [
//           'Some security engines flagged this URL',
//           'The page requests account information',
//         ],
//         enginesFlagged: 6,
//       );
//     }

//     return ScanReport( // safe
//       url: url,
//       tier: RiskTier.safe,
//       scannedAt: DateTime.now(),
//       redirectChain: const [],
//       reasons: const [
//         'No known threats detected',
//         'No hidden redirects found',
//       ],
//       enginesFlagged: 0,
//     );
    
//   }
// }

