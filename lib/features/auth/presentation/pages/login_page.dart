import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/google_sign_in_button.dart';

// ── Design tokens (aligned with home_web_page / LD) ─────────────────────────
const _bg = LuxColors.bg;
const _panel = LuxColors.surface;
const _border = LuxColors.border;
const _sph = LuxColors.sapphire;
const _sphLt = LuxColors.sapphireLight;
const _ink = LuxColors.ink;
const _onSph = LuxColors.onAccent;
const _kSans = 'Montserrat';
const _kSerif = 'Cormorant Garamond';

// ─────────────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

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
          // The router sends each role to its home (admins to /admin), or
          // back to the link that asked for sign-in.
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          context.go(from != null && from.startsWith('/') ? from : '/');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: const TextStyle(fontFamily: _kSans, color: _onSph)),
              backgroundColor: LuxColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: isWeb(context) ? _webLayout() : _mobileLayout(),
      ),
    );
  }

  // ── Web: two-column split ──────────────────────────────────────────────────

  Widget _webLayout() => Row(
        children: [
          // Left — brand panel
          const Expanded(child: AuthBrandPanel()),
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
                            fontWeight: FontWeight.w500,
                            color: _ink,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bienvenido de nuevo a Luxelane.',
                          style: TextStyle(
                            fontFamily: _kSans,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: LuxColors.inkTertiary,
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: const LuxelaneWordmark(size: 11),
              ),
              const SizedBox(height: 28),
              const _AuthHeroPhoto(),
              const SizedBox(height: 32),
              Text('BIENVENIDO',
                  style: LuxTypography.caption
                      .copyWith(color: _sph, letterSpacing: 3, fontSize: 10)),
              const SizedBox(height: 10),
              const Text(
                'Tu chófer,\ncomo lo recuerdas.',
                style: TextStyle(
                  fontFamily: _kSerif,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Inicia sesión para reservar y seguir tus trayectos.',
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: LuxColors.inkTertiary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
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
                const GoogleSignInButton(),
                const SizedBox(height: 24),
                const AuthOrDivider(),
                const SizedBox(height: 24),
                _AuthField(
                  label: 'Correo electrónico',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  validator: (v) => v == null || !v.contains('@')
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
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TextLink(
                    label: '¿Olvidaste tu contraseña?',
                    onTap: () {
                      if (_email.text.contains('@')) {
                        context.read<AuthBloc>().add(
                              PasswordResetRequested(email: _email.text.trim()),
                            );
                        showLuxSnackbar(context,
                            'Te enviamos un enlace para restablecer tu contraseña.');
                      } else {
                        showLuxSnackbar(context,
                            'Escribe tu correo arriba y te enviaremos un enlace.',
                            isError: true);
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
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: LuxColors.inkTertiary,
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

/// Shared by the login and register pages so both read as one experience.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({
    super.key,
    this.title = 'Tu chófer,\ncomo lo recuerdas.',
    this.subtitle = 'Tus direcciones, preferencias y viajes, siempre a mano.',
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Ivory base
          const ColoredBox(color: LuxColors.surfaceMuted),
          // Editorial photo — the promise of the experience, not a form.
          Image.asset(
            'assets/images/home/promise_photo.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                CustomPaint(painter: _DotGridPainter()),
          ),
          // Ivory veil so ink text stays legible over the photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _bg.withAlpha(60),
                  _bg.withAlpha(215),
                  _bg.withAlpha(250),
                ],
                stops: const [0.0, 0.4, 0.75],
              ),
            ),
          ),
          // Left accent line
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
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
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/'),
                      child: const LuxelaneWordmark(color: _ink),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: _kSerif,
                      fontSize: 52,
                      fontWeight: FontWeight.w400,
                      color: _ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: _kSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: LuxColors.inkSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Sapphire divider
                  Container(width: 40, height: 1, color: _sph),
                  const SizedBox(height: 32),
                  for (final line in const [
                    'Reserva en menos de 2 minutos',
                    'Todos tus viajes en un solo lugar',
                    'Seguimiento de tu chófer en tiempo real',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(children: [
                        const Icon(Icons.check_rounded,
                            size: 14, color: LuxColors.sapphire),
                        const SizedBox(width: 12),
                        Text(line,
                            style: const TextStyle(
                                fontFamily: _kSans,
                                fontSize: 12.5,
                                color: LuxColors.inkSecondary)),
                      ]),
                    ),
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
          color: _ink,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: _kSans,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: LuxColors.inkTertiary,
          ),
          floatingLabelStyle: const TextStyle(
            fontFamily: _kSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _sph,
          ),
          prefixIcon: Icon(icon, size: 18, color: LuxColors.inkTertiary),
          filled: true,
          fillColor: _panel,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _sph, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: LuxColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: LuxColors.error, width: 1.5),
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
        onExit: (_) => setState(() => _hover = false),
        cursor:
            widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
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
              borderRadius: BorderRadius.circular(10),
              boxShadow: widget.onTap == null ? null : luxSoftShadow,
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _onSph),
                  )
                : Text(
                    widget.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: _kSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: _onSph,
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
        onExit: (_) => setState(() => _hover = false),
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
              decoration:
                  _hover ? TextDecoration.underline : TextDecoration.none,
              decorationColor: _sphLt,
            ),
          ),
        ),
      );
}

// ── Dot grid (same as hero) ───────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x141B4F8A);
    const s = 40.0;
    for (double x = s; x < size.width; x += s)
      for (double y = s; y < size.height; y += s)
        canvas.drawCircle(Offset(x, y), 1.2, p);
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

// ── Mobile hero photo — the promise of the experience, framed in ivory ──────

class _AuthHeroPhoto extends StatelessWidget {
  const _AuthHeroPhoto();

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(LuxRadius.xl),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: LuxColors.surfaceMuted),
              Image.asset(
                'assets/images/home/promise_photo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    CustomPaint(painter: _DotGridPainter()),
              ),
              // Soft ivory fade into the page below.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_bg.withAlpha(0), _bg.withAlpha(90)],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
