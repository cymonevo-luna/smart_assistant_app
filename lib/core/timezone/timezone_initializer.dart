import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Initializes timezone data and sets [tz.local] from the device offset.
Future<void> initializeLocalTimeZone() async {
  tz_data.initializeTimeZones();
  tz.setLocalLocation(_locationForOffset(DateTime.now().timeZoneOffset));
}

tz.Location _locationForOffset(Duration offset) {
  final totalMinutes = offset.inMinutes;
  if (totalMinutes % 60 == 0) {
    final hours = totalMinutes ~/ 60;
    if (hours == 0) {
      return tz.UTC;
    }
    final name = hours > 0 ? 'Etc/GMT-$hours' : 'Etc/GMT+${hours.abs()}';
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.UTC;
    }
  }

  return tz.UTC;
}
