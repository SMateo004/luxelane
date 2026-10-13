import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/app_gate/global_config.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/admin_bloc.dart';

final _appStoreUrl = RegExp(r'^https://apps\.apple\.com/.{1,200}$');

/// The values to write to config/global, or null when one is invalid
/// (firestore.rules checks the same).
Map<String, dynamic>? minVersionFields({
  required String riderBuild,
  required String driverBuild,
  required String riderIosUrl,
  required String driverIosUrl,
}) {
  final rider = int.tryParse(riderBuild.trim().isEmpty ? '0' : riderBuild.trim());
  final driver = int.tryParse(driverBuild.trim().isEmpty ? '0' : driverBuild.trim());
  bool urlOk(String u) => u.isEmpty || _appStoreUrl.hasMatch(u);
  if (rider == null || driver == null || rider < 0 || driver < 0) return null;
  if (!urlOk(riderIosUrl.trim()) || !urlOk(driverIosUrl.trim())) return null;
  return {
    'riderMinBuild': rider,
    'driverMinBuild': driver,
    'riderIosUrl': riderIosUrl.trim(),
    'driverIosUrl': driverIosUrl.trim(),
  };
}

/// Admin → Settings: the oldest build of each app that may still be used.
class MinVersionCard extends StatelessWidget {
  const MinVersionCard({super.key, required this.settings, this.onSave});

  /// config/global as the admin bloc watches it.
  final Map<String, dynamic> settings;

  /// Defaults to saving through the admin bloc (audited).
  final ValueChanged<Map<String, dynamic>>? onSave;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = GlobalConfig.fromJson(settings);
    String show(int b) => b == 0 ? l.adminMinVersionNone : '$b';
    return LuxCard(
      child: Row(children: [
        const Icon(Icons.system_update_rounded, color: LuxColors.accent),
        const SizedBox(width: LuxSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.adminMinVersionTitle, style: LuxTypography.titleMedium),
            const SizedBox(height: 2),
            Text(l.adminMinVersionSummary(show(c.riderMinBuild), show(c.driverMinBuild)), style: LuxTypography.caption),
          ]),
        ),
        TextButton(
          onPressed: () {
            final save = onSave ?? (f) => context.read<AdminBloc>().add(AdminUpdateGlobalSettingsRequested(f));
            showDialog<void>(context: context, builder: (_) => _MinVersionDialog(config: c, onSave: save));
          },
          child: Text(l.supportHoursEdit, style: const TextStyle(color: LuxColors.accent)),
        ),
      ]),
    );
  }
}

class _MinVersionDialog extends StatefulWidget {
  const _MinVersionDialog({required this.config, required this.onSave});
  final GlobalConfig config;
  final ValueChanged<Map<String, dynamic>> onSave;

  @override
  State<_MinVersionDialog> createState() => _MinVersionDialogState();
}

class _MinVersionDialogState extends State<_MinVersionDialog> {
  late final _rider = TextEditingController(text: '${widget.config.riderMinBuild}');
  late final _driver = TextEditingController(text: '${widget.config.driverMinBuild}');
  late final _riderUrl = TextEditingController(text: widget.config.riderIosUrl ?? '');
  late final _driverUrl = TextEditingController(text: widget.config.driverIosUrl ?? '');
  bool _invalid = false;

  @override
  void dispose() {
    for (final c in [_rider, _driver, _riderUrl, _driverUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final fields = minVersionFields(
      riderBuild: _rider.text,
      driverBuild: _driver.text,
      riderIosUrl: _riderUrl.text,
      driverIosUrl: _driverUrl.text,
    );
    if (fields == null) return setState(() => _invalid = true);
    widget.onSave(fields);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.adminMinVersionTitle, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.adminMinVersionDesc, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.sm),
            Text(l.adminMinVersionHint, style: LuxTypography.caption),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(controller: _rider, label: l.adminMinBuildRider, keyboardType: TextInputType.number, inputFormatters: digits),
            const SizedBox(height: LuxSpacing.sm),
            LuxTextField(controller: _driver, label: l.adminMinBuildDriver, keyboardType: TextInputType.number, inputFormatters: digits),
            const SizedBox(height: LuxSpacing.sm),
            LuxTextField(controller: _riderUrl, label: l.adminIosUrlRider, hint: 'https://apps.apple.com/…', keyboardType: TextInputType.url),
            const SizedBox(height: LuxSpacing.sm),
            LuxTextField(controller: _driverUrl, label: l.adminIosUrlDriver, hint: 'https://apps.apple.com/…', keyboardType: TextInputType.url),
            if (_invalid) ...[
              const SizedBox(height: LuxSpacing.sm),
              Text(l.adminMinVersionInvalid, style: LuxTypography.caption.copyWith(color: LuxColors.error)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        TextButton(onPressed: _save, child: Text(l.commonSave, style: const TextStyle(color: LuxColors.accent))),
      ],
    );
  }
}
