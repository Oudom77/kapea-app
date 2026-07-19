import 'package:flutter/material.dart';
import 'package:kapea_app/ui/utils/async_data.dart';
import '../../services/scan_service.dart';
import '../../models/scan_report.dart';
import './result_screen.dart';

class HomeScreen extends StatefulWidget{

  final ScanService scanService;

  const HomeScreen({super.key, required this.scanService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  AsyncData<ScanReport> scanState = AsyncData.notStarted();
  

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // checks if currently loading(scanning)
  bool get _isScanning => scanState.status == AsyncStatus.loading;

  // Scanning function
  void _scanLink() async {

    final isValid = _formKey.currentState?.validate() ?? false; // check if form has a valid state

    if (!isValid || _isScanning){ // checks if no valid form and if currently scanning
      return;
    }

    final String url = _urlController.text.trim();

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

      // pushes to result with the scan report
      await Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ResultScreen(report: report),
        )
      );

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

  // URL validation function
  String? _validateUrl(String? value){

    final String text = value?.trim() ?? ""; // if value not null trim, else ""

    if (text.isEmpty){
      return 'Enter a link to scan';
    }

    final url = text.startsWith(RegExp(r'https?://')) ? text : "https://$text"; // if text start with 'https?://' valid, else add

    final Uri? uri = Uri.tryParse(url);
    
    // check for valid uri
    if (uri == null ||
      !uri.hasScheme ||
      !uri.hasAuthority ||
      !uri.host.contains('.')) {
      return 'Enter a valid link, such as example.com';
    }

    return null; // else valid url
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "K A P E A",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5,),
                    const Text(
                      "Check before you open",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54
                      ),
                    ),
                    const SizedBox(height: 35,),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      onFieldSubmitted: (value) => _scanLink(),
                      validator: _validateUrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.link),
                        hintText: "Paste a link to check",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15,),
                    ElevatedButton(
                      onPressed: _scanLink,
                      child: const Text(
                        "Scan Link"
                      )
                    ),
                  ],
                ),
              ),
            )
          ),
        ),
      ),
    );
  }
}
