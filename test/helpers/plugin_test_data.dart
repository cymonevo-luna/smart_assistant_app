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
  'enabled': true,
  'setup_status': 'not_started',
  'plugin': {
    'id': 'catalog-weather',
    'slug': 'weather',
    'name': 'Weather',
    'required_setup': true,
    'setup_type': 'oauth_google',
  },
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
