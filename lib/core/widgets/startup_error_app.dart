import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Shown instead of the app when Firebase can't start (a build without its
/// Firebase configuration, a broken install): every feature needs it, so a
/// clear message beats a screen that silently does nothing.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: luxTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        localeListResolutionCallback: resolveAppLocale,
        home: const _StartupErrorPage(),
      );
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: LuxColors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_outlined, size: 56, color: LuxColors.accent),
                const SizedBox(height: LuxSpacing.lg),
                Text(l.startupErrorTitle, textAlign: TextAlign.center, style: LuxTypography.headlineMedium),
                const SizedBox(height: LuxSpacing.md),
                Text(l.startupErrorBody, textAlign: TextAlign.center, style: LuxTypography.bodyMedium),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
