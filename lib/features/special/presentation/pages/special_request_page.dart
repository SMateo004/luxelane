import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/special_repository.dart';
import '../../domain/special_models.dart';

/// /especiales/aerotaxi y /especiales/paseo — solicitud de cotización.
/// Formulario corto, con valores por defecto sensatos para no hacer pensar.
class SpecialRequestPage extends StatefulWidget {
  const SpecialRequestPage({super.key, required this.kind});
  final SpecialKind kind;

  @override
  State<SpecialRequestPage> createState() => _SpecialRequestPageState();
}

class _SpecialRequestPageState extends State<SpecialRequestPage> {
  final _form = GlobalKey<FormState>();
  final _pickup = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();

  String _from = 'Santa Cruz';
  String? _to;
  late DateTime _date = _defaultDate();
  int _passengers = 1;
  int _hours = 3;
  String _language = 'es';
  bool _sending = false;
  bool _sent = false;

  bool get _aero => widget.kind == SpecialKind.aerotaxi;

  /// Mañana a las 10:00: un aerotaxi o un paseo rara vez es para ya.
  static DateTime _defaultDate() {
    final t = DateTime.now().add(const Duration(days: 1));
    return DateTime(t.year, t.month, t.day, 10);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthBloc>().state;
    if (_phone.text.isEmpty && auth is AuthAuthenticated) {
      _phone.text = auth.user.phone;
    }
  }

  @override
  void dispose() {
    _pickup.dispose();
    _notes.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Fecha del servicio',
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      helpText: 'Hora aproximada',
    );
    if (!mounted) return;
    setState(() {
      final time = t ?? TimeOfDay.fromDateTime(_date);
      _date = DateTime(d.year, d.month, d.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      // Tras iniciar sesión vuelve aquí, sin perder lo que estaba pidiendo.
      context.go(Uri(
              path: '/login',
              queryParameters: {'from': '/especiales/${widget.kind.slug}'})
          .toString());
      return;
    }
    if (_sending || !_form.currentState!.validate()) return;
    if (_aero && (_to == null || _to == _from)) {
      showLuxSnackbar(context, 'Elige un destino distinto del origen.',
          isError: true);
      return;
    }
    if (!_date.isAfter(DateTime.now().add(const Duration(minutes: 30)))) {
      showLuxSnackbar(context, 'Elige una fecha y hora futuras.',
          isError: true);
      return;
    }
    setState(() => _sending = true);
    final u = auth.user;
    final r =
        await sl<SpecialRepository>().create(SpecialRequest.newRequestJson(
      riderId: u.id,
      riderName: u.displayName,
      riderEmail: u.email,
      riderPhone: _phone.text.trim(),
      kind: widget.kind,
      date: _date,
      passengers: _passengers,
      from: _aero ? _from : null,
      to: _aero ? _to : null,
      pickup: _aero ? null : _pickup.text.trim(),
      durationHours: _aero ? null : _hours,
      language: _aero ? null : _language,
      notes: _notes.text,
    ));
    if (!mounted) return;
    setState(() => _sending = false);
    r.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthBloc>().state is AuthAuthenticated;
    return Scaffold(
      backgroundColor: LuxColors.bg,
      appBar: AppBar(
        title: Text(widget.kind.label),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md, LuxSpacing.lg, LuxSpacing.md, LuxSpacing.xxl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _sent ? _sentView() : _formView(signedIn),
          ),
        ),
      ),
    );
  }

  Widget _sentView() => LuxCard(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: LuxColors.success, size: 32),
            const SizedBox(height: 12),
            const Text('Solicitud enviada', style: LuxTypography.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Te enviaremos la cotización en menos de 24 horas. '
              'La verás en "Mis solicitudes" y te avisaremos.',
              style: LuxTypography.bodyMedium
                  .copyWith(color: LuxColors.inkSecondary),
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxButton(
                label: 'Ver mis solicitudes',
                onPressed: () => context.go('/especiales')),
            const SizedBox(height: 8),
            LuxOutlinedButton(
                label: 'Volver al inicio', onPressed: () => context.go('/')),
          ],
        ),
      );

  Widget _formView(bool signedIn) => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SERVICIO ESPECIAL · BAJO COTIZACIÓN',
                style: LuxTypography.caption.copyWith(letterSpacing: 1.6)),
            const SizedBox(height: 8),
            Text(widget.kind.tagline, style: LuxTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(widget.kind.lead,
                style: LuxTypography.bodyMedium
                    .copyWith(color: LuxColors.inkSecondary)),
            const SizedBox(height: LuxSpacing.lg),
            LuxCard(
              padding: const EdgeInsets.all(LuxSpacing.md + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_aero) ..._aeroFields() else ..._tourFields(),
                  const SizedBox(height: LuxSpacing.md),
                  _Label('Fecha y hora'),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(LuxFormat.dateTime(_date)),
                    style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14)),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  _Label('Pasajeros'),
                  _Stepper(
                    value: _passengers,
                    min: 1,
                    max: _aero ? 6 : 12,
                    onChanged: (v) => setState(() => _passengers = v),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  LuxTextField(
                    label: 'Teléfono de contacto',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: LuxValidators.phone,
                  ),
                  const SizedBox(height: 12),
                  LuxTextField(
                    label: _aero
                        ? 'Notas (equipaje, horario flexible…)'
                        : 'Qué te gustaría ver (opcional)',
                    controller: _notes,
                    maxLines: 3,
                    validator: (v) =>
                        (v ?? '').length > 500 ? 'Máximo 500 caracteres' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuxSpacing.md),
            Text(
              _aero
                  ? 'Sujeto a disponibilidad de aeronave y a las condiciones '
                      'meteorológicas. No se cobra nada hasta que aceptes la '
                      'cotización.'
                  : 'No se cobra nada hasta que aceptes la cotización.',
              style: LuxTypography.caption,
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxButton(
              label: signedIn
                  ? 'Solicitar cotización'
                  : 'Inicia sesión para solicitar',
              loading: _sending,
              onPressed: _sending ? null : _submit,
            ),
          ],
        ),
      );

  List<Widget> _aeroFields() => [
        _Label('Desde'),
        _CityDropdown(
          value: _from,
          onChanged: (v) => setState(() {
            _from = v;
            if (_to == v) _to = null;
          }),
        ),
        const SizedBox(height: LuxSpacing.md),
        _Label('Hacia'),
        _CityDropdown(
          value: _to,
          exclude: _from,
          hint: 'Elige el destino',
          onChanged: (v) => setState(() => _to = v),
        ),
      ];

  List<Widget> _tourFields() => [
        LuxTextField(
          label: 'Punto de recogida (hotel, dirección…)',
          controller: _pickup,
          prefixIcon: Icons.place_outlined,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.length < 3) return 'Indica dónde te recogemos';
            if (t.length > 120) return 'Máximo 120 caracteres';
            return null;
          },
        ),
        const SizedBox(height: LuxSpacing.md),
        _Label('Duración'),
        Wrap(spacing: 8, children: [
          for (final h in kTourDurations)
            ChoiceChip(
              label: Text('$h h'),
              selected: _hours == h,
              onSelected: (_) => setState(() => _hours = h),
            ),
        ]),
        const SizedBox(height: LuxSpacing.md),
        _Label('Idioma del chófer'),
        Wrap(spacing: 8, children: [
          for (final e in kTourLanguages.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _language == e.key,
              onSelected: (_) => setState(() => _language = e.key),
            ),
        ]),
      ];
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                LuxTypography.caption.copyWith(color: LuxColors.inkSecondary)),
      );
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.value,
    required this.onChanged,
    this.exclude,
    this.hint,
  });
  final String? value;
  final String? exclude;
  final String? hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: hint == null ? null : Text(hint!),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.flight_outlined, size: 18),
          isDense: true,
        ),
        items: [
          for (final c in kAerotaxiCities)
            if (c != exclude) DropdownMenuItem(value: c, child: Text(c)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        IconButton.outlined(
          tooltip: 'Menos pasajeros',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        SizedBox(
          width: 48,
          child: Text('$value',
              textAlign: TextAlign.center, style: LuxTypography.titleMedium),
        ),
        IconButton.outlined(
          tooltip: 'Más pasajeros',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ]);
}
