import 'dart:io';

import 'location_monitor_foreground_client.dart';

LocationMonitorForegroundClient createLocationMonitorForegroundClient() {
  if (Platform.isAndroid) {
    return AndroidLocationMonitorForegroundClient();
  }
  return NoOpLocationMonitorForegroundClient();
}
