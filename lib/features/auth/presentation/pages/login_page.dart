import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/auth_bloc.dart';

// ── Design tokens (aligned with home_web_page / LD) ─────────────────────────
const _dark    = Color(0xFF070E18);
const _panel   = Color(0xFF0A1220);
const _border  = Color(0xFF1A2B40);
const _sph     = Color(0xFF1B4F8A);
const _sphLt   = Color(0xFF2563B0);
const _white   = Colors.white;
const _kSans   = 'Montserrat';
const _kSerif  = 'Cormorant Garamond';

// ─────────────────────────────────────────────────────────────────────────────

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
          LoginRequested(email: _email.text.trim(), password: _pass.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(state.user.email == 'admin@luxelane.com' ? '/admin' : '/');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: const TextStyle(fontFamily: _kSans)),
              backgroundColor: LuxColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _dark,
        body: isWeb(context) ? _webLayout() : _mobileLayout(),
      ),
    );
  }

  // ── Web: two-column split ──────────────────────────────────────────────────

  Widget _webLayout() => Row(
        children: [
          // Left — brand panel
          Expanded(child: _BrandPanel()),
          // Right — form panel
          Expanded(
            child: Container(
              color: _panel,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 64),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontFamily: _kSerif,
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                            color: _white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bienvenido de nuevo a Luxelane.',
                          style: TextStyle(
                            fontFamily: _kSans,
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: _white.withAlpha(130),
                          ),
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
        ],
      );

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _mobileLayout() => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LuxLogo(),
              const SizedBox(height: 48),
              const Text(
                'Bienvenido\nde nuevo.',
                style: TextStyle(
                  fontFamily: _kSerif,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: _white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión en tu cuenta',
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: _white.withAlpha(130),
                ),
              ),
              const SizedBox(height: 40),
              _formContent(),
            ],
          ),
        ),
      );

  // ── Shared form ────────────────────────────────────────────────────────────

  Widget _formContent() => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthField(
                  label: 'Correo electrónico',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  validator: (v) =>
                      v == null || !v.contains('@')
                          ? 'Ingresa un correo válido'
                          : null,
                ),
                const SizedBox(height: 14),
                _AuthField(
                  label: 'Contraseña',
                  controller: _pass,
                  obscureText: true,
                  icon: Icons.lock_outline,
                  validator: (v) =>
                      v == null || v.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TextLink(
                    label: '¿Olvidaste tu contraseña?',
                    onTap: () {
                      if (_email.text.contains('@')) {
                        context.read<AuthBloc>().add(
                              PasswordResetRequested(
                                  email: _email.text.trim()),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Correo de restablecimiento enviado')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 28),
                _AuthButton(
                  label: 'Iniciar sesión',
                  loading: loading,
                  onTap: loading ? null : _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: _white.withAlpha(120),
                      ),
                    ),
                    _TextLink(
                      label: 'Crear una',
                      onTap: () => context.go('/register'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

// ── Brand panel (left side on web) ────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Deep navy base
          const ColoredBox(color: _dark),
          // Dot grid — same as hero
          CustomPaint(painter: _DotGridPainter()),
          // Subtle bottom vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _dark.withAlpha(200),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Left accent line
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(width: 1, color: _border),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LuxLogo(),
                  const SizedBox(height: 40),
                  const Text(
                    'Servicio de chófer\npremium.',
                    style: TextStyle(
                      fontFamily: _kSerif,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      color: _white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'En cualquier parte del mundo.',
                    style: TextStyle(
                      fontFamily: _kSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.6,
                      color: _white.withAlpha(140),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Sapphire divider
                  Container(width: 40, height: 1, color: _sph),
                ],
              ),
            ),
          ),
        ],
      );
}

// ── Input field styled for the auth pages ─────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontFamily: _kSans,
          fontSize: 14,
          color: _white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: _kSans,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _white.withAlpha(130),
          ),
          prefixIcon: Icon(icon, size: 18, color: _white.withAlpha(100)),
          filled: true,
          fillColor: const Color(0xFF0D1928),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _border.withAlpha(180)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _sph, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: LuxColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: LuxColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}

// ── Primary action button ──────────────────────────────────────────────────────

class _AuthButton extends StatefulWidget {
  const _AuthButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: widget.onTap == null
                  ? _sph.withAlpha(80)
                  : (_hover ? _sphLt : _sph),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _white),
                  )
                : Text(
                    widget.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: _kSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: _white,
                    ),
                  ),
          ),
        ),
      );
}

// ── Text link ─────────────────────────────────────────────────────────────────

class _TextLink extends StatefulWidget {
  const _TextLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _hover ? _sphLt : _sph.withAlpha(220),
              decoration: _hover ? TextDecoration.underline : TextDecoration.none,
              decorationColor: _sphLt,
            ),
          ),
        ),
      );
}

// ── Luxelane wordmark ─────────────────────────────────────────────────────────

class _LuxLogo extends StatelessWidget {
  const _LuxLogo();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: _sph, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'LUXELANE',
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.5,
              color: _white,
            ),
          ),
        ],
      );
}

// ── Dot grid (same as hero) ───────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x0FFFFFFF);
    const s = 40.0;
    for (double x = s; x < size.width;  x += s)
    for (double y = s; y < size.height; y += s)
      canvas.drawCircle(Offset(x, y), 1.2, p);
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}
