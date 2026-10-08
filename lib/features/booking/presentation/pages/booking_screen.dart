import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/env.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/waiting_policy.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_states.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/auth_error_messages.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../company/data/company_repository.dart';
import '../../../company/domain/company.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../../loyalty/data/loyalty_repository.dart';
import '../../../loyalty/domain/loyalty.dart';
import '../../../loyalty/presentation/loyalty_widgets.dart';
import '../../../payments/presentation/bloc/payment_bloc.dart';
import '../bloc/booking_bloc.dart';
import '../../domain/booking_error_codes.dart';
import '../booking_error_l10n.dart';

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
  int  _days    = 1; // chauffeur by the day (hourly only)
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
  _GuestTitle _guestTitle = _GuestTitle.mr;
  String _guestFirstName = '';
  String _guestLastName  = '';
  String _guestEmail     = '';
  String _guestPhone     = '';

  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedCardId;
  bool _awaitingPaymentIntent = false;
  Quote? _quote;

  // Promo code: previewed against the on-screen estimate, then applied by the
  // server in the quote.
  final TextEditingController _promoCtrl = TextEditingController();
  String? _promo;
  double _promoDiscount = 0;
  String? _promoError;
  bool _promoChecking = false;
  String? _promoCheckedFor;

  // Luxelane Circle standing (off unless the program is enabled).
  LoyaltyStatus _loyalty = LoyaltyStatus.off;

  // Corporate billing (riders who belong to a company account).
  Company? _company;
  bool _billCompany = false;
  String? _costCenter;
  String _billingRef = '';

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
      DefaultPricing.estimate(_selected, _service, km: _km, hours: _hours, days: _days);

  String get _promoKey => '${_selected.name}|${_price.round()}';

  double get _promoAmount => _promo != null && _promoCheckedFor == _promoKey ? _promoDiscount : 0;

  double get _loyaltyAmount {
    final tier = _loyalty.enabled ? _loyalty.tier : null;
    return tier == null ? 0 : Loyalty.discount(_price, tier.discountPct);
  }

  /// Discounts don't stack: the larger applies, a promo wins ties (as the server).
  bool get _loyaltyWins => _loyaltyAmount > _promoAmount;

  /// Estimate after the previewed discount (only while it matches the inputs).
  double get _payable {
    final off = _loyaltyWins ? _loyaltyAmount : _promoAmount;
    return (_price - off).clamp(0, _price).toDouble();
  }

  String get _discountLabel {
    final l = context.l10n;
    return _loyaltyWins
        ? l.loyaltyDiscountLine(_loyalty.tier!.id.localizedName(l))
        : l.promoDiscountLine(_promo ?? '');
  }

  Future<void> _applyPromo([String? raw]) async {
    final code = (raw ?? _promoCtrl.text).replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (code.isEmpty) return;
    final key = _promoKey;
    setState(() {
      _promoChecking = true;
      _promoError = null;
    });
    final r = await sl<BookingRepository>().checkPromoCode(code: code, fare: _price, vehicleClass: _selected);
    if (!mounted) return;
    setState(() {
      _promoChecking = false;
      if (r.error == null) {
        _promo = code;
        _promoDiscount = r.discount;
        _promoCheckedFor = key;
      } else {
        _promo = null;
        _promoDiscount = 0;
        _promoCheckedFor = null;
        _promoError = r.error;
      }
    });
  }

  void _removePromo() => setState(() {
        _promo = null;
        _promoDiscount = 0;
        _promoCheckedFor = null;
        _promoError = null;
        _promoCtrl.clear();
      });

  /// Re-previews the code when the vehicle or the fare changes.
  void _recheckPromoIfStale() {
    if (_promo == null || _promoChecking || _promoCheckedFor == _promoKey) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _promo != null && !_promoChecking && _promoCheckedFor != _promoKey) _applyPromo(_promo);
    });
  }

  Widget _daysRow() => _LightCounterRow(
        label: context.l10n.bookingDaysLabel,
        icon: Icons.date_range_outlined,
        value: _days,
        min: 1,
        max: DefaultPricing.maxDays,
        onChanged: (v) => setState(() => _days = v),
      );

  Widget _promoField() => _PromoCodeField(
        controller: _promoCtrl,
        applied: _promo,
        discount: _promoCheckedFor == _promoKey ? _promoDiscount : null,
        error: _promoError,
        checking: _promoChecking,
        onApply: () => _applyPromo(),
        onRemove: _removePromo,
        note: _promo != null && _loyaltyWins ? context.l10n.promoLoyaltyBetter : null,
      );

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
    _promoCtrl.dispose();
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
        _days     = extra.days;
      }
      _loadSavedCards();
      _loadCompany();
      _loadLoyalty();
    }
  }

  Future<void> _loadLoyalty() async {
    if (!sl.isRegistered<LoyaltyRepository>()) return;
    final status = await sl<LoyaltyRepository>().myStatus();
    if (mounted && status.enabled) setState(() => _loyalty = status);
  }

  Future<void> _loadCompany() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated || !sl.isRegistered<CompanyRepository>()) return;
    try {
      final repo = sl<CompanyRepository>();
      final membership = await repo.watchMembership(auth.user.id).first;
      if (membership == null) return;
      final company = await repo.watchCompany(membership.companyId).first;
      if (!mounted || company == null || !company.active) return;
      setState(() {
        _company = company;
        // Company members book for work by default.
        _billCompany = true;
      });
    } catch (_) {
      // Not readable (e.g. removed from the company): personal billing only.
    }
  }

  bool get _corporate => _billCompany && _company != null;

  Widget _corporatePanel() => _CorporateBillingPanel(
        company: _company!,
        billCompany: _billCompany,
        costCenter: _costCenter,
        onBillCompany: (v) => setState(() => _billCompany = v),
        onCostCenter: (v) => setState(() => _costCenter = v),
        onReference: (v) => _billingRef = v.trim(),
      );

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
      showLuxSnackbar(context, context.l10n.bookingSelectRouteError,
          isError: true);
      return;
    }
    if (_corporate && _company!.requireCostCenter && _costCenter == null) {
      showLuxSnackbar(context, context.l10n.corpErrorCostCenterRequired, isError: true);
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
      days: _service == ServiceType.byTheHour ? _days : null,
      promoCode: _promo,
    );
    if (!mounted) return;
    final quote = quoteResult.fold<Quote?>((f) {
      setState(() => _loading = false);
      showLuxSnackbar(context, localizedBookingError(context.l10n, f.message),
          isError: true);
      return null;
    }, (q) => q);
    if (quote == null) return;

    // The code stopped applying (expired, used up…): say why; the price
    // check below then asks to confirm the full price.
    if (_promo != null && quote.promoCode == null) {
      final loyaltyBetter = quote.promoError == PromoErrorCodes.loyaltyBetter;
      showLuxSnackbar(context, localizedBookingError(context.l10n, quote.promoError ?? 'promo/invalid'),
          isError: !loyaltyBetter);
      setState(() {
        _promoError = loyaltyBetter ? null : quote.promoError;
        _promo = null;
        _promoDiscount = 0;
        _promoCheckedFor = null;
      });
    }

    if ((quote.amount - _payable).abs() >= 1) {
      final accepted = await _confirmUpdatedPrice(quote.amount);
      if (!mounted) return;
      if (accepted != true) {
        setState(() => _loading = false);
        return;
      }
    }
    _quote = quote;

    // 2. Authorise the card for exactly the quoted amount.
    // Corporate rides are invoiced to the company: no card authorisation.
    if (!_corporate &&
        user.stripeCustomerId != null &&
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
          title: Text(ctx.l10n.bookingPriceConfirmedTitle,
              style: const TextStyle(fontFamily: kSerif, fontSize: 24, color: _kTextPrimary)),
          content: Text(
            ctx.l10n.bookingPriceConfirmedBody(LuxMoney.format(amount)),
            style: const TextStyle(fontFamily: kSans, fontSize: 14, height: 1.5, color: _kTextSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.commonCancel,
                  style: const TextStyle(color: _kTextTertiary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LD.cta,
                foregroundColor: LD.onCta,
                elevation: 0,
              ),
              child: Text(ctx.l10n.commonContinue),
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
        // Stripe localizes its own decline messages; fall back to ours.
        showLuxSnackbar(
            context,
            e.error.localizedMessage ?? context.l10n.bookingPaymentFailed,
            isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        showLuxSnackbar(context, context.l10n.bookingPaymentFailed, isError: true);
      }
    }
  }

  Future<void> _showAddGuestDialog() async {
    final result = await showDialog<_GuestInfo>(
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
        _bookForSelf    = false;
        _guestTitle     = result.title;
        _guestFirstName = result.firstName;
        _guestLastName  = result.lastName;
        _guestEmail     = result.email;
        _guestPhone     = result.phone;
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
      showLuxSnackbar(context, context.l10n.bookingSelectRouteError,
          isError: true);
      return;
    }
    final quote = _quote;
    if (quote == null) {
      setState(() => _loading = false);
      return;
    }
    final scheduledAt = _formData?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));

    // The person the chauffeur picks up: the rider, or the guest they booked
    // for. Name goes on the meet & greet sign; phone lets the chauffeur call.
    final forGuest = !_bookForSelf && _guestFirstName.isNotEmpty;
    final passengerName = forGuest
        ? '$_guestFirstName $_guestLastName'.trim()
        : authState.user.displayName.trim();
    final passengerPhone = forGuest ? _guestPhone.trim() : authState.user.phone.trim();
    // Stored on the booking for the chauffeur and operations (Spanish-speaking
    // team), not shown to the rider, so it stays in Spanish regardless of the
    // rider's language.
    final notes = [
      if (forGuest && _guestEmail.isNotEmpty) 'Correo del pasajero: $_guestEmail',
      if (_notes.isNotEmpty) _notes,
    ].join('\n');

    context.read<BookingBloc>().add(BookingCreateRequested(
          origin: origin,
          destination: destination,
          vehicleClass: _selected,
          serviceType: _service,
          scheduledAt: scheduledAt,
          riderId: authState.user.id,
          estimatedPrice: quote.amount,
          notes: notes.isEmpty ? null : notes,
          passengerName: passengerName.isEmpty ? null : passengerName,
          passengerPhone: passengerPhone.isEmpty ? null : passengerPhone,
          passengerCount: _passengers,
          luggageCount: _luggage,
          flightNumber: _flight.trim().isEmpty ? null : _flight.trim().toUpperCase(),
          hours: _service == ServiceType.byTheHour ? _hours : null,
          currency: AppConfig.currency,
          stripePaymentIntentId: paymentIntentId,
          quoteId: quote.id,
          companyId: _corporate ? _company!.id : null,
          costCenter: _corporate ? _costCenter : null,
          billingReference: _corporate && _billingRef.isNotEmpty ? _billingRef : null,
          promoCode: quote.promoCode,
        ));
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _recheckPromoIfStale();
    return MultiBlocListener(
      listeners: [
        BlocListener<BookingBloc, BookingState>(listener: (ctx, state) {
          if (state is BookingCreated) {
            setState(() => _loading = false);
            ctx.go('/reserva/${state.booking.id}/confirmada', extra: state.booking);
          }
          if (state is BookingError) {
            setState(() => _loading = false);
            showLuxSnackbar(ctx, localizedBookingError(ctx.l10n, state.message),
                isError: true);
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
                      _selected.localizedLabel(context.l10n).toUpperCase(),
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
                  Text(
                    context.l10n.bookingHeroTitle,
                    style: const TextStyle(
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
                  Text(
                    context.l10n.bookingHeroTagline,
                    style: const TextStyle(
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
                              km: _km, hours: _hours, days: _days),
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

  static List<String> _luggageOptionsFor(VehicleClass vc, AppLocalizations l) {
    final (carryOn, checked, extraLarge) = switch (vc) {
      VehicleClass.business    => (2, 2, 1),
      VehicleClass.firstClass  => (3, 2, 1),
      VehicleClass.businessVan => (8, 6, 4),
      VehicleClass.electric    => (2, 2, 1),
    };
    return [
      l.bookingLuggageCarryOn(carryOn),
      l.bookingLuggageChecked(checked),
      l.bookingLuggageExtraLarge(extraLarge),
    ];
  }

  static List<String> _seatingOptionsFor(VehicleClass vc, AppLocalizations l) {
    switch (vc) {
      case VehicleClass.business:
      case VehicleClass.firstClass:
      case VehicleClass.electric:
        return [l.bookingSeatingThree, l.bookingSeatingTwo, l.bookingSeatingInfantSeat];
      case VehicleClass.businessVan:
        return [l.bookingSeatingFive, l.bookingSeatingTwo];
    }
  }

  // (Seating images are now per-vehicle assets via _seatingAsset() — see below)

  // ── Hero slides per vehicle class: (caption, image URL) ────────────────────

  static List<(String, String)> _slidesFor(VehicleClass vc, AppLocalizations l) {
    const img = 'https://images.unsplash.com/photo-';
    const q = '?w=900&q=90&auto=format&fit=crop';
    switch (vc) {
      case VehicleClass.business:
        return [
          (l.bookingSlideBusiness1, '${img}1555215695-3004980ad54e$q'),
          (l.bookingSlideBusiness2, '${img}1549317661-bd32c8ce0db2$q'),
          (l.bookingSlideBusiness3, '${img}1511919884226-fd3cad34687c$q'),
          (l.bookingSlideBusiness4, '${img}1503736334956-4c8f8e92946d$q'),
        ];
      case VehicleClass.firstClass:
        return [
          (l.bookingSlideFirst1, '${img}1563720223523-e75db7d32e5c$q'),
          (l.bookingSlideFirst2, '${img}1485291571150-772bcfc10da5$q'),
          (l.bookingSlideFirst3, '${img}1493238792000-8113da705763$q'),
          (l.bookingSlideFirst4, '${img}1617788138017-80ad40651399$q'),
        ];
      case VehicleClass.businessVan:
        return [
          (l.bookingSlideVan1, '${img}1519641471654-76ce0107ad1b$q'),
          (l.bookingSlideVan2, '${img}1544620347-c4fd4a3d5957$q'),
          (l.bookingSlideVan3, '${img}1570125909232-eb263c188f7e$q'),
          (l.bookingSlideVan4, '${img}1560958089-b8a1929cea89$q'),
        ];
      case VehicleClass.electric:
        return [
          (l.bookingSlideElectric1, '${img}1617788138017-80ad40651399$q'),
          (l.bookingSlideElectric2, '${img}1560958089-b8a1929cea89$q'),
        ];
    }
  }

  Widget _webHeroSection() {
    final slides = _slidesFor(_selected, context.l10n);
    final page   = _heroPage.clamp(0, slides.length - 1);
    final (text, img) = slides[page];

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

  Widget _webDescriptiveText() => Padding(
        padding: const EdgeInsets.only(right: 40),
        child: Text(
          context.l10n.bookingDescriptiveText,
          style: const TextStyle(
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
    final l = context.l10n;
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
        Text(
          l.bookingIncludedTitle,
          style: const TextStyle(
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
                l.bookingIncludedMeetGreet)),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.timer_outlined,
                l.bookingIncludedWaiting(WaitingPolicy.airportFreeMinutes))),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.event_available_outlined,
                l.bookingIncludedFreeCancellation)),
          ],
        ),
        const SizedBox(height: 50),

        // Row 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: item(Icons.cable_outlined,
                l.bookingIncludedChargers)),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.clean_hands_outlined,
                l.bookingIncludedTissues)),
            const SizedBox(width: 48),
            Expanded(child: item(Icons.water_drop_outlined,
                l.bookingIncludedWater)),
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
    final l = context.l10n;
    // Per-vehicle luggage options (dynamic)
    final luggageOpts = _luggageOptionsFor(_selected, l);

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
        Text(
          l.bookingCapacityTitle,
          style: const TextStyle(
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
                tab(l.bookingLuggage, _capacityTab == 0,
                    () => setState(() => _capacityTab = 0)),
                const SizedBox(width: 36),
                tab(l.bookingSeating, _capacityTab == 1,
                    () => setState(() => _capacityTab = 1)),
              ],
            ),
            const Divider(color: _kDivider, height: 1),
          ],
        ),

        const SizedBox(height: 22),

        if (_capacityTab == 0) ...[
          // Description
          Text(
            l.bookingCapacityLuggageInfo,
            style: const TextStyle(
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
            // Wrap: longer translations flow onto a second line instead of overflowing.
            child: Wrap(
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
            final seatingOpts = _seatingOptionsFor(_selected, l);
            final safeIdx     = _seatingOption.clamp(0, seatingOpts.length - 1);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.bookingSeatingInfo,
                  style: const TextStyle(
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
                  child: Wrap(
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
    final l = context.l10n;
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
                LuxMoney.format(amount, cents: true),
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
          Text(
            l.bookingPriceBreakdownTitle,
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 20),

          // Base fare
          priceLine(l.bookingBaseFare, base),
          const Divider(color: _kDivider, height: 1),

          // Tax
          priceLine(l.bookingEstimatedTax, tax),
          const Divider(color: _kBorder, height: 1, thickness: 1.2),
          const SizedBox(height: 22),

          // Please note section
          Text(
            l.bookingPleaseNote,
            style: const TextStyle(
              fontFamily: kSans,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 14),

          note(l.bookingNoteCapacity),
          note(l.bookingNoteImages),
          note(l.bookingNoteExtras),
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
                          Text(context.l10n.bookingRoutePreview,
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
    final l = context.l10n;
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
                    _selected.localizedLabel(l),
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
                    _selected.localizedDescription(l),
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
              LuxMoney.format(_payable.round()),
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
          label: l.bookingPickupLabel,
          value: _formData?.origin.displayName ?? '—',
        ),
        const SizedBox(height: 12),
        _SummaryAddressRow(
          icon: Icons.flag_outlined,
          label: l.bookingDestinationLabel,
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
          title: l.bookingForMyself,
          subtitle: l.bookingForMyselfSubtitle,
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
          title: l.bookingForGuest,
          subtitle: (!_bookForSelf && _guestFirstName.isNotEmpty)
              ? l.bookingGuestDisplayName(
                  _guestTitle.label(l), _guestFirstName, _guestLastName).trim()
              : l.bookingForGuestSubtitle,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        size: 15, color: _kTextPrimary),
                    const SizedBox(width: 7),
                    Text(
                      l.bookingApplyOffer,
                      style: const TextStyle(
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.bookingAllFeesIncluded,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 12,
                  color: _kTextSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),

        if (_service == ServiceType.byTheHour) ...[
          const SizedBox(height: 20),
          _daysRow(),
        ],
        const SizedBox(height: 20),
        PriceBreakdown(
          vehicleClass: _selected,
          serviceType: _service,
          km: _km,
          hours: _hours,
          days: _days,
        ),
        const SizedBox(height: 20),
        _promoField(),
        if (_company != null) ...[
          const SizedBox(height: 20),
          _corporatePanel(),
        ],
        if (!_corporate && _savedCards.isEmpty) ...[
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
            title: Text(context.l10n.bookingStepOf(_step + 1, 3)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _LightStepIndicator(
                  steps: [
                    context.l10n.bookingStepVehicle,
                    context.l10n.bookingStepDetails,
                    context.l10n.commonConfirm,
                  ],
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
                price: _payable,
                label: _step < 2
                    ? context.l10n.commonContinue
                    : context.l10n.bookingConfirmCta,
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
          Text(context.l10n.bookingChooseExperience,
              style: const TextStyle(
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
            const SizedBox(height: 10),
            _daysRow(),
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
                  price: DefaultPricing.estimate(vc, _service, km: _km, hours: _hours, days: _days),
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

  Widget _detailsStep() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.bookingTripDetailsHeading,
            style: const TextStyle(
              fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w700,
              color: _kTextTertiary, letterSpacing: 2.0,
            )),
        const SizedBox(height: 20),
        _LightCounterRow(label: l.bookingPassengers, icon: Icons.person_outline,
            value: _passengers, min: 1, max: _selected.capacity,
            onChanged: (v) => setState(() => _passengers = v)),
        const SizedBox(height: 10),
        _LightCounterRow(label: l.bookingLuggage, icon: Icons.luggage_outlined,
            value: _luggage, min: 0, max: 6,
            onChanged: (v) => setState(() => _luggage = v)),
        const SizedBox(height: 20),
        _LightTextField(label: l.bookingFlightNumber, hint: l.bookingFlightNumberHint,
            icon: Icons.flight_outlined, onChanged: (v) => _flight = v),
        const SizedBox(height: 12),
        _LightTextField(label: l.bookingSpecialRequests,
            hint: l.bookingSpecialRequestsHint,
            icon: Icons.chat_bubble_outline_rounded, maxLines: 3,
            onChanged: (v) => _notes = v),
      ],
    );
  }

  Widget _confirmStep() {
    final l = context.l10n;
    final hasRoute = _formData?.origin != null;
    final hourly = _service == ServiceType.byTheHour;
    final distance = NumberFormat.decimalPatternDigits(
            locale: context.localeTag, decimalDigits: 1)
        .format(_km);
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
        Text(l.bookingSummaryHeading,
            style: const TextStyle(fontFamily: kSans, fontSize: 10,
                fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: _kBorder),
          ),
          child: Column(children: [
            _SummaryRow(l.bookingSummaryService, _service.localizedLabel(l), isFirst: true),
            _SummaryRow(l.bookingStepVehicle, _selected.localizedLabel(l)),
            if (_formData?.origin != null)
              _SummaryRow(l.bookingSummaryFrom, _formData!.origin.displayName),
            if (_formData?.destination != null)
              _SummaryRow(l.bookingSummaryTo, _formData!.destination!.displayName),
            _SummaryRow(
              hourly ? l.bookingSummaryDuration : l.bookingSummaryDistance,
              hourly ? (_days > 1 ? l.bookingDaysSummary(_days, _hours) : l.unitHours(_hours))
                  : _km > 0 ? l.bookingDistanceKm(distance) : '—',
            ),
            if (_formData?.routeDurationMin != null && _formData!.routeDurationMin > 0)
              _SummaryRow(l.bookingSummaryEstDuration,
                  localizedDuration(l, Duration(minutes: _formData!.routeDurationMin))),
            _SummaryRow(l.bookingPassengers, l.unitPassengers(_passengers)),
            _SummaryRow(l.bookingLuggage, l.unitBags(_luggage)),
            if (_flight.isNotEmpty) _SummaryRow(l.bookingSummaryFlight, _flight),
            if (_notes.isNotEmpty)  _SummaryRow(l.bookingSummaryNotes, _notes),
            if (_payable < _price)
              _SummaryRow(_discountLabel,
                  '−${LuxMoney.format((_price - _payable).round())}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F7F3),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(l.bookingEstimatedTotal,
                      style: const TextStyle(fontFamily: kSans, fontSize: 10,
                          fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 1.8)),
                ),
                const SizedBox(width: 12),
                Text(LuxMoney.format(_payable.ceil()),
                    style: const TextStyle(fontFamily: kSans, fontSize: 18,
                        fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.3)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Text(l.bookingBreakdownHeading,
            style: const TextStyle(fontFamily: kSans, fontSize: 10,
                fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
        const SizedBox(height: 8),
        PriceBreakdown(
          vehicleClass: _selected,
          serviceType: _service,
          km: _km,
          hours: _hours,
          days: _days,
        ),
        const SizedBox(height: 20),
        _promoField(),
        const SizedBox(height: 20),
        if (_company != null) ...[
          _corporatePanel(),
          const SizedBox(height: 20),
        ],
        if (_corporate)
          const SizedBox.shrink()
        else if (_savedCards.isEmpty)
          const _PayOnTripNotice()
        else ...[
          Text(l.bookingPaymentMethodHeading,
              style: const TextStyle(fontFamily: kSans, fontSize: 10,
                  fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
          const SizedBox(height: 12),
          ..._savedCards.map((card) {
            final id    = card['id'] as String;
            final rawBrand = card['brand'] as String?;
            final brand = rawBrand == null || rawBrand.isEmpty
                ? l.bookingCardFallback
                : _cap(rawBrand);
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
            l.bookingIncludedFreeCancellation),
        const SizedBox(height: 8),
      ],
    );
  }
}

