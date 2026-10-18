import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/enums.dart';
import '../vehicles/vehicle_catalog.dart';
import 'place_model.dart';

export 'place_model.dart';

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

class User {
  const User({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.vehicleClass, // Added for driver category
    required this.createdAt,
    required this.isVerified,
    required this.isActive,
    this.stripeCustomerId,
    required this.fcmTokens,
    this.companyId,
    this.companyRole,
    this.ridePreferences = RidePreferences.none,
  });

  final String id;
  final String email;
  final String phone;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final VehicleClass? vehicleClass;
  final DateTime createdAt;
  final bool isVerified;
  final bool isActive;
  final String? stripeCustomerId;
  final List<String> fcmTokens;

  /// Corporate account the rider belongs to (written by the backend).
  final String? companyId;

  /// 'admin' or 'member' within [companyId].
  final String? companyRole;

  bool get isCompanyAdmin => companyId != null && companyRole == 'admin';

  /// Cómo le gusta viajar (silencio, temperatura…); el chófer lo ve.
  final RidePreferences ridePreferences;

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String? ?? '',
        displayName: j['displayName'] as String,
        photoUrl: j['photoUrl'] as String?,
        role: UserRole.values.firstWhere(
          (e) => e.name == j['role'],
          orElse: () => UserRole.rider,
        ),
        vehicleClass: j['class'] != null || j['vehicleClass'] != null
            ? VehicleClass.fromId(j['class'] ?? j['vehicleClass'])
            : null,
        createdAt: (j['createdAt'] as Timestamp).toDate(),
        isVerified: j['isVerified'] as bool? ?? false,
        isActive: j['isActive'] as bool? ?? true,
        stripeCustomerId: j['stripeCustomerId'] as String?,
        fcmTokens: List<String>.from(j['fcmTokens'] ?? []),
        companyId: j['companyId'] as String?,
        companyRole: j['companyRole'] as String?,
        ridePreferences: RidePreferences.fromJson(j['ridePreferences']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'class': vehicleClass?.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerified': isVerified,
        'isActive': isActive,
        'stripeCustomerId': stripeCustomerId,
        'fcmTokens': fcmTokens,
        'ridePreferences': ridePreferences.toJson(),
      };

  User copyWith({
    String? phone,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    VehicleClass? vehicleClass,
    bool? isVerified,
    bool? isActive,
    String? stripeCustomerId,
    List<String>? fcmTokens,
    RidePreferences? ridePreferences,
  }) =>
      User(
        id: id,
        email: email,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        vehicleClass: vehicleClass ?? this.vehicleClass,
        createdAt: createdAt,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
        fcmTokens: fcmTokens ?? this.fcmTokens,
        companyId: companyId,
        companyRole: companyRole,
        ridePreferences: ridePreferences ?? this.ridePreferences,
      );
}

// ---------------------------------------------------------------------------
// RidePreferences — el "estilo de viaje" del pasajero
// ---------------------------------------------------------------------------

enum CabinTemperature {
  cool('Fresca', '20 °C'),
  mild('Templada', '22 °C'),
  warm('Cálida', '24 °C');

  const CabinTemperature(this.label, this.hint);
  final String label;
  final String hint;
}

/// Lo que el pasajero prefiere en cada viaje. Se guarda en su perfil, se
/// copia a cada reserva y el chófer lo ve antes de recogerlo: nadie tiene
/// que pedir lo mismo dos veces.
class RidePreferences {
  const RidePreferences({
    this.quiet = false,
    this.temperature,
    this.music = true,
    this.luggageHelp = false,
    this.openDoor = false,
  });

  static const none = RidePreferences();

  /// Prefiere viajar sin conversación.
  final bool quiet;
  final CabinTemperature? temperature;

  /// Música suave de fondo (false: viaje sin música).
  final bool music;

  /// Ayuda con el equipaje al subir y bajar.
  final bool luggageHelp;

  /// Que el chófer le abra la puerta.
  final bool openDoor;

  bool get isEmpty =>
      !quiet && temperature == null && music && !luggageHelp && !openDoor;

  /// Indicaciones breves para el chófer, en el orden en que las aplicará.
  List<String> get driverNotes => [
        if (openDoor) 'Abrir la puerta',
        if (luggageHelp) 'Ayuda con el equipaje',
        if (temperature != null)
          'Cabina ${temperature!.label.toLowerCase()} (${temperature!.hint})',
        if (quiet) 'Viaje en silencio',
        if (!music) 'Sin música',
      ];

  factory RidePreferences.fromJson(Object? raw) {
    if (raw is! Map) return none;
    final t = raw['temperature'];
    return RidePreferences(
      quiet: raw['quiet'] == true,
      temperature:
          CabinTemperature.values.where((e) => e.name == t).firstOrNull,
      music: raw['music'] != false,
      luggageHelp: raw['luggageHelp'] == true,
      openDoor: raw['openDoor'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'quiet': quiet,
        'temperature': temperature?.name,
        'music': music,
        'luggageHelp': luggageHelp,
        'openDoor': openDoor,
      };

  RidePreferences copyWith({
    bool? quiet,
    CabinTemperature? temperature,
    bool clearTemperature = false,
    bool? music,
    bool? luggageHelp,
    bool? openDoor,
  }) =>
      RidePreferences(
        quiet: quiet ?? this.quiet,
        temperature:
            clearTemperature ? null : (temperature ?? this.temperature),
        music: music ?? this.music,
        luggageHelp: luggageHelp ?? this.luggageHelp,
        openDoor: openDoor ?? this.openDoor,
      );

  @override
  bool operator ==(Object other) =>
      other is RidePreferences &&
      other.quiet == quiet &&
      other.temperature == temperature &&
      other.music == music &&
      other.luggageHelp == luggageHelp &&
      other.openDoor == openDoor;

  @override
  int get hashCode =>
      Object.hash(quiet, temperature, music, luggageHelp, openDoor);
}

// ---------------------------------------------------------------------------
// DriverProfile
// ---------------------------------------------------------------------------

class DriverProfile {
  const DriverProfile({
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.vehicleId,
    required this.documentsVerified,
    required this.rating,
    required this.totalRides,
    required this.isAvailable,
    this.currentLocation,
  });

  final String userId;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String vehicleId;
  final bool documentsVerified;
  final double rating;
  final int totalRides;
  final bool isAvailable;
  final GeoPoint? currentLocation;

  factory DriverProfile.fromJson(Map<String, dynamic> j) => DriverProfile(
        userId: j['userId'] as String,
        licenseNumber: j['licenseNumber'] as String? ?? '',
        licenseExpiry: j['licenseExpiry'] != null
            ? (j['licenseExpiry'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 365)),
        vehicleId: j['vehicleId'] as String? ?? '',
        documentsVerified: j['documentsVerified'] as bool? ?? false,
        rating: (j['rating'] as num?)?.toDouble() ?? 5.0,
        totalRides: j['totalRides'] as int? ?? 0,
        isAvailable: j['isAvailable'] as bool? ?? false,
        currentLocation: j['currentLocation'] as GeoPoint?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'licenseNumber': licenseNumber,
        'licenseExpiry': Timestamp.fromDate(licenseExpiry),
        'vehicleId': vehicleId,
        'documentsVerified': documentsVerified,
        'rating': rating,
        'totalRides': totalRides,
        'isAvailable': isAvailable,
        'currentLocation': currentLocation,
      };

  DriverProfile copyWith({
    bool? isAvailable,
    GeoPoint? currentLocation,
    double? rating,
    int? totalRides,
  }) =>
      DriverProfile(
        userId: userId,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        vehicleId: vehicleId,
        documentsVerified: documentsVerified,
        rating: rating ?? this.rating,
        totalRides: totalRides ?? this.totalRides,
        isAvailable: isAvailable ?? this.isAvailable,
        currentLocation: currentLocation ?? this.currentLocation,
      );
}

// ---------------------------------------------------------------------------
// Vehicle
// ---------------------------------------------------------------------------

class Vehicle {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.vehicleClass,
    required this.color,
    this.photoUrl,
    required this.capacity,
    required this.isActive,
  });

  final String id;
  final String driverId;
  final String make;
  final String model;
  final int year;
  final String plate;
  final VehicleClass vehicleClass;
  final String color;
  final String? photoUrl;
  final int capacity;
  final bool isActive;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        driverId: j['driverId'] as String,
        make: j['make'] as String? ?? '',
        model: j['model'] as String? ?? '',
        year: j['year'] as int? ?? 2024,
        plate: j['plate'] as String? ?? '',
        vehicleClass: VehicleClass.fromId(j['class']),
        color: j['color'] as String? ?? 'Black',
        photoUrl: j['photoUrl'] as String?,
        capacity: j['capacity'] as int? ?? 3,
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverId': driverId,
        'make': make,
        'model': model,
        'year': year,
        'plate': plate,
        'class': vehicleClass.name,
        'color': color,
        'photoUrl': photoUrl,
        'capacity': capacity,
        'isActive': isActive,
      };
}

// ---------------------------------------------------------------------------
// BookingSettlement
// ---------------------------------------------------------------------------

/// Comisión de plataforma por defecto, mientras el admin no configure otra
/// (el servidor usa el mismo valor: functions/src/settlement.ts).
const double kDefaultCommissionPct = 20;

/// Antelación con la que una reserva confirmada ya ocupa al chófer.
const kBusyLead = Duration(minutes: 60);

/// Reparto de un viaje completado entre la plataforma y el chófer.
///
/// Lo fija el servidor (Cloud Function `settleBooking`) con la comisión
/// vigente al completar el viaje; la app solo lo lee.
class BookingSettlement {
  const BookingSettlement({
    required this.amount,
    required this.commissionPct,
    required this.platformCommission,
    required this.driverPayout,
  });

  /// Importe repartido (precio final o estimado en ese momento).
  final double amount;
  final double commissionPct;
  final double platformCommission;
  final double driverPayout;

  static BookingSettlement? fromJson(Object? j) {
    if (j is! Map) return null;
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0.0;
    return BookingSettlement(
      amount: n('amount'),
      commissionPct: n('commissionPct'),
      platformCommission: n('platformCommission'),
      driverPayout: n('driverPayout'),
    );
  }

  /// Reparto provisional con [commissionPct], para viajes que el servidor aún
  /// no ha repartido.
  factory BookingSettlement.estimate(double amount,
      {double commissionPct = kDefaultCommissionPct}) {
    double round(double v) => (v * 100).roundToDouble() / 100;
    final pct = commissionPct.clamp(0, 100).toDouble();
    final commission = round(amount * pct / 100);
    return BookingSettlement(
      amount: amount,
      commissionPct: pct,
      platformCommission: commission,
      driverPayout: round(amount - commission),
    );
  }
}

// ---------------------------------------------------------------------------
// DriverInfo
// ---------------------------------------------------------------------------

/// Datos públicos del chófer asignado que el servidor copia en la reserva
/// (el pasajero no puede leer el perfil de otros usuarios).
class DriverInfo {
  const DriverInfo({
    required this.name,
    this.phone = '',
    this.photoUrl,
    this.vehicle,
  });

  final String name;
  final String phone;
  final String? photoUrl;

  /// "Toyota Camry · Negro · 1234ABC", o null si no hay vehículo.
  final String? vehicle;

  static DriverInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final v = j['vehicle'];
    String? vehicle;
    if (v is Map) {
      final parts = [
        '${v['make'] ?? ''} ${v['model'] ?? ''}'.trim(),
        (v['color'] as String?) ?? '',
        (v['plate'] as String?) ?? '',
      ].where((p) => p.isNotEmpty);
      vehicle = parts.isEmpty ? null : parts.join(' · ');
    }
    return DriverInfo(
      name: (j['name'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      photoUrl: j['photoUrl'] as String?,
      vehicle: vehicle,
    );
  }
}

// ---------------------------------------------------------------------------
// Booking
// ---------------------------------------------------------------------------

class Booking {
  const Booking({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.origin,
    required this.destination,
    required this.scheduledAt,
    required this.vehicleClass,
    required this.serviceType,
    required this.status,
    required this.estimatedPrice,
    this.finalPrice,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.flightNumber,
    this.flightType,
    this.pickupAirport,
    this.hours,
    this.passengerCount = 1,
    this.luggageCount = 0,
    this.currency = 'bob',
    this.stripePaymentIntentId,
    this.quoteId,
    this.pickupAt,
    this.chauffeur,
    this.flight,
    this.riderRating,
    this.passengerName,
    this.passengerPhone,
    this.driverArrivedAt,
    this.dispatch,
    this.cancelledBy,
    this.lateCancellation = false,
    this.cancelReason,
    this.paymentMethod,
    this.companyId,
    this.companyName,
    this.costCenter,
    this.billingReference,
    this.promoCode,
    this.discount = 0,
    this.baseAmount,
    this.days = 1,
    this.distanceKm,
    this.loyaltyTier,
    this.refundedAmount = 0,
    this.adjustments = const [],
    this.pricingReviewReason,
    this.settlement,
    this.refunded = false,
    this.driverInfo,
    this.cardPayment = false,
    this.cardPaymentFailed = false,
    this.riderPreferences = RidePreferences.none,
  });

  final String id;
  final String riderId;
  final String? driverId;
  final Place origin;
  final Place destination;
  final DateTime scheduledAt;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final BookingStatus status;
  final double estimatedPrice;
  final double? finalPrice;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? flightNumber;

  /// [FlightType.name] of the passenger's flight (airport pickups only).
  final String? flightType;

  /// IATA code of the pickup airport, e.g. "VVI" (airport pickups only).
  final String? pickupAirport;
  final int? hours;
  final int passengerCount;
  final int luggageCount;
  final String currency;

  /// Card authorisation created before booking; captured server-side when the
  /// ride is completed and released if it is cancelled.
  final String? stripePaymentIntentId;

  /// Server-issued quote the booking was priced from.
  final String? quoteId;

  /// Pickup moved by flight tracking (null when unchanged).
  final DateTime? pickupAt;

  /// Assigned chauffeur, copied onto the booking by the backend.
  final Chauffeur? chauffeur;

  /// Live status of the inbound flight, for airport pickups.
  final FlightInfo? flight;

  /// The rider's 1–5 rating, once given.
  final int? riderRating;

  /// Person being picked up (the rider or a guest) — shown on the name sign.
  final String? passengerName;
  final String? passengerPhone;

  /// Set by the backend when the chauffeur marks "He llegado".
  final DateTime? driverArrivedAt;

  /// Proximity dispatch state (who the booking is currently offered to).
  final DispatchInfo? dispatch;

  /// Who cancelled ('rider', 'driver', 'admin', 'system'), written by the
  /// backend together with [lateCancellation] and [cancelReason].
  final String? cancelledBy;

  /// Rider cancelled inside the late-cancellation window.
  final bool lateCancellation;

  /// Machine reason, e.g. 'no_driver_assigned' from scheduledCleanup.
  final String? cancelReason;

  /// 'card', 'pay_later' (cash/QR to the chauffeur) or 'corporate'.
  final String? paymentMethod;

  /// Corporate billing: the company is invoiced monthly and the chauffeur
  /// collects nothing. On a booking being created, a non-null [companyId]
  /// asks the backend to bill the rider's company.
  final String? companyId;
  final String? companyName;
  final String? costCenter;
  final String? billingReference;

  bool get isCorporate => companyId != null;

  /// Promo applied when booking: [estimatedPrice] = [baseAmount] - [discount].
  /// On a booking being created, [promoCode] is the code to quote with.
  final String? promoCode;
  final double discount;
  final double? baseAmount;

  /// Hourly charters can span several days ([hours] each day).
  final int days;

  /// Route distance the price was quoted with (one-way trips).
  final double? distanceKm;

  /// Loyalty tier whose discount applied (instead of a promo code).
  final String? loyaltyTier;

  /// Money given back for this ride (recordRefund), in Bs.
  final double refundedAmount;

  /// Extra charges / corrections added by an admin (adjustPrice); the
  /// server keeps finalPrice = estimatedPrice + their sum.
  final List<PriceAdjustment> adjustments;

  /// What the rider paid: the final price, or the quote.
  double get paidAmount => finalPrice ?? estimatedPrice;

  /// Whether [driverId] should see this pending booking as a request.
  bool isOfferedTo(String driverId) {
    final d = dispatch;
    if (d == null || !d.targeted) return true; // broadcast to everyone
    return d.offeredTo == driverId;
  }

  /// When the chauffeur will actually be there.
  DateTime get effectivePickup => pickupAt ?? scheduledAt;

  /// Lo marca el servidor si el precio no respeta la tarifa vigente
  /// (`below_fare`, `fare_disabled`, `unknown_fare`). Solo lectura.
  final String? pricingReviewReason;

  /// Reparto plataforma / chófer fijado por el servidor. Solo lectura.
  final BookingSettlement? settlement;

  /// El cobro se reembolsó (lo marca `refundPayment`): el viaje ya no
  /// genera comisión ni pago al chófer. Solo lectura.
  final bool refunded;

  /// Chófer asignado, copiado por el servidor. Solo lectura.
  final DriverInfo? driverInfo;

  /// Estilo de viaje del pasajero, copiado de su perfil al reservar.
  final RidePreferences riderPreferences;

  /// Se paga con tarjeta: el servidor la cobra al completar el viaje.
  final bool cardPayment;

  /// El cobro automático con tarjeta falló; se cobra a mano.
  final bool cardPaymentFailed;

  /// Cobro con tarjeta aún por resolver por el servidor: no se registra a
  /// mano para no cobrar dos veces.
  bool get cardPaymentPending =>
      cardPayment && !cardPaymentFailed && paymentId == null;

  /// Un viaje ocupa al chófer desde que sale a buscar al pasajero, o si la
  /// recogida es en menos de [kBusyLead]. Uno confirmado para más adelante
  /// no le impide atender otros mientras tanto.
  bool occupiesDriver([DateTime? now]) {
    switch (status) {
      case BookingStatus.driverArriving:
      case BookingStatus.driverArrived:
      case BookingStatus.inProgress:
        return true;
      case BookingStatus.confirmed:
        return scheduledAt.isBefore((now ?? DateTime.now()).add(kBusyLead));
      default:
        return false;
    }
  }

  /// Importe que se factura: el precio final o, si no hay, el estimado.
  double get chargedAmount => finalPrice ?? estimatedPrice;

  /// Reparto vigente del viaje: el del servidor si corresponde al importe
  /// actual o, si no, uno provisional con [commissionPct].
  BookingSettlement settlementOr(double commissionPct) {
    final s = settlement;
    if (s != null && (s.amount - chargedAmount).abs() < 0.005) return s;
    return BookingSettlement.estimate(chargedAmount,
        commissionPct: s?.commissionPct ?? commissionPct);
  }

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String? ?? '',
        riderId: j['riderId'] as String? ?? '',
        driverId: j['driverId'] as String?,
        origin: Place.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
        destination:
            Place.fromJson(j['destination'] as Map<String, dynamic>? ?? {}),
        scheduledAt: j['scheduledAt'] != null
            ? (j['scheduledAt'] as Timestamp).toDate()
            : DateTime.now(),
        vehicleClass: VehicleClass.fromId(j['class'] ?? j['vehicleClass']),
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == (j['serviceType'] ?? 'oneWay'),
          orElse: () => ServiceType.oneWay,
        ),
        status: BookingStatusX.fromString(j['status'] as String? ?? 'pending'),
        estimatedPrice: (j['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
        finalPrice: (j['finalPrice'] as num?)?.toDouble(),
        paymentId: j['paymentId'] as String?,
        createdAt: j['createdAt'] != null
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: j['updatedAt'] != null
            ? (j['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        notes: j['notes'] as String?,
        flightNumber: j['flightNumber'] as String?,
        flightType: j['flightType'] as String?,
        pickupAirport: j['pickupAirport'] as String?,
        hours: j['hours'] as int?,
        passengerCount: j['passengerCount'] as int? ?? 1,
        luggageCount: j['luggageCount'] as int? ?? 0,
        currency: j['currency'] as String? ?? 'bob',
        stripePaymentIntentId: j['stripePaymentIntentId'] as String?,
        quoteId: j['quoteId'] as String?,
        pickupAt: (j['pickupAt'] as Timestamp?)?.toDate(),
        chauffeur: j['chauffeur'] is Map
            ? Chauffeur.fromJson(Map<String, dynamic>.from(j['chauffeur'] as Map))
            : null,
        flight: j['flight'] is Map
            ? FlightInfo.fromJson(Map<String, dynamic>.from(j['flight'] as Map))
            : null,
        riderRating: (j['riderRating'] as num?)?.toInt(),
        passengerName: j['passengerName'] as String?,
        passengerPhone: j['passengerPhone'] as String?,
        driverArrivedAt: (j['driverArrivedAt'] as Timestamp?)?.toDate(),
        dispatch: j['dispatch'] is Map
            ? DispatchInfo.fromJson(Map<String, dynamic>.from(j['dispatch'] as Map))
            : null,
        cancelledBy: j['cancelledBy'] as String?,
        lateCancellation: j['lateCancellation'] as bool? ?? false,
        cancelReason: j['cancelReason'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        companyId: j['companyId'] as String?,
        companyName: j['companyName'] as String?,
        costCenter: j['costCenter'] as String?,
        billingReference: j['billingReference'] as String?,
        promoCode: j['promoCode'] as String?,
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        baseAmount: (j['baseAmount'] as num?)?.toDouble(),
        days: (j['days'] as num?)?.toInt() ?? 1,
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        loyaltyTier: j['loyaltyTier'] as String?,
        refundedAmount: (j['refundedAmount'] as num?)?.toDouble() ?? 0,
        adjustments: (j['adjustments'] as List? ?? const [])
            .map(PriceAdjustment.fromJson)
            .whereType<PriceAdjustment>()
            .toList(),
        pricingReviewReason: (j['pricingReview'] as Map?)?['reason'] as String?,
        settlement: BookingSettlement.fromJson(j['settlement']),
        refunded: j['refunded'] == true,
        driverInfo: DriverInfo.fromJson(j['driverInfo']),
        cardPayment: j['stripePaymentIntentId'] != null ||
            j['stripePaymentMethodId'] != null,
        cardPaymentFailed: j['cardPaymentFailed'] == true,
        riderPreferences: RidePreferences.fromJson(j['riderPreferences']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'driverId': driverId,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'class': vehicleClass.name,
        // Cloud Functions read `vehicleClass`; keep both keys in sync.
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'status': status.label,
        'estimatedPrice': estimatedPrice,
        'finalPrice': finalPrice,
        'paymentId': paymentId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'notes': notes,
        'flightNumber': flightNumber,
        'flightType': flightType,
        'pickupAirport': pickupAirport,
        'hours': hours,
        'passengerCount': passengerCount,
        'luggageCount': luggageCount,
        'currency': currency,
        'stripePaymentIntentId': stripePaymentIntentId,
        'quoteId': quoteId,
      };

  Booking copyWith({
    String? driverId,
    BookingStatus? status,
    double? finalPrice,
    String? paymentId,
    DateTime? updatedAt,
  }) =>
      Booking(
        id: id,
        riderId: riderId,
        driverId: driverId ?? this.driverId,
        origin: origin,
        destination: destination,
        scheduledAt: scheduledAt,
        vehicleClass: vehicleClass,
        serviceType: serviceType,
        status: status ?? this.status,
        estimatedPrice: estimatedPrice,
        finalPrice: finalPrice ?? this.finalPrice,
        paymentId: paymentId ?? this.paymentId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes,
        flightNumber: flightNumber,
        flightType: flightType,
        pickupAirport: pickupAirport,
        hours: hours,
        passengerCount: passengerCount,
        luggageCount: luggageCount,
        currency: currency,
        stripePaymentIntentId: stripePaymentIntentId,
        quoteId: quoteId,
        pickupAt: pickupAt,
        chauffeur: chauffeur,
        flight: flight,
        riderRating: riderRating,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        driverArrivedAt: driverArrivedAt,
        dispatch: dispatch,
        cancelledBy: cancelledBy,
        lateCancellation: lateCancellation,
        cancelReason: cancelReason,
        paymentMethod: paymentMethod,
        companyId: companyId,
        companyName: companyName,
        costCenter: costCenter,
        billingReference: billingReference,
        promoCode: promoCode,
        discount: discount,
        baseAmount: baseAmount,
        days: days,
        distanceKm: distanceKm,
        loyaltyTier: loyaltyTier,
        refundedAmount: refundedAmount,
        adjustments: adjustments,
        pricingReviewReason: pricingReviewReason,
        settlement: settlement,
        refunded: refunded,
        driverInfo: driverInfo,
        cardPayment: cardPayment,
        cardPaymentFailed: cardPaymentFailed,
        riderPreferences: riderPreferences,
      );
}

/// One line of [Booking.adjustments].
class PriceAdjustment {
  const PriceAdjustment({required this.type, required this.amount, this.note, this.at});

  final AdjustmentType type;
  final double amount;
  final String? note;
  final DateTime? at;

  static PriceAdjustment? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = AdjustmentType.values.where((t) => t.name == raw['type']).firstOrNull;
    final amount = (raw['amount'] as num?)?.toDouble();
    if (type == null || amount == null) return null;
    return PriceAdjustment(
      type: type,
      amount: amount,
      note: raw['note'] as String?,
      at: (raw['at'] as Timestamp?)?.toDate(),
    );
  }
}

// ---------------------------------------------------------------------------
// DispatchInfo — written by onBookingCreated / dispatchTick
// ---------------------------------------------------------------------------

class DispatchInfo {
  const DispatchInfo({required this.targeted, this.offeredTo, this.offerExpiresAt});

  /// true: offered to one chauffeur at a time; false: open to all.
  final bool targeted;
  final String? offeredTo;
  final DateTime? offerExpiresAt;

  factory DispatchInfo.fromJson(Map<String, dynamic> j) => DispatchInfo(
        targeted: j['mode'] == 'targeted',
        offeredTo: j['offeredTo'] as String?,
        offerExpiresAt: (j['offerExpiresAt'] as Timestamp?)?.toDate(),
      );
}

// ---------------------------------------------------------------------------
// Chauffeur — rider-facing snapshot written by the backend on assignment
// ---------------------------------------------------------------------------

class Chauffeur {
  const Chauffeur({
    required this.driverId,
    required this.name,
    required this.vehicle,
    required this.plate,
    this.vehicleColor = '',
    this.photoUrl,
    this.rating,
    this.ratingCount = 0,
    this.totalRides = 0,
    this.phone,
  });

  final String driverId;
  final String name;
  final String vehicle;
  final String vehicleColor;
  final String plate;
  final String? photoUrl;
  final double? rating;
  final int ratingCount;
  final int totalRides;

  /// Only present while the trip is active.
  final String? phone;

  String get vehicleLine =>
      vehicleColor.isEmpty ? vehicle : '$vehicle · $vehicleColor';

  factory Chauffeur.fromJson(Map<String, dynamic> j) => Chauffeur(
        driverId: j['driverId'] as String? ?? '',
        // Empty when the chauffeur has no name on file; the UI shows a
        // localized "Your chauffeur" instead.
        name: j['name'] as String? ?? '',
        vehicle: j['vehicle'] as String? ?? '',
        vehicleColor: j['vehicleColor'] as String? ?? '',
        plate: j['plate'] as String? ?? '',
        photoUrl: j['photoUrl'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        totalRides: (j['totalRides'] as num?)?.toInt() ?? 0,
        phone: j['phone'] as String?,
      );
}

// ---------------------------------------------------------------------------
// FlightInfo — written by the `trackFlights` scheduled function
// ---------------------------------------------------------------------------

class FlightInfo {
  const FlightInfo({
    required this.number,
    required this.status,
    this.scheduledArrival,
    this.estimatedArrival,
    this.delayMin = 0,
    this.arrived = false,
    this.cancelled = false,
    this.terminal,
    this.gate,
    this.checkedAt,
  });

  final String number;
  final String status;
  final DateTime? scheduledArrival;
  final DateTime? estimatedArrival;
  final int delayMin;
  final bool arrived;
  final bool cancelled;
  final String? terminal;
  final String? gate;
  final DateTime? checkedAt;

  bool get delayed => delayMin >= 10 && !arrived && !cancelled;

  // Display text: FlightInfoL10n.localizedLabel(context.l10n) in lib/l10n.

  factory FlightInfo.fromJson(Map<String, dynamic> j) => FlightInfo(
        number: j['number'] as String? ?? '',
        status: j['status'] as String? ?? '',
        scheduledArrival: (j['scheduledArrival'] as Timestamp?)?.toDate(),
        estimatedArrival: (j['estimatedArrival'] as Timestamp?)?.toDate(),
        delayMin: (j['delayMin'] as num?)?.toInt() ?? 0,
        arrived: j['arrived'] as bool? ?? false,
        cancelled: j['cancelled'] as bool? ?? false,
        terminal: j['terminal'] as String?,
        gate: j['gate'] as String?,
        checkedAt: (j['checkedAt'] as Timestamp?)?.toDate(),
      );
}

// ---------------------------------------------------------------------------
// LiveLocation — bookings/{id}/tracking/live
// ---------------------------------------------------------------------------

class LiveLocation {
  const LiveLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
    this.heading = 0,
    this.speed = 0,
  });

  final double lat;
  final double lng;
  final double heading;

  /// Metres per second.
  final double speed;
  final DateTime updatedAt;

  bool get isStale => DateTime.now().difference(updatedAt) > const Duration(minutes: 2);

  factory LiveLocation.fromJson(Map<String, dynamic> j) => LiveLocation(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        heading: (j['heading'] as num?)?.toDouble() ?? 0,
        speed: (j['speed'] as num?)?.toDouble() ?? 0,
        updatedAt: (j['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// Quote — fixed price issued by the `quoteBooking` Cloud Function
// ---------------------------------------------------------------------------

class Quote {
  const Quote({
    required this.id,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    this.distanceKm,
    this.hours,
    this.days = 1,
    this.baseAmount,
    this.discount = 0,
    this.promoCode,
    this.promoError,
    this.loyaltyTier,
  });

  final String id;

  /// Price in Bolivianos (after any promo discount).
  final double amount;

  /// Price before the promo; equals [amount] without one.
  final double? baseAmount;
  final double discount;

  /// Code applied to this quote, if any.
  final String? promoCode;

  /// Why the requested code was not applied (e.g. 'promo/expired').
  final String? promoError;

  /// Loyalty tier ('silver', 'gold', 'platinum') whose discount applied.
  final String? loyaltyTier;
  final String currency;
  final DateTime expiresAt;
  final double? distanceKm;
  final int? hours;

  /// Days of an hourly charter (chauffeur by the day).
  final int days;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        id: j['quoteId'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'bob',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
            (j['expiresAt'] as num).toInt()),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        hours: (j['hours'] as num?)?.toInt(),
        days: (j['days'] as num?)?.toInt() ?? 1,
        baseAmount: (j['baseAmount'] as num?)?.toDouble(),
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        promoCode: j['promoCode'] as String?,
        promoError: j['promoError'] as String?,
        loyaltyTier: j['loyaltyTier'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Ride
// ---------------------------------------------------------------------------

class Ride {
  const Ride({
    required this.id,
    required this.bookingId,
    required this.riderId,
    required this.driverId,
    required this.startedAt,
    this.completedAt,
    required this.driverRoute,
    this.distanceKm,
    this.durationMin,
    this.riderRating,
    this.driverRating,
  });

  final String id;
  final String bookingId;
  final String riderId;
  final String driverId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<GeoPoint> driverRoute;
  final double? distanceKm;
  final int? durationMin;
  final double? riderRating;
  final double? driverRating;

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
        id: j['id'] as String,
        bookingId: j['bookingId'] as String,
        riderId: j['riderId'] as String,
        driverId: j['driverId'] as String,
        startedAt: (j['startedAt'] as Timestamp).toDate(),
        completedAt: j['completedAt'] != null
            ? (j['completedAt'] as Timestamp).toDate()
            : null,
        driverRoute: List<GeoPoint>.from(
          (j['driverRoute'] as List? ?? []).map((e) => e as GeoPoint),
        ),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        durationMin: j['durationMin'] as int?,
        riderRating: (j['riderRating'] as num?)?.toDouble(),
        driverRating: (j['driverRating'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'riderId': riderId,
        'driverId': driverId,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'driverRoute': driverRoute,
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'riderRating': riderRating,
        'driverRating': driverRating,
      };
}

// ---------------------------------------------------------------------------
// Payment
// ---------------------------------------------------------------------------

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.riderId,
    required this.stripePaymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.receiptUrl,
  });

  final String id;
  final String bookingId;
  final String riderId;
  final String stripePaymentIntentId;

  /// Importe en centavos enteros, como Stripe (12550 = Bs 125,50). Las
  /// reservas guardan bolivianos; convierte con [amountBs] / [toCents].
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? receiptUrl;

  /// Importe en bolivianos.
  double get amountBs => amount / 100;

  /// Bolivianos → centavos enteros (sin errores de coma flotante).
  static int toCents(double bs) => (bs * 100).round();

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        bookingId: j['bookingId'] as String? ?? '',
        riderId: j['riderId'] as String? ?? '',
        stripePaymentIntentId: j['stripePaymentIntentId'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        currency: j['currency'] as String? ?? 'bob',
        status: PaymentStatusX.fromString(j['status'] as String? ?? 'pending'),
        createdAt: j['createdAt'] is Timestamp
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        receiptUrl: j['receiptUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'riderId': riderId,
        'stripePaymentIntentId': stripePaymentIntentId,
        'amount': amount,
        'currency': currency,
        'status': status.label,
        'createdAt': Timestamp.fromDate(createdAt),
        'receiptUrl': receiptUrl,
      };
}

// ---------------------------------------------------------------------------
// PricingRule (admin-configurable)
// ---------------------------------------------------------------------------

/// Tarifa de un tipo de servicio para una clase de vehículo.
///
/// Los importes están en bolivianos (Bs). Los nombres de campo `*Usd` se
/// mantienen por compatibilidad con los documentos ya guardados en Firestore.
class PricingRule {
  const PricingRule({
    required this.id,
    required this.vehicleClass,
    required this.serviceType,
    required this.basePriceUsd,
    required this.pricePerKmUsd,
    required this.pricePerHourUsd,
    required this.minimumPriceUsd,
    this.isActive = true,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final double basePriceUsd;
  final double pricePerKmUsd;
  final double pricePerHourUsd;
  final double minimumPriceUsd;

  /// Si es false, la combinación clase + servicio no se puede reservar.
  final bool isActive;
  final DateTime? updatedAt;
  final String? updatedBy;

  /// Id de documento canónico en /pricingRules: `business_oneWay`, etc.
  static String idFor(VehicleClass vc, ServiceType st) =>
      '${vc.name}_${st.name}';

  /// Tarifa de fábrica, usada mientras el admin no haya guardado otra.
  factory PricingRule.fallback(VehicleClass vc, ServiceType st) {
    final r = DefaultPricing.rules[vc]?[st] ?? _catalogRule(vc, st);
    return PricingRule(
      id: idFor(vc, st),
      vehicleClass: vc,
      serviceType: st,
      basePriceUsd: r['base']!,
      pricePerKmUsd: r['perKm']!,
      pricePerHourUsd: r['perHour']!,
      minimumPriceUsd: r['min']!,
    );
  }

  /// Types added by admins have no factory table: their own catalog prices.
  static Map<String, double> _catalogRule(VehicleClass vc, ServiceType st) {
    final info = VehicleCatalog.instance.info(vc);
    final p = st == ServiceType.oneWay ? info.oneWay : info.byTheHour;
    return {'base': p?.base ?? 0, 'perKm': p?.perKm ?? 0, 'perHour': p?.perHour ?? 0, 'min': p?.min ?? 0};
  }

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0.0;

  factory PricingRule.fromJson(Map<String, dynamic> j) => PricingRule(
        id: j['id'] as String,
        vehicleClass: VehicleClass.fromId(j['vehicleClass']),
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == j['serviceType'],
          orElse: () => ServiceType.oneWay,
        ),
        basePriceUsd: _num(j['basePriceUsd']),
        pricePerKmUsd: _num(j['pricePerKmUsd']),
        pricePerHourUsd: _num(j['pricePerHourUsd']),
        minimumPriceUsd: _num(j['minimumPriceUsd']),
        isActive: j['isActive'] as bool? ?? true,
        updatedAt: j['updatedAt'] is Timestamp
            ? (j['updatedAt'] as Timestamp).toDate()
            : null,
        updatedBy: j['updatedBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'basePriceUsd': basePriceUsd,
        'pricePerKmUsd': pricePerKmUsd,
        'pricePerHourUsd': pricePerHourUsd,
        'minimumPriceUsd': minimumPriceUsd,
        'isActive': isActive,
      };

  PricingRule copyWith({
    double? basePriceUsd,
    double? pricePerKmUsd,
    double? pricePerHourUsd,
    double? minimumPriceUsd,
    bool? isActive,
  }) =>
      PricingRule(
        id: id,
        vehicleClass: vehicleClass,
        serviceType: serviceType,
        basePriceUsd: basePriceUsd ?? this.basePriceUsd,
        pricePerKmUsd: pricePerKmUsd ?? this.pricePerKmUsd,
        pricePerHourUsd: pricePerHourUsd ?? this.pricePerHourUsd,
        minimumPriceUsd: minimumPriceUsd ?? this.minimumPriceUsd,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );

  /// Mismos importes que [other] (ignora metadatos).
  bool sameFareAs(PricingRule other) =>
      basePriceUsd == other.basePriceUsd &&
      pricePerKmUsd == other.pricePerKmUsd &&
      pricePerHourUsd == other.pricePerHourUsd &&
      minimumPriceUsd == other.minimumPriceUsd &&
      isActive == other.isActive;

  /// Errores de validación en español; lista vacía si la tarifa es válida.
  List<String> validate() {
    final errors = <String>[];
    final values = [
      basePriceUsd,
      pricePerKmUsd,
      pricePerHourUsd,
      minimumPriceUsd,
    ];
    if (values.any((v) => v.isNaN || v < 0)) {
      errors.add('Los importes no pueden ser negativos');
    }
    if (serviceType == ServiceType.oneWay &&
        basePriceUsd == 0 &&
        pricePerKmUsd == 0 &&
        minimumPriceUsd == 0) {
      errors.add('Un traslado no puede costar Bs0');
    }
    if (serviceType == ServiceType.byTheHour && pricePerHourUsd <= 0) {
      errors.add('El servicio por horas necesita un precio por hora');
    }
    return errors;
  }

  /// Precio de un servicio: base + distancia (solo ida) o base + horas
  /// (por horas), nunca por debajo del mínimo.
  double estimate({double km = 0, int hours = 2}) {
    final raw = serviceType == ServiceType.byTheHour
        ? basePriceUsd + hours * pricePerHourUsd
        : basePriceUsd + km * pricePerKmUsd;
    return raw < minimumPriceUsd ? minimumPriceUsd : raw;
  }

  double estimateOneWay(double km) => estimate(km: km);

  double estimateByHour(int hours) => estimate(hours: hours);
}

// ---------------------------------------------------------------------------
// AuditLog
// ---------------------------------------------------------------------------

class AuditLog {
  const AuditLog({
    required this.id,
    required this.adminId,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.details,
    required this.createdAt,
    this.adminEmail,
  });

  final String id;
  final String adminId;
  final String? adminEmail;
  final String action;
  final String targetId;
  final String targetType;
  final String details;
  final DateTime createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id: j['id'] as String,
        adminId: j['adminId'] as String? ?? '',
        adminEmail: j['adminEmail'] as String?,
        action: j['action'] as String? ?? '',
        targetId: j['targetId'] as String? ?? '',
        targetType: j['targetType'] as String? ?? '',
        details: j['details'] as String? ?? '',
        // serverTimestamp() llega como null en la escritura local pendiente.
        createdAt: j['createdAt'] is Timestamp
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'details': details,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ---------------------------------------------------------------------------
// Default pricing (fallback when Firestore unavailable)
// ---------------------------------------------------------------------------

abstract class DefaultPricing {
  // Not const: VehicleClass overrides ==, so it can't key a const map.
  static final Map<VehicleClass, Map<ServiceType, Map<String, double>>> rules =
      {
    VehicleClass.business: {
      ServiceType.oneWay: {'base': 50, 'perKm': 3.0, 'perHour': 0, 'min': 50},
      ServiceType.byTheHour: {'base': 0, 'perKm': 0, 'perHour': 80, 'min': 160},
    },
    VehicleClass.firstClass: {
      ServiceType.oneWay: {'base': 80, 'perKm': 4.0, 'perHour': 0, 'min': 80},
      ServiceType.byTheHour: {
        'base': 0,
        'perKm': 0,
        'perHour': 120,
        'min': 240
      },
    },
    // Between Business Class and Business Van.
    VehicleClass.businessSuv: {
      ServiceType.oneWay: {'base': 70, 'perKm': 4.0, 'perHour': 0, 'min': 70},
      ServiceType.byTheHour: {
        'base': 0,
        'perKm': 0,
        'perHour': 115,
        'min': 230
      },
    },
    VehicleClass.businessVan: {
      ServiceType.oneWay: {'base': 90, 'perKm': 5.0, 'perHour': 0, 'min': 90},
      ServiceType.byTheHour: {
        'base': 0,
        'perKm': 0,
        'perHour': 150,
        'min': 300
      },
    },
    VehicleClass.electric: {
      ServiceType.oneWay: {'base': 60, 'perKm': 3.5, 'perHour': 0, 'min': 60},
      ServiceType.byTheHour: {'base': 0, 'perKm': 0, 'perHour': 90, 'min': 180},
    },
  };

  /// Precio con las tarifas de fábrica. La app usa `PricingCatalog`, que
  /// aplica las tarifas que el admin haya guardado en Firestore.
  static double estimate(VehicleClass vc, ServiceType st,
          {double km = 0, int hours = 2}) =>
      PricingRule.fallback(vc, st).estimate(km: km, hours: hours);
}

// ---------------------------------------------------------------------------
// AppNotification
// ---------------------------------------------------------------------------

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String
      type; // booking_confirmed, driver_arriving, driver_arrived, ride_started, ride_completed, etc.
  final bool isRead;
  final DateTime createdAt;
  final String? bookingId;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        userId: j['userId'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String? ?? 'general',
        isRead: j['isRead'] as bool? ?? false,
        createdAt: j['createdAt'] != null
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        bookingId: j['bookingId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'bookingId': bookingId,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        bookingId: bookingId,
      );
}
