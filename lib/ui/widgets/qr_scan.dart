import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../themes/kapea_theme.dart';

const _kShortenerHosts = <String>{
  'bit.ly',
  'tinyurl.com',
  't.co',
  'goo.gl',
  'ow.ly',
  'is.gd',
  'buff.ly',
  'rebrand.ly',
  'cutt.ly',
  'shorte.st',
};

bool _isShortenedLink(String value) {
  final uri = Uri.tryParse(
    value.startsWith(RegExp(r'https?://')) ? value : 'https://$value',
  );
  final host = uri?.host.toLowerCase() ?? '';
  return _kShortenerHosts.any((shortener) => host == shortener || host.endsWith('.$shortener'));
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _sheetOpen = false; // guards against opening multiple sheets per frame

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_sheetOpen) return;

    final String? value = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;

    if (value == null || value.trim().isEmpty) return;

    _sheetOpen = true;
    await _controller.stop();

    if (!mounted) return;

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QrDetectedSheet(value: value.trim()),
    );

    if (!mounted) return;

    if (confirmed == true) {
      Navigator.of(context).pop(value.trim());
      return;
    }

    // Dismissed -> resume scanning
    _sheetOpen = false;
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ViewfinderOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Scan QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Column(
              children: [
                const Text(
                  'Point at a QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kapea previews the link first — nothing opens automatically',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(painter: _CornerBracketsPainter()),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  static const double _length = 32;
  static const double _strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBracketGreen
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(const Offset(0, _length), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(_length, 0), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - _length, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, _length), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - _length), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(_length, size.height), paint);

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - _length, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - _length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrDetectedSheet extends StatelessWidget {
  final String value;
  const _QrDetectedSheet({required this.value});

  @override
  Widget build(BuildContext context) {
    final bool isShortened = _isShortenedLink(value);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'QR code detected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This code points to :',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isShortened) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.visibility_off_outlined,
                      size: 18, color: kSuspiciousColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Shortened link — real destination hidden',
                      style: const TextStyle(fontSize: 13, color: kSuspiciousColor),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.verified_user, size: 18, color: Colors.white),
                label: const Text('Scan before opening'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSafeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(
                    color: kSafeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}