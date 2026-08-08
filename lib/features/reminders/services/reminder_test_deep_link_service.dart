import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../../core/di/locator.dart';
import 'reminder_notification_service.dart';

/// Debug deep link to schedule a test reminder notification without API access.
///
/// URI format:
/// `smartassistant://debug/reminder-test?message=Hello&delay_seconds=5`
class ReminderTestDeepLinkService {
  ReminderTestDeepLinkService({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  static const scheme = 'smartassistant';
  static const host = 'debug';
  static const path = '/reminder-test';

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> startListening() async {
    if (!kDebugMode) return;

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

  Future<void> handleUri(Uri uri) async {
    if (!kDebugMode) return;
    if (uri.scheme != scheme || uri.host != host || uri.path != path) {
      return;
    }

    final message = uri.queryParameters['message']?.trim();
    if (message == null || message.isEmpty) return;

    final delaySeconds =
        int.tryParse(uri.queryParameters['delay_seconds'] ?? '') ?? 5;
    final delay = Duration(seconds: delaySeconds.clamp(1, 120));

    await locator<ReminderNotificationService>().scheduleTestNotification(
      message: message,
      delay: delay,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
