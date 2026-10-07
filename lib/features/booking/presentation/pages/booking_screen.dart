import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/env.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_states.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../../payments/presentation/bloc/payment_bloc.dart';
import '../bloc/booking_bloc.dart';

part 'booking/widgets.dart';
part 'booking/dialogs.dart';

// ── Vehicle classes (Electric excluded) ───────────────────────────────────────
const _kVehicleClasses = [
  VehicleClass.business,
  VehicleClass.firstClass,
  VehicleClass.businessVan,
];

// ── Luxelane design tokens (mirrors home_design.dart LD class) ─────────────────
const _kBg           = LD.bg;            // #FAFBFE
const _kCardBg       = Colors.white;
const _kBorder       = LD.border;        // #DDE4F0
const _kTextPrimary  = LD.ink;           // #0D1B2E
const _kTextSub      = LD.ink2;          // #2C3D55
const _kTextTertiary = LD.ink3;          // #637490
const _kDivider      = LD.border;        // #DDE4F0
const _kPanelAccent  = LD.accent;        // deep champagne (text, lines)

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  BookingFormData? _formData;
  VehicleClass _selected = VehicleClass.business;
  ServiceType  _service  = ServiceType.oneWay;
  int  _hours   = 3;
  bool _loading = false;
  int  _step    = 0; // mobile only

  int    _passengers = 1;
  int    _luggage    = 0;
  String _notes      = '';
  String _flight     = '';
  bool   _bookForSelf    = true;
  int    _heroPage       = 0;
  int    _capacityTab    = 0; // 0 = Luggage, 1 = Seating
  int    _luggageOption  = 0; // 0, 1, 2
  int    _seatingOption  = 0; // 0, 1, 2, 3
  String _guestTitle     = 'Sr.';
  String _guestFirstName = '';
  String _guestLastName  = '';
  String _guestEmail     = '';
  String _guestPhone     = '';

  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedCardId;
  bool _awaitingPaymentIntent = false;
  Quote? _quote;

  // Scroll-based sticky selector
  final ScrollController _leftScrollCtrl = ScrollController();
  bool _showStickySelector = false;

  // Approximate offset at which the vehicle cards scroll out of view:
  // heading (~110px) + 28px gap + 430px cards + 28px gap ≈ 596px
  static const double _kStickyThreshold = 560.0;

  double get _km =>
      _formData?.routeDistanceKm != null && _formData!.routeDistanceKm > 0
          ? _formData!.routeDistanceKm
          : 25.0;

  double get _price =>
      DefaultPricing.estimate(_selected, _service, km: _km, hours: _hours);

  @override
  void initState() {
    super.initState();
    _leftScrollCtrl.addListener(() {
      final show = _leftScrollCtrl.offset > _kStickyThreshold;
      if (show != _showStickySelector) {
        setState(() => _showStickySelector = show);
      }
    });
  }

  @override
  void dispose() {
    _leftScrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formData == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is BookingFormData) {
        _formData = extra;
        _service  = extra.serviceType;
        _hours    = extra.hours;
      }
      _loadSavedCards();
    }
  }

  void _loadSavedCards() {
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
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (kIsWeb) {
        final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const _WebAuthGateDialog(),
          ),
        );
        if (ok != true || !mounted) return;
        final freshAuth = context.read<AuthBloc>().state;
        if (freshAuth is! AuthAuthenticated) return;
      } else {
        return;
      }
    }
    final freshState = context.read<AuthBloc>().state;
    if (freshState is! AuthAuthenticated) return;
    final user = freshState.user;

    final origin = _formData?.origin;
    final destination = _formData?.destination ??
        (_service == ServiceType.byTheHour ? origin : null);
    if (origin == null || destination == null) {
      showLuxSnackbar(context, 'Selecciona el punto de recogida y el destino',
          isError: true);
      return;
    }
    setState(() => _loading = true);

    // 1. Fixed price from the server (the on-screen price is an estimate).
    final quoteResult = await sl<BookingRepository>().requestQuote(
      vehicleClass: _selected,
      serviceType: _service,
      origin: origin,
      destination: _formData?.destination,
      routeDistanceKm: _formData?.routeDistanceKm,
      hours: _service == ServiceType.byTheHour ? _hours : null,
    );
    if (!mounted) return;
    final quote = quoteResult.fold<Quote?>((f) {
      setState(() => _loading = false);
      showLuxSnackbar(context, f.message, isError: true);
      return null;
    }, (q) => q);
    if (quote == null) return;

    if ((quote.amount - _price).abs() >= 1) {
      final accepted = await _confirmUpdatedPrice(quote.amount);
      if (!mounted) return;
      if (accepted != true) {
        setState(() => _loading = false);
        return;
      }
    }
    _quote = quote;

    // 2. Authorise the card for exactly the quoted amount.
    if (user.stripeCustomerId != null &&
        user.stripeCustomerId!.isNotEmpty &&
        _selectedCardId != null) {
      setState(() => _awaitingPaymentIntent = true);
      context.read<PaymentBloc>().add(PaymentIntentRequested(
            quoteId: quote.id,
            stripeCustomerId: user.stripeCustomerId!,
          ));
      return;
    }
    _createBooking();
  }

  Future<bool?> _confirmUpdatedPrice(double amount) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _kCardBg,
          title: const Text('Precio confirmado',
              style: TextStyle(fontFamily: kSerif, fontSize: 24, color: _kTextPrimary)),
          content: Text(
            'El precio fijo de tu viaje es ${LuxMoney.format(amount)}. '
            'No cambiará aunque haya tráfico.',
            style: const TextStyle(fontFamily: kSans, fontSize: 14, height: 1.5, color: _kTextSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: _kTextTertiary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LD.cta,
                foregroundColor: LD.onCta,
                elevation: 0,
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

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
      // The authorisation is linked to the booking; the backend captures it
      // when the ride completes and releases it on cancellation.
      _createBooking(paymentIntentId: clientSecret.split('_secret_').first);
    } on StripeException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showLuxSnackbar(context, e.error.message ?? 'El pago falló',
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showLuxSnackbar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _showAddGuestDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _AddGuestDialog(
        initialTitle:     _guestTitle,
        initialFirstName: _guestFirstName,
        initialLastName:  _guestLastName,
        initialEmail:     _guestEmail,
        initialPhone:     _guestPhone,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _bookForSelf   = false;
        _guestTitle     = result['title']     ?? 'Sr.';
        _guestFirstName = result['firstName'] ?? '';
        _guestLastName  = result['lastName']  ?? '';
        _guestEmail     = result['email']     ?? '';
        _guestPhone     = result['phone']     ?? '';
      });
    }
  }

  void _createBooking({String? paymentIntentId}) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final origin = _formData?.origin;
    // Hourly charters may not have a destination: the chauffeur stays with you.
    final destination = _formData?.destination ??
        (_service == ServiceType.byTheHour ? origin : null);
    if (origin == null || destination == null) {
      setState(() => _loading = false);
      showLuxSnackbar(context, 'Selecciona el punto de recogida y el destino',
          isError: true);
      return;
    }
    final quote = _quote;
    if (quote == null) {
      setState(() => _loading = false);
      return;
    }
    final scheduledAt = _formData?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));

    String? combinedNotes;
    if (!_bookForSelf && _guestFirstName.isNotEmpty) {
      final guestInfo =
          'Pasajero: $_guestTitle $_guestFirstName $_guestLastName'
          '${_guestEmail.isNotEmpty ? ' · $_guestEmail' : ''}'
          '${_guestPhone.isNotEmpty ? ' · $_guestPhone' : ''}';
      combinedNotes = _notes.isNotEmpty ? '$guestInfo\n$_notes' : guestInfo;
    } else {
      combinedNotes = _notes.isNotEmpty ? _notes : null;
    }

    context.read<BookingBloc>().add(BookingCreateRequested(
          origin: origin,
          destination: destination,
          vehicleClass: _selected,
          serviceType: _service,
          scheduledAt: scheduledAt,
          riderId: authState.user.id,
          estimatedPrice: quote.amount,
          notes: combinedNotes,
          passengerCount: _passengers,
          luggageCount: _luggage,
          flightNumber: _flight.trim().isEmpty ? null : _flight.trim().toUpperCase(),
          hours: _service == ServiceType.byTheHour ? _hours : null,
          currency: AppConfig.currency,
          stripePaymentIntentId: paymentIntentId,
          quoteId: quote.id,
        ));
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BookingBloc, BookingState>(listener: (ctx, state) {
          if (state is BookingCreated) {
            setState(() => _loading = false);
            ctx.go('/reserva/${state.booking.id}/confirmada', extra: state.booking);
          }
          if (state is BookingError) {
            setState(() => _loading = false);
            showLuxSnackbar(ctx, state.message, isError: true);
          }
        }),
        BlocListener<PaymentBloc, PaymentState>(listener: (ctx, state) {
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
            _handleStripeConfirm(state.clientSecret);
          }
          if (state is PaymentError) {
            setState(() { _loading = false; _awaitingPaymentIntent = false; });
            showLuxSnackbar(ctx, state.message, isError: true);
          }
        }),
      ],
      child: isWeb(context) ? _webLayout() : _mobileLayout(),
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
              onVehicleChanged: (vc) => setState(() { _selected = vc; _luggageOption = 0; _seatingOption = 0; _heroPage = 0; }),
              km: _km,
            ),
            const Divider(color: _kDivider, height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _webLeft()),
                  _webRight(),
                ],
              ),
            ),
          ],
        ),
      );

  // Per-vehicle dark atmospheric backgrounds
  // Section background — near-white with a whisper of the vehicle's accent
  static Color _vehicleBg(VehicleClass vc) {
    switch (vc) {
      case VehicleClass.business:    return const Color(0xFFF0F5FB); // icy navy white
      case VehicleClass.firstClass:  return const Color(0xFFF5F0FB); // icy lavender white
      case VehicleClass.businessVan: return const Color(0xFFF0F4FB); // icy slate white
      case VehicleClass.electric:    return const Color(0xFFEFF9F5); // icy mint white
    }
  }

  // Card accent tint (unselected). Pure white (selected) is applied in the card widget itself.
  static Color _vehicleCardBg(VehicleClass vc) {
    switch (vc) {
      case VehicleClass.business:    return const Color(0xFFF8FBFF); // barely blue-white
      case VehicleClass.firstClass:  return const Color(0xFFFAF8FF); // barely lavender-white
      case VehicleClass.businessVan: return const Color(0xFFF8FAFF); // barely slate-white
      case VehicleClass.electric:    return const Color(0xFFF7FDF9); // barely mint-white
    }
  }

  // Stronger accent tint shown when a card IS selected
  static Color _vehicleCardBgSelected(VehicleClass vc) {
    switch (vc) {
      case VehicleClass.business:    return const Color(0xFFEDF4FF); // soft navy tint
      case VehicleClass.firstClass:  return const Color(0xFFF0EBFF); // soft lavender tint
      case VehicleClass.businessVan: return const Color(0xFFEBF2FF); // soft slate tint
      case VehicleClass.electric:    return const Color(0xFFE8FAF2); // soft mint tint
    }
  }

  Widget _webLeft() => SingleChildScrollView(
        controller: _leftScrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Animated light-tinted hero section — changes with selected vehicle ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              color: _vehicleBg(_selected),
              padding: const EdgeInsets.fromLTRB(56, 52, 40, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _selected.label.toUpperCase(),
                      key: ValueKey(_selected),
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3.5,
                        color: _kTextTertiary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Heading
                  const Text(
                    'Elige tu\nexperiencia',
                    style: TextStyle(
                      fontFamily: kSerif,
                      fontSize: 60,
                      fontWeight: FontWeight.w300,
                      color: _kTextPrimary,
                      letterSpacing: -0.5,
                      height: 0.93,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Precio fijo · Sin sorpresas · Disponible en todo el mundo',
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: _kTextTertiary,
                      letterSpacing: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Vehicle cards
                  SizedBox(
                    height: 490,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.zero,
                      itemCount: _kVehicleClasses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final vc = _kVehicleClasses[i];
                        return _VehicleCard(
                          vehicleClass: vc,
                          price: DefaultPricing.estimate(vc, _service,
                              km: _km, hours: _hours),
                          selected: _selected == vc,
                          cardBg: _vehicleCardBg(vc),
                          cardBgSelected: _vehicleCardBgSelected(vc),
                          onTap: () => setState(() {
                            _selected = vc;
                            _luggageOption = 0;
                            _seatingOption = 0;
                            _heroPage = 0;
                          }),
                          serviceType: _service,
                          hours: _service == ServiceType.byTheHour
                              ? _hours
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Light content below ──
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 48, 40, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero carousel ────────────────────────────────────────
                  _webHeroSection(),
                  const SizedBox(height: 52),

                  // ── Descriptive heading ──────────────────────────────────
                  _webDescriptiveText(),

                  // ── What's included ──────────────────────────────────────
                  _webWhatsIncluded(),

                  const SizedBox(height: 64),
                  const Divider(color: _kDivider, height: 1),
                  const SizedBox(height: 64),

                  // ── Capacity ─────────────────────────────────────────────
                  _webCapacity(),

                  const SizedBox(height: 64),
                  const Divider(color: _kDivider, height: 1),
                  const SizedBox(height: 64),

                  // ── Price breakdown ──────────────────────────────────────
                  _webPriceBreakdown(),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Luggage capacity per vehicle ───────────────────────────────────────────

  static List<String> _luggageOptionsFor(VehicleClass vc) {
    switch (vc) {
      case VehicleClass.business:
        return ['2 x De mano', '2 x Facturada estándar', '1 x Extra grande'];
      case VehicleClass.firstClass:
        return ['3 x De mano', '2 x Facturada estándar', '1 x Extra grande'];
      case VehicleClass.businessVan:
        return ['8 x De mano', '6 x Facturada estándar', '4 x Extra grande'];
      case VehicleClass.electric:
        return ['2 x De mano', '2 x Facturada estándar', '1 x Extra grande'];
    }
  }

  static List<String> _seatingOptionsFor(VehicleClass vc) {
    switch (vc) {
      case VehicleClass.business:
      case VehicleClass.firstClass:
      case VehicleClass.electric:
        return ['Tres pasajeros', 'Dos pasajeros', 'Asiento de bebé'];
      case VehicleClass.businessVan:
        return ['Cinco pasajeros', 'Dos pasajeros'];
    }
  }

  // (Seating images are now per-vehicle assets via _seatingAsset() — see below)

  // ── Hero slides per vehicle class ──────────────────────────────────────────

  static const _kVehicleSlides = <VehicleClass, List<List<String>>>{
    VehicleClass.business: [
      [
        'Confort ejecutivo en cada trayecto',
        'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Puntual, profesional y perfectamente refinado',
        'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Llega con confianza, en cada ocasión',
        'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Premium hecho práctico para el ejecutivo moderno',
        'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=900&q=90&auto=format&fit=crop',
      ],
    ],
    VehicleClass.firstClass: [
      [
        'Un nivel extraordinario de lujo te espera',
        'https://images.unsplash.com/photo-1563720223523-e75db7d32e5c?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Diseñado para quienes exigen lo mejor',
        'https://images.unsplash.com/photo-1485291571150-772bcfc10da5?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Privacidad y elegancia en cada traslado',
        'https://images.unsplash.com/photo-1493238792000-8113da705763?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Primera clase, de puerta a puerta',
        'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=900&q=90&auto=format&fit=crop',
      ],
    ],
    VehicleClass.businessVan: [
      [
        'Espacio y confort para todo tu equipo',
        'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Traslados grupales sin estrés y con puntualidad',
        'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'El viaje perfecto para familias y grupos',
        'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Capacidad premium, sin compromiso en el confort',
        'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=90&auto=format&fit=crop',
      ],
    ],
    VehicleClass.electric: [
      [
        'Totalmente eléctrico, silencioso y de nivel ejecutivo',
        'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Cero emisiones, máxima experiencia de lujo',
        'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=90&auto=format&fit=crop',
      ],
    ],
  };

  List<List<String>> get _currentSlides =>
      _kVehicleSlides[_selected] ?? _kVehicleSlides[VehicleClass.business]!;

  Widget _webHeroSection() {
    final slides = _currentSlides;
    final page   = _heroPage.clamp(0, slides.length - 1);
    final slide  = slides[page];
    final text   = slide[0];
    final img    = slide[1];

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        height: 340,
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── Gradient background ─────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFC8DDD0), // left: soft desaturated green
                    Color(0xFFE6E2DA), // right: warm beige/grey
                  ],
                ),
              ),
            ),

            // ── Car image — lateral, ~80% width, centered ───────────────
            Positioned.fill(
              child: Align(
                child: FractionallySizedBox(
                  widthFactor: 0.82,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Image.network(
                      img,
                      key: ValueKey(img),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),

            // ── Glassmorphism bottom overlay ────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                    ),
                    child: Row(
                      children: [

                        // Text + dots
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  text,
                                  key: ValueKey(text),
                                  style: TextStyle(
                                    fontFamily: kSans,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Carousel dots
                              Row(
                                children: List.generate(
                                  slides.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.only(right: 6),
                                    width:  i == page ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == page
                                          ? _kPanelAccent
                                          : Colors.white.withValues(alpha: 0.40),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Right arrow button
                        GestureDetector(
                          onTap: () => setState(
                              () => _heroPage = (page + 1) % slides.length),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: _kTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Descriptive heading ────────────────────────────────────────────────────

  Widget _webDescriptiveText() => const Padding(
        padding: EdgeInsets.only(right: 40),
        child: Text(
          'Premium hecho práctico. Asientos espaciosos, un viaje suave '
          'y recogidas puntuales que mantienen tu día en ritmo.',
          style: TextStyle(
            fontFamily: kSans,
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
            height: 1.6,
            letterSpacing: -0.2,
          ),
        ),
      );

  // ── What's Included ────────────────────────────────────────────────────────

  Widget _webWhatsIncluded() {
    const accent = Color(0xFF4A7FD4);
    const itemText = TextStyle(
      fontFamily: kSans,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: Color(0xFF444444),
      height: 1.5,
    );

    Widget item(IconData icon, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: accent),
            const SizedBox(height: 14),
            Text(label, style: itemText),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: _kDivider, height: 1),
        const SizedBox(height: 60),

        // Title (serif, editorial)
        const Text(
          'Qué incluye',
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: 38,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 44),

        // Row 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: item(Icons.badge_outlined,
                'Recibimiento personalizado')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.timer_outlined,
                'Hasta 60 minutos de espera gratuita')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.event_available_outlined,
                'Cancelación gratuita hasta 1 hora antes de la recogida')),
          ],
        ),
        const SizedBox(height: 50),

        // Row 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: item(Icons.cable_outlined,
                'Cargadores para iOS y Android a bordo')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.clean_hands_outlined,
                'Pañuelos y toallitas desinfectantes de cortesía')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.water_drop_outlined,
                'Agua fría de cortesía incluida')),
          ],
        ),
      ],
    );
  }

  // ── Capacity ───────────────────────────────────────────────────────────────

  // Returns asset path for luggage image, with per-vehicle + per-option keys.
  // User places files at: assets/images/booking/luggage/<vehicle>_<0|1|2>.png
  // e.g. assets/images/booking/luggage/business_0.png
  static String _luggageAsset(VehicleClass vc, int option) {
    final key = switch (vc) {
      VehicleClass.business    => 'business',
      VehicleClass.firstClass  => 'first_class',
      VehicleClass.businessVan => 'van',
      VehicleClass.electric    => 'electric',
    };
    return 'assets/images/booking/luggage/${key}_$option.png';
  }

  // Fallback network images per option (generic, shown if asset not uploaded yet)
  static const _kLuggageFallbacks = [
    'https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=900&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1553440569-bcc63803a83d?w=900&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=900&q=90&auto=format&fit=crop',
  ];

  // Returns asset path for seating image, with per-vehicle + per-option keys.
  // User places files at: assets/images/booking/seating/<vehicle>_<0|1|2|3>.png
  static String _seatingAsset(VehicleClass vc, int option) {
    final key = switch (vc) {
      VehicleClass.business    => 'business',
      VehicleClass.firstClass  => 'first_class',
      VehicleClass.businessVan => 'van',
      VehicleClass.electric    => 'electric',
    };
    return 'assets/images/booking/seating/${key}_$option.png';
  }

  // Fallback network images per seating option index
  static const _kSeatingFallbacks = [
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1629310576093-9ddd4e666490?w=900&q=90&auto=format&fit=crop',
  ];

  Widget _webCapacity() {
    // Per-vehicle luggage options (dynamic)
    final luggageOpts = _luggageOptionsFor(_selected);

    // Tab widget
    Widget tab(String label, bool active, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: kSans,
                    fontSize: 15,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? _kTextPrimary : _kTextSub,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2.5,
                width: 60,
                decoration: BoxDecoration(
                  color: active ? _kPanelAccent : Colors.transparent,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Capacidad',
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: 38,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 24),

        // Tabs + underline
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                tab('Equipaje', _capacityTab == 0,
                    () => setState(() => _capacityTab = 0)),
                const SizedBox(width: 36),
                tab('Asientos', _capacityTab == 1,
                    () => setState(() => _capacityTab = 1)),
              ],
            ),
            const Divider(color: _kDivider, height: 1),
          ],
        ),

        const SizedBox(height: 22),

        if (_capacityTab == 0) ...[
          // Description
          const Text(
            'Basado en tamaños estándar de equipaje, que pueden diferir de los tuyos. '
            'Puedes especificar los detalles de tu equipaje en las '
            '"Notas de recogida" en el siguiente paso.',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 14,
              color: _kTextSub,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),

          // Segmented control
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEBE4),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(luggageOpts.length, (i) {
                final active = _luggageOption == i;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _luggageOption = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: active ? _kPanelAccent : Colors.transparent,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        luggageOpts[i],
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: active ? Colors.white : _kTextPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 22),

          // Luggage image — per vehicle + per option
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim, child: child),
              child: _CapacityImage(
                key: ValueKey('lug-$_selected-$_luggageOption'),
                assetPath: _luggageAsset(
                    _selected,
                    _luggageOption.clamp(0, luggageOpts.length - 1)),
                fallbackUrl: _kLuggageFallbacks[
                    _luggageOption.clamp(0, _kLuggageFallbacks.length - 1)],
                fallbackIcon: Icons.luggage_outlined,
              ),
            ),
          ),
        ] else ...[
          // ── Seating — mirrors Luggage structure ──────────────────────────
          Builder(builder: (_) {
            final seatingOpts = _seatingOptionsFor(_selected);
            final safeIdx     = _seatingOption.clamp(0, seatingOpts.length - 1);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elige la configuración de asientos que mejor se adapte a tus necesidades. '
                  'Los asientos especiales (infantil / bebé) deben solicitarse con anticipación '
                  'y están sujetos a disponibilidad.',
                  style: TextStyle(
                    fontFamily: kSans,
                    fontSize: 14,
                    color: _kTextSub,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),

                // Segmented control
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEBE4),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(seatingOpts.length, (i) {
                      final active = safeIdx == i;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _seatingOption = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              color: active ? _kPanelAccent : Colors.transparent,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              seatingOpts[i],
                              style: TextStyle(
                                fontFamily: kSans,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: active ? Colors.white : _kTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 22),

                // Seating image — per vehicle + per option
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim, child: child),
                    child: _CapacityImage(
                      key: ValueKey('seat-$_selected-$safeIdx'),
                      assetPath: _seatingAsset(_selected, safeIdx),
                      fallbackUrl: _kSeatingFallbacks[
                          safeIdx.clamp(0, _kSeatingFallbacks.length - 1)],
                      fallbackIcon: Icons.airline_seat_recline_extra,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  // ── Price breakdown ────────────────────────────────────────────────────────

  Widget _webPriceBreakdown() {
    final base = _price * 0.9185;
    final tax  = _price * 0.0815;

    // Dotted line row
    Widget priceLine(String label, double amount) => Padding(
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
                child: LayoutBuilder(builder: (_, c) {
                  const dW = 4.0, gap = 5.0;
                  final count = (c.maxWidth / (dW + gap)).floor();
                  return Row(
                    children: List.generate(count, (_) => Container(
                      width: dW, height: 1,
                      margin: const EdgeInsets.only(right: gap),
                      color: _kBorder,
                    )),
                  );
                }),
              ),
              const SizedBox(width: 10),
              Text(
                'Bs ${amount.toStringAsFixed(2)}',
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
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4ECF9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline,
                    size: 13, color: _kPanelAccent),
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
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F1),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Desglose de precio',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 20),

          // Base fare
          priceLine('Tarifa base', base),
          const Divider(color: _kDivider, height: 1),

          // Tax
          priceLine('Impuesto estimado', tax),
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

  Widget _webRight() => Container(
        width: 440,
        color: _kCardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dark map ─────────────────────────────────────────────────
            Container(
              height: 260,
              color: const Color(0xFF1A1A1A),
              child: _formData?.origin != null
                  ? LuxMap(
                      origin: _formData!.origin,
                      destination: _formData!.destination,
                      routeInfo: RouteInfo(
                        polylinePoints: _formData!.polylinePoints,
                        distanceKm: _formData!.routeDistanceKm,
                        durationMin: _formData!.routeDurationMin,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined,
                              size: 40, color: Colors.grey.shade700),
                          const SizedBox(height: 8),
                          Text('Vista previa de ruta',
                              style: TextStyle(
                                fontFamily: kSans,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              )),
                        ],
                      ),
                    ),
            ),

            const Divider(color: _kDivider, height: 1),

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
      );

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
            Text(
              'Bs ${_price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: kSerif,
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: _kTextPrimary,
                letterSpacing: -0.5,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),

        // ── Selection summary ───────────────────────────────────────────
        const SizedBox(height: 20),
        _SummaryAddressRow(
          icon: Icons.location_on_outlined,
          label: 'Recogida',
          value: _formData?.origin.displayName ?? '—',
        ),
        const SizedBox(height: 12),
        _SummaryAddressRow(
          icon: Icons.flag_outlined,
          label: 'Destino',
          value: _formData?.destination?.displayName ?? '—',
        ),

        const SizedBox(height: 24),
        const Divider(color: _kDivider, height: 1),
        const SizedBox(height: 20),

        // ── Book for myself ─────────────────────────────────────────────
        _BookOptionCard(
          icon: Icons.person_outlined,
          iconBg: const Color(0xFFDDE6F8),
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
          iconBg: !_bookForSelf
              ? const Color(0xFFDDE6F8)
              : const Color(0xFFF0EDE8),
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

        const SizedBox(height: 20),
        const Divider(color: _kDivider, height: 1),
        const SizedBox(height: 16),

        // ── Apply offer + All fees included ─────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 15, color: _kTextPrimary),
                    SizedBox(width: 7),
                    Text(
                      'Aplicar oferta',
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Todos los cargos incluidos',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 12,
                color: _kTextSub,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        PriceBreakdown(
          vehicleClass: _selected,
          serviceType: _service,
          km: _km,
          hours: _hours,
        ),
        if (_savedCards.isEmpty) ...[
          const SizedBox(height: 16),
          const _PayOnTripNotice(),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────────

  Widget _mobileLayout() => Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _kBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: _kBg,
            foregroundColor: _kTextPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: _kTextPrimary),
            titleTextStyle: TextStyle(
              fontFamily: kSans, fontSize: 12,
              fontWeight: FontWeight.w600, color: _kTextSub, letterSpacing: 1.4,
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => _step > 0 ? setState(() => _step--) : context.pop(),
            ),
            title: Text('PASO ${_step + 1} DE 3'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _LightStepIndicator(
                  steps: const ['Vehículo', 'Detalles', 'Confirmar'],
                  currentStep: _step,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _mobileStepContent(),
                ),
              ),
              _LightPriceBar(
                price: _price,
                label: _step < 2 ? 'Continuar' : 'Confirmar reserva',
                loading: _loading,
                onConfirm: _step < 2 ? () => setState(() => _step++) : _confirm,
              ),
            ],
          ),
        ),
      );

  Widget _mobileStepContent() {
    switch (_step) {
      case 0: return _mobileVehicleStep();
      case 1: return _detailsStep();
      case 2: return _confirmStep();
      default: return const SizedBox();
    }
  }

  Widget _mobileVehicleStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Elige tu experiencia',
              style: TextStyle(
                fontFamily: kSerif, fontSize: 28,
                fontWeight: FontWeight.w600, color: _kTextPrimary,
              )),
          const SizedBox(height: 16),
          _LightServiceTypeTab(
            selected: _service,
            onChanged: (t) => setState(() => _service = t),
          ),
          if (_service == ServiceType.byTheHour) ...[
            const SizedBox(height: 12),
            _LightHourRow(hours: _hours, onChanged: (h) => setState(() => _hours = h)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 340,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              itemCount: _kVehicleClasses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final vc = _kVehicleClasses[i];
                return _VehicleCard(
                  vehicleClass: vc,
                  price: DefaultPricing.estimate(vc, _service, km: _km, hours: _hours),
                  selected: _selected == vc,
                  onTap: () => setState(() => _selected = vc),
                  serviceType: _service,
                  hours: _service == ServiceType.byTheHour ? _hours : null,
                  width: 190,
                  cardBg: _vehicleCardBg(vc),
                  cardBgSelected: _vehicleCardBgSelected(vc),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _MobileVehicleDetail(
                key: ValueKey(_selected), vehicleClass: _selected),
          ),
        ],
      );

  Widget _detailsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DETALLES DEL VIAJE',
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w700,
                color: _kTextTertiary, letterSpacing: 2.0,
              )),
          const SizedBox(height: 20),
          _LightCounterRow(label: 'Pasajeros', icon: Icons.person_outline,
              value: _passengers, min: 1, max: _selected.capacity,
              onChanged: (v) => setState(() => _passengers = v)),
          const SizedBox(height: 10),
          _LightCounterRow(label: 'Equipaje', icon: Icons.luggage_outlined,
              value: _luggage, min: 0, max: 6,
              onChanged: (v) => setState(() => _luggage = v)),
          const SizedBox(height: 20),
          _LightTextField(label: 'Número de vuelo', hint: 'ej. LA 8810 (opcional)',
              icon: Icons.flight_outlined, onChanged: (v) => _flight = v),
          const SizedBox(height: 12),
          _LightTextField(label: 'Solicitudes especiales',
              hint: 'Asiento infantil, letrero de bienvenida…',
              icon: Icons.chat_bubble_outline_rounded, maxLines: 3,
              onChanged: (v) => _notes = v),
        ],
      );

  Widget _confirmStep() {
    final hasRoute = _formData?.origin != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRoute) ...[
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: SizedBox(
              height: 180,
              child: LuxMap(origin: _formData!.origin, destination: _formData!.destination),
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text('RESUMEN DE RESERVA',
            style: TextStyle(fontFamily: kSans, fontSize: 10,
                fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: _kBorder),
          ),
          child: Column(children: [
            _SummaryRow('Servicio',    _service.label,       isFirst: true),
            _SummaryRow('Vehículo',    _selected.label),
            if (_formData?.origin != null)
              _SummaryRow('Desde',     _formData!.origin.displayName),
            if (_formData?.destination != null)
              _SummaryRow('Hasta',       _formData!.destination!.displayName),
            _SummaryRow(
              _service == ServiceType.byTheHour ? 'Duración' : 'Distancia',
              _service == ServiceType.byTheHour ? '$_hours horas'
                  : _km > 0 ? '${_km.toStringAsFixed(1)} km' : '—',
            ),
            if (_formData?.routeDurationMin != null && _formData!.routeDurationMin > 0)
              _SummaryRow('Duración est.', '${_formData!.routeDurationMin} min'),
            _SummaryRow('Pasajeros', '$_passengers'),
            _SummaryRow('Equipaje',    '$_luggage bultos'),
            if (_flight.isNotEmpty) _SummaryRow('Vuelo', _flight),
            if (_notes.isNotEmpty)  _SummaryRow('Notas',  _notes),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F7F3),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(children: [
                const Text('TOTAL ESTIMADO',
                    style: TextStyle(fontFamily: kSans, fontSize: 10,
                        fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 1.8)),
                const Spacer(),
                Text(LuxMoney.format(_price.ceil()),
                    style: const TextStyle(fontFamily: kSans, fontSize: 18,
                        fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.3)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('DESGLOSE',
            style: TextStyle(fontFamily: kSans, fontSize: 10,
                fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
        const SizedBox(height: 8),
        PriceBreakdown(
          vehicleClass: _selected,
          serviceType: _service,
          km: _km,
          hours: _hours,
        ),
        const SizedBox(height: 20),
        if (_savedCards.isEmpty)
          const _PayOnTripNotice()
        else ...[
          const Text('MÉTODO DE PAGO',
              style: TextStyle(fontFamily: kSans, fontSize: 10,
                  fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
          const SizedBox(height: 12),
          ..._savedCards.map((card) {
            final id    = card['id'] as String;
            final brand = _cap(card['brand'] as String? ?? 'Card');
            final last4 = card['last4'] as String? ?? '****';
            final isSel = _selectedCardId == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCardId = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                        color: isSel ? LD.accent : _kBorder,
                        width: isSel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.credit_card_outlined, size: 20,
                        color: isSel ? LD.accent : _kTextSub),
                    const SizedBox(width: 12),
                    Expanded(child: Text('$brand •••• $last4',
                        style: const TextStyle(fontFamily: kSans,
                            fontSize: 13, fontWeight: FontWeight.w500, color: _kTextPrimary))),
                    if (isSel)
                      Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                            color: LD.cta, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 11, color: LD.onCta),
                      ),
                  ]),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 16),
        _GuaranteeRow(Icons.event_available_outlined,
            'Cancelación gratuita hasta 1 hora antes de la recogida'),
        const SizedBox(height: 8),
      ],
    );
  }
}

