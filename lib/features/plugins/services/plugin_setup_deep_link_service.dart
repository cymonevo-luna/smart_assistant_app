import 'dart:async';

import 'package:app_links/app_links.dart';

import 'plugin_setup_oauth_callback.dart';

/// Deep-link callback for plugin OAuth completion.
///
/// URI format: `smartassistant://plugin-setup/complete?status=success|failed`
class PluginSetupDeepLinkEvent {
  const PluginSetupDeepLinkEvent({required this.status});

  final PluginSetupDeepLinkStatus status;
}

enum PluginSetupDeepLinkStatus { success, failed }

class PluginSetupDeepLinkService {
  PluginSetupDeepLinkService({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  static const scheme = 'smartassistant';
  static const host = 'plugin-setup';
  static const path = '/complete';

  final AppLinks _appLinks;
  final _events = StreamController<PluginSetupDeepLinkEvent>.broadcast(
    sync: true,
  );
  StreamSubscription<Uri>? _subscription;

  Stream<PluginSetupDeepLinkEvent> get events => _events.stream;

  bool get hasActiveListeners => _events.hasListener;

  Future<void> startListening() async {
    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(
      handleUri,
      onError: (_) {},
    );
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        handleUri(initial);
      }
    } catch (_) {
      // Platform deep links are unavailable in some test environments.
    }
  }

  void handleUri(Uri uri) {
    final event = eventFromUri(uri);
    if (event == null) return;

    _events.add(event);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
