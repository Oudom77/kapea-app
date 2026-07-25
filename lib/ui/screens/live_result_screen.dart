// Packages
import 'package:flutter/material.dart';

// Ui
import '../../ui/widgets/scan_report_view.dart';
import '../../ui/utils/async_data.dart';
import '../widgets/scan_loading_view.dart';

// Models
import '../../models/scan_job.dart';

// Services
import '../../services/scan_service.dart';

class LiveResultScreen extends StatefulWidget {
  final String url;
  final ScanService scanService;

  const LiveResultScreen({
    super.key,
    required this.url,
    required this.scanService,
  });

  @override
  State<LiveResultScreen> createState() => _LiveResultScreenState();
}

class _LiveResultScreenState extends State<LiveResultScreen>{

  AsyncData<ScanJob> scanState = AsyncData.loading();

  @override
  void initState() {
    super.initState();
    _watchScan();
  }

  void _watchScan () async { 

    // Catches every yield(result) and stores in scanState.value
    // If complete or end, function ends

    try {

      await for (final job in widget.scanService.watchScan(widget.url)) {
        if (!mounted) {
          return;
        }

        if (job.status == ScanJobStatus.failed) { // if failed
          setState(() {
            scanState = AsyncData.error(job.errorMessage ?? 'Scan failed.');
          });
          break;
        }

        if (job.status == ScanJobStatus.complete && job.report == null) { // if completed but no report
          setState(() {
            scanState = AsyncData.error("Completed scan has no report/result.");
          });
          break;
        }

        setState(() { // if success
          scanState = AsyncData.success(job);
        });

        if (job.status == ScanJobStatus.complete) { // if completed
          break;
        }
        
      }
    } catch (e) {

      if (!mounted){
        return;
      }

      setState(() {
        scanState = AsyncData.error('$e');
      });
    }
  }

    Widget get errorContent {

      // Widget for error

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error occured!! \n\n${scanState.error}",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30,),
            ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
              }, 
              child: Text(
                "Click to go back."
              )
            )
          ],
        ),
      ),
    ); 
  }

  Widget get content {

    // Main getter for displaying result

  switch (scanState.status) {

    case AsyncStatus.notStarted:
    case AsyncStatus.loading:
      return ScanLoadingView();

    case AsyncStatus.success: // if result exist display it, if not display loading screen
      final job = scanState.value;

      if (job == null) {
        return ScanLoadingView();
      }

      if (job.report != null) {

        return ScanReportView(
          report: job.report!, 
          isLive: (job.status != ScanJobStatus.complete),
        );
        
      }

      return ScanLoadingView();

    case AsyncStatus.error:
      return errorContent;      
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Live Scan Result",
        ),
      ),
      body: SafeArea(
        child: content,
      ),
    );
  }
}
