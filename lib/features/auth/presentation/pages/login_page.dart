import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          LoginRequested(
            email: _email.text.trim(),
            password: _pass.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.email == 'admin@luxelane.com') {
            context.go('/admin');
          } else {
            context.go('/');
          }
        }
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
              const SizedBox(height: LuxSpacing.xxl),
              const LuxelaneWordmark(size: 16),
              const SizedBox(height: LuxSpacing.xl),
              const Text('Welcome back.', style: LuxTypography.displayMedium),
              const SizedBox(height: LuxSpacing.sm),
              const Text('Sign in to your account', style: LuxTypography.bodyMedium),
              const SizedBox(height: LuxSpacing.xl),
              _formContent(),
            ],
          ),
        ),
      );

  Widget _webLayout() => Row(
        children: [
          Expanded(
            child: Container(
              color: LuxColors.blackSurface,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LuxelaneWordmark(size: 20),
                    SizedBox(height: LuxSpacing.xl),
                    Text(
                      'Premium chauffeur service.\nAnywhere in the world.',
                      style: LuxTypography.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(LuxSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sign In', style: LuxTypography.displayMedium),
                      const SizedBox(height: LuxSpacing.xl),
                      _formContent(),
                    ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Password',
                  controller: _pass,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: LuxSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (_email.text.contains('@')) {
                        context.read<AuthBloc>().add(
                              PasswordResetRequested(email: _email.text.trim()),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reset email sent')),
                        );
                      }
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: LuxSpacing.md),
                LuxButton(
                  label: 'Sign In',
                  onPressed: loading ? null : _submit,
                  loading: loading,
                ),
                const SizedBox(height: LuxSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: LuxTypography.bodyMedium),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create one'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
