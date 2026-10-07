import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
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
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LuxSpacing.xl),
              const LuxelaneWordmark(size: 16),
              const SizedBox(height: LuxSpacing.xl),
              const Text('Crear cuenta.', style: LuxTypography.displayMedium),
              const SizedBox(height: LuxSpacing.sm),
              const Text('Únete a Luxelane hoy', style: LuxTypography.bodyMedium),
              const SizedBox(height: LuxSpacing.xl),
              _formContent(),
            ],
          ),
        ),
      );

  Widget _webLayout() => Center(
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
                const Text('Crear cuenta', style: LuxTypography.displayMedium),
                const SizedBox(height: LuxSpacing.xl),
                _formContent(),
              ],
            ),
          ),
        ),
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
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Correo electrónico',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Teléfono',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
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
                FormField<bool>(
                  initialValue: false,
                  validator: (v) => v == true
                      ? null
                      : 'Debes aceptar los términos y la política de privacidad',
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
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Acepto los ', style: LuxTypography.bodyMedium),
                                  _InlineLink(label: 'Términos y condiciones', path: '/terminos'),
                                  const Text(' y la ', style: LuxTypography.bodyMedium),
                                  _InlineLink(label: 'Política de privacidad', path: '/privacidad'),
                                ],
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
                  label: 'Crear cuenta',
                  onPressed: loading ? null : _submit,
                  loading: loading,
                ),
                const SizedBox(height: LuxSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
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

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push(path),
        child: Text(
          label,
          style: LuxTypography.bodyMedium.copyWith(
            color: LuxColors.accent,
            decoration: TextDecoration.underline,
            decorationColor: LuxColors.accent,
          ),
        ),
      );
}
