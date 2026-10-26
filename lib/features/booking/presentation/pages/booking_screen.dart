import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/config/remote_flags.dart';
import '../../../../core/design/lux_promise.dart';
import '../../../../core/design/vehicle_catalog.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/pricing_catalog.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/utils/service_area.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/email_not_verified_dialog.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../../core/widgets/lux_raised.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/google_sign_in_button.dart';
import '../../../auth/presentation/widgets/terms_required_dialog.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../../payments/presentation/bloc/payment_bloc.dart';
import '../bloc/booking_bloc.dart';
import '../widgets/vehicle_details.dart';
import '../widgets/vehicle_visuals.dart';

// Classes offered right now (First Class only when the admin enables it).
List<VehicleClass> get _kVehicleClasses => VehicleCatalog.bookable(
      firstClassEnabled: RemoteFlags.instance.firstClassEnabled.value,
    );

// ── Luxelane design tokens (mirrors home_design.dart LD class) ─────────────────
const _kBg = LD.bg; // #FAFBFE
const _kCardBg = Colors.white;
const _kBorder = LD.border; // #DDE4F0
const _kTextPrimary = LD.ink; // #0D1B2E
const _kTextSub = LD.ink2; // #2C3D55
const _kTextTertiary = LD.ink3; // #5B6B84
const _kDivider = LD.border; // #DDE4F0
const _kPanelAccent = LD.sph; // #1B4F8A sapphire

/// Precio para mostrar, o «Cotiza al reservar» si no hay tarifa
/// configurada: nunca una cifra inventada.
String formatPriceOrQuote(double? price, {bool from = false}) => price == null
    ? 'Cotiza al reservar'
    : '${from ? 'desde ' : ''}${LuxFormat.money(price)}';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

/// Corner radius shared by the phone layout's cards and fields, matching the
/// rounded summary card on desktop.
const double _kMobileRadius = 14;

class _BookingScreenState extends State<BookingScreen> {
  BookingFormData? _formData;
  VehicleClass _selected = VehicleClass.business;
  ServiceType _service = ServiceType.oneWay;
  int _hours = 3;
  bool _loading = false;
  int _step = 0; // mobile only

  int _passengers = 1;
  int _luggage = 0;
  String _notes = '';
  String _flight = '';
  FlightType? _flightType;
  bool _flightAttempted = false; // show the flight errors only after a try
  bool _bookForSelf = true;
  int _capacityTab = 0; // 0 = Luggage, 1 = Seating
  int _luggageOption = 0; // 0, 1, 2
  int _seatingOption = 0; // 0, 1, 2, 3
  String _guestTitle = 'Sr.';
  String _guestFirstName = '';
  String _guestLastName = '';
  String _guestPhone = '';
  String _guestLanguage = '';

  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedCardId;
  bool _awaitingPaymentIntent = false;
  bool _payByCard = false;
  String? _pendingBookingId;

  // Scroll-based sticky selector
  final ScrollController _leftScrollCtrl = ScrollController();
  bool _showStickySelector = false;

  // Approximate offset at which the vehicle cards scroll out of view:
  // heading (~110px) + 28px gap + 430px cards + 28px gap ≈ 596px
  static const double _kStickyThreshold = 420.0;

  /// Narrowest window that shows cards and summary side by side.
  static const double _kSplitMinWidth = 1100;

  final ScrollController _cardsCtrl = ScrollController();

  /// Distancia por calles ya conocida, o 0 si no la hay: nunca se inventa.
  double get _km =>
      _formData?.routeDistanceKm != null && _formData!.routeDistanceKm > 0
          ? _formData!.routeDistanceKm
          : 0;

  /// Sin ruta, un traslado solo puede mostrar el precio mínimo ("desde").
  bool get _priceIsFrom => _service == ServiceType.oneWay && _km == 0;

  /// Precio orientativo (solo visual) de las tarjetas: con la tarifa local
  /// de PricingCatalog. El que se cobra lo calcula el servidor.
  double? _cardPrice(VehicleClass vc) =>
      PricingCatalog.instance.estimate(vc, _service, km: _km, hours: _hours);

  // ── Precio del servidor (quoteBooking) ─────────────────────────────────
  // Se pide al llegar al resumen (en web el resumen siempre está a la
  // vista), con espera para no llamar a cada cambio.
  BookingQuote? _quote;
  String? _quoteKey;
  String? _requestedQuoteKey;
  String? _quoteError;
  Timer? _quoteTimer;

  String get _currentQuoteKey => [
        _selected.name,
        _service.name,
        _hours,
        _formData?.origin.lat,
        _formData?.origin.lng,
        _formData?.destination?.lat,
        _formData?.destination?.lng,
        _formData?.scheduledAt.millisecondsSinceEpoch,
      ].join('|');

  /// Cotización vigente para la selección actual, o null.
  BookingQuote? get _freshQuote =>
      _quoteKey == _currentQuoteKey ? _quote : null;

  /// Lo que se muestra y se envía como quotedPrice: el precio del servidor
  /// si ya llegó; si no (p. ej. sin sesión), la estimación local, que el
  /// servidor confirma al reservar.
  double? get _price => _freshQuote?.price ?? _cardPrice(_selected);

  /// El precio a la vista es el del servidor (E35). Mientras no llega (sin
  /// sesión, cargando o con error) se marca como estimado.
  bool get _priceIsServer => _freshQuote != null;

  /// Vuelve a pedir la cotización tras un error (E36).
  void _retryQuote() => setState(() {
        _quoteError = null;
        _requestedQuoteKey = null;
      });

  void _maybeQuote() {
    final auth = context.read<AuthBloc>().state;
    // En todos los pasos (E35): el precio de la barra es el del servidor.
    if (_formData == null || auth is! AuthAuthenticated) return;
    final key = _currentQuoteKey;
    if (key == _requestedQuoteKey) return;
    _requestedQuoteKey = key;
    _quoteTimer?.cancel();
    _quoteTimer = Timer(
      const Duration(milliseconds: 600),
      () => _fetchQuote(key),
    );
  }

  Future<void> _fetchQuote(String key) async {
    final trip = _tripFor(_selected);
    if (trip == null) return;
    final result = await sl<BookingRepository>().quoteBooking(trip);
    if (!mounted || key != _currentQuoteKey) return;
    setState(
      () => result.fold(
        (f) {
          _quoteError = f.message;
          _quote = null;
          _quoteKey = null;
          if (f is AppUpdateRequiredFailure) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => mounted ? AppUpdateDialog.show(context, f) : null,
            );
          }
        },
        (q) {
          _quoteError = null;
          _quote = q;
          _quoteKey = key;
        },
      ),
    );
  }

  /// El viaje tal como se cotiza y se reserva (sin datos personales).
  Booking? _tripFor(VehicleClass vc) {
    final data = _formData;
    if (data == null) return null;
    final now = DateTime.now();
    return Booking(
      id: '',
      riderId: '',
      origin: data.origin,
      destination: data.destination ?? data.origin,
      scheduledAt: data.scheduledAt,
      vehicleClass: vc,
      serviceType: _service,
      status: BookingStatus.pending,
      estimatedPrice: 0,
      createdAt: now,
      updatedAt: now,
      hours: _service == ServiceType.byTheHour ? _hours : null,
    );
  }

  // Identificador del intento de reserva (requestId): se reutiliza en los
  // reintentos tras un error o un cambio de precio, y se renueva tras
  // reservar o si cambia el viaje.
  String? _requestId;
  String? _requestIdKey;

  String get _attemptId {
    final key = _currentQuoteKey;
    if (_requestId == null || _requestIdKey != key) {
      _requestId = const Uuid().v4();
      _requestIdKey = key;
    }
    return _requestId!;
  }

  Future<void> _confirmNewPrice(BookingPriceChanged state) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('El precio cambió'),
        content: Text(
          'El precio de este viaje es ahora '
          '${LuxFormat.money(state.newPrice)} '
          '(antes ${LuxFormat.money(state.previousPrice)}). '
          '¿Quieres reservar con el precio nuevo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No reservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reservar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _quote = BookingQuote(price: state.newPrice);
      _quoteKey = _currentQuoteKey;
      _loading = ok == true;
    });
    if (ok == true) {
      context.read<BookingBloc>().add(
            state.request.withQuotedPrice(state.newPrice),
          );
    }
  }

  void _onPricingChanged() {
    if (mounted) setState(() {});
  }

  /// Airport pickups need the flight number so the driver can follow it.
  bool get _airportPickup =>
      _formData != null && ServiceArea.isAirport(_formData!.origin);

  String? get _flightError {
    if (!_airportPickup && _flight.trim().isEmpty) return null;
    return FlightNumber.error(_flight);
  }

  String? get _flightTypeError => _airportPickup && _flightType == null
      ? 'Indica si tu vuelo es nacional o internacional.'
      : null;

  bool _checkFlight() {
    final error = _flightError ?? _flightTypeError;
    if (error == null) return true;
    setState(() => _flightAttempted = true);
    showLuxSnackbar(context, error, isError: true);
    return false;
  }

  @override
  void initState() {
    super.initState();
    PricingCatalog.instance.addListener(_onPricingChanged);
    _leftScrollCtrl.addListener(() {
      final show = _leftScrollCtrl.offset > _kStickyThreshold;
      if (show != _showStickySelector) {
        setState(() => _showStickySelector = show);
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    PricingCatalog.instance.removeListener(_onPricingChanged);
    _leftScrollCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formData == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is BookingFormData) {
        _formData = extra;
        _service = extra.serviceType;
        if (extra.preferredClass != null &&
            _kVehicleClasses.contains(extra.preferredClass)) {
          _selected = extra.preferredClass!;
        }
        _hours = extra.hours;
        _ensureRoute();
      }
      _loadSavedCards();
    }
  }

  /// Si la reserva llega sin el recorrido por calles (p. ej. al recargar la
  /// página, o si falló al calcularlo antes), lo calcula aquí: el mapa lo
  /// dibuja y el precio usa los km reales en lugar de una estimación.
  Future<void> _ensureRoute() async {
    final data = _formData;
    final dest = data?.destination;
    if (data == null || dest == null) return;
    if (data.polylinePoints.length > 2 && data.routeDistanceKm > 0) return;
    RouteInfo? route;
    try {
      route = await sl<MapsService>().getRoute(
        origin: data.origin,
        destination: dest,
      );
    } catch (_) {
      route = null;
    }
    if (!mounted || route == null || route.polylinePoints.length <= 2) return;
    if (_formData != data) return; // cambió mientras se calculaba
    setState(() => _formData = data.withRoute(route!));
  }

  /// Recorrido de la reserva para el mapa (null si aún no se tiene).
  RouteInfo? get _routeInfo {
    final d = _formData;
    if (d == null || d.polylinePoints.length <= 2) return null;
    return RouteInfo(
      polylinePoints: d.polylinePoints,
      distanceKm: d.routeDistanceKm,
      durationMin: d.routeDurationMin,
    );
  }

  /// El pago con tarjeta usa el SDK nativo de Stripe, que no existe en web.
  static bool get _cardsSupported => !kIsWeb;

  void _loadSavedCards() {
    if (!_cardsSupported) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        authState.user.stripeCustomerId != null &&
        authState.user.stripeCustomerId!.isNotEmpty) {
      context.read<PaymentBloc>().add(
            CardsLoadRequested(
                stripeCustomerId: authState.user.stripeCustomerId!),
          );
    }
  }

  Future<void> _confirm() async {
    if (!_checkFlight()) {
      if (!isWeb(context)) setState(() => _step = 1);
      return;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      // Guests sign in (Google or email) without leaving their booking.
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: const _AuthGateDialog(),
        ),
      );
      if (ok != true || !mounted) return;
      final freshAuth = context.read<AuthBloc>().state;
      if (freshAuth is! AuthAuthenticated) return;
    }
    final freshState = context.read<AuthBloc>().state;
    if (freshState is! AuthAuthenticated) return;
    if (_formData == null) {
      // Sin recogida (recarga de página, enlace directo…): no se inventa
      // un lugar; se vuelve a empezar la búsqueda.
      showLuxSnackbar(
        context,
        'Vuelve a indicar tu recogida para reservar.',
        isError: true,
      );
      context.go('/');
      return;
    }
    final blocked = PricingCatalog.instance.unavailableReason(
      _selected,
      _service,
    );
    if (blocked != null) {
      showLuxSnackbar(context, blocked, isError: true);
      return;
    }
    if (_formData!.scheduledAt.isBefore(
      DateTime.now().subtract(const Duration(minutes: 5)),
    )) {
      showLuxSnackbar(
        context,
        'La hora de recogida ya pasó. Elige una nueva hora.',
        isError: true,
      );
      context.go('/');
      return;
    }
    // Nunca se reserva sin que el pasajero haya visto el precio del
    // servidor (p. ej. quien inició sesión al reservar, o sin tarifa local).
    if (_freshQuote == null) {
      setState(() => _loading = true);
      await _fetchQuote(_currentQuoteKey);
      if (!mounted) return;
      setState(() => _loading = false);
      final quote = _freshQuote;
      showLuxSnackbar(
        context,
        quote == null
            ? (_quoteError ??
                'No pudimos calcular el precio. Inténtalo de nuevo.')
            : 'El precio de tu viaje es ${LuxFormat.money(quote.price)}. '
                'Pulsa Reservar para confirmar.',
        isError: quote == null,
      );
      return;
    }
    // La reserva se crea primero y la tarjeta se autoriza contra ella: si la
    // tarjeta falla, se cancela la reserva y no queda ninguna retención.
    _payByCard = _cardsSupported && _selectedCardId != null;
    setState(() => _loading = true);
    _createBooking();
  }

  /// Autoriza la tarjeta para la reserva recién creada.
  void _authorizeCard(Booking booking) {
    _pendingBookingId = booking.id;
    setState(() => _awaitingPaymentIntent = true);
    context.read<PaymentBloc>().add(
          PaymentIntentRequested(
            bookingId: booking.id,
            paymentMethodId: _selectedCardId!,
          ),
        );
  }

  /// La tarjeta no se pudo autorizar: la reserva se cancela para no dejarla
  /// sin pago, y el pasajero puede intentarlo de nuevo.
  Future<void> _cardFailed(String message) async {
    final id = _pendingBookingId;
    _pendingBookingId = null;
    _payByCard = false;
    // Sin retención no hay recargo (basis payment_failed en el servidor).
    if (id != null) {
      await sl<BookingRepository>().cancelBooking(id, reason: 'payment_failed');
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _awaitingPaymentIntent = false;
    });
    showLuxSnackbar(
      context,
      'No se pudo autorizar tu tarjeta ($message). La reserva no se '
      'confirmó; inténtalo de nuevo o elige otra tarjeta.',
      isError: true,
    );
  }

  /// Cierra la reserva con un momento de certeza antes de seguir el viaje.
  Future<void> _celebrate(String bookingId) async {
    await showLuxSuccess(
      context,
      title: 'Reserva confirmada',
      message: 'Te avisaremos en cuanto tu chófer vaya en camino.',
    );
    if (mounted) context.go('/ride/$bookingId');
  }

  Future<void> _handleStripeConfirm(String clientSecret) async {
    if (_selectedCardId == null) return;
    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: _selectedCardId!,
          ),
        ),
      );
      final id = _pendingBookingId;
      _pendingBookingId = null;
      if (!mounted || id == null) return;
      setState(() => _loading = false);
      await _celebrate(id);
    } on StripeException catch (e) {
      await _cardFailed(e.error.localizedMessage ?? 'pago rechazado');
    } catch (_) {
      await _cardFailed('error de conexión');
    }
  }

  Future<void> _showAddGuestDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _AddGuestDialog(
        initialTitle: _guestTitle,
        initialFirstName: _guestFirstName,
        initialLastName: _guestLastName,
        initialPhone: _guestPhone,
        initialLanguage: _guestLanguage,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _bookForSelf = false;
        _guestTitle = result['title'] ?? 'Sr.';
        _guestFirstName = result['firstName'] ?? '';
        _guestLastName = result['lastName'] ?? '';
        _guestPhone = result['phone'] ?? '';
        _guestLanguage = result['language'] ?? '';
      });
    }
  }

  void _createBooking() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    // Sin el correo verificado el servidor no reserva: se avisa antes.
    if (sl<AuthRepository>().needsEmailVerification) {
      setState(() => _loading = false);
      EmailNotVerifiedDialog.show(context);
      return;
    }
    final origin = _formData!.origin;
    // Por horas sin destino fijo: se guarda la recogida como referencia (con
    // coordenadas reales) en lugar de un lugar inventado en (0,0).
    final destination = _formData!.destination ??
        Place(
          name: 'Servicio por horas',
          address: origin.address,
          lat: origin.lat,
          lng: origin.lng,
        );
    final scheduledAt =
        _formData?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));

    // Los datos del invitado van en su propio campo, separados de las notas
    // del solicitante; ningún chófer los ve antes de aceptar.
    final guest = !_bookForSelf && _guestFirstName.isNotEmpty
        ? BookingGuest(
            title: _guestTitle,
            firstName: _guestFirstName,
            lastName: _guestLastName,
            phone: _guestPhone,
            language: _guestLanguage,
          )
        : null;

    context.read<BookingBloc>().add(
          BookingCreateRequested(
            origin: origin,
            destination: destination,
            vehicleClass: _selected,
            serviceType: _service,
            scheduledAt: scheduledAt,
            riderId: authState.user.id,
            estimatedPrice: _freshQuote!.price,
            quotedPrice: _freshQuote!.price,
            requestId: _attemptId,
            notes: _notes.isNotEmpty ? _notes : null,
            guest: guest,
            passengerCount: _passengers,
            luggageCount: _luggage,
            flightNumber:
                _flight.trim().isEmpty ? null : FlightNumber.normalize(_flight),
            flightType: _airportPickup ? _flightType?.name : null,
            pickupAirport: _airportPickup
                ? ServiceArea.airportFor(_formData!.origin)?.iata
                : null,
            hours: _service == ServiceType.byTheHour ? _hours : null,
          ),
        );
  }

  void _selectVehicle(VehicleClass vc) {
    setState(() {
      _selected = vc;
      _luggageOption = 0;
      _seatingOption = 0;
      // Never keep more people or bags than the new class takes.
      _passengers = _passengers.clamp(1, vc.capacity);
      _luggage = _luggage.clamp(0, vc.luggageCapacity);
    });
    _revealCard(vc);
  }

  /// Slides the card row so the chosen card is fully in view once it has
  /// finished growing.
  void _revealCard(VehicleClass vc) {
    final i = _kVehicleClasses.indexOf(vc);
    final split = MediaQuery.sizeOf(context).width >= _kSplitMinWidth;
    final teaser = split ? 210.0 : _mobileCardWidth;
    final gap = split ? 14.0 : 12.0;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_cardsCtrl.hasClients || i < 0) return;
      final pos = _cardsCtrl.position;
      _cardsCtrl.animateTo(
        (i * (teaser + gap)).clamp(0.0, pos.maxScrollExtent),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Phone cards are narrow teasers; tablets get roomier ones.
  double get _mobileCardWidth =>
      MediaQuery.sizeOf(context).width >= 600 ? 220 : 168;

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _maybeQuote();
    return MultiBlocListener(
      listeners: [
        BlocListener<BookingBloc, BookingState>(
          listener: (ctx, state) {
            if (state is BookingCreated) {
              _requestId = null;
              if (_payByCard) {
                _authorizeCard(state.booking);
                return;
              }
              setState(() => _loading = false);
              _celebrate(state.booking.id);
            }
            if (state is BookingUpdateRequired) {
              setState(() => _loading = false);
              AppUpdateDialog.show(ctx, state.failure);
            }
            if (state is BookingEmailNotVerified) {
              setState(() => _loading = false);
              EmailNotVerifiedDialog.show(ctx);
            }
            if (state is BookingTermsRequired) {
              setState(() => _loading = false);
              TermsRequiredDialog.show(ctx);
            }
            if (state is BookingPriceChanged) {
              setState(() => _loading = false);
              _confirmNewPrice(state);
            }
            if (state is BookingError) {
              setState(() => _loading = false);
              showLuxSnackbar(ctx, state.message, isError: true);
            }
          },
        ),
        BlocListener<PaymentBloc, PaymentState>(
          listener: (ctx, state) {
            if (state is CardsLoaded) {
              setState(() {
                _savedCards = state.cards;
                if (_savedCards.isNotEmpty && _selectedCardId == null) {
                  _selectedCardId = _savedCards.first['id'] as String?;
                }
              });
            }
            if (state is PaymentIntentCreated && _awaitingPaymentIntent) {
              setState(() => _awaitingPaymentIntent = false);
              final secret = state.clientSecret;
              if (secret != null) {
                _handleStripeConfirm(secret);
              } else {
                // Viaje lejano: la tarjeta queda guardada en la reserva y se
                // cobra al completar.
                final id = _pendingBookingId;
                _pendingBookingId = null;
                setState(() => _loading = false);
                if (id != null) ctx.go('/ride/$id');
              }
            }
            if (state is PaymentError) {
              if (_awaitingPaymentIntent) {
                _cardFailed(state.message);
                return;
              }
              // Un fallo al cargar las tarjetas no bloquea reservar.
              setState(() => _loading = false);
            }
          },
        ),
      ],
      // Rebuild when the admin toggles which classes are on offer.
      child: ValueListenableBuilder<bool>(
        valueListenable: RemoteFlags.instance.firstClassEnabled,
        builder: (context, _, __) {
          if (!_kVehicleClasses.contains(_selected)) {
            _selected = VehicleClass.business;
          }
          // The split layout needs room for the cards and the summary side
          // by side; phones and tablets get the step-by-step flow.
          return MediaQuery.sizeOf(context).width >= _kSplitMinWidth
              ? _webLayout()
              : _mobileLayout();
        },
      ),
    );
  }

  // ── WEB LAYOUT ──────────────────────────────────────────────────────────────

  Widget _webLayout() => Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _WebTopBar(
              formData: _formData,
              service: _service,
              hours: _hours,
              onBack: () => context.pop(),
              onServiceChanged: (t) => setState(() => _service = t),
              onHoursChanged: (h) => setState(() => _hours = h),
              showStickySelector: _showStickySelector,
              selectedVehicle: _selected,
              onVehicleChanged: _selectVehicle,
              km: _km,
            ),
            const Divider(color: _kDivider, height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Content and summary card travel together as one centred
                  // block; the card floats over the page beside the content.
                  final w = c.maxWidth;
                  final cardW = w >= 1440 ? 400.0 : 360.0;
                  const cardGap = 32.0;
                  final outer = w >= 1400 ? 48.0 : 28.0;
                  final blockW = math.min(
                    w - 2 * outer,
                    _kContentMax + cardGap + cardW,
                  );
                  final blockLeft = (w - blockW) / 2;
                  final contentRight = blockLeft + cardW + cardGap;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _webLeft(left: blockLeft, right: contentRight),
                      ),
                      Positioned(
                        top: 24,
                        bottom: 24,
                        right: blockLeft,
                        width: cardW,
                        child: _webRight(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );

  /// An hourly booking has no route to draw, so it gets no map.
  bool get _showRouteMap =>
      _service != ServiceType.byTheHour && _formData?.origin != null;

  /// Colours of the selected class; the page follows them as you choose.
  VehicleTone get _tone => VehicleCatalog.tone(_selected);

  /// Widest the reading column gets: on big screens the content stays
  /// centred instead of stretching edge to edge.
  static const double _kContentMax = 1040;

  /// [left]/[right] are the page margins that keep the content inside the
  /// centred block, clear of the floating summary card.
  Widget _webLeft({
    required double left,
    required double right,
  }) =>
      SingleChildScrollView(
        controller: _leftScrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero: tinted with the selected class ─────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              color: _tone.wash,
              padding: EdgeInsets.fromLTRB(left, 36, right, 40),
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        _selected.label.toUpperCase(),
                        key: ValueKey(_selected),
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                          color: _tone.accent,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Elige tu experiencia',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: _kTextPrimary,
                        letterSpacing: -0.3,
                        height: 1.05,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: LuxSpacing.sm),
                    const Text(
                      '${LuxPromise.fixedPrice}  ·  ${LuxPromise.chauffeurs}',
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 11,
                        color: _kTextTertiary,
                        letterSpacing: 1.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: LuxSpacing.lg),

                    // Narrow cards tease the front of each car; the chosen
                    // one opens up to reveal it whole.
                    SizedBox(
                      height: 450,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          // Fit the row to the column: the open card up to
                          // 500px, the teasers share what is left (140–210px)
                          // so nothing slides under the summary card.
                          const gap = 14.0;
                          final n = _kVehicleClasses.length;
                          final selW = math.min(
                            500.0,
                            c.maxWidth - (n - 1) * (140 + gap),
                          );
                          final teaserW = n > 1
                              ? ((c.maxWidth - selW - (n - 1) * gap) / (n - 1))
                                  .clamp(140.0, 210.0)
                              : selW;
                          return ListView.separated(
                            controller: _cardsCtrl,
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            padding: EdgeInsets.zero,
                            itemCount: n,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: gap),
                            itemBuilder: (_, i) {
                              final vc = _kVehicleClasses[i];
                              return _VehicleCard(
                                vehicleClass: vc,
                                price: _cardPrice(vc),
                                fromPrice: _priceIsFrom,
                                selected: _selected == vc,
                                onTap: () => _selectVehicle(vc),
                                serviceType: _service,
                                hours: _service == ServiceType.byTheHour
                                    ? _hours
                                    : null,
                                width: teaserW,
                                carWidth: selW - 20,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Everything about the selected class ───────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(left, 40, right, 48),
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleDetailsGallery(vehicleClass: _selected),
                    const SizedBox(height: 40),
                    const Divider(color: _kDivider, height: 1),
                    const SizedBox(height: 36),
                    _capacitySection(),
                    const SizedBox(height: 40),
                    _webPriceBreakdown(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _capacitySection({bool compact = false}) => CapacitySection(
        vehicleClass: _selected,
        tab: _capacityTab,
        luggageIndex: _luggageOption,
        seatingIndex: _seatingOption,
        onTab: (t) => setState(() => _capacityTab = t),
        onLuggage: (i) => setState(() => _luggageOption = i),
        onSeating: (i) => setState(() => _seatingOption = i),
        compact: compact,
      );

  // «Qué incluye» (recibimiento personalizado, cargadores, pañuelos y agua
  // de cortesía) se quitó en F2: no está respaldado. La lista para decidir
  // cuáles reponer está en docs/EXPERIENCIA_LUXLANE.md.

  // ── Price breakdown ────────────────────────────────────────────────────────

  Widget _webPriceBreakdown({bool compact = false}) {
    // Dotted line row
    Widget priceLine(String label, double? amount) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) {
                    const dW = 4.0, gap = 5.0;
                    final count = (c.maxWidth / (dW + gap)).floor();
                    return Row(
                      children: List.generate(
                        count,
                        (_) => Container(
                          width: dW,
                          height: 1,
                          margin: const EdgeInsets.only(right: gap),
                          color: _kBorder,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatPriceOrQuote(amount),
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _kTextPrimary,
                ),
              ),
            ],
          ),
        );

    // Note row with info icon
    Widget note(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: LD.sphTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 13,
                  color: _kPanelAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 12,
                    color: _kTextSub,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 30),
      decoration: BoxDecoration(
        color: compact ? Colors.white : LD.bg2,
        borderRadius: BorderRadius.circular(compact ? _kMobileRadius : 4),
        border: compact ? Border.all(color: _kBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Desglose de precio',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 20),

          // Total: el precio del servidor, sin desglose fiscal (no hay
          // una cifra de impuesto definida).
          // El error de la cotización va junto al precio (E36), no aquí.
          priceLine(_priceIsServer ? 'Total' : 'Total estimado', _price),
          const Divider(color: _kBorder, height: 1, thickness: 1.2),
          const SizedBox(height: 22),

          // Please note section
          const Text(
            'Nota importante:',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 14),

          note(
            'Los límites de capacidad de pasajeros y equipaje deben respetarse por '
            'razones de seguridad. Si se exceden, el chófer podrá rechazar el servicio.',
          ),
          note(
            'Las imágenes del vehículo son solo de referencia. El vehículo real puede '
            'variar manteniendo una calidad equivalente o superior.',
          ),
          note(
            'Las necesidades adicionales (silla de ruedas, asiento infantil, artículos extra) pueden '
            'añadirse en "Notas de recogida". Elige Business Van para grupos más grandes '
            'o equipaje adicional.',
          ),
        ],
      ),
    );
  }

  /// Summary card: rounded, lifted off the page with a soft shadow, sitting
  /// beside the content it summarises.
  Widget _webRight() => DecoratedBox(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LD.border),
          boxShadow: [
            BoxShadow(
              color: LD.ink.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: LD.ink.withValues(alpha: 0.10),
              blurRadius: 40,
              spreadRadius: -12,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Route map: only when there is a route (not for hourly) ────
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showRouteMap
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: MediaQuery.sizeOf(context).width >= 1440
                                ? 260
                                : 210,
                            color: LD.bg3,
                            child: LuxMap(
                              origin: _formData!.origin,
                              destination: _formData!.destination,
                              routeInfo: _routeInfo,
                            ),
                          ),
                          const Divider(color: _kDivider, height: 1),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),

              // ── Booking summary ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                  child: _webSummaryContent(),
                ),
              ),

              // ── Reserve button — pinned bottom ────────────────────────────
              _ReserveBar(
                selected: _selected,
                loading: _loading,
                onReserve: _confirm,
              ),
            ],
          ),
        ),
      );

  /// «Para mí» o «para un invitado»: el mismo diálogo y los mismos datos en
  /// los dos diseños (E39: antes el asistente móvil no lo tenía). El servidor
  /// valida al invitado igual (createSchema.guest).
  List<Widget> _bookForOptions() => [
        // ── Book for myself ─────────────────────────────────────────────
        _BookOptionCard(
          icon: Icons.person_outlined,
          iconBg: LD.sphTint,
          iconColor: _kPanelAccent,
          title: 'Reservar para mí',
          subtitle: 'Reserva con la información de tu cuenta',
          selected: _bookForSelf,
          onTap: () => setState(() => _bookForSelf = true),
        ),

        const SizedBox(height: 10),

        // ── Book for a guest ────────────────────────────────────────────
        _BookOptionCard(
          icon: Icons.group_outlined,
          iconBg: !_bookForSelf ? LD.sphTint : LD.bg2,
          iconColor: !_bookForSelf ? _kPanelAccent : _kTextSub,
          title: 'Reservar para un invitado',
          subtitle: (!_bookForSelf && _guestFirstName.isNotEmpty)
              ? '$_guestTitle $_guestFirstName $_guestLastName'
              : 'Seleccionar o añadir un invitado',
          selected: !_bookForSelf,
          onTap: _showAddGuestDialog,
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: !_bookForSelf ? _kPanelAccent : _kTextSub,
          ),
        ),
      ];

  Widget _webSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Vehicle name + price ────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selected.label,
                    style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: _kTextPrimary,
                      letterSpacing: -0.3,
                      height: 1.0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _selected.description,
                    style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: _kTextTertiary,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPriceOrQuote(_price),
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: _kTextPrimary,
                    letterSpacing: -0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  _priceIsServer ? 'Precio final' : 'Precio estimado',
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 11,
                    color: _kTextTertiary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_quoteError != null) ...[
          const SizedBox(height: 10),
          _QuoteErrorNote(message: _quoteError!, onRetry: _retryQuote),
        ],

        // ── Selection summary ───────────────────────────────────────────
        const SizedBox(height: 20),
        _SummaryAddressRow(
          icon: Icons.location_on_outlined,
          label: 'Recogida',
          value: _formData?.origin.displayName ?? '—',
        ),
        const SizedBox(height: 12),
        _service == ServiceType.byTheHour
            ? _SummaryAddressRow(
                icon: Icons.schedule_rounded,
                label: 'Duración',
                value: '$_hours horas a tu disposición',
              )
            : _SummaryAddressRow(
                icon: Icons.flag_outlined,
                label: 'Destino',
                value: _formData?.destination?.displayName ?? '—',
              ),
        if (_airportPickup) ...[
          const SizedBox(height: 20),
          const _FlightNote(),
          const SizedBox(height: 10),
          _flightField(),
        ],

        const SizedBox(height: LuxSpacing.lg),
        const Divider(color: _kDivider, height: 1),
        const SizedBox(height: 20),

        ..._bookForOptions(),

        const SizedBox(height: 20),
        const Divider(color: _kDivider, height: 1),
        const SizedBox(height: LuxSpacing.md),

        // ── All fees included ───────────────────────────────────────────
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: _kTextSub),
            SizedBox(width: LuxSpacing.sm),
            Text(
              LuxPromise.fixedPrice,
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 12,
                color: _kTextSub,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        const SizedBox(height: LuxSpacing.md),
      ],
    );
  }

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────────

  // The vehicle step wears the selected class colour, like the web hero.
  Widget _mobileLayout() => AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: _step == 0 ? _tone.wash : _kBg,
        child: Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: _kTextPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: _kTextPrimary),
              titleTextStyle: TextStyle(
                fontFamily: kSans,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextSub,
                letterSpacing: 1.4,
              ),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () =>
                    _step > 0 ? setState(() => _step--) : context.pop(),
              ),
              title: Text('PASO ${_step + 1} DE 3'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _LightStepIndicator(
                        steps: const ['Vehículo', 'Detalles', 'Confirmar'],
                        currentStep: _step,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    // Tablets keep a comfortable reading width.
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: _mobileStepContent(),
                      ),
                    ),
                  ),
                ),
                _LightPriceBar(
                  price: _price,
                  estimated: !_priceIsServer,
                  error: _quoteError,
                  onRetry: _retryQuote,
                  label: _step < 2 ? 'Continuar' : 'Reservar',
                  loading: _loading,
                  onConfirm: _step < 2
                      ? () {
                          if (_step == 1 && !_checkFlight()) return;
                          setState(() => _step++);
                        }
                      : _confirm,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _mobileStepContent() {
    switch (_step) {
      case 0:
        return _mobileVehicleStep();
      case 1:
        return _detailsStep();
      case 2:
        return _confirmStep();
      default:
        return const SizedBox();
    }
  }

  Widget _mobileVehicleStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige tu experiencia',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: LuxSpacing.md),
          _LightServiceTypeTab(
            selected: _service,
            onChanged: (t) => setState(() => _service = t),
          ),
          if (_service == ServiceType.byTheHour) ...[
            const SizedBox(height: 12),
            _LightHourRow(
              hours: _hours,
              onChanged: (h) => setState(() => _hours = h),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: _mobileCardWidth > 168 ? 400 : 340,
            child: ListView.separated(
              controller: _cardsCtrl,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              itemCount: _kVehicleClasses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final vc = _kVehicleClasses[i];
                return _VehicleCard(
                  vehicleClass: vc,
                  price: _cardPrice(vc),
                  fromPrice: _priceIsFrom,
                  selected: _selected == vc,
                  onTap: () => _selectVehicle(vc),
                  serviceType: _service,
                  hours: _service == ServiceType.byTheHour ? _hours : null,
                  width: _mobileCardWidth,
                  carWidth: _mobileCardWidth > 168 ? 360 : 270,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const _MobilePromises(),
          const SizedBox(height: LuxSpacing.xl),
          VehicleDetailsGallery(vehicleClass: _selected, compact: true),
          const SizedBox(height: 36),
          _capacitySection(compact: true),
          const SizedBox(height: 36),
          _webPriceBreakdown(compact: true),
          const SizedBox(height: LuxSpacing.sm),
        ],
      );

  Widget _detailsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETALLES DEL VIAJE',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kTextTertiary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),
          _LightCounterRow(
            label: 'Pasajeros',
            icon: Icons.person_outline,
            value: _passengers,
            min: 1,
            max: _selected.capacity,
            onChanged: (v) => setState(() => _passengers = v),
          ),
          const SizedBox(height: 10),
          _LightCounterRow(
            label: 'Equipaje',
            icon: Icons.luggage_outlined,
            value: _luggage,
            min: 0,
            max: _selected.luggageCapacity,
            onChanged: (v) => setState(() => _luggage = v),
          ),
          const SizedBox(height: 20),
          if (_airportPickup) ...[
            const _FlightNote(),
            const SizedBox(height: 10)
          ],
          _flightField(),
          const SizedBox(height: 12),
          _LightTextField(
            label: 'Solicitudes especiales',
            hint: 'Asiento infantil, letrero de bienvenida…',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 3,
            onChanged: (v) => _notes = v,
          ),
        ],
      );

  Widget _flightField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LightTextField(
            label: _airportPickup ? 'Número de vuelo *' : 'Número de vuelo',
            hint: _airportPickup ? 'ej. OB 760' : 'ej. OB 760 (opcional)',
            icon: Icons.flight_outlined,
            initialValue: _flight,
            errorText: _flightAttempted ? _flightError : null,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => setState(() => _flight = v),
          ),
          if (_airportPickup) ...[
            const SizedBox(height: 12),
            _FlightTypeSelector(
              value: _flightType,
              errorText: _flightAttempted ? _flightTypeError : null,
              onChanged: (t) => setState(() => _flightType = t),
            ),
          ],
        ],
      );

  Widget _confirmStep() {
    final hasRoute = _showRouteMap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRoute) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(_kMobileRadius),
            child: SizedBox(
              height: 180,
              child: LuxMap(
                origin: _formData!.origin,
                destination: _formData!.destination,
                routeInfo: _routeInfo,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'RESUMEN DE RESERVA',
          style: TextStyle(
            fontFamily: kSans,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kTextTertiary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(_kMobileRadius),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              _SummaryRow('Servicio', _service.label, isFirst: true),
              _SummaryRow('Vehículo', _selected.label),
              if (_formData?.origin != null)
                _SummaryRow('Desde', _formData!.origin.displayName),
              if (_formData?.destination != null)
                _SummaryRow('Hasta', _formData!.destination!.displayName),
              _SummaryRow(
                _service == ServiceType.byTheHour ? 'Duración' : 'Distancia',
                _service == ServiceType.byTheHour
                    ? '$_hours horas'
                    : _km > 0
                        ? '${_km.toStringAsFixed(1)} km'
                        : '—',
              ),
              if (_formData?.routeDurationMin != null &&
                  _formData!.routeDurationMin > 0)
                _SummaryRow(
                  'Duración est.',
                  '${_formData!.routeDurationMin} min',
                ),
              _SummaryRow('Pasajeros', '$_passengers'),
              _SummaryRow('Equipaje', '$_luggage bultos'),
              if (_flight.isNotEmpty)
                _SummaryRow(
                  'Vuelo',
                  _flightType == null || !_airportPickup
                      ? _flight
                      : '$_flight · ${_flightType!.label}',
                ),
              if (_notes.isNotEmpty) _SummaryRow('Notas', _notes),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: LD.bg2,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(_kMobileRadius - 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _priceIsServer ? 'TOTAL · PRECIO FIJO' : 'TOTAL ESTIMADO',
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kTextTertiary,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPriceOrQuote(_price),
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_quoteError != null) ...[
          const SizedBox(height: 10),
          _QuoteErrorNote(message: _quoteError!, onRetry: _retryQuote),
        ],
        const SizedBox(height: 20),
        ..._bookForOptions(),
        const SizedBox(height: 20),
        if (!_cardsSupported)
          const SizedBox.shrink()
        else if (_savedCards.isEmpty)
          _OutlinedBtn(
            label: 'Agregar método de pago',
            icon: Icons.add_card_outlined,
            onPressed: () async {
              await context.push('/payment/add');
              if (mounted) _loadSavedCards();
            },
          )
        else ...[
          const Text(
            'MÉTODO DE PAGO',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kTextTertiary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          ..._savedCards.map((card) {
            final id = card['id'] as String;
            final brand = _cap(card['brand'] as String? ?? 'Card');
            final last4 = card['last4'] as String? ?? '****';
            final isSel = _selectedCardId == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCardId = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(_kMobileRadius),
                    border: Border.all(
                      color: isSel ? LuxColors.sapphire : _kBorder,
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card_outlined,
                        size: 20,
                        color: isSel ? LuxColors.sapphire : _kTextSub,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$brand •••• $last4',
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kTextPrimary,
                          ),
                        ),
                      ),
                      if (isSel)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: LuxColors.sapphire,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: LuxSpacing.md),
        _GuaranteeRow(Icons.lock_outline_rounded, LuxPromise.fixedPriceLong),
        const SizedBox(height: LuxSpacing.sm),
      ],
    );
  }
}

// ── WEB TOP BAR ───────────────────────────────────────────────────────────────

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({
    required this.formData,
    required this.service,
    required this.hours,
    required this.onBack,
    required this.onServiceChanged,
    required this.onHoursChanged,
    this.showStickySelector = false,
    this.selectedVehicle,
    this.onVehicleChanged,
    this.km = 0,
  });

  final BookingFormData? formData;
  final ServiceType service;
  final int hours;
  final VoidCallback onBack;
  final ValueChanged<ServiceType> onServiceChanged;
  final ValueChanged<int> onHoursChanged;
  final bool showStickySelector;
  final VehicleClass? selectedVehicle;
  final ValueChanged<VehicleClass>? onVehicleChanged;

  /// Distancia por calles conocida; 0 = sin ruta (se muestra "desde").
  final double km;

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        decoration: const BoxDecoration(
          color: _kBg,
          border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width >= 1400 ? 56 : 36,
        ),
        child: Row(
          children: [
            // ── Luxelane logo mark ───────────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/'),
                child: const LuxelaneWordmark(color: _kTextPrimary),
              ),
            ),
            const SizedBox(width: 40),
            // ── Back button ──────────────────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 12,
                      color: _kTextSub,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Volver',
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.8,
                        color: _kTextSub,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sticky vehicle selector (appears after scrolling past cards) ─
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: showStickySelector && selectedVehicle != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: showStickySelector ? 1.0 : 0.0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _kVehicleClasses.map((vc) {
                              final price = PricingCatalog.instance.estimate(
                                vc,
                                service,
                                km: km,
                                hours: hours,
                              );
                              final isActive = selectedVehicle == vc;
                              final tone = VehicleCatalog.tone(vc);
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => onVehicleChanged?.call(vc),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isActive ? tone.wash : Colors.white,
                                        borderRadius: BorderRadius.zero,
                                        border: Border.all(
                                          color:
                                              isActive ? tone.accent : _kBorder,
                                          width: isActive ? 2.0 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            vc.label,
                                            style: TextStyle(
                                              fontFamily: kSans,
                                              fontSize: 13,
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isActive
                                                  ? tone.accent
                                                  : _kTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: LuxSpacing.sm),
                                          Container(
                                            width: 1,
                                            height: 12,
                                            color: isActive
                                                ? tone.accent.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : _kBorder,
                                          ),
                                          const SizedBox(width: LuxSpacing.sm),
                                          Text(
                                            formatPriceOrQuote(
                                              price,
                                              from: service ==
                                                      ServiceType.oneWay &&
                                                  km == 0,
                                            ),
                                            style: TextStyle(
                                              fontFamily: kSans,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isActive
                                                  ? tone.accent
                                                  : _kTextSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const Spacer(),

            // ── Route summary pill (only where it fits beside the rest) ──
            if (formData?.origin != null &&
                MediaQuery.sizeOf(context).width >= 1280)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          formData!.origin.displayName,
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: _kTextSub,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formData!.destination?.displayName ?? '—',
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(width: LuxSpacing.md),

            _LightServiceTypeTab(
              selected: service,
              onChanged: onServiceChanged,
              compact: true,
            ),

            if (service == ServiceType.byTheHour) ...[
              const SizedBox(width: 12),
              _CompactHourPicker(hours: hours, onChanged: onHoursChanged),
            ],
          ],
        ),
      );
}

// ── VEHICLE CARD ──────────────────────────────────────────────────────────────

class _VehicleCard extends StatefulWidget {
  const _VehicleCard({
    required this.vehicleClass,
    required this.price,
    required this.selected,
    required this.onTap,
    this.fromPrice = false,
    this.serviceType = ServiceType.oneWay,
    this.hours,
    this.width,
    this.carWidth = 480,
  });

  final VehicleClass vehicleClass;

  /// Precio orientativo; con [fromPrice] es el mínimo ("desde"), porque aún
  /// no se conoce la ruta. Null sin tarifa configurada.
  final double? price;
  final bool fromPrice;
  final bool selected;
  final VoidCallback onTap;
  final ServiceType serviceType;
  final int? hours;
  final double? width;

  /// Width of the car artwork. The selected card grows to show all of it;
  /// unselected cards show the front three-quarters as a teaser.
  final double carWidth;

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // Each card wears its class colours, so the page tint that follows the
    // selection always matches a card.
    final tone = VehicleCatalog.tone(widget.vehicleClass);
    final accent = tone.accent;
    const kSelPad = 20.0;
    final baseW = widget.width ?? 210.0;
    final targetW = widget.selected ? widget.carWidth + kSelPad : baseW;
    final sel = widget.selected;

    return Semantics(
      button: true,
      selected: sel,
      label: '${widget.vehicleClass.label}, '
          '${formatPriceOrQuote(widget.price, from: widget.fromPrice)}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
            width: targetW,
            transform: Matrix4.translationValues(0, _hover && !sel ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? accent : LD.border,
                width: sel ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: LD.ink.withValues(alpha: sel ? 0.08 : 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: (sel ? accent : LD.ink).withValues(
                    alpha: sel ? 0.18 : (_hover ? 0.10 : 0.05),
                  ),
                  blurRadius: sel ? 30 : 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Vehicle artwork ────────────────────────────────────────
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: tone.stageGradient,
                          ),
                        ),
                        // The car at full size, anchored left: a narrow card
                        // shows its front, the selected one all of it. The
                        // 2:1 window keeps only the car (the photos are
                        // square with the car across the middle), centred
                        // vertically so it is never cut at the top.
                        Positioned(
                          left: 10,
                          top: 0,
                          bottom: 0,
                          width: widget.carWidth,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 2,
                              child: VehicleImage(
                                widget.vehicleClass,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: sel ? 1.0 : 0.0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Info strip ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: LD.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.vehicleClass.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: _kTextPrimary,
                          height: 1.1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.vehicleClass.description,
                        style: const TextStyle(
                          fontFamily: kSans,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: _kTextTertiary,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              formatPriceOrQuote(
                                widget.price,
                                from: widget.fromPrice,
                              ),
                              style: const TextStyle(
                                fontFamily: kSerif,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: _kTextPrimary,
                                height: 1,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          // Narrow teaser cards keep just the price.
                          if (sel || baseW >= 200) ...[
                            const SizedBox(width: LuxSpacing.sm),
                            _CapChip(
                              Icons.person_outline_rounded,
                              widget.vehicleClass.capacity,
                            ),
                            const SizedBox(width: 6),
                            _CapChip(
                              Icons.luggage_outlined,
                              widget.vehicleClass.luggageCapacity,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip(this.icon, this.value);
  final IconData icon;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: LD.bg2,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _kTextSub),
            const SizedBox(width: 3),
            Text(
              '$value',
              style: const TextStyle(
                fontFamily: kSans,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _kTextSub,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
}

// ── BOOK OPTION CARD (Blacklane "Book for myself / guest" style) ───────────────

class _BookOptionCard extends StatelessWidget {
  const _BookOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: selected ? _kPanelAccent : _kBorder,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 12,
                        color: _kTextSub,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}

// ── RESERVE BAR (web, pinned bottom of right panel) ───────────────────────────

class _ReserveBar extends StatelessWidget {
  const _ReserveBar({
    required this.selected,
    required this.loading,
    required this.onReserve,
  });

  final VehicleClass selected;
  final bool loading;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: LuxRaisedButton(
          label: 'Reservar ${selected.label}',
          loading: loading,
          onPressed: onReserve,
          uppercase: false,
          fontSize: 15,
          radius: LuxRadius.md,
          height: 54,
        ),
      );
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: enabled ? LD.bg2 : LD.bg,
            border: Border.all(color: LD.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 14,
            color: enabled ? _kTextPrimary : _kTextTertiary,
          ),
        ),
      );
}

// ── GUARANTEE ROW ─────────────────────────────────────────────────────────────

Widget _GuaranteeRow(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 15, color: _kTextSub),
        const SizedBox(width: LuxSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: kSans,
              fontSize: 11,
              color: _kTextSub,
            ),
          ),
        ),
      ],
    );

// ── MOBILE VEHICLE DETAIL ─────────────────────────────────────────────────────

/// The two promises under the class cards, on one rounded strip. The card
/// itself already names the class and its capacity.
class _MobilePromises extends StatelessWidget {
  const _MobilePromises();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(_kMobileRadius),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuaranteeRow(Icons.price_check_outlined, LuxPromise.fixedPrice),
            const SizedBox(height: 6),
            _GuaranteeRow(Icons.verified_user_outlined, LuxPromise.chauffeurs),
          ],
        ),
      );
}

// ── SUMMARY ROW (confirm step) ────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isFirst = false});
  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (!isFirst) const Divider(color: _kDivider, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 12,
                    color: _kTextSub,
                  ),
                ),
                const SizedBox(width: LuxSpacing.md),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ── SERVICE TYPE TAB ──────────────────────────────────────────────────────────

class _LightServiceTypeTab extends StatelessWidget {
  const _LightServiceTypeTab({
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });
  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 40.0 : 46.0;
    Widget segment(ServiceType t) {
      final active = selected == t;
      return Semantics(
        button: true,
        selected: active,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              LuxHaptics.tap();
              onChanged(t);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.all(3),
              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 0),
              decoration: active
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140D1B2E),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    )
                  : const BoxDecoration(color: Colors.transparent),
              alignment: Alignment.center,
              child: Text(
                t.label,
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: active ? _kTextPrimary : _kTextSub,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: LD.bg2,
        borderRadius: BorderRadius.circular(LuxRadius.md),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (final t in ServiceType.values)
            compact ? segment(t) : Expanded(child: segment(t)),
        ],
      ),
    );
  }
}

// ── COMPACT HOUR PICKER (top bar) ─────────────────────────────────────────────

class _CompactHourPicker extends StatelessWidget {
  const _CompactHourPicker({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(
              icon: Icons.remove,
              enabled: hours > 2,
              onTap: () => onChanged(hours - 1),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${hours}h',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
            ),
            _Btn(
              icon: Icons.add,
              enabled: hours < 12,
              onTap: () => onChanged(hours + 1),
            ),
          ],
        ),
      );
}

// ── LIGHT HOUR ROW (mobile) ───────────────────────────────────────────────────

class _LightHourRow extends StatelessWidget {
  const _LightHourRow({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(_kMobileRadius),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Text(
              'Duración',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kTextPrimary,
              ),
            ),
            const Spacer(),
            _Btn(
              icon: Icons.remove,
              enabled: hours > 2,
              onTap: () => onChanged(hours - 1),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${hours}h',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
            ),
            _Btn(
              icon: Icons.add,
              enabled: hours < 12,
              onTap: () => onChanged(hours + 1),
            ),
          ],
        ),
      );
}

// ── LIGHT COUNTER ROW (mobile) ────────────────────────────────────────────────

class _LightCounterRow extends StatelessWidget {
  const _LightCounterRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(_kMobileRadius),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kTextSub),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kTextPrimary,
                ),
              ),
            ),
            _Btn(
              icon: Icons.remove,
              enabled: value > min,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
            ),
            _Btn(
              icon: Icons.add,
              enabled: value < max,
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
      );
}

// ── LIGHT TEXT FIELD ──────────────────────────────────────────────────────────

class _LightTextField extends StatelessWidget {
  const _LightTextField({
    required this.label,
    this.hint,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
    this.initialValue,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
  });
  final String label;
  final String? hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final String? initialValue;
  final String? errorText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          fontFamily: kSans,
          fontSize: 13,
          color: _kTextPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          hintStyle: const TextStyle(
            fontFamily: kSans,
            fontSize: 13,
            color: _kTextTertiary,
            fontWeight: FontWeight.w300,
          ),
          labelStyle: const TextStyle(
            fontFamily: kSans,
            fontSize: 12,
            color: _kTextSub,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, size: 18, color: _kTextSub),
          filled: true,
          fillColor: _kCardBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)),
            borderSide: BorderSide(color: _kBorder),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)),
            borderSide: BorderSide(color: _kBorder),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)),
            borderSide: BorderSide(color: _kTextPrimary, width: 1.5),
          ),
        ),
      );
}

// ── FLIGHT NOTE (airport pickups) ─────────────────────────────────────────────

class _FlightNote extends StatelessWidget {
  const _FlightNote();

  @override
  Widget build(BuildContext context) => const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flight_land_rounded, size: 16, color: _kPanelAccent),
          SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Text(
              'Recogida en aeropuerto: indica tu número de vuelo para que '
              'tu chófer lo tenga.',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 12,
                height: 1.4,
                color: _kTextSub,
              ),
            ),
          ),
        ],
      );
}

// ── FLIGHT TYPE (airport pickups) ─────────────────────────────────────────────

/// National or international: the driver waits at a different arrivals exit.
class _FlightTypeSelector extends StatelessWidget {
  const _FlightTypeSelector({
    required this.value,
    required this.onChanged,
    this.errorText,
  });
  final FlightType? value;
  final ValueChanged<FlightType> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de vuelo *',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 12,
              color: _kTextSub,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: LuxSpacing.sm),
          Row(
            children: [
              for (final t in FlightType.values) ...[
                if (t != FlightType.values.first)
                  const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      LuxHaptics.tap();
                      onChanged(t);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: value == t ? _kPanelAccent : _kCardBg,
                        borderRadius: BorderRadius.circular(_kMobileRadius),
                        border: Border.all(
                          color: value == t
                              ? _kPanelAccent
                              : errorText != null
                                  ? Colors.red.shade700
                                  : _kBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            t == FlightType.domestic
                                ? Icons.flight_land_rounded
                                : Icons.public_rounded,
                            size: 16,
                            color: value == t ? Colors.white : _kTextSub,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontFamily: kSans,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: value == t ? Colors.white : _kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText!,
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      );
}

// ── OUTLINED ACTION BTN ───────────────────────────────────────────────────────

class _OutlinedBtn extends StatelessWidget {
  const _OutlinedBtn({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(_kMobileRadius),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _kTextSub),
              const SizedBox(width: LuxSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── MOBILE PRICE BAR ──────────────────────────────────────────────────────────

class _LightPriceBar extends StatelessWidget {
  const _LightPriceBar({
    required this.price,
    required this.onConfirm,
    this.loading = false,
    this.label = 'Confirmar reserva',
    this.estimated = false,
    this.error,
    this.onRetry,
  });
  final double? price;
  final VoidCallback onConfirm;
  final bool loading;
  final String label;

  /// Sin cotización del servidor: el importe es una estimación (E35).
  final bool estimated;

  /// La cotización falló: se dice junto al precio (E36).
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          14 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  _QuoteErrorNote(message: error!, onRetry: onRetry),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          estimated ? 'PRECIO ESTIMADO' : 'PRECIO FINAL',
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _kTextTertiary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          formatPriceOrQuote(price),
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: LuxSpacing.md),
                    Expanded(
                      child: LuxRaisedButton(
                        label: label,
                        height: 52,
                        loading: loading,
                        onPressed: onConfirm,
                        uppercase: false,
                        fontSize: 15,
                        radius: LuxRadius.md,
                        trailingIcon: Icons.arrow_forward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Error de la cotización junto al precio, con reintento (E36). Sin texto
/// técnico: el mensaje ya viene traducido del repositorio.
class _QuoteErrorNote extends StatelessWidget {
  const _QuoteErrorNote({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: LuxColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 13,
                  color: LuxColors.error,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
}

// ── MOBILE STEP INDICATOR ─────────────────────────────────────────────────────

class _LightStepIndicator extends StatelessWidget {
  const _LightStepIndicator({required this.steps, required this.currentStep});
  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 1,
                color: i ~/ 2 < currentStep ? LD.sph : _kBorder,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < currentStep;
          final active = idx == currentStep;
          return Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? LD.sph : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done || active ? LD.sph : _kBorder,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontFamily: kSans,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: active ? LD.sph : _kTextTertiary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[idx],
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? _kTextPrimary : _kTextTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );
        }),
      );
}

// ── AUTH GATE DIALOG ──────────────────────────────────────────────────────

class _AuthGateDialog extends StatefulWidget {
  const _AuthGateDialog();
  @override
  State<_AuthGateDialog> createState() => _AuthGateDialogState();
}

class _AuthGateDialogState extends State<_AuthGateDialog> {
  bool _showRegister = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _loading = true);
    if (_showRegister) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              email: email,
              password: pass,
              displayName: _nameCtrl.text.trim().isNotEmpty
                  ? _nameCtrl.text.trim()
                  : email.split('@').first,
              phone: '',
              role: UserRole.rider,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            LoginRequested(email: email, password: pass),
          );
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthAuthenticated) Navigator.of(ctx).pop(true);
          if (state is AuthError) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: LuxColors.onAccent),
                ),
                backgroundColor: LuxColors.error,
              ),
            );
          }
        },
        child: Dialog(
          backgroundColor: LuxColors.surface,
          insetPadding: const EdgeInsets.all(LuxSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.lg),
            side: const BorderSide(color: LuxColors.border),
          ),
          child: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isWeb(context) ? LuxSpacing.xxl : LuxSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showRegister
                              ? 'Crear una cuenta'
                              : 'Inicia sesión para continuar',
                          style: LuxTypography.headlineLarge
                              .copyWith(fontSize: 24),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: LuxColors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  Text(
                    _showRegister
                        ? 'Crea tu cuenta de Luxelane para completar la reserva.'
                        : 'Inicia sesión para confirmar tu reserva.',
                    style: LuxTypography.bodyMedium,
                  ),
                  const SizedBox(height: LuxSpacing.xl),
                  const GoogleSignInButton(),
                  const SizedBox(height: LuxSpacing.lg),
                  const AuthOrDivider(),
                  const SizedBox(height: LuxSpacing.lg),
                  if (_showRegister) ...[
                    LuxTextField(
                      label: 'Nombre completo',
                      hint: 'Tu nombre',
                      prefixIcon: Icons.person_outline,
                      controller: _nameCtrl,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: LuxSpacing.md),
                  ],
                  LuxTextField(
                    label: 'Correo electrónico',
                    hint: 'tu@ejemplo.com',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  LuxTextField(
                    label: 'Contraseña',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onChanged: (_) {},
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: LuxColors.inkTertiary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: LuxSpacing.xl),
                  LuxButton(
                    label: _showRegister ? 'Crear cuenta' : 'Iniciar sesión',
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showRegister = !_showRegister),
                    child: Text(
                      _showRegister
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Crear una',
                      style: LuxTypography.bodyMedium.copyWith(
                        color: LuxColors.sapphire,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ── ADD GUEST DIALOG ──────────────────────────────────────────────────────────

InputDecoration _guestFieldDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: kSans,
        fontSize: 15,
        color: _kTextTertiary,
        fontWeight: FontWeight.w400,
      ),
      border:
          const UnderlineInputBorder(borderSide: BorderSide(color: _kBorder)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _kBorder),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _kTextPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      filled: false,
      isDense: false,
    );

const _kGuestValueStyle = TextStyle(
  fontFamily: kSans,
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: _kTextPrimary,
);

Widget _guestFieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: kSans,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kTextPrimary,
        ),
      ),
    );

class _AddGuestDialog extends StatefulWidget {
  const _AddGuestDialog({
    this.initialTitle = 'Sr.',
    this.initialFirstName = '',
    this.initialLastName = '',
    this.initialPhone = '',
    this.initialLanguage = '',
  });

  final String initialTitle;
  final String initialFirstName;
  final String initialLastName;
  final String initialPhone;
  final String initialLanguage;

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  static const _kTitles = ['Sr.', 'Sra.', 'Srta.', 'Dr.', 'Prof.'];

  late String _title;
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _languageCtrl;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _firstCtrl = TextEditingController(text: widget.initialFirstName);
    _lastCtrl = TextEditingController(text: widget.initialLastName);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _languageCtrl = TextEditingController(text: widget.initialLanguage);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _languageCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(<String, String>{
      'title': _title,
      'firstName': _firstCtrl.text.trim(),
      'lastName': _lastCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'language': _languageCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Añadir nuevo invitado',
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder, width: 1.5),
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: _kTextSub,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Description ─────────────────────────────────────────────
              const Text(
                'Ingresa los datos de la persona que viajará. Compartiremos '
                'estos datos con el chófer asignado para coordinar la recogida.',
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 13,
                  color: _kTextSub,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 30),

              // ── Title dropdown ──────────────────────────────────────────
              _guestFieldLabel('Tratamiento'),
              DropdownButtonFormField<String>(
                value: _title,
                style: _kGuestValueStyle,
                dropdownColor: _kBg,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kTextPrimary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  filled: false,
                  isDense: false,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _kTextSub,
                  size: 22,
                ),
                items: _kTitles
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: _kGuestValueStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _title = v!),
              ),

              const SizedBox(height: 26),

              // ── First name + Last name ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _guestFieldLabel('Nombre'),
                        TextField(
                          controller: _firstCtrl,
                          style: _kGuestValueStyle,
                          decoration: _guestFieldDecor('Nombre del invitado'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LuxSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _guestFieldLabel('Apellido'),
                        TextField(
                          controller: _lastCtrl,
                          style: _kGuestValueStyle,
                          decoration: _guestFieldDecor('Apellido del invitado'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ── Mobile number ───────────────────────────────────────────
              _guestFieldLabel('Número de móvil del invitado'),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: _kGuestValueStyle,
                decoration: _guestFieldDecor(
                  'Número de móvil del invitado',
                ).copyWith(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined, size: 17, color: _kTextSub),
                        SizedBox(width: 3),
                        Icon(Icons.language, size: 15, color: _kTextSub),
                        SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: _kTextSub,
                        ),
                        SizedBox(width: LuxSpacing.sm),
                      ],
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(height: LuxSpacing.sm),

              const Text(
                'El chófer asignado usará este número para coordinar la recogida.',
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 11,
                  color: _kTextSub,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 26),

              // ── Language ────────────────────────────────────────────────
              _guestFieldLabel('Idioma del invitado (opcional)'),
              TextField(
                controller: _languageCtrl,
                maxLength: 40,
                style: _kGuestValueStyle,
                decoration: _guestFieldDecor(
                  'Ej.: español, inglés',
                ).copyWith(counterText: ''),
              ),

              const SizedBox(height: 30),

              // ── Confirm — right-aligned blue pill ───────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPanelAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryAddressRow extends StatelessWidget {
  const _SummaryAddressRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: LD.ink3),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: LD.ink3,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: LD.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
