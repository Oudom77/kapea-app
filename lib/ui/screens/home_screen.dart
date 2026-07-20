import 'package:flutter/material.dart';
import 'package:kapea_app/ui/utils/async_data.dart';
import '../../services/scan_service.dart';
import '../../models/scan_report.dart';
// import './result_screen.dart';
import '../widgets/scan_form.dart';
import '../widgets/scan_loading_view.dart';
// import './result_test.dart';
import 'testing.dart';

class HomeScreen extends StatefulWidget{

  final ScanService scanService;

  const HomeScreen({super.key, required this.scanService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  AsyncData<ScanReport> scanState = AsyncData.notStarted();

  // checks if currently loading(scanning)
  bool get _isScanning => scanState.status == AsyncStatus.loading;

  // Scanning function
  Future<void> _scanLink(String url) async {

    if (_isScanning){ // checks if no valid form and if currently scanning
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar( // displays if scanning activated
      SnackBar(
        content: Text(
          "Scanning $url",
        )
      )
    );

    setState(() {
        scanState = AsyncData.loading();
    });

    try {

      final ScanReport report = await widget.scanService.scan(url); // fetches resulting scan

      if (!mounted) {
        return;
      }

      setState(() {
        scanState = AsyncData.success(report);
      });

      await resultScreen(report);

      // Restart state after exiting result screen
      if (!mounted) {
        return;
      }

      setState(() {
        scanState = AsyncData.notStarted();
      });


    } catch (e){

      if (!mounted) {
        return;
      }

      setState(() {
        scanState = AsyncData.error("$e");
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to scan $url",
          ),
        ),
      );
    }
  }

  Future<void> resultScreen(ScanReport report) async {

    // pushes to result with the scan report
    await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ResultScreen(report: report),
      )
    );

  }

  Widget get homeContent {

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
      child: Center(
        child: ScanForm(onScan: _scanLink),
      ),
    );
  }

  Widget get errorContent {

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
                setState(() {
                  scanState = AsyncData.notStarted();
                });
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

    switch(scanState.status) {
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
    return Scaffold(
      body: SafeArea(
        child: content
      ),
    );
  }
}
