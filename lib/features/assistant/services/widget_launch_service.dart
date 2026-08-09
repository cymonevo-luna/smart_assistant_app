import 'dart:async';

import 'package:app_links/app_links.dart';

import 'widget_launch_uri.dart';

/// Deep link fired when the user taps the 1×1 home-screen assistant widget.
class WidgetLaunchEvent {
  const WidgetLaunchEvent({required this.uri});

  final Uri uri;
}

class WidgetLaunchService {
  WidgetLaunchService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final _events = StreamController<WidgetLaunchEvent>.broadcast(sync: true);
  StreamSubscription<Uri>? _subscription;

  Stream<WidgetLaunchEvent> get events => _events.stream;

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
    if (!isWidgetListenUri(uri)) return;

    _events.add(WidgetLaunchEvent(uri: uri));
  }

  void dispose() {
    _subscription?.cancel();
  }
}
