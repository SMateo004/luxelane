import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

// ---------------------------------------------------------------------------
// DriverOnboardingScreen
// Shown once when a driver account has no driverProfile + vehicle registered.
// ---------------------------------------------------------------------------

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() =>
      _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  int _step = 0; // 0 = vehicle info, 1 = license info
  bool _saving = false;

  // Vehicle fields
  final _vehicleForm   = GlobalKey<FormState>();
  final _make          = TextEditingController();
  final _model         = TextEditingController();
  final _year          = TextEditingController(text: '2024');
  final _plate         = TextEditingController();
  final _color         = TextEditingController(text: 'Black');
  VehicleClass _vehicleClass = VehicleClass.business;

  // License fields
  final _licenseForm   = GlobalKey<FormState>();
  final _licenseNumber = TextEditingController();
  final _licenseExpiry = TextEditingController();

  @override
  void dispose() {
    _make.dispose(); _model.dispose(); _year.dispose();
    _plate.dispose(); _color.dispose();
    _licenseNumber.dispose(); _licenseExpiry.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_licenseForm.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final driverId = authState.user.id;

    setState(() => _saving = true);
    try {
      // 1. Create vehicle document
      final vehicleId = 'v_$driverId';
      final vehicle = Vehicle(
        id: vehicleId,
        driverId: driverId,
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text.trim()) ?? 2024,
        plate: _plate.text.trim().toUpperCase(),
        vehicleClass: _vehicleClass,
        color: _color.text.trim(),
        capacity: _vehicleClass.capacity,
        isActive: true,
      );
      await sl<VehicleRepository>().createVehicle(vehicle);

      // 2. Create driverProfile document
      DateTime? expiry;
      try {
        final parts = _licenseExpiry.text.trim().split('/');
        if (parts.length == 2) {
          expiry = DateTime(
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}

      final profile = DriverProfile(
        userId: driverId,
        licenseNumber: _licenseNumber.text.trim(),
        licenseExpiry: expiry ?? DateTime(2030),
        vehicleId: vehicleId,
        documentsVerified: false, // admin must verify
        rating: 0,
        totalRides: 0,
        isAvailable: false,
      );
      await sl<UserRepository>().updateDriverProfile(profile);

      if (mounted) context.go('/driver');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: LuxColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxColors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const LuxelaneWordmark(),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
            child: Text('Sign out',
                style: LuxTypography.caption
                    .copyWith(color: LuxColors.whiteTertiary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress indicator ──────────────────────────────────
              _StepIndicator(currentStep: _step, totalSteps: 2),
              const SizedBox(height: LuxSpacing.xl),

              if (_step == 0) ...[
                const Text('Your vehicle',
                    style: LuxTypography.displayMedium),
                const SizedBox(height: LuxSpacing.xs),
                const Text('Register the vehicle you will be driving.',
                    style: LuxTypography.bodyMedium),
                const SizedBox(height: LuxSpacing.xl),
                _VehicleForm(
                  formKey: _vehicleForm,
                  make: _make,
                  model: _model,
                  year: _year,
                  plate: _plate,
                  color: _color,
                  vehicleClass: _vehicleClass,
                  onClassChanged: (v) =>
                      setState(() => _vehicleClass = v),
                ),
                const SizedBox(height: LuxSpacing.xl),
                LuxButton(
                  label: 'Continue',
                  onPressed: () {
                    if (_vehicleForm.currentState!.validate()) {
                      setState(() => _step = 1);
                    }
                  },
                ),
              ] else ...[
                const Text("Driver's license",
                    style: LuxTypography.displayMedium),
                const SizedBox(height: LuxSpacing.xs),
                const Text(
                    'Your documents will be reviewed before you can accept rides.',
                    style: LuxTypography.bodyMedium),
                const SizedBox(height: LuxSpacing.xl),
                _LicenseForm(
                  formKey: _licenseForm,
                  licenseNumber: _licenseNumber,
                  licenseExpiry: _licenseExpiry,
                ),
                const SizedBox(height: LuxSpacing.xl),
                // Pending-review notice
                Container(
                  padding: const EdgeInsets.all(LuxSpacing.md),
                  decoration: BoxDecoration(
                    color: LuxColors.sapphire.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(LuxRadius.md),
                    border: Border.all(
                        color: LuxColors.sapphire.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: LuxColors.sapphire, size: 18),
                      const SizedBox(width: LuxSpacing.sm),
                      Expanded(
                        child: Text(
                          'An admin will verify your documents before you can go online.',
                          style: LuxTypography.caption
                              .copyWith(color: LuxColors.sapphire),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LuxSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: LuxOutlinedButton(
                        label: 'Back',
                        onPressed: () => setState(() => _step = 0),
                      ),
                    ),
                    const SizedBox(width: LuxSpacing.md),
                    Expanded(
                      child: LuxButton(
                        label: 'Submit',
                        loading: _saving,
                        onPressed: _saving ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Indicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator(
      {required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(totalSteps, (i) {
          final active = i == currentStep;
          final done   = i < currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: done || active
                    ? LuxColors.sapphire
                    : LuxColors.blackBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      );
}

// ---------------------------------------------------------------------------
// Vehicle Form
// ---------------------------------------------------------------------------

class _VehicleForm extends StatelessWidget {
  const _VehicleForm({
    required this.formKey,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.vehicleClass,
    required this.onClassChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController make;
  final TextEditingController model;
  final TextEditingController year;
  final TextEditingController plate;
  final TextEditingController color;
  final VehicleClass vehicleClass;
  final ValueChanged<VehicleClass> onClassChanged;

  static const _classes = VehicleClass.values;

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle class selector
            const Text('Vehicle class', style: LuxTypography.caption),
            const SizedBox(height: LuxSpacing.sm),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: _classes.map((vc) {
                final sel = vc == vehicleClass;
                return GestureDetector(
                  onTap: () => onClassChanged(vc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: LuxSpacing.md, vertical: LuxSpacing.sm),
                    decoration: BoxDecoration(
                      color: sel
                          ? LuxColors.sapphire.withOpacity(0.15)
                          : LuxColors.blackElevated,
                      borderRadius: BorderRadius.circular(LuxRadius.md),
                      border: Border.all(
                        color: sel
                            ? LuxColors.sapphire
                            : LuxColors.blackBorder,
                      ),
                    ),
                    child: Text(vc.label,
                        style: LuxTypography.bodyMedium.copyWith(
                          color: sel
                              ? LuxColors.sapphire
                              : LuxColors.white,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: LuxSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: LuxTextField(
                    label: 'Make',
                    controller: make,
                    prefixIcon: Icons.directions_car_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: LuxTextField(
                    label: 'Model',
                    controller: model,
                    prefixIcon: Icons.car_repair_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.md),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: LuxTextField(
                    label: 'License plate',
                    controller: plate,
                    prefixIcon: Icons.credit_card_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: LuxTextField(
                    label: 'Year',
                    controller: year,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) {
                      final y = int.tryParse(v ?? '');
                      if (y == null || y < 2000 || y > 2030) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              label: 'Color',
              controller: color,
              prefixIcon: Icons.palette_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// License Form
// ---------------------------------------------------------------------------

class _LicenseForm extends StatelessWidget {
  const _LicenseForm({
    required this.formKey,
    required this.licenseNumber,
    required this.licenseExpiry,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController licenseNumber;
  final TextEditingController licenseExpiry;

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          children: [
            LuxTextField(
              label: 'License number',
              controller: licenseNumber,
              prefixIcon: Icons.badge_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              label: 'Expiry date (MM/YYYY)',
              controller: licenseExpiry,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.calendar_today_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                LengthLimitingTextInputFormatter(7),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final parts = v.split('/');
                if (parts.length != 2) return 'Use MM/YYYY';
                final m = int.tryParse(parts[0]);
                final y = int.tryParse(parts[1]);
                if (m == null || m < 1 || m > 12) return 'Invalid month';
                if (y == null || y < 2024) return 'License expired';
                return null;
              },
            ),
          ],
        ),
      );
}
