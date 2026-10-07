import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums/enums.dart';

enum PromoType { percent, fixed }

/// A promo code as defined by Luxelane admins (promoCodes/{code}).
class PromoCode {
  const PromoCode({
    required this.code,
    required this.type,
    required this.value,
    this.description = '',
    this.maxDiscount = 0,
    this.minFare = 0,
    this.validFrom,
    this.validUntil,
    this.maxRedemptions = 0,
    this.redemptions = 0,
    this.perUserLimit = 1,
    this.firstRideOnly = false,
    this.vehicleClasses = const [],
    this.active = true,
  });

  final String code;
  final PromoType type;

  /// Percent (1–100) or Bs.
  final double value;
  final String description;

  /// Cap for percent codes in Bs (0 = none).
  final double maxDiscount;
  final double minFare;
  final DateTime? validFrom;
  final DateTime? validUntil;

  /// Total uses (0 = unlimited).
  final int maxRedemptions;
  final int redemptions;
  final int perUserLimit;
  final bool firstRideOnly;

  /// Empty = every class.
  final List<VehicleClass> vehicleClasses;
  final bool active;

  bool expiredAt(DateTime now) => validUntil != null && now.isAfter(validUntil!);
  bool exhausted() => maxRedemptions > 0 && redemptions >= maxRedemptions;

  factory PromoCode.fromJson(String id, Map<String, dynamic> j) => PromoCode(
        code: j['code'] as String? ?? id,
        type: j['type'] == 'fixed' ? PromoType.fixed : PromoType.percent,
        value: (j['value'] as num?)?.toDouble() ?? 0,
        description: j['description'] as String? ?? '',
        maxDiscount: (j['maxDiscount'] as num?)?.toDouble() ?? 0,
        minFare: (j['minFare'] as num?)?.toDouble() ?? 0,
        validFrom: (j['validFrom'] as Timestamp?)?.toDate(),
        validUntil: (j['validUntil'] as Timestamp?)?.toDate(),
        maxRedemptions: (j['maxRedemptions'] as num?)?.toInt() ?? 0,
        redemptions: (j['redemptions'] as num?)?.toInt() ?? 0,
        perUserLimit: (j['perUserLimit'] as num?)?.toInt() ?? 1,
        firstRideOnly: j['firstRideOnly'] as bool? ?? false,
        vehicleClasses: [
          for (final v in (j['vehicleClasses'] as List? ?? const []))
            ...VehicleClass.values.where((c) => c.name == v),
        ],
        active: j['active'] as bool? ?? true,
      );

  /// Payload for the savePromoCode Cloud Function.
  Map<String, dynamic> toCallable({required bool create}) => {
        'create': create,
        'code': code,
        'type': type.name,
        'value': value,
        'description': description,
        'maxDiscount': maxDiscount,
        'minFare': minFare,
        'validFrom': validFrom?.millisecondsSinceEpoch,
        'validUntil': validUntil?.millisecondsSinceEpoch,
        'maxRedemptions': maxRedemptions,
        'perUserLimit': perUserLimit,
        'firstRideOnly': firstRideOnly,
        'vehicleClasses': vehicleClasses.map((c) => c.name).toList(),
        'active': active,
      };

  PromoCode copyWith({bool? active}) => PromoCode(
        code: code,
        type: type,
        value: value,
        description: description,
        maxDiscount: maxDiscount,
        minFare: minFare,
        validFrom: validFrom,
        validUntil: validUntil,
        maxRedemptions: maxRedemptions,
        redemptions: redemptions,
        perUserLimit: perUserLimit,
        firstRideOnly: firstRideOnly,
        vehicleClasses: vehicleClasses,
        active: active ?? this.active,
      );
}

/// Error codes from savePromoCode.
abstract final class PromoAdminErrorCodes {
  static const badCode = 'promo/bad-code';
  static const badValue = 'promo/bad-value';
  static const badDates = 'promo/bad-dates';
  static const exists = 'promo/exists';
  static const failed = 'promo/failed';

  static String fromMessage(String? m) =>
      [badCode, badValue, badDates, exists].firstWhere((c) => (m ?? '').contains(c), orElse: () => failed);
}
