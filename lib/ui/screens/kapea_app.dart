import 'package:flutter/material.dart';
import '../../data/services/backend_scan_service.dart';
import '../../services/flagged_scan_storage_service.dart';
import '../themes/kapea_theme.dart';
import './home_screen.dart';

class KapeaApp extends StatelessWidget {
  const KapeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kapea',
      debugShowCheckedModeBanner: false,
      theme: apptheme,
      home: const HomeScreen(
        scanService: BackendScanService(), //baseUrl: 'http://127.0.0.1:8080' Add this to test local.Delete if test hosting backend
        storage: FlaggedScanStorage(),
      ),
    );
  }
}
