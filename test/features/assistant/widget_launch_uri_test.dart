import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant_app/features/assistant/services/widget_launch_uri.dart';

void main() {
  group('widgetListenUri', () {
    test('defines the widget listen deep link', () {
      expect(widgetListenUri.toString(), 'smartassistant://assistant/widget-listen');
    });

    test('isWidgetListenUri matches the widget listen URI', () {
      expect(
        isWidgetListenUri(Uri.parse('smartassistant://assistant/widget-listen')),
        isTrue,
      );
    });

    test('isWidgetListenUri rejects other smartassistant URIs', () {
      expect(
        isWidgetListenUri(
          Uri.parse('smartassistant://plugin-setup/complete?status=success'),
        ),
        isFalse,
      );
      expect(
        isWidgetListenUri(Uri.parse('smartassistant://assistant/other')),
        isFalse,
      );
      expect(
        isWidgetListenUri(Uri.parse('https://assistant/widget-listen')),
        isFalse,
      );
    });
  });
}
