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

  static double estimate(VehicleClass vc, ServiceType st, {double km = 0, int hours = 2}) {
    final r = rules[vc]![st]!;
    if (st == ServiceType.byTheHour) {
      return (r['perHour']! * hours).clamp(r['min']!, double.infinity);
    }
    return (r['base']! + km * r['perKm']!).clamp(r['min']!, double.infinity);
  }
}
