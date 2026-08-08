import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'auth_controller.dart';

/// Clean startup screen: shows the brand mark while the auth session is
/// restored, then routes to Home (token found) or Login.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const _minDisplay = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // Keep the splash visible for a beat, then wait until auth resolves.
    await Future<void>.delayed(_minDisplay);
    while (mounted && ref.read(authProvider).status == AuthStatus.unknown) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    if (!mounted) return;

    final authed = ref.read(authProvider).isAuthenticated;
    context.goNamed(authed ? AppRoute.home.name : AppRoute.login.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 96),
                  const VGap(AppSpacing.xl),
                  AppText(
                    l10n.appTitle,
                    variant: AppTextVariant.headlineMedium,
                    weight: FontWeight.w700,
                  ),
                  const VGap(AppSpacing.xs),
                  AppText.body(l10n.appTagline, muted: true),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xxs),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: colors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
