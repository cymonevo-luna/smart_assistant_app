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
  required String id,
  required String slug,
  required String name,
  bool enabled = true,
  String setupStatus = 'not_started',
  String? catalogId,
}) {
  return {
    'id': id,
    'enabled': enabled,
    'setup_status': setupStatus,
    'plugin': {
      'id': catalogId ?? 'catalog-$slug',
      'slug': slug,
      'name': name,
      'required_setup': true,
      'setup_type': 'oauth_google',
    },
  };
}
