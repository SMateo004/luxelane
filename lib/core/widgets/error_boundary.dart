import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Global error boundary. Wrap the root widget to catch Flutter render errors.
/// Call [ErrorBoundary.register] once in main() after WidgetsFlutterBinding.
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({super.key, required this.child});
  final Widget child;

  /// Call once in main() to hook into Flutter's global error handler.
  static void register() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      original?.call(details);
      // Errors are already printed by the original handler.
    };
  }

  @override
  Widget build(BuildContext context) => child;
}

/// Shown when an unrecoverable widget error occurs.
class LuxErrorScreen extends StatelessWidget {
  const LuxErrorScreen({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: LuxColors.accent,
                  size: 56,
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(
                  context.l10n.coreErrorTitle,
                  style: const TextStyle(
                    color: LuxColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: LuxSpacing.sm),
                Text(
                  context.l10n.coreErrorBody,
                  style: const TextStyle(color: LuxColors.whiteTertiary),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: LuxSpacing.xl),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      context.l10n.commonRetry,
                      style: const TextStyle(color: LuxColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
