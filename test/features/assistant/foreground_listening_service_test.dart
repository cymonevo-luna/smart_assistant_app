import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/assistant/services/foreground_listening_service_io.dart';
import 'package:smart_assistant_app/features/assistant/services/foreground_task_client.dart';

class FakeForegroundTaskClient implements ForegroundTaskClient {
  NotificationPermission checkPermissionResult =
      NotificationPermission.granted;
  NotificationPermission requestPermissionResult =
      NotificationPermission.granted;
  ServiceRequestResult startServiceResult = const ServiceRequestSuccess();
  ServiceRequestResult updateServiceResult = const ServiceRequestSuccess();
  ServiceRequestResult stopServiceResult = const ServiceRequestSuccess();

  final List<String> callOrder = [];

  @override
  Future<NotificationPermission> checkNotificationPermission() async {
    callOrder.add('checkNotificationPermission');
    return checkPermissionResult;
  }

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    callOrder.add('requestNotificationPermission');
    return requestPermissionResult;
  }

  @override
  Future<ServiceRequestResult> startService({
    required int serviceId,
    required String notificationTitle,
    required String notificationText,
    required Function callback,
  }) async {
    callOrder.add('startService');
    return startServiceResult;
  }

  @override
  Future<ServiceRequestResult> updateService({
    required String notificationTitle,
    required String notificationText,
  }) async {
    callOrder.add('updateService');
    return updateServiceResult;
  }

  @override
  Future<ServiceRequestResult> stopService() async {
    callOrder.add('stopService');
    return stopServiceResult;
  }
}

void main() {
  late FakeForegroundTaskClient taskClient;
  late PlatformForegroundListeningService service;

  setUp(() {
    taskClient = FakeForegroundTaskClient();
    service = PlatformForegroundListeningService(
      taskClient: taskClient,
      isAndroid: true,
    );
  });

  test('start requests notification permission when initially denied', () async {
    taskClient.checkPermissionResult = NotificationPermission.denied;
    taskClient.requestPermissionResult = NotificationPermission.granted;

    final started = await service.start(
      notificationText: 'Listening for Jarvis…',
    );

    expect(started, isTrue);
    expect(service.isRunning, isTrue);
    expect(
      taskClient.callOrder,
      [
        'checkNotificationPermission',
        'requestNotificationPermission',
        'startService',
      ],
    );
  });

  test('start fails when notification permission stays denied', () async {
    taskClient.checkPermissionResult = NotificationPermission.denied;
    taskClient.requestPermissionResult = NotificationPermission.denied;

    final started = await service.start(
      notificationText: 'Listening for Jarvis…',
    );

    expect(started, isFalse);
    expect(service.isRunning, isFalse);
    expect(
      taskClient.callOrder,
      [
        'checkNotificationPermission',
        'requestNotificationPermission',
      ],
    );
    expect(taskClient.callOrder.contains('startService'), isFalse);
  });

  test('start uses updateService when already running', () async {
    taskClient.checkPermissionResult = NotificationPermission.granted;

    final firstStart = await service.start(
      notificationText: 'Listening for Jarvis…',
    );
    final secondStart = await service.start(
      notificationText: 'Listening for Alexa…',
    );

    expect(firstStart, isTrue);
    expect(secondStart, isTrue);
    expect(service.isRunning, isTrue);
    expect(
      taskClient.callOrder,
      [
        'checkNotificationPermission',
        'startService',
        'updateService',
      ],
    );
    expect(
      taskClient.callOrder.contains('requestNotificationPermission'),
      isFalse,
    );
  });

  test('stop clears running state', () async {
    taskClient.checkPermissionResult = NotificationPermission.granted;
    await service.start(notificationText: 'Listening for Jarvis…');

    await service.stop();

    expect(service.isRunning, isFalse);
    expect(taskClient.callOrder.last, 'stopService');
  });
}
