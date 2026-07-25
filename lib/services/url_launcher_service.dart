import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static Future<void> open(String url) async {
    final uri = Uri.parse(
      url.startsWith('http://') || url.startsWith('https://')
          ? url
          : 'https://$url',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}