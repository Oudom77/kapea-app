import 'package:flutter/material.dart';
import '../../models/scan_report.dart';

// ---- Palette pulled from the design ----
const _kMaliciousColor = Color(0xFFA3313A);
const _kSuspiciousColor = Color(0xFFD98A2B);
const _kSafeColor = Color(0xFF1E7D46);
const _kTeal = Color(0xFF0B6E63);
const _kDeleteRed = Color(0xFFE0483E);
const _kScreenshotBg = Color(0xFF3A3A3A);

extension RiskTierX on RiskTier {
  String get label {
    switch (this) {
      case RiskTier.malicious:
        return 'Malicious';
      case RiskTier.suspicious:
        return 'Suspicious';
      case RiskTier.safe:
        return 'No threats found';
    }
  }
}

class ResultScreen extends StatefulWidget {
  final ScanReport report;
  const ResultScreen({super.key, required this.report});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showTechnicalDetails = false;

  Color get _tierColor {
    switch (widget.report.tier) {
      case RiskTier.malicious:
        return _kMaliciousColor;
      case RiskTier.suspicious:
        return _kSuspiciousColor;
      case RiskTier.safe:
        return _kSafeColor;
    }
  }

  IconData get _tierIcon {
    switch (widget.report.tier) {
      case RiskTier.malicious:
      case RiskTier.suspicious:
        return Icons.error;
      case RiskTier.safe:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

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
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(report),
                  const SizedBox(height: 16),
                  _buildScreenshotPreview(report),
                  if (report.redirectChain.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildRedirectChain(report),
                  ],
                  if (report.reasons.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildReasonsSection(report),
                  ],
                  if (report.tier == RiskTier.suspicious) ...[
                    const SizedBox(height: 16),
                    _buildOpenAnywayButton(),
                  ],
                  if (report.tier == RiskTier.safe) ...[
                    const SizedBox(height: 16),
                    _buildOpenLinkButton(),
                  ],
                  const SizedBox(height: 12),
                  _buildTechnicalDetailsToggle(report),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, report),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ScanReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tierColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_tierIcon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                report.tier.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.url,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Flagged by ${report.enginesFlagged} of ${report.totalEngines} engines',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotPreview(ScanReport report) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: _kScreenshotBg,
        borderRadius: BorderRadius.circular(12),
        image: report.screenshotUrl != null
            ? DecorationImage(
                image: NetworkImage(report.screenshotUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),

      // child: Stack(
      //   children: [
      //     if (report.screenshotUrl == null)
      //       const Center(
      //         child: Icon(Icons.image_outlined, color: Colors.white38, size: 36),
      //       ),
      //     Positioned(
      //       right: 10,
      //       bottom: 10,
      //       child: Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      //         decoration: BoxDecoration(
      //           color: Colors.black.withValues(alpha: 0.5),
      //           borderRadius: BorderRadius.circular(20),
      //         ),
      //         child: const Row(
      //           mainAxisSize: MainAxisSize.min,
      //           children: [
      //             Icon(Icons.zoom_in, color: Colors.white, size: 14),
      //             SizedBox(width: 4),
      //             Text('Tap to zoom',
      //                 style: TextStyle(color: Colors.white, fontSize: 11)),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (report.screenshotUrl != null)
            Image.network(
              report.screenshotUrl!,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white38,
                    size: 36,
                  ),
                );
              },
            )
          else
            const Center(
              child: Icon(
                Icons.image_outlined,
                color: Colors.white38,
                size: 36,
              ),
            ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Tap to zoom',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedirectChain(ScanReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Redirect Chain',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < report.redirectChain.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 16,
                    top: i == 0 ? 0 : 4,
                  ),
                  child: Row(
                    children: [
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.subdirectory_arrow_right,
                            size: 16,
                            color: Colors.black45,
                          ),
                        ),
                      Text(
                        report.redirectChain[i],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonsSection(ScanReport report) {
    final isSafe = report.tier == RiskTier.safe;
    final title = isSafe ? 'Check passed' : 'Why this was flagged';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final reason in report.reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tierRowIcon(report.tier),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(reason, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tierRowIcon(RiskTier tier) {
    switch (tier) {
      case RiskTier.malicious:
        return const Icon(Icons.cancel, color: _kMaliciousColor, size: 18);
      case RiskTier.suspicious:
        return const Icon(
          Icons.warning_rounded,
          color: _kSuspiciousColor,
          size: 18,
        );
      case RiskTier.safe:
        return const Icon(Icons.check_circle, color: _kSafeColor, size: 18);
    }
  }

  Widget _buildOpenAnywayButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          // TODO: hook up "open anyway" flow
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _kSuspiciousColor,
          side: const BorderSide(color: _kSuspiciousColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Open anyway',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildOpenLinkButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: hook up "open link" flow
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _kTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Open Link',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTechnicalDetailsToggle(ScanReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showTechnicalDetails = !_showTechnicalDetails),
          child: Row(
            children: [
              const Text(
                'Technical details',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Icon(
                _showTechnicalDetails ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        if (_showTechnicalDetails)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'URL: ${report.url}\n'
              'Scanned at: ${report.scannedAt}\n'
              'Engines flagged: ${report.enginesFlagged}/${report.totalEngines}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ScanReport report) {
    final showShareWarning = report.tier != RiskTier.safe;

    return Row(
      children: [
        if (showShareWarning) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: hook up "share warning" flow
              },
              icon: const Icon(Icons.ios_share, size: 16, color: Colors.white),
              label: const Text('Share warning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: hook up "rescan" flow
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTeal,
              side: const BorderSide(color: _kTeal),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Rescan'),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kDeleteRed),
          ),
          child: IconButton(
            onPressed: () {
              // TODO: hook up "delete" flow
            },
            icon: const Icon(Icons.delete_outline, color: _kDeleteRed),
          ),
        ),
      ],
    );
  }
}
