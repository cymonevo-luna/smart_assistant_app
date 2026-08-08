const catalogGoogleCalendarMeet = {
  'slug': 'google-calendar-meet',
  'name': 'Google Meet Scheduler',
  'description':
      'Schedule Google Calendar events with Meet links for your contacts.',
};

const catalogPlugins = [
  {
    'slug': 'weather',
    'name': 'Weather',
    'description': 'Get weather forecasts',
  },
  {
    'slug': 'calendar',
    'name': 'Calendar Sync',
    'description': 'Sync your calendar events',
  },
];

const installedWeather = {
  'id': 'plugin-1',
  'slug': 'weather',
  'name': 'Weather',
  'description': 'Get weather forecasts',
  'enabled': true,
  'setup_status': 'not_started',
};

Map<String, dynamic> nestedInstalledPlugin({
  required String slug,
  required String name,
  String? description,
  bool enabled = true,
  String setupStatus = 'not_started',
}) {
  return {
    'id': 'plugin-$slug',
    'slug': slug,
    'name': name,
    'description': description ?? '',
    'enabled': enabled,
    'setup_status': setupStatus,
  };
}
