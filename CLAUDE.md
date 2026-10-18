# Luxelane — notes for Claude

- Talk to the owner in Spanish.
- Flutter 3.29 (Dart 3.7) + Firebase. Two apps from one codebase: rider (`lib/main.dart`, also the web) and driver (`lib/main_driver.dart`).
- Checks before pushing:
  - `flutter analyze --no-fatal-infos` (warnings fail CI)
  - `flutter test`
  - `cd functions && npx tsc --noEmit -p . && npm test`
  - `cd rules-tests && npm test`
  - `python3 tool/check_native_config.py`

## Brand colours — "Marfil" (do not change)

The app is light: ivory surfaces, ink text and **sapphire / light blue** as the only accent. **Never champagne, gold or dark themes.**

| Token | Hex | Use |
|---|---|---|
| `LuxColors.bg` / `LD.bg` | `#FAFBFE` | page background (ivory) |
| `LuxColors.surface` | `#FFFFFF` | cards, sheets, bars |
| `LuxColors.surfaceMuted` / `LD.bg2` | `#F2F5FB` | inputs, chips |
| `LuxColors.surfaceDeep` / `LD.bg3` | `#E8EDF7` | pressed, tracks |
| `LuxColors.border` / `LD.border` | `#DDE4F0` | hairlines |
| `LuxColors.ink` / `LD.ink` | `#0D1B2E` | text |
| `LuxColors.inkSecondary` / `LD.ink2` | `#2C3D55` | secondary text |
| `LuxColors.inkTertiary` / `LD.ink3` | `#637490` | captions |
| `LuxColors.sapphire` / `LD.sph` | `#1B4F8A` | accent, primary buttons (white text) |
| `LuxColors.sapphireLight` / `LD.sphLt` | `#2E6FBF` | hover, links |
| `LuxColors.sapphireTint` / `LD.sphTint` | `#EEF3FA` | accent backgrounds |

- Colours come from these tokens (`lib/app/theme/app_theme.dart`, web `lib/features/home/presentation/pages/home_design.dart`), never ad-hoc hex values.
- App icon and launch screens: sapphire "L" monogram on ivory.

## Text

User-facing strings are translated (es/en/pt):
- Edit `lib/l10n/parts/*.json`, then `dart run tool/build_l10n.dart && flutter gen-l10n`.
- `test/no_hardcoded_strings_test.dart` enforces it.
