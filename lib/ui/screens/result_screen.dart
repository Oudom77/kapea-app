import '../../models/scan_report.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget{
  
  final ScanReport report;
  
  const ResultScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  report.tier.name,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(report.url),
                const SizedBox(height: 12),
                Text(
                  '${report.enginesFlagged}/${report.totalEngines} engines flagged it',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}