import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../../payments/presentation/bloc/payment_bloc.dart';
import '../bloc/booking_bloc.dart';

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
const _kPanelAccent  = LD.sph;           // #1B4F8A sapphire

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
  String _guestTitle     = 'Mr.';
  String _guestFirstName = '';
  String _guestLastName  = '';
  String _guestEmail     = '';
  String _guestPhone     = '';

  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedCardId;
  bool _awaitingPaymentIntent = false;

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
    setState(() => _loading = true);

    if (user.stripeCustomerId != null &&
        user.stripeCustomerId!.isNotEmpty &&
        _selectedCardId != null) {
      setState(() => _awaitingPaymentIntent = true);
      context.read<PaymentBloc>().add(PaymentIntentRequested(
            amount: _price,
            currency: 'bob',
            stripeCustomerId: user.stripeCustomerId!,
          ));
      return;
    }
    _createBooking();
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
      _createBooking();
    } on StripeException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showLuxSnackbar(context, e.error.message ?? 'Payment failed',
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
        _guestTitle     = result['title']     ?? 'Mr.';
        _guestFirstName = result['firstName'] ?? '';
        _guestLastName  = result['lastName']  ?? '';
        _guestEmail     = result['email']     ?? '';
        _guestPhone     = result['phone']     ?? '';
      });
    }
  }

  void _createBooking() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final origin = _formData?.origin ?? const Place(address: 'Pickup', lat: 0, lng: 0);
    final destination = _formData?.destination ?? const Place(address: 'Destination', lat: 0, lng: 0);
    final scheduledAt = _formData?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));

    String? combinedNotes;
    if (!_bookForSelf && _guestFirstName.isNotEmpty) {
      final guestInfo =
          'Passenger: $_guestTitle $_guestFirstName $_guestLastName'
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
          estimatedPrice: _price,
          notes: combinedNotes,
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
            ctx.go('/ride/${state.booking.id}');
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
                    'Choose your\nexperience',
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
                    'Fixed price · No surprises · Available worldwide',
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
        return ['2 x Carry-on', '2 x Standard check-in', '1 x Extra large check-in'];
      case VehicleClass.firstClass:
        return ['3 x Carry-on', '2 x Standard check-in', '1 x Extra large check-in'];
      case VehicleClass.businessVan:
        return ['8 x Carry-on', '6 x Standard check-in', '4 x Extra large check-in'];
      case VehicleClass.electric:
        return ['2 x Carry-on', '2 x Standard check-in', '1 x Extra large check-in'];
    }
  }

  static List<String> _seatingOptionsFor(VehicleClass vc) {
    switch (vc) {
      case VehicleClass.business:
      case VehicleClass.firstClass:
      case VehicleClass.electric:
        return ['Three passengers', 'Two passengers', 'Baby seat'];
      case VehicleClass.businessVan:
        return ['Five passengers', 'Two passengers'];
    }
  }

  // (Seating images are now per-vehicle assets via _seatingAsset() — see below)

  // ── Hero slides per vehicle class ──────────────────────────────────────────

  static const _kVehicleSlides = <VehicleClass, List<List<String>>>{
    VehicleClass.business: [
      [
        'Executive comfort for every journey',
        'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Punctual, professional, and perfectly refined',
        'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Arrive with confidence, every single time',
        'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Premium made practical for the modern executive',
        'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=900&q=90&auto=format&fit=crop',
      ],
    ],
    VehicleClass.firstClass: [
      [
        'An extraordinary level of luxury awaits',
        'https://images.unsplash.com/photo-1563720223523-e75db7d32e5c?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Crafted for those who demand the finest',
        'https://images.unsplash.com/photo-1485291571150-772bcfc10da5?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Privacy and elegance in every transfer',
        'https://images.unsplash.com/photo-1493238792000-8113da705763?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'First class, from door to door',
        'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=900&q=90&auto=format&fit=crop',
      ],
    ],
    VehicleClass.businessVan: [
      [
        'Space and comfort for your entire team',
        'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Seamless group transfers, stress-free arrivals',
        'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'The perfect ride for families and groups',
        'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Premium capacity, zero compromise on comfort',
        'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=90&auto=format&fit=crop',
      ],
    ],
    VehicleClass.electric: [
      [
        'All-electric, quiet and executive-level comfort',
        'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=900&q=90&auto=format&fit=crop',
      ],
      [
        'Zero emissions, maximum luxury experience',
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
          'Premium made practical. Spacious seating, a smooth journey, '
          'and punctual pickups that keep your day in rhythm.',
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
          "What's included",
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
                'Personal meet & greet')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.timer_outlined,
                'Includes up to 60 minutes of free wait time')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.event_available_outlined,
                'Free to cancel up to 1 hour before pickup')),
          ],
        ),
        const SizedBox(height: 50),

        // Row 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: item(Icons.cable_outlined,
                'iOS and Android chargers onboard')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.clean_hands_outlined,
                'Complimentary tissues & sanitizing wipes')),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.water_drop_outlined,
                'Complimentary chilled water included')),
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
          'Capacity',
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
                tab('Luggage', _capacityTab == 0,
                    () => setState(() => _capacityTab = 0)),
                const SizedBox(width: 36),
                tab('Seating', _capacityTab == 1,
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
            'Based on standard luggage sizes, which may differ from yours. '
            'You can specify the details of your luggage in the '
            '"Pickup notes" on the next step.',
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
                  'Choose the seating configuration that fits your needs. '
                  'Special seats (child / baby) must be requested in advance '
                  'and are subject to availability.',
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
            'Price breakdown',
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
          priceLine('Base fare', base),
          const Divider(color: _kDivider, height: 1),

          // Tax
          priceLine('Estimated tax', tax),
          const Divider(color: _kBorder, height: 1, thickness: 1.2),
          const SizedBox(height: 22),

          // Please note section
          const Text(
            'Please note:',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 14),

          note(
            'Passenger and luggage capacity limits must be respected for '
            'safety reasons. If exceeded, the driver may refuse the service.',
          ),
          note(
            'Vehicle images are for reference only. The actual vehicle may '
            'vary while maintaining equivalent or superior quality.',
          ),
          note(
            'Additional needs (wheelchair, child seat, extra items) can be '
            'added in "Pickup notes". Choose Business Van for larger groups '
            'or extra luggage.',
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
                          Text('Route preview',
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
          label: 'Pickup',
          value: _formData?.origin.displayName ?? '—',
        ),
        const SizedBox(height: 12),
        _SummaryAddressRow(
          icon: Icons.flag_outlined,
          label: 'Destination',
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
          title: 'Book for myself',
          subtitle: 'Book with your account information',
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
          title: 'Book for a guest',
          subtitle: (!_bookForSelf && _guestFirstName.isNotEmpty)
              ? '$_guestTitle $_guestFirstName $_guestLastName'
              : 'Select or add a guest',
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
                      'Apply offer',
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
              'All fees included',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 12,
                color: _kTextSub,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

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
            title: Text('STEP ${_step + 1} OF 3'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _LightStepIndicator(
                  steps: const ['Vehicle', 'Details', 'Confirm'],
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
                label: _step < 2 ? 'Continue' : 'Confirm Booking',
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
          const Text('Choose your experience',
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
          const Text('TRIP DETAILS',
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w700,
                color: _kTextTertiary, letterSpacing: 2.0,
              )),
          const SizedBox(height: 20),
          _LightCounterRow(label: 'Passengers', icon: Icons.person_outline,
              value: _passengers, min: 1, max: _selected.capacity,
              onChanged: (v) => setState(() => _passengers = v)),
          const SizedBox(height: 10),
          _LightCounterRow(label: 'Luggage', icon: Icons.luggage_outlined,
              value: _luggage, min: 0, max: 6,
              onChanged: (v) => setState(() => _luggage = v)),
          const SizedBox(height: 20),
          _LightTextField(label: 'Flight Number', hint: 'e.g. LA 8810 (optional)',
              icon: Icons.flight_outlined, onChanged: (v) => _flight = v),
          const SizedBox(height: 12),
          _LightTextField(label: 'Special Requests',
              hint: 'Child seat, meeting sign…',
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
        const Text('BOOKING SUMMARY',
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
            _SummaryRow('Service',    _service.label,       isFirst: true),
            _SummaryRow('Vehicle',    _selected.label),
            if (_formData?.origin != null)
              _SummaryRow('From',     _formData!.origin.displayName),
            if (_formData?.destination != null)
              _SummaryRow('To',       _formData!.destination!.displayName),
            _SummaryRow(
              _service == ServiceType.byTheHour ? 'Duration' : 'Distance',
              _service == ServiceType.byTheHour ? '$_hours hours'
                  : _km > 0 ? '${_km.toStringAsFixed(1)} km' : '—',
            ),
            if (_formData?.routeDurationMin != null && _formData!.routeDurationMin > 0)
              _SummaryRow('Est. Duration', '${_formData!.routeDurationMin} min'),
            _SummaryRow('Passengers', '$_passengers'),
            _SummaryRow('Luggage',    '$_luggage bags'),
            if (_flight.isNotEmpty) _SummaryRow('Flight', _flight),
            if (_notes.isNotEmpty)  _SummaryRow('Notes',  _notes),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F7F3),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(children: [
                const Text('TOTAL · FIXED PRICE',
                    style: TextStyle(fontFamily: kSans, fontSize: 10,
                        fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 1.8)),
                const Spacer(),
                Text('Bs ${_price.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: kSans, fontSize: 18,
                        fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.3)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        if (_savedCards.isEmpty)
          _OutlinedBtn(label: 'Add Payment Method', icon: Icons.add_card_outlined,
              onPressed: () => context.push('/payment/add'))
        else ...[
          const Text('PAYMENT METHOD',
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
                        color: isSel ? LuxColors.sapphire : _kBorder,
                        width: isSel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.credit_card_outlined, size: 20,
                        color: isSel ? LuxColors.sapphire : _kTextSub),
                    const SizedBox(width: 12),
                    Expanded(child: Text('$brand •••• $last4',
                        style: const TextStyle(fontFamily: kSans,
                            fontSize: 13, fontWeight: FontWeight.w500, color: _kTextPrimary))),
                    if (isSel)
                      Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                            color: LuxColors.sapphire, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 11, color: Colors.white),
                      ),
                  ]),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 16),
        _GuaranteeRow(Icons.event_available_outlined,
            'Free cancellation up to 1 hour before pickup'),
        const SizedBox(height: 8),
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
    this.km = 25.0,
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
  final double km;

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        decoration: const BoxDecoration(
          color: _kBg,
          border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Row(
          children: [
            // ── Luxelane logo mark ───────────────────────────────────────
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  border: Border.all(color: _kTextPrimary, width: 1.5),
                ),
                child: const Center(
                  child: Text('L', style: TextStyle(
                    fontFamily: kSerif, fontSize: 15,
                    fontWeight: FontWeight.w500, color: _kTextPrimary,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              const Text('LUXELANE', style: TextStyle(
                fontFamily: kSans, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 3.0,
                color: _kTextPrimary,
              )),
            ]),
            const SizedBox(width: 40),
            // ── Back button ──────────────────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onBack,
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: _kTextSub),
                  SizedBox(width: 5),
                  Text('Back',
                      style: TextStyle(fontFamily: kSans, fontSize: 11,
                          fontWeight: FontWeight.w400, letterSpacing: 0.8,
                          color: _kTextSub)),
                ]),
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
                              final price = DefaultPricing.estimate(
                                  vc, service, km: km, hours: hours);
                              final isActive = selectedVehicle == vc;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => onVehicleChanged?.call(vc),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFEEF2FC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.zero,
                                        border: Border.all(
                                          color: isActive
                                              ? _kPanelAccent
                                              : _kBorder,
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
                                                  ? _kPanelAccent
                                                  : _kTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 1,
                                            height: 12,
                                            color: isActive
                                                ? _kPanelAccent
                                                    .withValues(alpha: 0.3)
                                                : _kBorder,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bs ${price.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontFamily: kSans,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isActive
                                                  ? _kPanelAccent
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

            // ── Route summary pill ───────────────────────────────────────
            if (formData?.origin != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          style: const TextStyle(fontFamily: kSans,
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: _kTextPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 14,
                            color: _kTextSub),
                      ),
                      Flexible(
                        child: Text(
                          formData!.destination?.displayName ?? '—',
                          style: const TextStyle(fontFamily: kSans,
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: _kTextPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(width: 16),

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
    required this.cardBg,
    required this.cardBgSelected,
    required this.onTap,
    this.serviceType = ServiceType.oneWay,
    this.hours,
    this.width,
  });

  final VehicleClass vehicleClass;
  final double       price;
  final bool         selected;
  final Color        cardBg;
  final Color        cardBgSelected;
  final VoidCallback onTap;
  final ServiceType  serviceType;
  final int?         hours;
  final double?      width;

  // Asset path for transparent-background PNG
  String get _assetPath {
    switch (vehicleClass) {
      case VehicleClass.business:
        return 'assets/images/vehicles/business/car.png';
      case VehicleClass.firstClass:
        return 'assets/images/vehicles/first_class/car.png';
      case VehicleClass.businessVan:
        return 'assets/images/vehicles/van/car.png';
      case VehicleClass.electric:
        return 'assets/images/vehicles/electric/car.png';
    }
  }

  // Network fallback
  String get _fallbackUrl {
    switch (vehicleClass) {
      case VehicleClass.business:
        return 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=700&q=90&auto=format&fit=crop';
      case VehicleClass.firstClass:
        return 'https://images.unsplash.com/photo-1563720223523-e75db7d32e5c?w=700&q=90&auto=format&fit=crop';
      case VehicleClass.businessVan:
        return 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=700&q=90&auto=format&fit=crop';
      case VehicleClass.electric:
        return 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=700&q=90&auto=format&fit=crop';
    }
  }

  // Sapphire-family accent per vehicle (border + pill)
  Color get _accentColor {
    switch (vehicleClass) {
      case VehicleClass.business:    return const Color(0xFF3A7BD5);
      case VehicleClass.firstClass:  return const Color(0xFF7B4DB5);
      case VehicleClass.businessVan: return const Color(0xFF2E6AC8);
      case VehicleClass.electric:    return const Color(0xFF2A9E72);
    }
  }

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late AnimationController _popCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _tiltAnim;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    // Scale: pops up then settles (elastic feel)
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.98), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.01), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.01, end: 1.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut));
    // Tilt: brief perspective lean on the Y axis (3D feel)
    _tiltAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_VehicleCard old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _popCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Car image is fixed at 480 px wide, anchored to the LEFT edge.
    // Unselected card (210 px) → shows left ~44 % of the car (corner only).
    // Selected card (500 px)   → shows the entire car + 20 px right margin.
    const kCarW    = 480.0;
    const kCarLeft = 0.0;   // car left edge flush with card left edge
    const kSelPad  = 20.0;  // extra breathing room on the right when selected

    final baseW   = widget.width ?? 210.0;
    final targetW = widget.selected ? kCarW + kSelPad : baseW;

    final accent = widget._accentColor;
    final bgColor = widget.selected ? widget.cardBgSelected : widget.cardBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _popCtrl,
          builder: (context, child) {
            final perspective = Matrix4.identity()
              ..setEntry(3, 2, 0.0008) // perspective depth
              ..rotateY(_tiltAnim.value);
            return Transform(
              transform: perspective * (Matrix4.identity()..scale(_scaleAnim.value)),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
            width: targetW,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected ? accent : const Color(0xFFE0DDD8),
                width: widget.selected ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.selected
                      ? accent.withAlpha(55)
                      : Colors.black.withAlpha(18),
                  blurRadius: widget.selected ? 32 : 12,
                  spreadRadius: widget.selected ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // Hover lift (only when not selected)
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                  0, _hover && !widget.selected ? -5 : 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Vehicle image — fills most of the card ───────────────
                  // Car is anchored to the BOTTOM-RIGHT corner at a FIXED
                  // 440 px width.  As the card expands from 210 → 310 px the
                  // ClipRRect reveals an extra 100 px of the car's left side.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [

                          // bg colour
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            color: bgColor,
                          ),

                          // radial spotlight — centred towards bottom-left
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.5, 0.5),
                                    radius: 0.9,
                                    colors: [
                                      accent.withAlpha(
                                          widget.selected ? 65 : 32),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── car — fixed 480 px, pinned to BOTTOM-LEFT ───────
                          // Card clips the right side of the image.
                          // Unselected (210 px): left 44 % visible = corner only.
                          // Selected   (500 px): full car visible + 20 px margin.
                          Positioned(
                            bottom: -14,
                            left:   kCarLeft,
                            child: SizedBox(
                              width: kCarW,
                              child: _CarImage(
                                assetPath: widget._assetPath,
                                fallbackUrl: widget._fallbackUrl,
                              ),
                            ),
                          ),

                          // bottom fade — blends car into info strip
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      bgColor,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // checkmark badge
                          Positioned(
                            top: 14, right: 14,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: widget.selected ? 1.0 : 0.0,
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withAlpha(90),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.check,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Info strip — always at the very bottom ───────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name row + selected pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.vehicleClass.label,
                                style: const TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w400,
                                  color: _kTextPrimary,
                                  letterSpacing: 0.1,
                                  height: 1.1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: widget.selected ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withAlpha(22),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: accent.withAlpha(60), width: 1),
                                ),
                                child: Text(
                                  'SELECTED',
                                  style: TextStyle(
                                    fontFamily: kSans,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.6,
                                    color: accent,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Description
                        Text(
                          widget.vehicleClass.description,
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: _kTextTertiary,
                            letterSpacing: 0.2,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Price + capacity
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bs ${widget.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: kSerif,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: _kTextPrimary,
                                height: 1,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEBE4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline,
                                      size: 11, color: _kTextSub),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${widget.vehicleClass.capacity}',
                                    style: const TextStyle(
                                      fontFamily: kSans,
                                      fontSize: 10,
                                      color: _kTextSub,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}

/// Tries local asset first; falls back to a placeholder icon if not found.
class _CarImage extends StatelessWidget {
  const _CarImage({required this.assetPath, required this.fallbackUrl});
  final String assetPath;
  final String fallbackUrl;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.black12,
          ),
        ),
      );
}

/// Capacity section image: tries local asset, falls back to network, then icon.
class _CapacityImage extends StatelessWidget {
  const _CapacityImage({
    super.key,
    required this.assetPath,
    required this.fallbackUrl,
    required this.fallbackIcon,
  });
  final String   assetPath;
  final String   fallbackUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        width: double.infinity,
        height: 290,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.network(
          fallbackUrl,
          width: double.infinity,
          height: 290,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 290,
            color: const Color(0xFFF0EDE8),
            child: Center(
              child: Icon(fallbackIcon, size: 60, color: _kTextTertiary),
            ),
          ),
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

  final IconData  icon;
  final Color     iconBg;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final bool      selected;
  final VoidCallback onTap;
  final Widget?   trailing;

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
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontFamily: kSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                          fontFamily: kSans,
                          fontSize: 12,
                          color: _kTextSub,
                          fontWeight: FontWeight.w400,
                        )),
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
  final bool         loading;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: GestureDetector(
          onTap: loading ? null : onReserve,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 52,
            color: loading ? _kPanelAccent.withValues(alpha: 0.6) : _kPanelAccent,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Colors.white))
                  : Text(
                      'RESERVE ${selected.label.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
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
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFEEEBE4) : const Color(0xFFF5F4F1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14,
              color: enabled ? _kTextPrimary : _kTextTertiary),
        ),
      );
}

// ── GUARANTEE ROW ─────────────────────────────────────────────────────────────

Widget _GuaranteeRow(IconData icon, String text) => Row(children: [
      Icon(icon, size: 15, color: _kTextSub),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontFamily: kSans, fontSize: 11, color: _kTextSub)),
      ),
    ]);

// ── MOBILE VEHICLE DETAIL ─────────────────────────────────────────────────────

class _MobileVehicleDetail extends StatelessWidget {
  const _MobileVehicleDetail({super.key, required this.vehicleClass});
  final VehicleClass vehicleClass;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F3),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: _kDivider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(vehicleClass.description,
                style: const TextStyle(fontFamily: kSans,
                    fontSize: 12, color: _kTextSub))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEBE4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Up to ${vehicleClass.capacity} pax',
                  style: const TextStyle(fontFamily: kSans,
                      fontSize: 10, fontWeight: FontWeight.w600, color: _kTextSub)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(color: _kDivider, height: 1),
          const SizedBox(height: 10),
          _GuaranteeRow(Icons.price_check_outlined, 'All fees included'),
          const SizedBox(height: 6),
          _GuaranteeRow(Icons.event_available_outlined, 'Free cancellation up to 1h before'),
        ]),
      );
}

// ── SUMMARY ROW (confirm step) ────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isFirst = false});
  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) => Column(children: [
        if (!isFirst) const Divider(color: _kDivider, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text(label,
                style: const TextStyle(fontFamily: kSans, fontSize: 12, color: _kTextSub)),
            const SizedBox(width: 16),
            Flexible(child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontFamily: kSans, fontSize: 12,
                    fontWeight: FontWeight.w500, color: _kTextPrimary))),
          ]),
        ),
      ]);
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
    final h = compact ? 38.0 : 42.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: ServiceType.values.map((t) {
          final active = selected == t;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.all(3),
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 0),
              decoration: BoxDecoration(
                color: active ? _kTextPrimary : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              alignment: Alignment.center,
              child: compact
                  ? Text(t.label,
                      style: TextStyle(
                        fontFamily: kSans, fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : _kTextSub,
                      ))
                  : null,
            ),
          );
        }).toList(),
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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Btn(icon: Icons.remove, enabled: hours > 2, onTap: () => onChanged(hours - 1)),
          SizedBox(width: 40,
              child: Text('${hours}h', textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: kSans, fontSize: 13,
                      fontWeight: FontWeight.w600, color: _kTextPrimary))),
          _Btn(icon: Icons.add, enabled: hours < 12, onTap: () => onChanged(hours + 1)),
        ]),
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
          color: _kCardBg, borderRadius: BorderRadius.zero,
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          const Text('Duration',
              style: TextStyle(fontFamily: kSans, fontSize: 13,
                  fontWeight: FontWeight.w500, color: _kTextPrimary)),
          const Spacer(),
          _Btn(icon: Icons.remove, enabled: hours > 2, onTap: () => onChanged(hours - 1)),
          SizedBox(width: 48, child: Text('${hours}h', textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kSans, fontSize: 15,
                  fontWeight: FontWeight.w600, color: _kTextPrimary))),
          _Btn(icon: Icons.add, enabled: hours < 12, onTap: () => onChanged(hours + 1)),
        ]),
      );
}

// ── LIGHT COUNTER ROW (mobile) ────────────────────────────────────────────────

class _LightCounterRow extends StatelessWidget {
  const _LightCounterRow({
    required this.label, required this.icon,
    required this.value, required this.min, required this.max,
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
          color: _kCardBg, borderRadius: BorderRadius.zero,
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: _kTextSub),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontFamily: kSans, fontSize: 13,
                  fontWeight: FontWeight.w500, color: _kTextPrimary))),
          _Btn(icon: Icons.remove, enabled: value > min, onTap: () => onChanged(value - 1)),
          SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kSans, fontSize: 15,
                  fontWeight: FontWeight.w600, color: _kTextPrimary))),
          _Btn(icon: Icons.add, enabled: value < max, onTap: () => onChanged(value + 1)),
        ]),
      );
}

// ── LIGHT TEXT FIELD ──────────────────────────────────────────────────────────

class _LightTextField extends StatelessWidget {
  const _LightTextField({
    required this.label, this.hint, required this.icon,
    required this.onChanged, this.maxLines = 1,
  });
  final String label;
  final String? hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged, maxLines: maxLines,
        style: const TextStyle(fontFamily: kSans, fontSize: 13,
            color: _kTextPrimary),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          hintStyle: const TextStyle(fontFamily: kSans, fontSize: 13,
              color: _kTextTertiary, fontWeight: FontWeight.w300),
          labelStyle: const TextStyle(fontFamily: kSans, fontSize: 12,
              color: _kTextSub, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 18, color: _kTextSub),
          filled: true, fillColor: _kCardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: _kTextPrimary, width: 1.5)),
        ),
      );
}

// ── OUTLINED ACTION BTN ───────────────────────────────────────────────────────

class _OutlinedBtn extends StatelessWidget {
  const _OutlinedBtn({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: _kCardBg,
              borderRadius: BorderRadius.zero, border: Border.all(color: _kBorder)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: _kTextSub),
            const SizedBox(width: 8),
            Text(label.toUpperCase(),
                style: const TextStyle(fontFamily: kSans, fontSize: 11,
                    fontWeight: FontWeight.w600, color: _kTextPrimary, letterSpacing: 1.2)),
          ]),
        ),
      );
}

// ── MOBILE PRICE BAR ──────────────────────────────────────────────────────────

class _LightPriceBar extends StatelessWidget {
  const _LightPriceBar({
    required this.price, required this.onConfirm,
    this.loading = false, this.label = 'Confirm Booking',
  });
  final double price;
  final VoidCallback onConfirm;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FIXED PRICE',
                    style: TextStyle(fontFamily: kSans, fontSize: 9,
                        fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 1.5)),
                Text('Bs ${price.toStringAsFixed(0)}',
                    style: const TextStyle(fontFamily: kSans, fontSize: 22,
                        fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.5)),
              ]),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTextPrimary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontFamily: kSans, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
                child: loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                    : Text(label.toUpperCase()),
              ),
            ),
          ),
        ]),
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
            return Expanded(child: Container(height: 1,
                color: i ~/ 2 < currentStep ? _kTextPrimary : _kBorder));
          }
          final idx    = i ~/ 2;
          final done   = idx < currentStep;
          final active = idx == currentStep;
          return Column(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: done ? _kTextPrimary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done || active ? _kTextPrimary : _kBorder,
                    width: active ? 1.5 : 1),
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : Text('${idx + 1}',
                      style: TextStyle(fontFamily: kSans, fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: active ? _kTextPrimary : _kTextTertiary))),
            ),
            const SizedBox(height: 3),
            Text(steps[idx], style: TextStyle(fontFamily: kSans, fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? _kTextPrimary : _kTextTertiary, letterSpacing: 0.3)),
          ]);
        }),
      );
}

// ── WEB AUTH GATE DIALOG ──────────────────────────────────────────────────────

class _WebAuthGateDialog extends StatefulWidget {
  const _WebAuthGateDialog();
  @override
  State<_WebAuthGateDialog> createState() => _WebAuthGateDialogState();
}

class _WebAuthGateDialogState extends State<_WebAuthGateDialog> {
  bool _showRegister = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
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
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _loading = true);
    if (_showRegister) {
      context.read<AuthBloc>().add(RegisterRequested(
            email: email, password: pass,
            displayName: _nameCtrl.text.trim().isNotEmpty
                ? _nameCtrl.text.trim()
                : email.split('@').first,
            phone: '', role: UserRole.rider));
    } else {
      context.read<AuthBloc>().add(LoginRequested(email: email, password: pass));
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthAuthenticated) Navigator.of(ctx).pop(true);
          if (state is AuthError) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: LuxColors.error));
          }
        },
        child: Dialog(
          backgroundColor: LuxColors.blackSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.lg),
            side: const BorderSide(color: LuxColors.blackBorder),
          ),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(LuxSpacing.xxl),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                        _showRegister ? 'Create an account' : 'Sign in to continue',
                        style: LuxTypography.headlineLarge.copyWith(fontSize: 24))),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded,
                              color: LuxColors.whiteTertiary)),
                    ]),
                    const SizedBox(height: LuxSpacing.sm),
                    Text(
                      _showRegister
                          ? 'Create your Luxelane account to complete the booking.'
                          : 'Sign in to confirm your booking.',
                      style: LuxTypography.bodyMedium),
                    const SizedBox(height: LuxSpacing.xl),
                    if (_showRegister) ...[
                      LuxTextField(label: 'Full Name', hint: 'Your name',
                          prefixIcon: Icons.person_outline,
                          controller: _nameCtrl, onChanged: (_) {}),
                      const SizedBox(height: LuxSpacing.md),
                    ],
                    LuxTextField(label: 'Email', hint: 'you@example.com',
                        prefixIcon: Icons.email_outlined, controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress, onChanged: (_) {}),
                    const SizedBox(height: LuxSpacing.md),
                    LuxTextField(label: 'Password', hint: '••••••••',
                        prefixIcon: Icons.lock_outline, controller: _passCtrl,
                        obscureText: _obscure, onChanged: (_) {},
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: LuxColors.whiteTertiary, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )),
                    const SizedBox(height: LuxSpacing.xl),
                    LuxButton(label: _showRegister ? 'Create Account' : 'Sign In',
                        loading: _loading, onPressed: _loading ? null : _submit),
                    const SizedBox(height: LuxSpacing.md),
                    TextButton(
                      onPressed: () => setState(() => _showRegister = !_showRegister),
                      child: Text(
                        _showRegister
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Create one",
                        style: LuxTypography.bodyMedium.copyWith(color: LuxColors.sapphire)),
                    ),
                  ]),
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
  border: const UnderlineInputBorder(
      borderSide: BorderSide(color: _kBorder)),
  enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: _kBorder)),
  focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: _kTextPrimary, width: 1.5)),
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
    this.initialTitle     = 'Mr.',
    this.initialFirstName = '',
    this.initialLastName  = '',
    this.initialEmail     = '',
    this.initialPhone     = '',
  });

  final String initialTitle;
  final String initialFirstName;
  final String initialLastName;
  final String initialEmail;
  final String initialPhone;

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  static const _kTitles = ['Mr.', 'Mrs.', 'Ms.', 'Dr.', 'Prof.'];

  late String _title;
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _title     = widget.initialTitle;
    _firstCtrl = TextEditingController(text: widget.initialFirstName);
    _lastCtrl  = TextEditingController(text: widget.initialLastName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(<String, String>{
      'title':     _title,
      'firstName': _firstCtrl.text.trim(),
      'lastName':  _lastCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'phone':     _phoneCtrl.text.trim(),
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
                      'Add new guest',
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
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder, width: 1.5),
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.close, size: 18, color: _kTextSub),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Description ─────────────────────────────────────────────
              const Text(
                "Enter your guests' information and treat them to a premium service. "
                'We will keep them informed of their journey throughout the process. '
                "Don't worry, we will not share any payment or invoice information with them.",
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
              _guestFieldLabel('Title'),
              DropdownButtonFormField<String>(
                value: _title,
                style: _kGuestValueStyle,
                dropdownColor: _kBg,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kTextPrimary, width: 1.5)),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  filled: false,
                  isDense: false,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kTextSub, size: 22),
                items: _kTitles.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: _kGuestValueStyle),
                )).toList(),
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
                        _guestFieldLabel('First name'),
                        TextField(
                          controller: _firstCtrl,
                          style: _kGuestValueStyle,
                          decoration: _guestFieldDecor("Guest's first name"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _guestFieldLabel('Last name'),
                        TextField(
                          controller: _lastCtrl,
                          style: _kGuestValueStyle,
                          decoration: _guestFieldDecor("Guest's last name"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ── Email ───────────────────────────────────────────────────
              _guestFieldLabel('Email address'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: _kGuestValueStyle,
                decoration: _guestFieldDecor("Guest's email address"),
              ),

              const SizedBox(height: 26),

              // ── Mobile number ───────────────────────────────────────────
              _guestFieldLabel("Guest's mobile number"),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: _kGuestValueStyle,
                decoration: _guestFieldDecor("Guest's mobile number").copyWith(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined, size: 17, color: _kTextSub),
                        SizedBox(width: 3),
                        Icon(Icons.language, size: 15, color: _kTextSub),
                        SizedBox(width: 3),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 15, color: _kTextSub),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your guest will receive their journey notifications on this number',
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 11,
                  color: _kTextSub,
                  fontWeight: FontWeight.w400,
                ),
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
                        horizontal: 44, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Confirm'),
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
        Icon(icon, size: 18, color: const Color(0xFF777777)),
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
                  color: Color(0xFFBBBBBB),
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
                  color: Color(0xFF111111),
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
