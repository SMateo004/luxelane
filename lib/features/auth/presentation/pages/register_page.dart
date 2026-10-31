import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/google_sign_in_button.dart';
import 'login_page.dart' show AuthBrandPanel;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();

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
        if (state is AuthAuthenticated) {
          // Primero «Verifica tu correo» (reservar lo exige); luego, a donde
          // iba.
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          context.go(
            from != null && from.startsWith('/')
                ? '/verify-email?from=${Uri.encodeComponent(from)}'
                : '/verify-email',
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(color: LuxColors.onAccent),
              ),
              backgroundColor: LuxColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: LuxColors.bg,
        body: isWeb(context) ? _webLayout() : _mobileLayout(),
      ),
    );
  }

  Widget _mobileLayout() => SafeArea(
        child: SingleChildScrollView(
          // El logo enlaza al inicio con 48 px de alto para el dedo (E9);
          // se quitan 12 px arriba y abajo para que no se mueva nada.
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuxPressable(
                semanticLabel: context.l10n.authHomeLinkSemantics,
                haptic: false,
                onTap: () => context.go('/'),
                child: const LuxTapArea(child: LuxelaneWordmark(size: 11)),
              ),
              const SizedBox(height: 36),
              Text(
                context.l10n.authRegisterEyebrow,
                style: LuxTypography.caption.copyWith(
                  color: LuxColors.sapphire,
                  letterSpacing: 3,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.authRegisterHeadline,
                textScaler: luxDisplayTextScaler(context),
                style: LuxTypography.displayMedium.copyWith(
                  fontSize: 40,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.authRegisterSubtitle,
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: 40),
              _formContent(),
            ],
          ),
        ),
      );

  Widget _webLayout() => Row(
        children: [
          Expanded(
            child: AuthBrandPanel(
              title: context.l10n.authRegisterHeadline,
              subtitle: context.l10n.authRegisterBrandSubtitle,
            ),
          ),
          Expanded(
            child: Container(
              color: LuxColors.surface,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 64,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.authRegisterTitle,
                            style: LuxTypography.displayMedium.copyWith(
                              fontSize: 42,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.authRegisterWebSubtitle,
                            style: LuxTypography.bodyMedium,
                          ),
                          const SizedBox(height: 40),
                          _formContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _formContent() => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Form(
            key: _form,
            child: Column(
              children: [
                GoogleSignInButton(label: context.l10n.authGoogleRegister),
                const SizedBox(height: LuxSpacing.lg),
                const AuthOrDivider(),
                const SizedBox(height: LuxSpacing.lg),
                LuxTextField(
                  label: context.l10n.authNameLabel,
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? context.l10n.authNameRequired
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: context.l10n.authEmailLabel,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => v == null || !v.contains('@')
                      ? context.l10n.authEmailInvalid
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: context.l10n.authPhoneLabel,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => v == null || v.trim().length < 6
                      ? context.l10n.authPhoneRequired
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: context.l10n.authPasswordLabel,
                  controller: _pass,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => v == null || v.length < 6
                      ? context.l10n.authPasswordMinLength
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                // Casilla explícita (decisión 7): sin marcarla no se crea la
                // cuenta. El servidor anota versión y hora (acceptTerms).
                FormField<bool>(
                  initialValue: false,
                  validator: (v) =>
                      v == true ? null : context.l10n.authTermsRequired,
                  builder: (field) => _TermsConsent(
                    value: field.value ?? false,
                    error: field.errorText,
                    onChanged: loading ? null : field.didChange,
                  ),
                ),
                const SizedBox(height: LuxSpacing.lg),
                LuxButton(
                  label: context.l10n.authRegisterTitle,
                  onPressed: loading ? null : _submit,
                  loading: loading,
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(
                  context.l10n.authRegisterDataNote,
                  textAlign: TextAlign.center,
                  style: LuxTypography.caption.copyWith(
                    color: LuxColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: LuxSpacing.sm),
                // Wrap: en otros idiomas la frase puede no caber en una línea.
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      context.l10n.authHaveAccount,
                      style: LuxTypography.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(context.l10n.authSignInLink),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

/// «He leído y acepto los Términos y la Política de privacidad», con enlace a
/// cada texto. Los textos están en /legal/* (pendientes de revisión legal).
class _TermsConsent extends StatelessWidget {
  const _TermsConsent({
    required this.value,
    required this.onChanged,
    this.error,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final plain = LuxTypography.caption.copyWith(color: LuxColors.inkSecondary);
    final link = LuxTypography.caption.copyWith(
      color: LuxColors.sapphire,
      decoration: TextDecoration.underline,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              label: context.l10n.authTermsCheckboxSemantics,
              child: Checkbox(
                key: const Key('terms-checkbox'),
                value: value,
                onChanged:
                    onChanged == null ? null : (v) => onChanged!(v ?? false),
              ),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(context.l10n.authTermsReadPrefix, style: plain),
                  Semantics(
                    link: true,
                    child: LuxFocusable(
                      onActivate: () => context.push('/legal/terminos'),
                      child: GestureDetector(
                        onTap: () => context.push('/legal/terminos'),
                        child: Text(context.l10n.authTermsLink, style: link),
                      ),
                    ),
                  ),
                  Text(context.l10n.authTermsAnd, style: plain),
                  Semantics(
                    link: true,
                    child: LuxFocusable(
                      onActivate: () => context.push('/legal/privacidad'),
                      child: GestureDetector(
                        onTap: () => context.push('/legal/privacidad'),
                        child: Text(context.l10n.authPrivacyLink, style: link),
                      ),
                    ),
                  ),
                  Text('.', style: plain),
                ],
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error!,
              style: LuxTypography.caption.copyWith(color: LuxColors.error),
            ),
          ),
      ],
    );
  }
}
