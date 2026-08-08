import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';

class PluginSetupPage extends StatelessWidget {
  const PluginSetupPage({super.key, required this.pluginId});

  final String pluginId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: AppText.heading(l10n.pluginSetup),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppText.body(l10n.pluginSetupComingSoon),
        ),
      ),
    );
  }
}
