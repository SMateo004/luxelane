import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../features/home/presentation/pages/home_design.dart';
import '../design/lux_promise.dart';
import '../di/injection.dart';
import '../enums/enums.dart';
import '../models/booking_form_data.dart';
import '../models/place_model.dart';
import '../services/maps_service.dart';
import '../utils/lux_format.dart';
import 'map_picker_dialog.dart';
import 'place_autocomplete_field.dart';

/// How the booking card is pre-configured for each service page.
enum LuxBookingMode {
  /// Airport transfers: one-way or by-the-hour, scheduled.
  airport,
  /// Chauffeur by the hour: duration first, destination optional.
  hourly,
  /// Immediate pickup: "now" by default, can be scheduled.
  immediate,
}

/// Functional booking widget for the service pages.
///
/// Collects the same data as the home search and hands off to `/booking`
/// with a [BookingFormData], so every entry point leads to the same flow.
/// Design intent: few fields, sensible defaults, and the reassurance a
/// first-time luxury client needs exactly where they commit.
class LuxServiceBookingCard extends StatefulWidget {
  const LuxServiceBookingCard({super.key, required this.mode});
  final LuxBookingMode mode;

  @override
  State<LuxServiceBookingCard> createState() => _LuxServiceBookingCardState();
}

class _LuxServiceBookingCardState extends State<LuxServiceBookingCard> {
  static const _santaCruz = LatLng(-17.7833, -63.1821);

  late ServiceType _service;
  Place? _origin;
  Place? _destination;
  late DateTime _date;
  bool _asap = false;
  int _hours = 3;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.mode == LuxBookingMode.hourly
        ? ServiceType.byTheHour
        : ServiceType.oneWay;
    _asap = widget.mode == LuxBookingMode.immediate;
    _date = _defaultDate();
  }

  DateTime _defaultDate() => LuxFormat.nextQuarter();

  bool get _needsDestination => _service == ServiceType.oneWay;

  Future<void> _pickFromMap({required bool origin}) async {
    final current = origin ? _origin : _destination;
    final picked = await showMapPickerDialog(
      context,
      initial: current != null ? LatLng(current.lat, current.lng) : _santaCruz,
      title: origin ? 'Seleccionar lugar de recogida' : 'Seleccionar destino',
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (origin) {
        _origin = picked;
      } else {
        _destination = picked;
      }
      _error = null;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'FECHA DE RECOGIDA',
      cancelText: 'Cancelar',
      confirmText: 'Siguiente',
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      helpText: 'HORA DE RECOGIDA',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (t == null || !mounted) return;
    var picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (picked.isBefore(now.add(const Duration(minutes: 30)))) {
      picked = now.add(const Duration(minutes: 30));
    }
    setState(() {
      _date = picked;
      _asap = false;
    });
  }

  Future<void> _submit() async {
    if (_origin == null) {
      setState(() => _error = 'Indica dónde te recogemos.');
      return;
    }
    if (_needsDestination && _destination == null) {
      setState(() => _error = 'Indica tu destino para calcular el precio fijo.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });

    RouteInfo? route;
    if (_destination != null) {
      try {
        route = await sl<MapsService>()
            .getRoute(origin: _origin!, destination: _destination!);
      } catch (_) {
        route = null; // Price falls back to the booking screen's estimate.
      }
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    context.go(
      '/booking',
      extra: BookingFormData(
        origin: _origin!,
        destination: _destination,
        serviceType: _service,
        scheduledAt: _asap ? DateTime.now().add(const Duration(minutes: 15)) : _date,
        hours: _hours,
        routeDistanceKm: route?.distanceKm ?? 0,
        routeDurationMin: route?.durationMin ?? 0,
        polylinePoints: route?.polylinePoints ?? const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final airport = widget.mode == LuxBookingMode.airport;
    final originHint = airport
        ? 'Recogida — aeropuerto, hotel o dirección'
        : 'Recogida — dirección, hotel o lugar';
    final destHint = airport
        ? 'Destino — aeropuerto, hotel o dirección'
        : _service == ServiceType.byTheHour
            ? 'Destino (opcional)'
            : 'Destino — dirección, hotel o lugar';

    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1220),
          border: Border.all(color: const Color(0xFF1A2B40)),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 40, offset: Offset(0, 24)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('RESERVA TU CHÓFER',
                style: uiLabel(size: 10, color: const Color(0xFF8CB2E3), spacing: 3)),
            const SizedBox(height: 18),

            if (widget.mode != LuxBookingMode.immediate) ...[
              _Segmented(
                options: const ['Solo ida', 'Por horas'],
                index: _service == ServiceType.oneWay ? 0 : 1,
                onChanged: (i) => setState(() {
                  _service = i == 0 ? ServiceType.oneWay : ServiceType.byTheHour;
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
            ],

            PlaceAutocompleteField(
              label: 'Recogida',
              hint: originHint,
              prefixIcon: Icons.trip_origin_rounded,
              initialValue: _origin,
              onPlaceSelected: (p) => setState(() {
                _origin = p;
                _error = null;
              }),
              onMapPick: () => _pickFromMap(origin: true),
            ),
            _MapLink(onTap: () => _pickFromMap(origin: true)),
            PlaceAutocompleteField(
              label: 'Destino',
              hint: destHint,
              prefixIcon: Icons.place_outlined,
              initialValue: _destination,
              onPlaceSelected: (p) => setState(() {
                _destination = p;
                _error = null;
              }),
              onMapPick: () => _pickFromMap(origin: false),
            ),
            _MapLink(onTap: () => _pickFromMap(origin: false)),

            if (widget.mode == LuxBookingMode.immediate) ...[
              _Segmented(
                options: const ['Ahora', 'Programar'],
                index: _asap ? 0 : 1,
                onChanged: (i) {
                  if (i == 0) {
                    setState(() => _asap = true);
                  } else {
                    _pickDateTime();
                  }
                },
              ),
              const SizedBox(height: 12),
            ],

            if (!_asap) ...[
              _FieldTile(
                icon: Icons.event_outlined,
                label: _formatDate(_date),
                trailing: 'Cambiar',
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
            ],

            if (_service == ServiceType.byTheHour) ...[
              _HoursStepper(
                hours: _hours,
                onChanged: (h) => setState(() => _hours = h),
              ),
              const SizedBox(height: 12),
            ],

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFE59A9A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: uiLabel(size: 12, color: const Color(0xFFE59A9A), spacing: 0.2)),
                        ),
                      ]),
                    ),
            ),

            const SizedBox(height: 4),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LD.sph,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: LD.sph.withAlpha(140),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('VER VEHÍCULOS Y PRECIOS',
                              style: TextStyle(fontFamily: kSans, fontSize: 11,
                                  fontWeight: FontWeight.w600, letterSpacing: 1.8)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Lowers the perceived commitment of the first click.
            Text(
              'Sin compromiso: verás el precio final antes de confirmar.',
              textAlign: TextAlign.center,
              style: uiLabel(size: 11, color: Colors.white.withAlpha(130), spacing: 0.2),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withAlpha(20)),
            const SizedBox(height: 18),
            _Assurance(LuxPromise.fixedPrice),
            _Assurance(LuxPromise.freeCancel),
            _Assurance(airport ? LuxPromise.waitAirport : LuxPromise.waitStandard),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => LuxFormat.dateTime(d);
}

// ── Pieces ──────────────────────────────────────────────────────────────────

class _Segmented extends StatelessWidget {
  const _Segmented({required this.options, required this.index, required this.onChanged});
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF070E18),
          border: Border.all(color: const Color(0xFF1A2B40)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == index,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.center,
                        color: i == index ? LD.sph : Colors.transparent,
                        child: Text(
                          options[i].toUpperCase(),
                          style: uiLabel(
                            size: 10,
                            spacing: 1.6,
                            color: i == index ? Colors.white : Colors.white.withAlpha(140),
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _MapLink extends StatelessWidget {
  const _MapLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: Colors.white.withAlpha(140),
          ),
          icon: const Icon(Icons.map_outlined, size: 13),
          label: Text('Elegir en el mapa',
              style: uiLabel(size: 10.5, color: Colors.white.withAlpha(140), spacing: 0.3)),
        ),
      );
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.icon, required this.label, required this.onTap, this.trailing});
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1928),
            border: Border.all(color: const Color(0xFF1A2B40)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: Colors.white.withAlpha(150)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontFamily: kSans, fontSize: 13, color: Colors.white)),
            ),
            if (trailing != null)
              Text(trailing!.toUpperCase(),
                  style: uiLabel(size: 9.5, color: const Color(0xFF8CB2E3), spacing: 1.4)),
          ]),
        ),
      );
}

class _HoursStepper extends StatelessWidget {
  const _HoursStepper({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback? f, String tip) => IconButton(
          tooltip: tip,
          onPressed: f,
          icon: Icon(i, size: 16),
          color: Colors.white,
          disabledColor: Colors.white24,
        );
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1928),
        border: Border.all(color: const Color(0xFF1A2B40)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(children: [
        Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.white.withAlpha(150)),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Duración',
              style: TextStyle(fontFamily: kSans, fontSize: 13, color: Colors.white)),
        ),
        btn(Icons.remove_rounded, hours > 2 ? () => onChanged(hours - 1) : null, 'Menos horas'),
        SizedBox(
          width: 44,
          child: Text('$hours h',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kSans, fontSize: 13,
                  fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        btn(Icons.add_rounded, hours < 24 ? () => onChanged(hours + 1) : null, 'Más horas'),
      ]),
    );
  }
}

class _Assurance extends StatelessWidget {
  const _Assurance(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF8CB2E3)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: uiLabel(size: 11.5, color: Colors.white.withAlpha(170), spacing: 0.2)),
          ),
        ]),
      );
}
