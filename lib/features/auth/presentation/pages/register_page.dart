import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../auth_error_messages.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass  = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          RegisterRequested(
            email: _email.text.trim(),
            password: _pass.text,
            phone: _phone.text.trim(),
            displayName: _name.text.trim(),
            role: UserRole.rider,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/');
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authErrorMessage(context.l10n, state.code)),
              backgroundColor: LuxColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: LuxColors.black,
        body: isWeb(context) ? _webLayout() : _mobileLayout(),
      ),
    );
  }

  Widget _mobileLayout() => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LuxSpacing.xl),
              const LuxelaneWordmark(size: 16),
              const SizedBox(height: LuxSpacing.xl),
              Text(context.l10n.authRegisterHeadline, style: LuxTypography.displayMedium),
              const SizedBox(height: LuxSpacing.sm),
              Text(context.l10n.authRegisterSubtitle, style: LuxTypography.bodyMedium),
              const SizedBox(height: LuxSpacing.xl),
              _formContent(),
            ],
          ),
        ),
      );

  Widget _webLayout() => Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(LuxSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LuxelaneWordmark(),
                  const SizedBox(height: LuxSpacing.xl),
                  Text(context.l10n.authRegisterTitle, style: LuxTypography.displayMedium),
                  const SizedBox(height: LuxSpacing.xl),
                  _formContent(),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _formContent() => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final loading = state is AuthLoading;
          final l = context.l10n;
          return Form(
            key: _form,
            child: Column(
              children: [
                LuxTextField(
                  label: l.authFullNameLabel,
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? l.commonRequired : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: l.authEmailLabel,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) =>
                      v == null || !v.contains('@') ? l.authEmailInvalid : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: l.authPhoneLabel,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? l.commonRequired : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: l.authPasswordLabel,
                  controller: _pass,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      v == null || v.length < 6 ? l.authPasswordTooShort(6) : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                FormField<bool>(
                  initialValue: false,
                  validator: (v) => v == true ? null : l.authConsentRequired,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: field.value ?? false,
                            onChanged: field.didChange,
                            activeColor: LuxColors.accent,
                            checkColor: LuxColors.onAccent,
                            semanticLabel: l.authConsentText(
                                l.authConsentTermsLink, l.authConsentPrivacyLink),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _ConsentText(
                                onToggle: () => field.didChange(!(field.value ?? false)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(field.errorText!,
                              style: LuxTypography.caption.copyWith(color: LuxColors.error)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: LuxSpacing.lg),
                LuxButton(
                  label: l.authRegisterTitle,
                  onPressed: loading ? null : _submit,
                  loading: loading,
                ),
                const SizedBox(height: LuxSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l.authAlreadyHaveAccount, style: LuxTypography.bodyMedium),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(l.authSignInLink),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

/// "I accept the [Terms and Conditions] and the [Privacy Policy]" with the two
/// link texts as tappable spans. The sentence is a single translation
/// (authConsentText) with {terms}/{privacy} placeholders, so every language
/// controls its own word order and articles; tapping the plain text toggles
/// the checkbox.
class _ConsentText extends StatefulWidget {
  const _ConsentText({required this.onToggle});
  final VoidCallback onToggle;

  @override
  State<_ConsentText> createState() => _ConsentTextState();
}

class _ConsentTextState extends State<_ConsentText> {
  late final _terms = TapGestureRecognizer()..onTap = () => context.push('/terminos');
  late final _privacy = TapGestureRecognizer()..onTap = () => context.push('/privacidad');

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final link = LuxTypography.bodyMedium.copyWith(
      color: LuxColors.accent,
      decoration: TextDecoration.underline,
      decorationColor: LuxColors.accent,
    );
    final spans = <InlineSpan>[];
    l.authConsentText('{terms}', '{privacy}').splitMapJoin(
      RegExp(r'\{terms\}|\{privacy\}'),
      onMatch: (m) {
        final terms = m[0] == '{terms}';
        spans.add(TextSpan(
          text: terms ? l.authConsentTermsLink : l.authConsentPrivacyLink,
          style: link,
          recognizer: terms ? _terms : _privacy,
        ));
        return '';
      },
      onNonMatch: (text) {
        if (text.isNotEmpty) spans.add(TextSpan(text: text));
        return '';
      },
    );
    return GestureDetector(
      onTap: widget.onToggle,
      child: Text.rich(TextSpan(style: LuxTypography.bodyMedium, children: spans)),
    );
  }
}
