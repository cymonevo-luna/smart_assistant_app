import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/reminders/services/location_reminder_notification_service.dart';

void main() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final log = <MethodCall>[];

  late LocationReminderNotificationService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'initialize':
          return true;
        case 'createNotificationChannel':
          return null;
        case 'pendingNotificationRequests':
          return <Map<String, Object?>>[];
        case 'getActiveNotifications':
          return <Map<String, Object?>>[];
        case 'getNotificationAppLaunchDetails':
          return null;
        default:
          return null;
      }
    });

    service = LocationReminderNotificationService(
      ensureNotificationPermission: () async => true,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('showReminderNotification invokes platform show with reminder title', () async {
    const reminderTitle = 'Buy milk at the store';
    const reminderBody = 'You are near the grocery store';

    await service.initialize();
    await service.showReminderNotification(
      id: 'reminder-42',
      title: reminderTitle,
      body: reminderBody,
    );

    final showCall = log.lastWhere((call) => call.method == 'show');
    expect(showCall.arguments, isA<Map>());
    final args = showCall.arguments! as Map;
    expect(args['title'], reminderTitle);
    expect(args['body'], reminderBody);
    expect(args['payload'], 'reminder-42');

    final platformSpecifics = args['platformSpecifics'] as Map?;
    expect(platformSpecifics?['channelId'], LocationReminderNotificationService.channelId);
    expect(platformSpecifics?['channelName'], LocationReminderNotificationService.channelName);
  });
}
