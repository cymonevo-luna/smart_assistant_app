import 'package:home_widget/home_widget.dart';

/// Android manifest widget provider class name for [HomeWidget.updateWidget].
const assistantWidgetProviderName = 'AssistantWidgetProvider';

/// Prepares the home_widget plugin for the 1×1 assistant widget.
///
/// Tap handling is implemented natively in [AssistantWidgetProvider]; launch
/// routing in Dart is handled in a follow-up ticket.
Future<void> initAssistantWidget() async {
  // iOS WidgetKit app group is not configured yet.
  // Background interactivity callback is not required for tap-to-launch.
}
