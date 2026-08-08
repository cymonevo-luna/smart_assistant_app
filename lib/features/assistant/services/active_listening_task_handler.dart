import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../core/config/app_config.dart';
import 'active_listening_messages.dart';
import 'wake_word_engine.dart';

/// Entry point for the background isolate flutter_foreground_task spawns.
/// Runs independently of the main Activity/UI, so the wake-word engine set
/// up here keeps listening even after the app is swiped away from recents
/// (Android only — see AndroidManifest `stopWithTask="false"`).
@pragma('vm:entry-point')
void startActiveListeningTask() {
  FlutterForegroundTask.setTaskHandler(ActiveListeningTaskHandler());
}

class ActiveListeningTaskHandler extends TaskHandler {
  WakeWordEngine? _engine;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Re-load .env: this isolate does not share the main isolate's dotenv
    // singleton.
    await AppConfig.load();

    final engine = createWakeWordEngine();
    engine.onWakeWord = () {
      FlutterForegroundTask.sendDataToMain(wakeWordDetectedMessage);
    };
    engine.onError = (message) {
      FlutterForegroundTask.sendDataToMain('wake_word_error:$message');
    };
    _engine = engine;

    final started = await engine.start();
    if (!started && engine.lastError != null) {
      FlutterForegroundTask.sendDataToMain('wake_word_error:${engine.lastError}');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _engine?.dispose();
    _engine = null;
  }
}
