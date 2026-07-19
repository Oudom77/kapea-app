import 'package:flutter/material.dart';

class ScanForm extends StatefulWidget{

  final Future<void> Function(String url) onScan;

  const ScanForm({super.key, required this.onScan});

  @override
  State<ScanForm> createState() => _ScanFormState();
}

class _ScanFormState extends State<ScanForm> {

  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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

  Future<void> _onSubmit() async {

    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {

      return;

    }

    final String url = _urlController.text.trim();

    await widget.onScan(url); // submits the url and awaits for result
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
              onFieldSubmitted: (value) => _onSubmit(), // submits when pressed enter
              validator: _validateUrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link),
                hintText: "Paste a link to check",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15,),
            ElevatedButton(
              onPressed: _onSubmit, // submits when button clicked
              child: const Text(
                "Scan Link"
              )
            ),
          ],
        ),
      ),
    );
  }
}