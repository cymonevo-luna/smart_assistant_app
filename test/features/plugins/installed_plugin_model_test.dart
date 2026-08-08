import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/plugins/models/installed_plugin.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_setup_status.dart';

void main() {
  test('parses nested InstalledResponse from API', () {
    final json = {
      'id': 'install-uuid',
      'enabled': true,
      'setup_status': 'not_started',
      'plugin': {
        'id': 'catalog-uuid',
        'slug': 'google-calendar-meet',
        'name': 'Google Calendar Meet',
        'required_setup': true,
        'setup_type': 'oauth_google',
      },
    };

    final plugin = InstalledPlugin.fromJson(json);

    expect(plugin.id, 'install-uuid');
    expect(plugin.slug, 'google-calendar-meet');
    expect(plugin.name, 'Google Calendar Meet');
    expect(plugin.enabled, isTrue);
    expect(plugin.setupStatus, PluginSetupStatus.notStarted);
    expect(plugin.description, '');
  });

  test('parses flat legacy installed plugin JSON', () {
    final json = {
      'id': 'plugin-1',
      'slug': 'weather',
      'name': 'Weather',
      'description': 'Get weather forecasts',
      'enabled': false,
      'setup_status': 'completed',
    };

    final plugin = InstalledPlugin.fromJson(json);

    expect(plugin.id, 'plugin-1');
    expect(plugin.slug, 'weather');
    expect(plugin.name, 'Weather');
    expect(plugin.description, 'Get weather forecasts');
    expect(plugin.enabled, isFalse);
    expect(plugin.setupStatus, PluginSetupStatus.completed);
  });
}
