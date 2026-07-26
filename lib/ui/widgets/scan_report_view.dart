import 'package:flutter/material.dart';
import '../../models/scan_report.dart';
import '../themes/kapea_theme.dart';
import '../../services/url_launcher_service.dart';
import 'package:share_plus/share_plus.dart';

class ScanReportView extends StatefulWidget {
  final ScanReport report;
  final bool isLive;
  final VoidCallback? onRescan;
  final VoidCallback? onDelete;
  const ScanReportView({super.key, required this.report, this.isLive = false, this.onRescan, this.onDelete});

  @override
  State<ScanReportView> createState() => _ScanReportViewState();
}

class _ScanReportViewState extends State<ScanReportView> {

  

  bool _showTechnicalDetails = false;

  Future<void> _shareWarning(ScanReport report) async {
    final String message = 
    
'''
Kapea Warning

This link was marked as ${report.tier.label}:

${report.url}

Reason:
${report.reasons.isNotEmpty ? report.reasons.join('\n') : 'Security engines reported a risk.'}

Do not open this link unless you trust the source.
''';

    await SharePlus.instance.share(
      ShareParams(text: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isLive) ...[
                _buildLiveBanner(),
                const SizedBox(height: 16),
              ],
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
                _buildOpenAnywayButton(report),
              ],
              if (report.tier == RiskTier.safe) ...[
                const SizedBox(height: 16),
                _buildOpenLinkButton(report),
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
    );
  }

  Future<void> _confirmOpenLink(BuildContext context, ScanReport report) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            report.tier == RiskTier.safe ? 'Open Website' : 'Security Warning',
          ),
          content: Text(
            report.tier == RiskTier.safe
                ? 'Do you want to open this website?\n\n${report.url}'
                : 'This website has been flagged as ${report.tier.label.toLowerCase()}.\n\nOpening it may expose you to phishing, malware, or other security risks.\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                report.tier == RiskTier.safe ? 'Open' : 'Yes, Continue',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await UrlLauncherService.open(report.url);
    }
  }

  Future<void> _openLink(BuildContext context, ScanReport report) async {
      await UrlLauncherService.open(report.url);
  }

  Widget _buildLiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTeal.withValues(alpha: 0.24)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: kTeal),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scan still running. Showing early verdict while screenshot and redirects are checked.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ScanReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: report.tier.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(report.tier.icon, color: Colors.white, size: 22),
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
    final hasScreenshot = report.screenshotUrl != null;

    return GestureDetector(
      onTap: hasScreenshot
          ? () => _openScreenshotViewer(context, report.screenshotUrl!)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 160,
          color: kScreenshotBg,
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
              else if (widget.isLive)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Capturing screenshot...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white38,
                    size: 36,
                  ),
                ),

              if (hasScreenshot)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
        ),
      ),
    );
  }

  void _openScreenshotViewer(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _ScreenshotViewerScreen(imageUrl: imageUrl),
          );
        },
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.only(right: 4, top: 2),
                          child: Icon(
                            Icons.subdirectory_arrow_right,
                            size: 16,
                            color: Colors.black45,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          report.redirectChain[i],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
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
        return const Icon(Icons.cancel, color: kMaliciousColor, size: 18);
      case RiskTier.suspicious:
        return const Icon(
          Icons.warning_rounded,
          color: kSuspiciousColor,
          size: 18,
        );
      case RiskTier.safe:
        return const Icon(Icons.check_circle, color: kSafeColor, size: 18);
    }
  }

  Widget _buildOpenAnywayButton(ScanReport report) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _confirmOpenLink(context, report),
        style: OutlinedButton.styleFrom(
          foregroundColor: kSuspiciousColor,
          side: const BorderSide(color: kSuspiciousColor),
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

  Widget _buildOpenLinkButton(ScanReport report) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openLink(context, report),
        style: ElevatedButton.styleFrom(
          backgroundColor: kTeal,
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
                _shareWarning(report);
              },
              icon: const Icon(Icons.ios_share, size: 16, color: Colors.white),
              label: const Text('Share warning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
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
            onPressed: widget.onRescan,
            style: OutlinedButton.styleFrom(
              foregroundColor: kTeal,
              side: const BorderSide(color: kTeal),
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
            border: Border.all(color: kDeleteRed),
          ),
          child: IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, color: kDeleteRed),
          ),
        ),
      ],
    );
  }
}

class _ScreenshotViewerScreen extends StatelessWidget {
  final String imageUrl;
  const _ScreenshotViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator(
                      color: Colors.white54,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 48,
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
