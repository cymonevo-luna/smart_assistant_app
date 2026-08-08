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

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    if (ok && mounted) context.goNamed(AppRoute.home.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = AuthValidators(l10n);
    final busy = ref.watch(authProvider.select((s) => s.busy));

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
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
                      l10n.createAccount,
                      variant: AppTextVariant.headlineLarge,
                      weight: FontWeight.w700,
                    ),
                    const VGap(AppSpacing.xs),
                    AppText.body(l10n.signUpToGetStarted, muted: true),
                    const VGap(AppSpacing.xl),
                    AppTextField(
                      label: l10n.fullName,
                      hint: l10n.fullNameHint,
                      controller: _name,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: validators.required,
                    ),
                    const VGap(AppSpacing.md),
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
                      textInputAction: TextInputAction.next,
                      validator: validators.password,
                    ),
                    const VGap(AppSpacing.md),
                    AppTextField(
                      label: l10n.confirmPassword,
                      hint: l10n.passwordHint,
                      controller: _confirm,
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator:
                          validators.confirmPassword(() => _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                    const VGap(AppSpacing.xl),
                    AppButton(l10n.register, loading: busy, onPressed: _submit),
                    const VGap(AppSpacing.lg),
                    OrDivider(label: l10n.orContinueWith),
                    const VGap(AppSpacing.lg),
                    const SocialAuthRow(),
                    const VGap(AppSpacing.xl),
                    _LoginPrompt(l10n: l10n),
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

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText.body(l10n.alreadyHaveAccount, muted: true),
        GestureDetector(
          onTap: () => context.pop(),
          child: AppText.label(l10n.signIn, color: context.colors.primary),
        ),
      ],
    );
  }
}
