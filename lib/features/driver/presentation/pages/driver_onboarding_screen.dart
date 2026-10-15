import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/sign_out.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/driver_bloc.dart';

/// Vencimiento de licencia "MM/AAAA" → último instante de ese mes, o null si
/// el texto no es válido.
DateTime? parseLicenseExpiry(String text) {
  final parts = text.trim().split('/');
  if (parts.length != 2) return null;
  final m = int.tryParse(parts[0]);
  final y = int.tryParse(parts[1]);
  if (m == null || y == null || m < 1 || m > 12 || y < 2000 || y > 2100) {
    return null;
  }
  return DateTime(y, m + 1).subtract(const Duration(milliseconds: 1));
}

/// Mensaje de error para el vencimiento, o null si es válido y vigente.
String? validateLicenseExpiry(String? v, {DateTime? now}) {
  if (v == null || v.trim().isEmpty) return 'Requerido';
  final expiry = parseLicenseExpiry(v);
  if (expiry == null) return 'Usa MM/AAAA, p. ej. 08/2027';
  if (expiry.isBefore(now ?? DateTime.now())) return 'Licencia vencida';
  return null;
}

// ---------------------------------------------------------------------------
// DriverOnboardingScreen
// Shown once when a driver account has no driverProfile + vehicle registered.
// ---------------------------------------------------------------------------

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  int _step = 0; // 0 = vehicle info, 1 = license info
  bool _saving = false;

  // Vehicle fields
  final _vehicleForm = GlobalKey<FormState>();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: '2024');
  final _plate = TextEditingController();
  final _color = TextEditingController(text: 'Negro');
  VehicleClass _vehicleClass = VehicleClass.business;

  // License fields
  final _licenseForm = GlobalKey<FormState>();
  final _licenseNumber = TextEditingController();
  final _licenseExpiry = TextEditingController();

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    _color.dispose();
    _licenseNumber.dispose();
    _licenseExpiry.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_licenseForm.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final driverId = authState.user.id;

    setState(() => _saving = true);
    try {
      final vehicles = sl<VehicleRepository>();
      final users = sl<UserRepository>();

      // 1. Vehículo (v_<uid>). Si ya existe de un intento anterior se
      // actualizan solo los datos que el chófer puede cambiar.
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
      final existingVehicle = (await vehicles.getVehicleById(vehicleId))
          .fold((_) => null, (v) => v);
      final vehicleResult = existingVehicle == null
          ? await vehicles.createVehicle(vehicle)
          : await vehicles.updateVehicle(Vehicle(
              id: vehicleId,
              driverId: driverId,
              make: vehicle.make,
              model: vehicle.model,
              year: vehicle.year,
              plate: vehicle.plate,
              // Clase, capacidad y estado los fija el admin una vez creado.
              vehicleClass: existingVehicle.vehicleClass,
              color: vehicle.color,
              photoUrl: existingVehicle.photoUrl,
              capacity: existingVehicle.capacity,
              isActive: existingVehicle.isActive,
            ));
      if (vehicleResult.isLeft()) {
        throw const _OnboardingError(
            'No pudimos guardar tu vehículo. Revisa tu conexión e inténtalo de nuevo.');
      }

      // 2. Perfil de chófer. La verificación, la valoración y los viajes no
      // se tocan si el perfil ya existía (solo los cambia un admin).
      final existing =
          (await users.getDriverProfile(driverId)).fold((_) => null, (p) => p);
      final profile = DriverProfile(
        userId: driverId,
        licenseNumber: _licenseNumber.text.trim().toUpperCase(),
        licenseExpiry: parseLicenseExpiry(_licenseExpiry.text)!,
        vehicleId: vehicleId,
        documentsVerified: existing?.documentsVerified ?? false,
        rating: existing?.rating ?? 0,
        totalRides: existing?.totalRides ?? 0,
        isAvailable: existing?.isAvailable ?? false,
        currentLocation: existing?.currentLocation,
      );
      final profileResult = await users.updateDriverProfile(profile);
      if (profileResult.isLeft()) {
        throw const _OnboardingError(
            'No pudimos guardar tu licencia. Revisa tu conexión e inténtalo de nuevo.');
      }

      if (!mounted) return;
      // Re-dispatch DriverStarted so the bloc reloads the profile
      // (it was in DriverOnboardingRequired — now the profile exists).
      context.read<DriverBloc>().add(DriverStarted(userId: driverId));
      context.go('/driver');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is _OnboardingError
                ? e.message
                : 'Algo salió mal. Inténtalo de nuevo.'),
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
      backgroundColor: LuxColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const LuxelaneWordmark(),
        actions: [
          TextButton(
            onPressed: () => signOut(context),
            child: Text('Cerrar sesión',
                style: LuxTypography.caption
                    .copyWith(color: LuxColors.inkTertiary)),
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
                const Text('Tu vehículo', style: LuxTypography.displayMedium),
                const SizedBox(height: LuxSpacing.xs),
                const Text('Registra el vehículo que vas a conducir.',
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
                  onClassChanged: (v) => setState(() => _vehicleClass = v),
                ),
                const SizedBox(height: LuxSpacing.xl),
                LuxButton(
                  label: 'Continuar',
                  onPressed: () {
                    if (_vehicleForm.currentState!.validate()) {
                      setState(() => _step = 1);
                    }
                  },
                ),
              ] else ...[
                const Text('Licencia de conducir',
                    style: LuxTypography.displayMedium),
                const SizedBox(height: LuxSpacing.xs),
                const Text(
                    'Tus documentos serán revisados antes de que puedas aceptar viajes.',
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
                    border:
                        Border.all(color: LuxColors.sapphire.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: LuxColors.sapphire, size: 18),
                      const SizedBox(width: LuxSpacing.sm),
                      Expanded(
                        child: Text(
                          'Un administrador verificará tus documentos antes de que puedas conectarte.',
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
                        label: 'Atrás',
                        onPressed: () => setState(() => _step = 0),
                      ),
                    ),
                    const SizedBox(width: LuxSpacing.md),
                    Expanded(
                      child: LuxButton(
                        label: 'Enviar',
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
  const _StepIndicator({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(totalSteps, (i) {
          final active = i == currentStep;
          final done = i < currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: done || active ? LuxColors.sapphire : LuxColors.border,
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
            const Text('Categoría del vehículo', style: LuxTypography.caption),
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
                          : LuxColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(LuxRadius.md),
                      border: Border.all(
                        color: sel ? LuxColors.sapphire : LuxColors.border,
                      ),
                    ),
                    child: Text(vc.label,
                        style: LuxTypography.bodyMedium.copyWith(
                          color: sel ? LuxColors.sapphire : LuxColors.ink,
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
                    label: 'Marca',
                    controller: make,
                    prefixIcon: Icons.directions_car_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: LuxTextField(
                    label: 'Modelo',
                    controller: model,
                    prefixIcon: Icons.car_repair_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
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
                    label: 'Placa',
                    controller: plate,
                    prefixIcon: Icons.credit_card_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9 -]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      final t = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                      if (t.isEmpty) return 'Requerido';
                      if (t.length < 5) return 'Placa inválida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: LuxTextField(
                    label: 'Año',
                    controller: year,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) {
                      final y = int.tryParse(v ?? '');
                      if (y == null ||
                          y < 2000 ||
                          y > DateTime.now().year + 1) {
                        return 'Inválido';
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
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
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
              label: 'Número de licencia',
              controller: licenseNumber,
              prefixIcon: Icons.badge_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              label: 'Fecha de vencimiento (MM/AAAA)',
              controller: licenseExpiry,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.calendar_today_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                LengthLimitingTextInputFormatter(7),
              ],
              validator: (v) => validateLicenseExpiry(v),
            ),
          ],
        ),
      );
}

class _OnboardingError implements Exception {
  const _OnboardingError(this.message);
  final String message;
}
