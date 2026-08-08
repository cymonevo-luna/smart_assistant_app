import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'auth_controller.dart';
import 'auth_validators.dart';
import 'widgets/social_auth_row.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authProvider.notifier).login(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (ok && mounted) context.goNamed(AppRoute.home.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final validators = AuthValidators(l10n);
    final busy = ref.watch(authProvider.select((s) => s.busy));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.splash.name)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      l10n.welcomeBack,
                      variant: AppTextVariant.headlineLarge,
                      weight: FontWeight.w700,
                    ),
                    const VGap(AppSpacing.xs),
                    AppText.body(l10n.signInToContinue, muted: true),
                    const VGap(AppSpacing.xl),
                    AppTextField(
                      label: l10n.email,
                      hint: l10n.emailHint,
                      controller: _email,
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: validators.email,
                    ),
                    const VGap(AppSpacing.md),
                    AppTextField(
                      label: l10n.password,
                      hint: l10n.passwordHint,
                      controller: _password,
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: validators.password,
                      onSubmitted: (_) => _submit(),
                    ),
                    const VGap(AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: AppText.label(
                          l10n.forgotPassword,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const VGap(AppSpacing.lg),
                    AppButton(l10n.login, loading: busy, onPressed: _submit),
                    const VGap(AppSpacing.lg),
                    OrDivider(label: l10n.orContinueWith),
                    const VGap(AppSpacing.lg),
                    const SocialAuthRow(),
                    const VGap(AppSpacing.xl),
                    _RegisterPrompt(l10n: l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText.body(l10n.dontHaveAccount, muted: true),
        GestureDetector(
          onTap: () => context.pushNamed(AppRoute.register.name),
          child: AppText.label(l10n.register, color: context.colors.primary),
        ),
      ],
    );
  }
}
