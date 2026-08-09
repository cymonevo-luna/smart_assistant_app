import 'package:smart_assistant_app/features/plugins/models/plugin_setup_type.dart';

const catalogGoogleCalendarMeet = {
  'id': 'catalog-gcm',
  'slug': 'google-calendar-meet',
  'name': 'Google Calendar Meet',
  'description': 'Schedule Google Meet calls from your calendar',
  'version': '1.0.0',
  'required_setup': true,
  'setup_type': 'oauth_google',
};

const catalogComposioAi = {
  'id': 'catalog-composio-ai',
  'slug': 'composio-ai',
  'name': 'Composio AI',
  'description':
      'Connect external apps and automate workflows with Composio integrations',
  'version': '1.0.0',
  'required_setup': true,
  'setup_type': 'form',
};

const catalogReminder = {
  'id': 'catalog-reminder',
  'slug': 'reminder',
  'name': 'Reminder',
  'description': 'Set time and location reminders from your assistant',
  'version': '1.0.0',
  'required_setup': false,
  'setup_type': null,
};

const catalogPlugins = [
  catalogGoogleCalendarMeet,
  catalogComposioAi,
  catalogReminder,
  {
    'id': 'catalog-weather',
    'slug': 'weather',
    'name': 'Weather',
    'description': 'Get weather forecasts',
    'version': '1.0.0',
    'required_setup': true,
    'setup_type': 'oauth_google',
  },
  {
    'id': 'catalog-calendar',
    'slug': 'calendar',
    'name': 'Calendar Sync',
    'description': 'Sync your calendar events',
    'version': '1.0.0',
    'required_setup': false,
    'setup_type': null,
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
  bool requiredSetup = true,
  String? setupType = 'oauth_google',
}) {
  return {
    'id': id,
    'enabled': enabled,
    'setup_status': setupStatus,
    'plugin': {
      'id': catalogId ?? 'catalog-$slug',
      'slug': slug,
      'name': name,
      'required_setup': requiredSetup,
      'setup_type': setupType,
    },
  };
}

Map<String, dynamic> nestedInstalledComposioAi({
  required String id,
  String setupStatus = 'not_started',
  bool enabled = true,
}) {
  return nestedInstalledPlugin(
    id: id,
    slug: 'composio-ai',
    name: 'Composio AI',
    enabled: enabled,
    setupStatus: setupStatus,
    catalogId: 'catalog-composio-ai',
    requiredSetup: true,
    setupType: PluginSetupType.form.toApi(),
  );
}
