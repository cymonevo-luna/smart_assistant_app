import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/plugins/models/installed_plugin.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_setup_status.dart';

void main() {
  test('fromJson unwraps nested plugin fields from API response', () {
    final plugin = InstalledPlugin.fromJson({
      'id': 'install-1',
      'enabled': true,
      'setup_status': 'not_started',
      'plugin': {
        'id': 'catalog-1',
        'slug': 'google-calendar-meet',
        'name': 'Google Calendar',
        'required_setup': true,
        'setup_type': 'oauth_google',
      },
    });

    expect(plugin.id, 'install-1');
    expect(plugin.slug, 'google-calendar-meet');
    expect(plugin.name, 'Google Calendar');
    expect(plugin.description, '');
    expect(plugin.enabled, isTrue);
    expect(plugin.setupStatus, PluginSetupStatus.notStarted);
  });
}
