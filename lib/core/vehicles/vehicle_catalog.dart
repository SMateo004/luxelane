import 'dart:async';
import 'dart:ui' show Color, Locale;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;

import '../../l10n/gen/app_localizations.dart';
import '../enums/enums.dart';

/// Languages every vehicle text is kept in.
const vehicleLangs = ['es', 'en', 'pt'];

/// Prices of one service for one vehicle type, in Bolivianos.
@immutable
class PriceRule {
  const PriceRule({this.base = 0, this.perKm = 0, this.perHour = 0, required this.min});
  final double base;
  final double perKm;
  final double perHour;
  final double min;

  static PriceRule? fromJson(Object? j) {
    if (j is! Map) return null;
    double n(String k) {
      final v = j[k];
      return v is num && v.isFinite && v >= 0 ? v.toDouble() : 0;
    }

    return PriceRule(base: n('base'), perKm: n('perKm'), perHour: n('perHour'), min: n('min'));
  }

  Map<String, dynamic> toJson() => {'base': base, 'perKm': perKm, 'perHour': perHour, 'min': min};

  @override
  bool operator ==(Object other) =>
      other is PriceRule && other.base == base && other.perKm == perKm && other.perHour == perHour && other.min == min;

  @override
  int get hashCode => Object.hash(base, perKm, perHour, min);
}

/// A photo of the vehicle with a caption in each language (booking hero).
@immutable
class VehicleSlide {
  const VehicleSlide({required this.url, this.caption = const {}});
  final String url;
  final Map<String, String> caption;

  String captionIn(String lang) => caption[lang] ?? caption['es'] ?? '';

  static VehicleSlide? fromJson(Object? j) {
    if (j is! Map || j['url'] is! String || !(j['url'] as String).startsWith('https://')) return null;
    return VehicleSlide(url: j['url'] as String, caption: _texts(j['caption']));
  }

  Map<String, dynamic> toJson() => {'url': url, 'caption': caption};
}

Map<String, String> _texts(Object? j) => {
      if (j is Map)
        for (final lang in vehicleLangs)
          if (j[lang] is String && (j[lang] as String).trim().isNotEmpty) lang: (j[lang] as String).trim(),
    };

/// Icons the admin can pick for a vehicle type.
const vehicleIcons = <String, IconData>{
  'car': Icons.directions_car_outlined,
  'star': Icons.star_outline_rounded,
  'van': Icons.airport_shuttle_outlined,
  'electric': Icons.electric_car_outlined,
  'suv': Icons.directions_car_filled_outlined,
};

/// Everything about a vehicle type: what riders see, what it carries and what
/// each service costs. Built-in types have defaults; an admin document in
/// vehicleClasses/{id} overrides them, and new ids add new types.
@immutable
class VehicleClassInfo {
  const VehicleClassInfo({
    required this.id,
    required this.name,
    this.description = const {},
    this.active = true,
    this.order = 100,
    this.capacity = 3,
    this.carryOn = 2,
    this.checked = 2,
    this.extraLarge = 1,
    this.childSeat = true,
    this.icon = 'car',
    this.color = const Color(0xFF3A7BD5),
    this.imageUrl,
    this.asset,
    this.slides = const [],
    this.oneWay,
    this.byTheHour,
    this.builtIn = false,
  });

  final String id;
  final Map<String, String> name;
  final Map<String, String> description;

  /// Offered to riders (and chosen by chauffeurs). Archived types stay for
  /// past bookings but can't be booked.
  final bool active;
  final int order;
  final int capacity;
  final int carryOn;
  final int checked;
  final int extraLarge;
  final bool childSeat;
  final String icon;
  final Color color;

  /// Uploaded photo (cut-out PNG looks best); built-ins fall back to [asset].
  final String? imageUrl;

  /// Bundled image of a built-in type (assets/images/vehicles/...).
  final String? asset;
  final List<VehicleSlide> slides;

  /// Null when the type doesn't offer that service.
  final PriceRule? oneWay;
  final PriceRule? byTheHour;
  final bool builtIn;

  VehicleClass get vehicleClass => VehicleClass(id);

  String nameIn(String lang) => name[lang] ?? name['es'] ?? (name.isEmpty ? id : name.values.first);
  String descriptionIn(String lang) => description[lang] ?? description['es'] ?? '';

  IconData get iconData => vehicleIcons[icon] ?? Icons.directions_car_outlined;

  // Light tints of the accent for the booking screen.
  Color get sectionTint => Color.lerp(const Color(0xFFFFFFFF), color, 0.08)!;
  Color get cardTint => Color.lerp(const Color(0xFFFFFFFF), color, 0.03)!;
  Color get selectedTint => Color.lerp(const Color(0xFFFFFFFF), color, 0.09)!;

  PriceRule? rule(ServiceType st) => st == ServiceType.oneWay ? oneWay : byTheHour;
  bool offers(ServiceType st) => rule(st) != null;

  /// Estimate before the server quote (the server price is the one charged).
  double estimate(ServiceType st, {double km = 0, int hours = 2, int days = 1}) {
    final r = rule(st);
    if (r == null) return 0;
    if (st == ServiceType.byTheHour) {
      // Each day is priced as an hourly charter, with its own minimum.
      return days.clamp(1, maxCharterDays) * (r.base + r.perHour * hours).clamp(r.min, double.infinity);
    }
    return (r.base + km * r.perKm).clamp(r.min, double.infinity);
  }

  /// Chauffeur by the day: up to this many days, the same hours each day.
  static const maxCharterDays = 7;

  /// Reads an admin document over [base] (the built-in defaults, if any).
  factory VehicleClassInfo.fromJson(String id, Map<String, dynamic> j, {VehicleClassInfo? base}) {
    int count(String k, int d, {int max = 60}) {
      final v = j[k];
      return v is num && v.isFinite && v >= 0 && v <= max ? v.round() : d;
    }

    final services = j['services'] is Map ? j['services'] as Map : const {};
    final hasServices = j['services'] is Map;
    final slides = j['slides'] is List
        ? (j['slides'] as List).map(VehicleSlide.fromJson).whereType<VehicleSlide>().toList()
        : base?.slides ?? const <VehicleSlide>[];
    final name = _texts(j['name']);
    final colorHex = j['color'];
    return VehicleClassInfo(
      id: id,
      name: name.isEmpty ? base?.name ?? {'es': id} : name,
      description: j.containsKey('description') ? _texts(j['description']) : base?.description ?? const {},
      active: j['active'] is bool ? j['active'] as bool : base?.active ?? true,
      order: count('order', base?.order ?? 100, max: 9999),
      capacity: count('capacity', base?.capacity ?? 3).clamp(1, 60),
      carryOn: count('carryOn', base?.carryOn ?? 2),
      checked: count('checked', base?.checked ?? 2),
      extraLarge: count('extraLarge', base?.extraLarge ?? 1),
      childSeat: j['childSeat'] is bool ? j['childSeat'] as bool : base?.childSeat ?? true,
      icon: j['icon'] is String && vehicleIcons.containsKey(j['icon']) ? j['icon'] as String : base?.icon ?? 'car',
      color: colorHex is String ? parseHexColor(colorHex) ?? base?.color ?? const Color(0xFF3A7BD5) : base?.color ?? const Color(0xFF3A7BD5),
      imageUrl: j['imageUrl'] is String && (j['imageUrl'] as String).startsWith('https://') ? j['imageUrl'] as String : null,
      asset: base?.asset,
      slides: slides,
      oneWay: hasServices ? PriceRule.fromJson(services['oneWay']) : base?.oneWay,
      byTheHour: hasServices ? PriceRule.fromJson(services['byTheHour']) : base?.byTheHour,
      builtIn: base?.builtIn ?? false,
    );
  }

  /// What the admin saves (saveVehicleClass checks it again).
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'active': active,
        'order': order,
        'capacity': capacity,
        'carryOn': carryOn,
        'checked': checked,
        'extraLarge': extraLarge,
        'childSeat': childSeat,
        'icon': icon,
        'color': hexColor(color),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'slides': [for (final s in slides) s.toJson()],
        'services': {
          if (oneWay != null) 'oneWay': oneWay!.toJson(),
          if (byTheHour != null) 'byTheHour': byTheHour!.toJson(),
        },
      };

  VehicleClassInfo copyWith({
    Map<String, String>? name,
    Map<String, String>? description,
    bool? active,
    int? order,
    int? capacity,
    int? carryOn,
    int? checked,
    int? extraLarge,
    bool? childSeat,
    String? icon,
    Color? color,
    String? imageUrl,
    bool clearImage = false,
    List<VehicleSlide>? slides,
    PriceRule? oneWay,
    bool clearOneWay = false,
    PriceRule? byTheHour,
    bool clearByTheHour = false,
  }) =>
      VehicleClassInfo(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        active: active ?? this.active,
        order: order ?? this.order,
        capacity: capacity ?? this.capacity,
        carryOn: carryOn ?? this.carryOn,
        checked: checked ?? this.checked,
        extraLarge: extraLarge ?? this.extraLarge,
        childSeat: childSeat ?? this.childSeat,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        imageUrl: clearImage ? null : imageUrl ?? this.imageUrl,
        asset: asset,
        slides: slides ?? this.slides,
        oneWay: clearOneWay ? null : oneWay ?? this.oneWay,
        byTheHour: clearByTheHour ? null : byTheHour ?? this.byTheHour,
        builtIn: builtIn,
      );

  /// Placeholder for a type that's no longer in the catalog (old bookings).
  factory VehicleClassInfo.unknown(String id) =>
      VehicleClassInfo(id: id, name: {'es': id}, active: false, order: 9999);
}

/// Ids are kept on bookings forever: short, lowercase-ish, no spaces.
final vehicleIdPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]{1,39}$');

/// Error key (l10n `vehicleError…`) for an invalid type, or null.
String? validateVehicleClass(VehicleClassInfo v) {
  if (!vehicleIdPattern.hasMatch(v.id)) return 'id';
  if (vehicleLangs.any((l) => (v.name[l] ?? '').trim().isEmpty)) return 'name';
  if (v.name.values.any((n) => n.length > 40) || v.description.values.any((d) => d.length > 120)) return 'length';
  if (v.capacity < 1 || v.capacity > 60) return 'capacity';
  if (v.oneWay == null && v.byTheHour == null) return 'services';
  final ow = v.oneWay;
  if (ow != null && ow.min <= 0) return 'price';
  final bh = v.byTheHour;
  if (bh != null && (bh.perHour <= 0 || bh.min <= 0)) return 'price';
  if (v.slides.length > 8) return 'slides';
  return null;
}

Color? parseHexColor(String hex) {
  final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  return m == null ? null : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

String hexColor(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

// ── Built-in types (what the app offered before the catalog) ────────────────

Map<String, String> _l10n(String Function(AppLocalizations l) pick) =>
    {for (final lang in vehicleLangs) lang: pick(lookupAppLocalizations(Locale(lang)))};

const _img = 'https://images.unsplash.com/photo-';
const _q = '?w=900&q=90&auto=format&fit=crop';

List<VehicleSlide> _slides(List<(String Function(AppLocalizations), String)> s) =>
    [for (final (caption, photo) in s) VehicleSlide(url: '$_img$photo$_q', caption: _l10n(caption))];

final Map<String, VehicleClassInfo> builtInVehicleClasses = {
  'business': VehicleClassInfo(
    id: 'business',
    name: _l10n((l) => l.vehicleBusiness),
    description: _l10n((l) => l.vehicleBusinessDesc),
    order: 0,
    capacity: 3,
    carryOn: 2,
    checked: 2,
    extraLarge: 1,
    icon: 'car',
    color: const Color(0xFF3A7BD5),
    asset: 'assets/images/vehicles/business/car.png',
    slides: _slides([
      ((l) => l.bookingSlideBusiness1, '1555215695-3004980ad54e'),
      ((l) => l.bookingSlideBusiness2, '1549317661-bd32c8ce0db2'),
      ((l) => l.bookingSlideBusiness3, '1511919884226-fd3cad34687c'),
      ((l) => l.bookingSlideBusiness4, '1503736334956-4c8f8e92946d'),
    ]),
    oneWay: const PriceRule(base: 50, perKm: 3.0, min: 50),
    byTheHour: const PriceRule(perHour: 80, min: 160),
    builtIn: true,
  ),
  'firstClass': VehicleClassInfo(
    id: 'firstClass',
    name: _l10n((l) => l.vehicleFirstClass),
    description: _l10n((l) => l.vehicleFirstClassDesc),
    order: 1,
    capacity: 3,
    carryOn: 3,
    checked: 2,
    extraLarge: 1,
    icon: 'star',
    color: const Color(0xFF7B4DB5),
    asset: 'assets/images/vehicles/first_class/car.png',
    slides: _slides([
      ((l) => l.bookingSlideFirst1, '1563720223523-e75db7d32e5c'),
      ((l) => l.bookingSlideFirst2, '1485291571150-772bcfc10da5'),
      ((l) => l.bookingSlideFirst3, '1493238792000-8113da705763'),
      ((l) => l.bookingSlideFirst4, '1617788138017-80ad40651399'),
    ]),
    oneWay: const PriceRule(base: 80, perKm: 4.0, min: 80),
    byTheHour: const PriceRule(perHour: 120, min: 240),
    builtIn: true,
  ),
  'businessVan': VehicleClassInfo(
    id: 'businessVan',
    name: _l10n((l) => l.vehicleBusinessVan),
    description: _l10n((l) => l.vehicleBusinessVanDesc),
    order: 2,
    capacity: 7,
    carryOn: 8,
    checked: 6,
    extraLarge: 4,
    childSeat: false,
    icon: 'van',
    color: const Color(0xFF2E6AC8),
    asset: 'assets/images/vehicles/van/car.png',
    slides: _slides([
      ((l) => l.bookingSlideVan1, '1519641471654-76ce0107ad1b'),
      ((l) => l.bookingSlideVan2, '1544620347-c4fd4a3d5957'),
      ((l) => l.bookingSlideVan3, '1570125909232-eb263c188f7e'),
      ((l) => l.bookingSlideVan4, '1560958089-b8a1929cea89'),
    ]),
    oneWay: const PriceRule(base: 90, perKm: 5.0, min: 90),
    byTheHour: const PriceRule(perHour: 150, min: 300),
    builtIn: true,
  ),
  // Not offered to riders until an admin turns it on (as before).
  'electric': VehicleClassInfo(
    id: 'electric',
    name: _l10n((l) => l.vehicleElectric),
    description: _l10n((l) => l.vehicleElectricDesc),
    active: false,
    order: 3,
    capacity: 3,
    carryOn: 2,
    checked: 2,
    extraLarge: 1,
    icon: 'electric',
    color: const Color(0xFF2A9E72),
    asset: 'assets/images/vehicles/electric/car.png',
    slides: _slides([
      ((l) => l.bookingSlideElectric1, '1617788138017-80ad40651399'),
      ((l) => l.bookingSlideElectric2, '1560958089-b8a1929cea89'),
    ]),
    oneWay: const PriceRule(base: 60, perKm: 3.5, min: 60),
    byTheHour: const PriceRule(perHour: 90, min: 180),
    builtIn: true,
  ),
};

/// The vehicle types in effect: built-ins overridden by vehicleClasses/{id},
/// plus the types admins added. Watched live, so an edit in the admin shows
/// up in every open app.
class VehicleCatalog extends ChangeNotifier {
  VehicleCatalog._();
  static final instance = VehicleCatalog._();

  Map<String, VehicleClassInfo> _merged = Map.of(builtInVehicleClasses);
  Map<String, Map<String, dynamic>> _docs = const {};
  Map<String, Map<String, dynamic>> _legacyRules = const {};
  final _subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

  void watch(FirebaseFirestore db) {
    if (_subs.isNotEmpty) return;
    _subs
      ..add(db.collection('vehicleClasses').snapshots().listen(
            (snap) => setDocs({for (final d in snap.docs) d.id: d.data()}),
            // Unreadable catalog (offline first run): keep the defaults.
            onError: (Object _) {},
          ))
      // Prices set in the old pricing tab, for built-in types never edited
      // in the catalog (the server reads them the same way).
      ..add(db.collection('pricingRules').snapshots().listen(
            (snap) => setLegacyRules({for (final d in snap.docs) d.id: d.data()}),
            onError: (Object _) {},
          ));
  }

  /// Applies admin documents over the built-ins (also used by tests).
  void setDocs(Map<String, Map<String, dynamic>> docs) {
    _docs = docs;
    _rebuild();
  }

  /// pricingRules/{type}_{service} documents (Bs, fields named *Usd).
  void setLegacyRules(Map<String, Map<String, dynamic>> rules) {
    _legacyRules = rules;
    _rebuild();
  }

  void _rebuild() {
    _merged = {
      for (final e in builtInVehicleClasses.entries) e.key: _withLegacyPrices(e.value),
      for (final e in _docs.entries) e.key: VehicleClassInfo.fromJson(e.key, e.value, base: builtInVehicleClasses[e.key]),
    };
    notifyListeners();
  }

  VehicleClassInfo _withLegacyPrices(VehicleClassInfo v) {
    PriceRule? legacy(ServiceType st, PriceRule? fallback) {
      final d = _legacyRules['${v.id}_${st.name}'];
      if (d == null || fallback == null) return fallback;
      double n(String k, double def) {
        final x = d[k];
        return x is num && x.isFinite && x >= 0 ? x.toDouble() : def;
      }

      return PriceRule(
        base: n('basePriceUsd', fallback.base),
        perKm: n('pricePerKmUsd', fallback.perKm),
        perHour: n('pricePerHourUsd', fallback.perHour),
        min: n('minimumPriceUsd', fallback.min),
      );
    }

    return v.copyWith(oneWay: legacy(ServiceType.oneWay, v.oneWay), byTheHour: legacy(ServiceType.byTheHour, v.byTheHour));
  }

  /// Whether an admin has saved this type (built-ins start from defaults).
  bool isCustomized(String id) => _docs.containsKey(id);

  /// Every type, archived ones included, in display order.
  List<VehicleClassInfo> get all => _merged.values.toList()
    ..sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.id.compareTo(b.id));

  /// Types riders can book (and chauffeurs can drive).
  List<VehicleClassInfo> get active => all.where((v) => v.active).toList();

  /// Bookable types that offer [st].
  List<VehicleClassInfo> activeFor(ServiceType st) => active.where((v) => v.offers(st)).toList();

  VehicleClassInfo info(VehicleClass vc) => _merged[vc.id] ?? VehicleClassInfo.unknown(vc.id);
}
