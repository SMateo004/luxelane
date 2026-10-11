import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/app_theme.dart';
import '../config/env.dart';
import '../models/place_model.dart';

// ignore_for_file: prefer_const_constructors

/// Ivory map style — the same light palette as the app (LD tokens):
/// pale ivory land, soft blue-grey roads, sapphire-tinted water.
const _kIvoryMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f2f5fb"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#637490"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#fafbfe"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#e8edf7"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e3eee8"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#637490"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dde4f0"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#8a98ae"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#dde4f0"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cfdcee"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2c3d55"}]}
]
''';

const _kDefaultCenter = LatLng(48.8566, 2.3522); // Paris

class LuxMap extends StatefulWidget {
  const LuxMap({
    super.key,
    this.origin,
    this.destination,
    this.routeInfo,
    this.driverLocation,
    this.onTap,
    this.lightStyle = false,
  });

  final Place? origin;
  final Place? destination;
  final RouteInfo? routeInfo;
  final LatLng? driverLocation;
  final void Function(LatLng)? onTap;

  /// Use the plain Google Maps style instead of the branded ivory style.
  final bool lightStyle;

  @override
  State<LuxMap> createState() => _LuxMapState();
}

class _LuxMapState extends State<LuxMap> {
  GoogleMapController? _controller;

  LatLng get _center {
    if (widget.origin != null) return widget.origin!.latLng;
    return _kDefaultCenter;
  }

  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final origin = await _drawCircleMarker(LuxColors.sapphireLight);
    final dest = await _drawCircleMarker(LuxColors.sapphireDark);
    if (mounted) {
      setState(() {
        _originIcon = origin;
        _destIcon = dest;
      });
    }
  }

  Future<BitmapDescriptor> _drawCircleMarker(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 14.0; // Ultra discrete

    // White border (outer circle)
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, whitePaint);

    // Inner color
    final Paint colorPaint = Paint()..color = color;
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 2, colorPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Set<Marker> get _markers {
    final Set<Marker> m = {};
    if (widget.origin != null) {
      m.add(Marker(
        markerId: const MarkerId('origin'),
        position: widget.origin!.latLng,
        icon: _originIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: widget.origin!.displayName),
      ));
    }
    if (widget.destination != null) {
      m.add(Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination!.latLng,
        icon: _destIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: widget.destination!.displayName),
      ));
    }
    return m;
  }

  Set<Polyline> get _polylines {
    if (widget.routeInfo == null || widget.routeInfo!.polylinePoints.isEmpty) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routeInfo!.polylinePoints,
        color: LuxColors.sapphire,
        width: 5,
      ),
    };
  }

  void _fitBounds() {
    if (_controller == null) return;
    if (widget.origin == null || widget.destination == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        [widget.origin!.lat, widget.destination!.lat]
            .reduce((a, b) => a < b ? a : b),
        [widget.origin!.lng, widget.destination!.lng]
            .reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        [widget.origin!.lat, widget.destination!.lat]
            .reduce((a, b) => a > b ? a : b),
        [widget.origin!.lng, widget.destination!.lng]
            .reduce((a, b) => a > b ? a : b),
      ),
    );
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _animateToDriver() {
    if (_controller == null || widget.driverLocation == null) return;
    _controller!.animateCamera(
      CameraUpdate.newLatLng(widget.driverLocation!),
    );
  }

  @override
  void didUpdateWidget(LuxMap old) {
    super.didUpdateWidget(old);
    if (old.origin != widget.origin || old.destination != widget.destination) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
    if (old.driverLocation != widget.driverLocation &&
        widget.origin == null &&
        widget.destination == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _animateToDriver());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.googleMapsKey.isEmpty) return _placeholder();

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 13),
      markers: _markers,
      polylines: _polylines,
      style: widget.lightStyle ? null : _kIvoryMapStyle,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (c) {
        _controller = c;
        _fitBounds();
      },
      onTap: widget.onTap,
    );
  }

  Widget _placeholder() => Container(
        color: LuxColors.surfaceMuted,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  color: LuxColors.inkTertiary, size: 48),
              const SizedBox(height: LuxSpacing.md),
              Text(
                widget.origin != null ? widget.origin!.displayName : 'Map view',
                style: LuxTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
