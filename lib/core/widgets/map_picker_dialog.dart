import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../di/injection.dart';
import '../models/place_model.dart';
import '../services/maps_service.dart';

/// Shows a full-screen map dialog where the user can drag the map
/// to select an exact pickup or destination point.
/// Returns a [Place] with coordinates, or null if cancelled.
Future<Place?> showMapPickerDialog(
  BuildContext context, {
  LatLng? initial,
  String title = 'Select location',
}) {
  return showDialog<Place>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _MapPickerDialog(
      initial: initial ??
          const LatLng(-17.7833, -63.1821), // Santa Cruz center
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
      _address = place?.address ?? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF141414);
    final textColor = isLight ? const Color(0xFF111111) : Colors.white;
    final subColor = isLight ? const Color(0xFF888888) : const Color(0xFF777777);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 700,
          height: 560,
          child: Stack(
            children: [
              // ── Map ────────────────────────────────────────────────────
              kIsWeb && false
                  // On web without Maps JS key, show placeholder
                  ? const _MapPlaceholder()
                  : GoogleMap(
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
                          style: TextStyle(
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
                        icon: Icon(Icons.close, color: subColor, size: 20),
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
                            Text(
                              'Selected location',
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
                              SizedBox(
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
                                style: TextStyle(
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
                            backgroundColor: const Color(0xFF111111),
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          child: const Text('CONFIRM'),
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
              color: const Color(0xFF111111),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Container(
            width: 1.5,
            height: 20,
            color: const Color(0xFF111111),
          ),
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Placeholder when Maps JS key is missing
// ---------------------------------------------------------------------------

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFE8E5DF),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Color(0xFFBBBBBB)),
              SizedBox(height: 12),
              Text(
                'Add GOOGLE_MAPS_KEY to enable map',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      );
}
