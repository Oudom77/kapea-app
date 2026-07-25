import 'package:flutter/material.dart';
import '../../models/scan_report.dart';
import '../widgets/scan_report_view.dart';

class ResultScreen extends StatelessWidget {
  final ScanReport report;

  const ResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Scan Result'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ScanReportView(report: report),
      ),
    );
  }
}
