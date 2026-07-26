import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/scan_report.dart';
import '../data/dto/scan_report_dto.dart';


class FlaggedScanStorage {
  static const _storageKey = 'flagged_scans';

  final FlutterSecureStorage _storage;

  const FlaggedScanStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<ScanReport>> getAll() async {
    final String? raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => ScanReportDto.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveIfFlagged(ScanReport report) async {
    if (report.tier == RiskTier.safe) {
      await remove(report.url);
      return;
    }

    final List<ScanReport> current = await getAll();
    current.removeWhere((existing) => existing.url == report.url);
    current.insert(0, report);

    await _writeAll(current);
  }

  Future<void> remove(String url) async {
    final List<ScanReport> current = await getAll();
    final int before = current.length;
    current.removeWhere((existing) => existing.url == url);

    if (current.length != before) {
      await _writeAll(current);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _storageKey);
  }

  Future<void> _writeAll(List<ScanReport> reports) async {
    final String encoded = jsonEncode(
      reports.map(ScanReportDto.toJson).toList(),
    );
    await _storage.write(key: _storageKey, value: encoded);
  }
}