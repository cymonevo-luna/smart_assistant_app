import 'package:url_launcher/url_launcher.dart';

/// Opens plugin OAuth URLs in the system browser.
abstract class PluginAuthUrlLauncher {
  Future<bool> launchAuthorizationUrl(String url);
}

class DefaultPluginAuthUrlLauncher implements PluginAuthUrlLauncher {
  @override
  Future<bool> launchAuthorizationUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
