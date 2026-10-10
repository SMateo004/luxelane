import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../enums/enums.dart';
import '../models/models.dart';

/// Fuente única de tarifas y estado operativo para toda la app.
///
/// Escucha `/pricingRules` (tarifas que guarda el admin) y `/config/global`
/// (modo mantenimiento). Cualquier precio mostrado o enviado al reservar sale
/// de aquí, así lo que el admin configura es exactamente lo que se cobra.
/// Mientras no hay datos (sin conexión, sin Firebase) usa las tarifas de
/// fábrica de [DefaultPricing].
class PricingCatalog extends ChangeNotifier {
  PricingCatalog._();

  static final PricingCatalog instance = PricingCatalog._();

  final Map<String, PricingRule> _rules = {};
  bool _maintenance = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _rulesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;

  bool get isMaintenanceMode => _maintenance;

  void start(FirebaseFirestore db) {
    _rulesSub?.cancel();
    _configSub?.cancel();
    _rulesSub = db.collection('pricingRules').snapshots().listen(
          (snap) => setRules(snap.docs.map((d) {
            try {
              return PricingRule.fromJson({...d.data(), 'id': d.id});
            } catch (_) {
              return null;
            }
          }).whereType<PricingRule>()),
          onError: (Object e) => debugPrint('[PricingCatalog] reglas: $e'),
        );
    _configSub = db.collection('config').doc('global').snapshots().listen(
          (doc) => setMaintenanceMode(doc.data()?['isMaintenanceMode'] == true),
          onError: (Object e) => debugPrint('[PricingCatalog] config: $e'),
        );
  }

  @visibleForTesting
  void setRules(Iterable<PricingRule> rules) {
    _rules
      ..clear()
      ..addEntries(rules.map((r) =>
          MapEntry(PricingRule.idFor(r.vehicleClass, r.serviceType), r)));
    notifyListeners();
  }

  @visibleForTesting
  void setMaintenanceMode(bool value) {
    if (value == _maintenance) return;
    _maintenance = value;
    notifyListeners();
  }

  /// Tarifa vigente: la guardada por el admin o, si no existe, la de fábrica.
  PricingRule ruleFor(VehicleClass vc, ServiceType st) =>
      _rules[PricingRule.idFor(vc, st)] ?? PricingRule.fallback(vc, st);

  double estimate(VehicleClass vc, ServiceType st,
          {double km = 0, int hours = 2}) =>
      ruleFor(vc, st).estimate(km: km, hours: hours);

  /// Precio "desde" que se anuncia en la web (el mínimo de la tarifa).
  double startingPrice(VehicleClass vc, ServiceType st) =>
      ruleFor(vc, st).minimumPriceUsd;

  bool isAvailable(VehicleClass vc, ServiceType st) =>
      !_maintenance && ruleFor(vc, st).isActive;

  /// Motivo legible por el que no se puede reservar, o null si se puede.
  String? unavailableReason(VehicleClass vc, ServiceType st) {
    if (_maintenance) {
      return 'Las reservas están en pausa por mantenimiento. '
          'Vuelve a intentarlo en unos minutos.';
    }
    if (!ruleFor(vc, st).isActive) {
      return '${vc.label} no está disponible para "${st.label}" '
          'en este momento.';
    }
    return null;
  }
}
