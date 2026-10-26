import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: const LuxelaneWordmark(size: 11),
              ),
              const SizedBox(height: 48),
              Text(
                'CREAR CUENTA',
                style: LuxTypography.caption.copyWith(
                  color: LuxColors.sapphire,
                  letterSpacing: 3,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bienvenido\na Luxelane.',
                textScaler: luxDisplayTextScaler(context),
                style: LuxTypography.displayMedium.copyWith(
                  fontSize: 40,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu cuenta en menos de un minuto.',
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
          const Expanded(
            child: AuthBrandPanel(
              title: 'Bienvenido\na Luxelane.',
              subtitle:
                  'Una cuenta para reservar, seguir y recordar cada trayecto.',
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
                            'Crear cuenta',
                            style: LuxTypography.displayMedium.copyWith(
                              fontSize: 42,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Solo te pediremos lo necesario para tu chófer.',
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
                const GoogleSignInButton(label: 'Registrarte con Google'),
                const SizedBox(height: LuxSpacing.lg),
                const AuthOrDivider(),
                const SizedBox(height: LuxSpacing.lg),
                LuxTextField(
                  label: 'Nombre completo',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Indica tu nombre para que tu chófer pueda recibirte'
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Correo electrónico',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Ingresa un correo válido'
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Teléfono (con código de país)',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => v == null || v.trim().length < 6
                      ? 'Tu chófer lo necesita para contactarte'
                      : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Contraseña',
                  controller: _pass,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                // Casilla explícita (decisión 7): sin marcarla no se crea la
                // cuenta. El servidor anota versión y hora (acceptTerms).
                FormField<bool>(
                  initialValue: false,
                  validator: (v) => v == true
                      ? null
                      : 'Acepta los Términos y la Política de privacidad '
                          'para continuar',
                  builder: (field) => _TermsConsent(
                    value: field.value ?? false,
                    error: field.errorText,
                    onChanged: loading ? null : field.didChange,
                  ),
                ),
                const SizedBox(height: LuxSpacing.lg),
                LuxButton(
                  label: 'Crear cuenta',
                  onPressed: loading ? null : _submit,
                  loading: loading,
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(
                  'Tu nombre y teléfono permiten a tu chófer recibirte y contactarte.',
                  textAlign: TextAlign.center,
                  style: LuxTypography.caption.copyWith(
                    color: LuxColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: LuxSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta? ',
                      style: LuxTypography.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Inicia sesión'),
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
              label: 'Acepto los Términos y la Política de privacidad',
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
                  Text('He leído y acepto los ', style: plain),
                  Semantics(
                    link: true,
                    child: LuxFocusable(
                      onActivate: () => context.push('/legal/terminos'),
                      child: GestureDetector(
                        onTap: () => context.push('/legal/terminos'),
                        child: Text('Términos', style: link),
                      ),
                    ),
                  ),
                  Text(' y la ', style: plain),
                  Semantics(
                    link: true,
                    child: LuxFocusable(
                      onActivate: () => context.push('/legal/privacidad'),
                      child: GestureDetector(
                        onTap: () => context.push('/legal/privacidad'),
                        child: Text('Política de privacidad', style: link),
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
