import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  final openedByDefault = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (openedByDefault) return true;

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
