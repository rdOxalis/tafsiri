import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the browser, silently doing nothing when nothing can.
///
/// A desktop with no handler registered is the realistic case, and a dead tap
/// is a smaller annoyance than an error about a link.
Future<void> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
