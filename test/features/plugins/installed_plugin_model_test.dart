import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant_app/features/plugins/models/installed_plugin.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_setup_status.dart';

import '../../helpers/plugin_test_data.dart';

void main() {
  group('InstalledPlugin.fromJson', () {
    test('nested API shape flattens plugin fields', () {
      final json = nestedInstalledPlugin(
        id: 'install-google-calendar-meet',
        slug: 'google-calendar-meet',
        name: 'Google Meet Scheduler',
      );

      final plugin = InstalledPlugin.fromJson(json);

      expect(plugin.id, 'install-google-calendar-meet');
      expect(plugin.slug, 'google-calendar-meet');
      expect(plugin.name, 'Google Meet Scheduler');
      expect(plugin.enabled, isTrue);
      expect(plugin.setupStatus, PluginSetupStatus.notStarted);
    });

    test('uses nested plugin description when present', () {
      final json = nestedInstalledPlugin(
        id: 'install-1',
        slug: 'weather',
        name: 'Weather',
      );
      (json['plugin'] as Map<String, dynamic>)['description'] =
          'Get weather forecasts';

      final plugin = InstalledPlugin.fromJson(json);

      expect(plugin.description, 'Get weather forecasts');
    });

    test('falls back to top-level description when nested plugin has none', () {
      final json = {
        ...nestedInstalledPlugin(
          id: 'install-1',
          slug: 'weather',
          name: 'Weather',
        ),
        'description': 'Top-level description',
      };

      final plugin = InstalledPlugin.fromJson(json);

      expect(plugin.description, 'Top-level description');
    });

    test('defaults description to empty string when absent', () {
      final json = nestedInstalledPlugin(
        id: 'install-1',
        slug: 'weather',
        name: 'Weather',
      );

      final plugin = InstalledPlugin.fromJson(json);

      expect(plugin.description, '');
    });

    test('flat JSON without nested plugin parses successfully', () {
      final json = {
        'id': 'plugin-1',
        'slug': 'weather',
        'name': 'Weather',
        'enabled': true,
        'setup_status': 'not_started',
      };

      final plugin = InstalledPlugin.fromJson(json);

      expect(plugin.id, 'plugin-1');
      expect(plugin.slug, 'weather');
      expect(plugin.name, 'Weather');
      expect(plugin.enabled, isTrue);
      expect(plugin.setupStatus, PluginSetupStatus.notStarted);
      expect(plugin.description, '');
    });

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
  });
}
