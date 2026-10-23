import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/app_theme.dart';
import '../config/env.dart';
import '../di/injection.dart';
import '../models/place_model.dart';
import '../services/maps_service.dart';
import 'lux_map.dart' show MapsKeyMissing;

/// Shows a full-screen map dialog where the user can drag the map
/// to select an exact pickup or destination point.
/// Returns a [Place] with coordinates, or null if cancelled.
Future<Place?> showMapPickerDialog(
  BuildContext context, {
  LatLng? initial,
  String title = 'Seleccionar ubicación',
}) {
  return showDialog<Place>(
    context: context,
    barrierColor: LuxColors.ink.withOpacity(0.35),
    builder: (_) => _MapPickerDialog(
      initial: initial ?? const LatLng(-17.7833, -63.1821), // Santa Cruz center
      title: title,
    ),
  );
}

// ---------------------------------------------------------------------------

class _MapPickerDialog extends StatefulWidget {
  const _MapPickerDialog({required this.initial, required this.title});
  final LatLng initial;
  final String title;

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  final _maps = sl<MapsService>();
  GoogleMapController? _ctrl;

  LatLng _center = const LatLng(-17.7833, -63.1821);
  String _address = 'Move the map to select a location';
  bool _loading = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
    _reverseGeocode(_center);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _loading = true);
    final place = await _maps.reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _address = place?.address ??
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      _loading = false;
    });
  }

  void _onCameraMove(CameraPosition pos) {
    _center = pos.target;
    if (!_dragging) setState(() => _dragging = true);
  }

  void _onCameraIdle() {
    setState(() => _dragging = false);
    _reverseGeocode(_center);
  }

  void _confirm() {
    Navigator.of(context).pop(
      Place(
        name: _address.split(',').first,
        address: _address,
        lat: _center.latitude,
        lng: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = LuxColors.surface;
    const textColor = LuxColors.ink;
    const subColor = LuxColors.inkTertiary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LuxRadius.lg),
        child: SizedBox(
          width: 700,
          height: 560,
          child: Stack(
            children: [
              // ── Map ────────────────────────────────────────────────────
              if (!AppConfig.hasMapsKey)
                const Positioned.fill(child: MapsKeyMissing())
              else
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 15,
                  ),
                  onMapCreated: (c) => _ctrl = c,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),

              // ── Center pin (stays fixed, map moves under it) ────────
              const Center(child: _CenterPin()),

              // ── Top bar ────────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: cardBg,
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: subColor,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom confirm bar ─────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: cardBg,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'UBICACIÓN SELECCIONADA',
                              style: TextStyle(
                                color: subColor,
                                fontSize: 10,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_loading)
                              const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.2,
                                  color: subColor,
                                ),
                              )
                            else
                              Text(
                                _address,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuxColors.sapphire,
                            foregroundColor: LuxColors.onAccent,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LuxRadius.md),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          child: const Text('CONFIRMAR'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Center pin widget (fixed overlay on top of the map)
// ---------------------------------------------------------------------------

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: LuxColors.sapphire,
              shape: BoxShape.circle,
              border: Border.all(color: LuxColors.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: LuxColors.ink.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Container(width: 1.5, height: 20, color: LuxColors.sapphire),
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: LuxColors.ink.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Placeholder when Maps JS key is missing
// ---------------------------------------------------------------------------
