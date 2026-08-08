import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:smart_assistant_app/features/reminders/services/reminder_notification_service.dart';

/// Device integration test: posts a reminder notification for host-side
/// verification via scripts/verify-reminder-notification.sh.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('showReminderNotification displays on device', (tester) async {
    final service = ReminderNotificationService(
      ensureNotificationPermission: () async => true,
    );
    await service.initialize();
    await service.showReminderNotification(
      id: 'integration-reminder-1',
      title: 'Location Reminder',
      body: 'You are near the store',
    );
    // Keep the notification visible for host-side dumpsys verification.
    await Future<void>.delayed(const Duration(seconds: 5));
  });
}
