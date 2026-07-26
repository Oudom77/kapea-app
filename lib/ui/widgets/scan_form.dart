import 'package:flutter/material.dart';
import '../../models/scan_report.dart';
import '../themes/kapea_theme.dart';
import 'qr_scan.dart';

class ScanForm extends StatefulWidget {
  final Future<void> Function(String url) onScan;
  final List<ScanReport> flaggedReports;
  final ValueChanged<ScanReport> onTapFlagged;

  const ScanForm({
    super.key,
    required this.onScan,
    required this.flaggedReports,
    required this.onTapFlagged,
  });

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
  String? _validateUrl(String? value) {
    final String text = value?.trim() ?? ""; // if value not null trim, else ""

    if (text.isEmpty) {
      return 'Enter a link to scan';
    }

    final url = text.startsWith(RegExp(r'https?://'))
        ? text
        : "https://$text"; // if text start with 'https?://' valid, else add

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

  Future<void> _onScanQrCode() async {
    final String? scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedValue == null || !mounted) {
      return;
    }

    _urlController.text = scannedValue;
    await _onSubmit();
  }

  Widget _buildFlaggedTile(ScanReport report) {
    final bool isMalicious = report.tier == RiskTier.malicious;
    final Color color = isMalicious ? kMaliciousColor : kSuspiciousColor;
    final IconData icon = isMalicious ? Icons.cancel : Icons.warning_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onTapFlagged(report),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.tier.label,
                      style: TextStyle(fontSize: 13, color: color),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "K A P E A",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            const Text(
              "Check before you open",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 35),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onFieldSubmitted: (value) =>
                  _onSubmit(), // submits when pressed enter
              validator: _validateUrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link),
                hintText: "Paste a link to check",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _onSubmit, // submits when button clicked
              child: const Text("Scan Link"),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _onScanQrCode,
              icon: Icon(Icons.qr_code_scanner),
              label: const Text("Scan QR Code"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
              ),
            ),
            const SizedBox(height: 40),
            if (widget.flaggedReports.isNotEmpty) ...[
              const SizedBox(height: 40),
              const Text(
                "Needs attention (click to view):",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...widget.flaggedReports.map(_buildFlaggedTile),
            ],
          ],
        ),
      ),
    );
  }
}
