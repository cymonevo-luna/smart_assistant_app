import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import 'plugin_setup_provider.dart';
import 'plugins_provider.dart';
import 'services/plugin_setup_deep_link_service.dart';

class PluginSetupDeepLinkNotifier extends Notifier<void> {
  @override
  void build() {
    final service = locator<PluginSetupDeepLinkService>();
    final subscription = service.events.listen((event) {
      unawaited(_handleDeepLink(event));
    });
    ref.onDispose(subscription.cancel);
  }

  Future<void> _handleDeepLink(PluginSetupDeepLinkEvent event) async {
    await ref.read(installedPluginsProvider.notifier).refresh();
    await ref.read(pluginSetupControllerProvider.notifier).handleDeepLink(event);
  }
}

final pluginSetupDeepLinkNotifierProvider =
    NotifierProvider<PluginSetupDeepLinkNotifier, void>(
  PluginSetupDeepLinkNotifier.new,
);
