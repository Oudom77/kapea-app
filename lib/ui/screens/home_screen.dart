import 'package:flutter/material.dart';
import 'package:kapea_app/ui/screens/live_result_screen.dart';
import 'package:kapea_app/ui/utils/async_data.dart';
import '../../services/scan_service.dart';
import '../../services/flagged_scan_storage_service.dart';
import '../widgets/scan_form.dart';
import '../widgets/scan_loading_view.dart';
import '../../models/scan_report.dart';

class HomeScreen extends StatefulWidget {
  final ScanService scanService;
  final FlaggedScanStorage storage;

  const HomeScreen({
    super.key,
    required this.scanService,
    required this.storage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AsyncData<void> scanState = AsyncData.notStarted();
  List<ScanReport> _flaggedReports = [];

  @override
  void initState() {
    super.initState();
    _loadFlaggedReports();
  }

  Future<void> _loadFlaggedReports() async {
    final reports = await widget.storage.getAll();
    if (!mounted) return;
    setState(() {
      _flaggedReports = reports;
    });
  }

  // checks if currently loading(scanning)
  bool get _isScanning => scanState.status == AsyncStatus.loading;

  // Scanning function
  Future<void> _scanLink(String url) async {
    if (_isScanning) {
      // checks if no valid form and if currently scanning
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      // displays if scanning activated
      SnackBar(content: Text("Scanning $url")),
    );

    setState(() {
      scanState = AsyncData.loading();
    });

    try {
      await resultScreen(url);

      if (!mounted) {
        return;
      }

      setState(() {
        scanState = AsyncData.notStarted();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        scanState = AsyncData.error("$e");
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to scan $url")));
    }
  }

  Future<void> resultScreen(String url) async {
    // pushes to result with the scan report
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveResultScreen(
          url: url,
          scanService: widget.scanService,
          storage: widget.storage,
        ),
      ),
    );
    await _loadFlaggedReports();
  }

  Widget get homeContent {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ScanForm(
          onScan: _scanLink,
          flaggedReports: _flaggedReports,
          onTapFlagged: (report) => _scanLink(report.url),
        ),
      ),
    );
  }

  Widget get errorContent {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error occured!! \n\n${scanState.error}",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  scanState = AsyncData.notStarted();
                });
              },
              child: Text("Click to go back."),
            ),
          ],
        ),
      ),
    );
  }

  Widget get content {
    switch (scanState.status) {
      case AsyncStatus.loading:
        return ScanLoadingView();
      case AsyncStatus.notStarted:
      case AsyncStatus.success:
        return homeContent;
      case AsyncStatus.error:
        return errorContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: content));
  }
}
