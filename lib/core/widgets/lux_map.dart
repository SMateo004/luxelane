import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/app_theme.dart';
import '../config/env.dart';
import '../models/place_model.dart';
import '../services/maps_service.dart';
import '../utils/route_geometry.dart';

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

/// Calcula el recorrido entre dos lugares. Se puede sustituir en tests.
typedef RouteLoader = Future<RouteInfo?> Function(
    Place origin, Place destination);

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

  /// Cómo se calcula el recorrido cuando [routeInfo] no lo trae.
  @visibleForTesting
  static RouteLoader routeLoader = (origin, destination) =>
      MapsService().getRoute(origin: origin, destination: destination);

  /// Recorridos ya calculados, para no repetir la consulta al reconstruir.
  static final Map<String, RouteInfo> _routeCache = {};

  @visibleForTesting
  static void clearRouteCache() => _routeCache.clear();

  @override
  State<LuxMap> createState() => LuxMapState();
}

@visibleForTesting
class LuxMapState extends State<LuxMap> {
  GoogleMapController? _controller;

  /// Recorrido calculado aquí cuando el que llega no trae las calles.
  RouteInfo? _fetchedRoute;
  String? _fetchingKey;

  /// Recorrido que se dibuja: el recibido si es real, si no el calculado.
  @visibleForTesting
  RouteInfo? get route =>
      hasRoadPath(widget.routeInfo) ? widget.routeInfo : _fetchedRoute;

  /// Centro inicial: la recogida, el destino o, sin ninguno, Santa Cruz.
  @visibleForTesting
  LatLng get initialCenter =>
      widget.origin?.latLng ?? widget.destination?.latLng ?? kSantaCruzCenter;

  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _ensureRoute();
  }

  /// Si hay recogida y destino pero no el recorrido por calles, lo pide a
  /// Google (Directions) y lo guarda en caché.
  Future<void> _ensureRoute() async {
    final o = widget.origin, d = widget.destination;
    if (o == null || d == null || hasRoadPath(widget.routeInfo)) return;
    final key = routeKey(o, d);
    final cached = LuxMap._routeCache[key];
    if (cached != null) {
      _fetchedRoute = cached;
      return;
    }
    if (_fetchingKey == key) return;
    _fetchingKey = key;
    RouteInfo? r;
    try {
      r = await LuxMap.routeLoader(o, d);
    } catch (_) {
      r = null;
    }
    if (!mounted || _fetchingKey != key) return;
    _fetchingKey = null;
    if (!hasRoadPath(r)) return;
    LuxMap._routeCache[key] = r!;
    setState(() => _fetchedRoute = r);
    _fitBounds();
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
      const Offset(size / 2, size / 2),
      size / 2 - 2,
      colorPaint,
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Set<Marker> get _markers {
    final Set<Marker> m = {};
    if (widget.origin != null) {
      m.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin!.latLng,
          icon: _originIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(title: widget.origin!.displayName),
        ),
      );
    }
    if (widget.destination != null) {
      m.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!.latLng,
          icon: _destIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.destination!.displayName),
        ),
      );
    }
    return m;
  }

  Set<Polyline> get _polylines {
    final r = route;
    if (!hasRoadPath(r)) return {};
    // Borde blanco bajo la línea para que se lea sobre cualquier calle.
    return {
      Polyline(
        polylineId: const PolylineId('route-casing'),
        points: r!.polylinePoints,
        color: Colors.white,
        width: 8,
        zIndex: 1,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: r.polylinePoints,
        color: LuxColors.sapphire,
        width: 5,
        zIndex: 2,
      ),
    };
  }

  /// Puntos que la cámara debe encuadrar: marcadores y recorrido.
  @visibleForTesting
  List<LatLng> get framePoints => [
        if (widget.origin != null) widget.origin!.latLng,
        if (widget.destination != null) widget.destination!.latLng,
        ...?route?.polylinePoints,
      ];

  void _fitBounds([int attempt = 0]) {
    final c = _controller;
    if (c == null) return;
    if (widget.origin == null || widget.destination == null) return;
    final bounds = boundsOf(framePoints);
    if (bounds == null) return;
    // En web el mapa puede no tener tamaño aún justo al crearse: reintenta.
    void retry(Object _) {
      if (attempt < 3 && mounted) {
        Future.delayed(
          const Duration(milliseconds: 300),
          () => mounted ? _fitBounds(attempt + 1) : null,
        );
      }
    }

    try {
      c
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 48))
          .catchError(retry);
    } catch (e) {
      retry(e);
    }
  }

  void _animateToDriver() {
    if (_controller == null || widget.driverLocation == null) return;
    _controller!.animateCamera(CameraUpdate.newLatLng(widget.driverLocation!));
  }

  @override
  void didUpdateWidget(LuxMap old) {
    super.didUpdateWidget(old);
    if (old.origin != widget.origin || old.destination != widget.destination) {
      _fetchedRoute = null;
      _fetchingKey = null;
      _ensureRoute();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    } else if (old.routeInfo != widget.routeInfo) {
      _ensureRoute();
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
    if (!AppConfig.hasMapsKey) return const MapsKeyMissing();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialCenter,
        zoom: kCityZoom,
      ),
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Shown instead of a map when the app was built without a Google Maps key
/// (`GOOGLE_MAPS_KEY`), so a missing key is visible instead of a blank map.
/// La persona ve un texto neutro; la causa técnica va al registro al
/// arrancar («GOOGLE_MAPS_KEY is empty», E27).
const kMapUnavailableDetail =
    'El mapa no se puede mostrar ahora. Los datos del viaje siguen aquí.';

class MapsKeyMissing extends StatelessWidget {
  const MapsKeyMissing({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: LuxColors.surfaceMuted,
        padding: const EdgeInsets.all(LuxSpacing.md),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: LuxColors.inkTertiary, size: 40),
              SizedBox(height: LuxSpacing.sm),
              Text(
                'Mapa no disponible',
                style: LuxTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: LuxSpacing.xs),
              Text(
                kMapUnavailableDetail,
                style: LuxTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
