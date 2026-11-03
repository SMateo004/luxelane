import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/driver_registration_repository.dart';
import '../bloc/registration_cubit.dart';

/// Validaciones locales: las mismas que el servidor (zod), para avisar
/// antes de enviar. El servidor sigue siendo quien decide.
final _idPattern = RegExp(r'^[A-Z0-9-]{4,20}$');
final _platePattern = RegExp(r'^[A-Z0-9]{4,10}$');
const kMinVehicleYear = 1990;

String normalizeId(String s) => s.toUpperCase().replaceAll(RegExp(r'\s+'), '');
String normalizePlate(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'[\s.-]'), '');

/// Pie con Atrás y la acción principal.
class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.primary,
    required this.onPrimary,
    this.loading = false,
    this.showBack = true,
  });

  final String primary;
  final VoidCallback? onPrimary;
  final bool loading;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<RegistrationCubit>();
    return Padding(
      padding: const EdgeInsets.only(top: LuxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuxButton(
            label: primary,
            loading: loading,
            onPressed: loading ? null : onPrimary,
          ),
          if (showBack) ...[
            const SizedBox(height: LuxSpacing.sm),
            LuxButton.ghost(label: t.regBack, onPressed: cubit.back),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPicked,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final now = DateTime.now();
    return Semantics(
      button: true,
      label:
          '$label: ${value == null ? t.regPickDate : LuxFormat.date(value!)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(LuxRadius.md),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? now.add(const Duration(days: 365)),
            firstDate: now,
            lastDate: DateTime(now.year + 30),
          );
          if (d != null) onPicked(d);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              value == null ? t.regPickDate : LuxFormat.date(value!),
              style: LuxTypography.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Datos personales ────────────────────────────────────────────────────────

class PersonalStep extends StatefulWidget {
  const PersonalStep({super.key, required this.state});
  final RegistrationState state;

  @override
  State<PersonalStep> createState() => _PersonalStepState();
}

class _PersonalStepState extends State<PersonalStep> {
  final _form = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.state.app.personal?.fullName);
  late final _id =
      TextEditingController(text: widget.state.app.personal?.nationalIdNumber);
  late final _license =
      TextEditingController(text: widget.state.app.personal?.licenseNumber);
  late DateTime? _expiry = widget.state.app.personal?.licenseExpiry;
  bool _expiryMissing = false;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = _form.currentState!.validate();
    setState(() => _expiryMissing = _expiry == null);
    if (!ok || _expiry == null) return;
    await context.read<RegistrationCubit>().savePersonal(DriverPersonalData(
          fullName: _name.text.trim(),
          nationalIdNumber: normalizeId(_id.text),
          licenseNumber: normalizeId(_license.text),
          licenseExpiry: _expiry!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    String? idCheck(String? v) {
      if ((v ?? '').trim().isEmpty) return t.regFieldRequired;
      return _idPattern.hasMatch(normalizeId(v!)) ? null : t.regIdInvalid;
    }

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        children: [
          LuxTextField(
            key: const ValueKey('reg-full-name'),
            label: t.regFullName,
            controller: _name,
            validator: (v) {
              final n = (v ?? '').trim().length;
              if (n == 0) return t.regFieldRequired;
              return n < 2 || n > 120 ? t.regFullNameInvalid : null;
            },
          ),
          const SizedBox(height: LuxSpacing.md),
          LuxTextField(
            key: const ValueKey('reg-national-id'),
            label: t.regNationalId,
            controller: _id,
            validator: idCheck,
          ),
          const SizedBox(height: LuxSpacing.md),
          LuxTextField(
            key: const ValueKey('reg-license'),
            label: t.regLicenseNumber,
            controller: _license,
            validator: idCheck,
          ),
          const SizedBox(height: LuxSpacing.md),
          _DateField(
            label: t.regLicenseExpiry,
            value: _expiry,
            errorText: _expiryMissing ? t.regFieldRequired : null,
            onPicked: (d) => setState(() {
              _expiry = d;
              _expiryMissing = false;
            }),
          ),
          const SizedBox(height: LuxSpacing.md),
          Text(t.regPrivacyNote, style: LuxTypography.caption),
          _StepActions(
            primary: t.regSaveContinue,
            loading: widget.state.saving,
            onPrimary: _save,
            showBack: false,
          ),
        ],
      ),
    );
  }
}

// ── Vehículo ──────────────────────────────────────────────────────────────

class VehicleStep extends StatefulWidget {
  const VehicleStep({super.key, required this.state});
  final RegistrationState state;

  @override
  State<VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<VehicleStep> {
  final _form = GlobalKey<FormState>();
  DriverVehicleData? get _v => widget.state.app.vehicle;
  late final _make = TextEditingController(text: _v?.make);
  late final _model = TextEditingController(text: _v?.model);
  late final _year = TextEditingController(text: _v?.year.toString());
  late final _plate = TextEditingController(text: _v?.plate);
  late final _colorOther = TextEditingController(text: _v?.colorOther);
  late VehicleColorOption? _color = _v?.color;
  late VehicleBodyType _body = _v?.bodyType ?? VehicleBodyType.sedan;
  late int _passengers = _v?.passengers ?? 3;
  late VehicleClass _class = VehicleClass.values
          .where((c) => c.name == _v?.vehicleClass)
          .firstOrNull ??
      VehicleClass.business;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    _colorOther.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await context.read<RegistrationCubit>().saveVehicle(DriverVehicleData(
          make: _make.text.trim(),
          model: _model.text.trim(),
          year: int.parse(_year.text.trim()),
          color: _color!,
          colorOther: _color == VehicleColorOption.other
              ? _colorOther.text.trim()
              : null,
          plate: normalizePlate(_plate.text),
          bodyType: _body,
          passengers: _passengers,
          vehicleClass: _class.name,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final maxYear = DateTime.now().year + 1;
    String? textCheck(String? v) {
      final n = (v ?? '').trim().length;
      if (n == 0) return t.regFieldRequired;
      return n > 40 ? t.regTextInvalid : null;
    }

    final plateError = widget.state.fieldErrors.contains('plate');
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        children: [
          LuxTextField(
            key: const ValueKey('reg-make'),
            label: t.regMake,
            controller: _make,
            validator: textCheck,
          ),
          const SizedBox(height: LuxSpacing.md),
          LuxTextField(
            key: const ValueKey('reg-model'),
            label: t.regModel,
            controller: _model,
            validator: textCheck,
          ),
          const SizedBox(height: LuxSpacing.md),
          LuxTextField(
            key: const ValueKey('reg-year'),
            label: t.regYear,
            controller: _year,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (v) {
              final y = int.tryParse((v ?? '').trim());
              return y == null || y < kMinVehicleYear || y > maxYear
                  ? t.regYearInvalid(kMinVehicleYear, maxYear)
                  : null;
            },
          ),
          const SizedBox(height: LuxSpacing.md),
          DropdownButtonFormField<VehicleColorOption>(
            key: const ValueKey('reg-color'),
            value: _color,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.regColor),
            items: [
              for (final c in VehicleColorOption.values)
                DropdownMenuItem(value: c, child: Text(c.label)),
            ],
            validator: (v) => v == null ? t.regFieldRequired : null,
            onChanged: (c) => setState(() => _color = c),
          ),
          if (_color == VehicleColorOption.other) ...[
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              key: const ValueKey('reg-color-other'),
              label: t.regColorOtherText,
              controller: _colorOther,
              validator: (v) {
                final n = (v ?? '').trim().length;
                if (n == 0) return t.regFieldRequired;
                return n > 20 ? t.regColorOtherInvalid : null;
              },
            ),
          ],
          const SizedBox(height: LuxSpacing.md),
          LuxTextField(
            key: const ValueKey('reg-plate'),
            label: t.regPlate,
            controller: _plate,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 .-]')),
              LengthLimitingTextInputFormatter(14),
            ],
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return t.regFieldRequired;
              if (!_platePattern.hasMatch(normalizePlate(v!))) {
                return t.regPlateInvalid;
              }
              return plateError ? t.regErrorPlateInUse : null;
            },
          ),
          const SizedBox(height: LuxSpacing.md),
          Text(t.regBodyType, style: LuxTypography.caption),
          const SizedBox(height: LuxSpacing.xs),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.sm,
            children: [
              for (final b in VehicleBodyType.values)
                ChoiceChip(
                  label: Text(b.label),
                  selected: _body == b,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() => _body = b),
                ),
            ],
          ),
          const SizedBox(height: LuxSpacing.md),
          DropdownButtonFormField<int>(
            key: const ValueKey('reg-passengers'),
            value: _passengers,
            decoration: InputDecoration(labelText: t.regPassengers),
            items: [
              for (var i = 1; i <= 8; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => setState(() => _passengers = v ?? _passengers),
          ),
          const SizedBox(height: LuxSpacing.md),
          DropdownButtonFormField<VehicleClass>(
            key: const ValueKey('reg-class'),
            value: _class,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.regVehicleClass),
            items: [
              for (final c in VehicleClass.values)
                DropdownMenuItem(value: c, child: Text(c.label)),
            ],
            onChanged: (v) => setState(() => _class = v ?? _class),
          ),
          const SizedBox(height: LuxSpacing.md),
          Text(t.regVehicleChangeNote, style: LuxTypography.caption),
          _StepActions(
            primary: t.regSaveContinue,
            loading: widget.state.saving,
            onPrimary: _save,
          ),
        ],
      ),
    );
  }
}

// ── Segundo factor (con mfaEnforced) ───────────────────────────────────────

class SecurityStep extends StatelessWidget {
  const SecurityStep({super.key, required this.state, this.onEnrollMfa});
  final RegistrationState state;
  final Future<void> Function(BuildContext context)? onEnrollMfa;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<RegistrationCubit>();
    final s = state.secondFactor;
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        Text(t.regSecurityBody, style: LuxTypography.bodyLarge),
        const SizedBox(height: LuxSpacing.lg),
        if (s == SecondFactorState.inSession)
          MergeSemantics(
            child: Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.verified_user_outlined,
                      color: LuxColors.success),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child:
                      Text(t.regSecurityReady, style: LuxTypography.bodyMedium),
                ),
              ],
            ),
          )
        else if (s == SecondFactorState.enrolledNotInSession)
          Text(t.regSecuritySignInAgain, style: LuxTypography.bodyMedium)
        else
          LuxButton(
            key: const ValueKey('reg-security-enroll'),
            label: t.regSecurityEnroll,
            onPressed: onEnrollMfa == null
                ? null
                : () async {
                    await onEnrollMfa!(context);
                    await cubit.refreshSecondFactor();
                  },
          ),
        const SizedBox(height: LuxSpacing.sm),
        if (s != SecondFactorState.inSession)
          LuxOutlinedButton(
            label: t.regSecurityCheck,
            onPressed: cubit.refreshSecondFactor,
          ),
        _StepActions(
          primary: t.regContinue,
          onPrimary: state.securityReady ? cubit.next : null,
        ),
      ],
    );
  }
}

// ── Resumen y envío ───────────────────────────────────────────────────────

class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key, required this.state});
  final RegistrationState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<RegistrationCubit>();
    final a = state.app;
    final required = a.requirements.where((r) => r.required).toList();
    final missing = a.missingRequired;
    Widget section(String title, RegistrationStep step, List<String> lines) =>
        LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: LuxTypography.titleMedium),
                    ),
                  ),
                  TextButton(
                    onPressed: () => cubit.goTo(step),
                    child: Text(t.regEdit),
                  ),
                ],
              ),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(top: LuxSpacing.xs),
                  child: Text(l, style: LuxTypography.bodyMedium),
                ),
            ],
          ),
        );
    final p = a.personal;
    final v = a.vehicle;
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        Text(t.regSummaryIntro, style: LuxTypography.bodyLarge),
        const SizedBox(height: LuxSpacing.md),
        section(t.regSummaryPersonal, RegistrationStep.personal, [
          if (p != null) ...[
            p.fullName,
            '${t.regLicenseExpiry}: ${LuxFormat.date(p.licenseExpiry)}',
          ],
        ]),
        const SizedBox(height: LuxSpacing.md),
        section(t.regSummaryVehicle, RegistrationStep.vehicle, [
          if (v != null) ...[
            '${v.make} ${v.model} · ${v.year}',
            '${v.colorLabel} · ${v.plate}',
          ],
        ]),
        const SizedBox(height: LuxSpacing.md),
        section(t.regStepDocuments, RegistrationStep.documents, [
          if (!a.requirementsConfigured)
            t.regDocsNotConfigured
          else ...[
            t.regSummaryDocs(required.length - missing.length, required.length),
            if (missing.isNotEmpty)
              t.regSummaryMissing(missing.map((m) => m.label).join(', ')),
          ],
        ]),
        if (p == null || v == null) ...[
          const SizedBox(height: LuxSpacing.md),
          Text(t.regSummaryIncomplete, style: LuxTypography.bodyMedium),
        ],
        if (state.mfaEnforced && !state.securityReady) ...[
          const SizedBox(height: LuxSpacing.md),
          Text(t.regSecurityNeededToSubmit, style: LuxTypography.bodyMedium),
        ],
        _StepActions(
          primary: t.regSubmit,
          loading: state.saving,
          onPrimary: state.canSubmit
              ? () async {
                  if (await cubit.submit() && context.mounted) {
                    showLuxSnackbar(context, t.regSubmitted);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
