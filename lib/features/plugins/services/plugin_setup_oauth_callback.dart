import 'plugin_setup_deep_link_service.dart';

/// Whether [uri] is a plugin setup OAuth completion deep link.
bool isPluginSetupOAuthCallback(Uri uri) => eventFromUri(uri) != null;

/// Parses a plugin setup OAuth callback [uri], or returns null when it does not
/// match the expected contract.
PluginSetupDeepLinkEvent? eventFromUri(Uri uri) {
  if (uri.scheme != PluginSetupDeepLinkService.scheme ||
      uri.host != PluginSetupDeepLinkService.host ||
      uri.path != PluginSetupDeepLinkService.path) {
    return null;
  }

  final status = switch (uri.queryParameters['status']) {
    'success' => PluginSetupDeepLinkStatus.success,
    'failed' => PluginSetupDeepLinkStatus.failed,
    _ => null,
  };
  if (status == null) return null;

  return PluginSetupDeepLinkEvent(status: status);
}
