import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/assistant/services/widget_launch_service.dart';
import 'package:smart_assistant_app/features/assistant/services/widget_launch_uri.dart';

void main() {
  group('WidgetLaunchService', () {
    late WidgetLaunchService service;

    setUp(() {
      service = WidgetLaunchService();
    });

    test('handleUri emits WidgetLaunchEvent for widget listen URI', () {
      final events = <WidgetLaunchEvent>[];
      final subscription = service.events.listen(events.add);

      service.handleUri(widgetListenUri);

      expect(events, hasLength(1));
      expect(events.first.uri, widgetListenUri);

      subscription.cancel();
    });

    test('handleUri ignores unrelated URIs', () {
      final events = <WidgetLaunchEvent>[];
      final subscription = service.events.listen(events.add);

      service.handleUri(Uri.parse('https://example.com'));
      service.handleUri(
        Uri.parse('smartassistant://plugin-setup/complete?status=success'),
      );

      expect(events, isEmpty);

      subscription.cancel();
    });
  });
}
