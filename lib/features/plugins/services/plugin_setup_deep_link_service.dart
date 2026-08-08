import 'dart:async';

import 'package:app_links/app_links.dart';

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
    if (uri.scheme != scheme || uri.host != host || uri.path != path) {
      return;
    }

    final status = switch (uri.queryParameters['status']) {
      'success' => PluginSetupDeepLinkStatus.success,
      'failed' => PluginSetupDeepLinkStatus.failed,
      _ => null,
    };
    if (status == null) return;

    _events.add(PluginSetupDeepLinkEvent(status: status));
  }

  void dispose() {
    _subscription?.cancel();
  }
}
