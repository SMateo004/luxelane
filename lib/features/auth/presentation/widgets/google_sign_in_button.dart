import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/auth_bloc.dart';

const _kSans = 'Montserrat'; // i18n-ignore: nombre de fuente

/// "Continuar con Google" — white button with the Google mark, as Google's
/// branding guidelines ask for on light surfaces. Dispatches
/// [GoogleSignInRequested]; works on web (popup) and Android/iOS (native).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.label});

  /// Por defecto, «Continuar con Google».
  final String? label;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (a, b) => (a is AuthLoading) != (b is AuthLoading),
        builder: (context, state) {
          final loading = state is AuthLoading;
          final label = this.label ?? context.l10n.authGoogleContinue;
          return Semantics(
            button: true,
            label: label,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: loading
                    ? null
                    : () => context.read<AuthBloc>().add(
                          const GoogleSignInRequested(),
                        ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: LuxColors.surface,
                  foregroundColor: LuxColors.ink,
                  disabledForegroundColor: LuxColors.inkTertiary,
                  side: const BorderSide(color: LuxColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(painter: _GoogleMarkPainter()),
                    ),
                    const SizedBox(width: 12),
                    // Flexible: una traducción más larga no desborda.
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _kSans,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: LuxColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

/// Thin rule with a centred word — separates Google from email sign-in.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label});

  /// Por defecto, «o con tu correo».
  final String? label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: LuxColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              (label ?? context.l10n.authOrWithEmail).toUpperCase(),
              style: LuxTypography.caption.copyWith(
                letterSpacing: 1.6,
                fontSize: 10,
              ),
            ),
          ),
          const Expanded(child: Divider(color: LuxColors.border)),
        ],
      );
}

/// The four-colour Google "G", drawn so no image asset is needed.
class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (s - stroke) / 2,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;

    // Angles run clockwise from 3 o'clock; the gap sits at the right.
    canvas.drawArc(rect, deg(-40), deg(-95), false, arc(_red));
    canvas.drawArc(rect, deg(-135), deg(-90), false, arc(_yellow));
    canvas.drawArc(rect, deg(135), deg(-100), false, arc(_green));
    canvas.drawArc(rect, deg(35), deg(-35), false, arc(_blue));
    // Crossbar of the G.
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        size.height / 2 - stroke / 2,
        rect.right - size.width / 2 + stroke / 2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleMarkPainter oldDelegate) => false;
}
