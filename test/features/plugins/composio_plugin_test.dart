import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant_app/features/plugins/models/installed_plugin.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_catalog_item.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_setup_status.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_setup_type.dart';

import '../../helpers/plugin_test_data.dart';

void main() {
  group('PluginCatalogItem.fromJson', () {
    test('parses composio-ai catalog fields', () {
      final item = PluginCatalogItem.fromJson(catalogComposioAi);

      expect(item.slug, 'composio-ai');
      expect(item.name, 'Composio AI');
      expect(item.requiredSetup, isTrue);
      expect(item.setupType, PluginSetupType.form);
    });
  });

  group('InstalledPlugin.fromJson', () {
    test('parses composio-ai nested install response', () {
      final plugin = InstalledPlugin.fromJson(
        nestedInstalledComposioAi(id: 'install-composio-ai'),
      );

      expect(plugin.slug, 'composio-ai');
      expect(plugin.requiredSetup, isTrue);
      expect(plugin.setupType, PluginSetupType.form);
      expect(plugin.setupStatus, PluginSetupStatus.notStarted);
      expect(plugin.needsSetup, isTrue);
    });

    test('needsSetup is false when setup completed', () {
      final plugin = InstalledPlugin.fromJson(
        nestedInstalledComposioAi(
          id: 'install-composio-ai',
          setupStatus: 'completed',
        ),
      );

      expect(plugin.needsSetup, isFalse);
    });

    test('needsSetup is false when setup not required', () {
      final plugin = InstalledPlugin.fromJson(
        nestedInstalledPlugin(
          id: 'install-reminder',
          slug: 'reminder',
          name: 'Reminder',
          requiredSetup: false,
          setupType: null,
          setupStatus: 'not_started',
        ),
      );

      expect(plugin.needsSetup, isFalse);
    });
  });
}
