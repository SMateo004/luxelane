import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../app/lux_locale.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/locale_sync.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Idioma de la app en el perfil: «Sistema», «Español», «English»,
/// «Português». Al tocar una opción la app cambia al instante (vista previa)
/// y se guarda en la cuenta; si la cuenta no lo guarda, se avisa y el
/// dispositivo lo conserva.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.sync,
    this.signedIn = true,
  });

  final LocaleSync sync;
  final bool signedIn;

  Future<void> _pick(BuildContext context, LocaleChoice choice) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final saved = await sync.choose(choice, signedIn: signedIn);
    if (saved || messenger == null || !messenger.mounted) return;
    final l10n = lookupAppLocalizations(sync.controller.effective());
    messenger.showSnackBar(SnackBar(content: Text(l10n.languageSaveError)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final device = LuxLocale.fromDevice(
      WidgetsBinding.instance.platformDispatcher.locales,
    ).languageCode;
    return ValueListenableBuilder<LocaleChoice>(
      valueListenable: sync.controller,
      builder: (context, current, _) => LuxGroup(
        children: [
          _Option(
            label: l10n.languageSystem,
            detail: l10n.languageSystemDetail(LuxLocale.endonyms[device]!),
            selected: current == LocaleChoice.system,
            onTap: () => _pick(context, LocaleChoice.system),
          ),
          for (final code in LuxLocale.codes)
            _Option(
              label: LuxLocale.endonyms[code]!,
              // Cada idioma se anuncia en su propia lengua.
              labelLocale: Locale(code),
              selected: current.name == code,
              onTap: () => _pick(context, LuxLocale.choiceOf(code)),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.labelLocale,
  });

  final String label;
  final String? detail;
  final Locale? labelLocale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      attributedLabel: AttributedString(
        label,
        attributes: [
          if (labelLocale != null)
            LocaleStringAttribute(
              range: TextRange(start: 0, end: label.length),
              locale: labelLocale!,
            ),
        ],
      ),
      excludeSemantics: true,
      hint: detail,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? LuxColors.ink : LuxColors.inkSecondary,
                ),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        locale: labelLocale,
                        style: LuxTypography.bodyLarge,
                      ),
                      if (detail != null)
                        Text(detail!, style: LuxTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
