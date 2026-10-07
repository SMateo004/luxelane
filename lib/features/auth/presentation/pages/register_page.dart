import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart' show AuthBrandPanel;

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
              content: Text(state.message),
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
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: const LuxelaneWordmark(),
              ),
              const SizedBox(height: 48),
              Text('Bienvenido\na Luxelane.',
                  style: LuxTypography.displayMedium.copyWith(fontSize: 40, height: 1.15)),
              const SizedBox(height: 8),
              const Text('Crea tu cuenta en menos de un minuto.',
                  style: LuxTypography.bodyMedium),
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
              subtitle: 'Una cuenta para reservar, seguir y recordar cada trayecto.',
            ),
          ),
          Expanded(
            child: Container(
              color: LuxColors.blackSurface,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Crear cuenta',
                              style: LuxTypography.displayMedium.copyWith(fontSize: 42)),
                          const SizedBox(height: 6),
                          const Text('Solo te pediremos lo necesario para tu chófer.',
                              style: LuxTypography.bodyMedium),
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
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Ingresa un correo válido' : null,
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
                const SizedBox(height: LuxSpacing.xl),
                LuxButton(
                  label: 'Crear cuenta',
                  onPressed: loading ? null : _submit,
                  loading: loading,
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(
                  'Tu nombre y teléfono permiten a tu chófer recibirte y contactarte.',
                  textAlign: TextAlign.center,
                  style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary),
                ),
                const SizedBox(height: LuxSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? ',
                        style: LuxTypography.bodyMedium),
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
