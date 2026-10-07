import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/enums.dart';
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
            ? VehicleClass.values.firstWhere(
                (e) => e.name == (j['class'] ?? j['vehicleClass']),
                orElse: () => VehicleClass.business,
              )
            : null,
        createdAt: (j['createdAt'] as Timestamp).toDate(),
        isVerified: j['isVerified'] as bool? ?? false,
        isActive: j['isActive'] as bool? ?? true,
        stripeCustomerId: j['stripeCustomerId'] as String?,
        fcmTokens: List<String>.from(j['fcmTokens'] ?? []),
        companyId: j['companyId'] as String?,
        companyRole: j['companyRole'] as String?,
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
      );
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
        vehicleClass: VehicleClass.values.firstWhere(
          (e) => e.name == j['class'],
          orElse: () => VehicleClass.business,
        ),
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

  /// Whether [driverId] should see this pending booking as a request.
  bool isOfferedTo(String driverId) {
    final d = dispatch;
    if (d == null || !d.targeted) return true; // broadcast to everyone
    return d.offeredTo == driverId;
  }

  /// When the chauffeur will actually be there.
  DateTime get effectivePickup => pickupAt ?? scheduledAt;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String? ?? '',
        riderId: j['riderId'] as String? ?? '',
        driverId: j['driverId'] as String?,
        origin: Place.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
        destination: Place.fromJson(j['destination'] as Map<String, dynamic>? ?? {}),
        scheduledAt: j['scheduledAt'] != null 
            ? (j['scheduledAt'] as Timestamp).toDate()
            : DateTime.now(),
        vehicleClass: VehicleClass.values.firstWhere(
          (e) => e.name == (j['class'] ?? j['vehicleClass'] ?? 'business'),
          orElse: () => VehicleClass.business,
        ),
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'driverId': driverId,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'class': vehicleClass.name,
        'serviceType': serviceType.name,
        'status': status.label,
        'estimatedPrice': estimatedPrice,
        'finalPrice': finalPrice,
        'paymentId': paymentId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'notes': notes,
        'flightNumber': flightNumber,
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
      );
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
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
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
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? receiptUrl;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        bookingId: j['bookingId'] as String,
        riderId: j['riderId'] as String,
        stripePaymentIntentId: j['stripePaymentIntentId'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String,
        status: PaymentStatusX.fromString(j['status'] as String),
        createdAt: (j['createdAt'] as Timestamp).toDate(),
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

class PricingRule {
  const PricingRule({
    required this.id,
    required this.vehicleClass,
    required this.serviceType,
    required this.basePriceUsd,
    required this.pricePerKmUsd,
    required this.pricePerHourUsd,
    required this.minimumPriceUsd,
  });

  final String id;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final double basePriceUsd;
  final double pricePerKmUsd;
  final double pricePerHourUsd;
  final double minimumPriceUsd;

  factory PricingRule.fromJson(Map<String, dynamic> j) => PricingRule(
        id: j['id'] as String,
        vehicleClass: VehicleClass.values.firstWhere(
          (e) => e.name == j['vehicleClass'],
          orElse: () => VehicleClass.business,
        ),
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == j['serviceType'],
          orElse: () => ServiceType.oneWay,
        ),
        basePriceUsd: (j['basePriceUsd'] as num).toDouble(),
        pricePerKmUsd: (j['pricePerKmUsd'] as num).toDouble(),
        pricePerHourUsd: (j['pricePerHourUsd'] as num).toDouble(),
        minimumPriceUsd: (j['minimumPriceUsd'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'basePriceUsd': basePriceUsd,
        'pricePerKmUsd': pricePerKmUsd,
        'pricePerHourUsd': pricePerHourUsd,
        'minimumPriceUsd': minimumPriceUsd,
      };

  double estimateOneWay(double km) =>
      (basePriceUsd + km * pricePerKmUsd).clamp(minimumPriceUsd, double.infinity);

  double estimateByHour(int hours) =>
      (basePriceUsd + hours * pricePerHourUsd).clamp(minimumPriceUsd, double.infinity);
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
  });

  final String id;
  final String adminId;
  final String action;
  final String targetId;
  final String targetType;
  final String details;
  final DateTime createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id: j['id'] as String,
        adminId: j['adminId'] as String,
        action: j['action'] as String,
        targetId: j['targetId'] as String,
        targetType: j['targetType'] as String,
        details: j['details'] as String? ?? '',
        createdAt: (j['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'adminId': adminId,
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
  static const Map<VehicleClass, Map<ServiceType, Map<String, double>>> rules = {
    VehicleClass.business: {
      ServiceType.oneWay:     {'base': 50, 'perKm': 3.0,  'perHour': 0,   'min': 50},
      ServiceType.byTheHour: {'base': 0,  'perKm': 0,    'perHour': 80,  'min': 160},
    },
    VehicleClass.firstClass: {
      ServiceType.oneWay:     {'base': 80, 'perKm': 4.0,  'perHour': 0,   'min': 80},
      ServiceType.byTheHour: {'base': 0,  'perKm': 0,    'perHour': 120, 'min': 240},
    },
    VehicleClass.businessVan: {
      ServiceType.oneWay:     {'base': 90, 'perKm': 5.0,  'perHour': 0,   'min': 90},
      ServiceType.byTheHour: {'base': 0,  'perKm': 0,    'perHour': 150, 'min': 300},
    },
    VehicleClass.electric: {
      ServiceType.oneWay:     {'base': 60, 'perKm': 3.5,  'perHour': 0,   'min': 60},
      ServiceType.byTheHour: {'base': 0,  'perKm': 0,    'perHour': 90,  'min': 180},
    },
  };

  /// Chauffeur by the day: up to [maxDays], the same hours each day.
  static const maxDays = 7;

  static double estimate(VehicleClass vc, ServiceType st, {double km = 0, int hours = 2, int days = 1}) {
    final r = rules[vc]![st]!;
    if (st == ServiceType.byTheHour) {
      // Each day is priced as an hourly charter, with its own minimum.
      return days.clamp(1, maxDays) * (r['perHour']! * hours).clamp(r['min']!, double.infinity);
    }
    return (r['base']! + km * r['perKm']!).clamp(r['min']!, double.infinity);
  }
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
  final String type; // booking_confirmed, driver_arriving, driver_arrived, ride_started, ride_completed, etc.
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
