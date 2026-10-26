import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../domain/admin_finance.dart';
import '../../domain/admin_operations.dart';
import '../../domain/repositories/admin_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class AdminDataRequested extends AdminEvent {}

/// Listas que solo usa una pestaña: se escuchan al abrirla por primera vez,
/// no al entrar al panel (E15). Las tarifas no: la app ya escucha la misma
/// consulta (PricingCatalog) y Firestore la comparte.
enum AdminLazyData { audit }

class AdminLazyDataNeeded extends AdminEvent {
  const AdminLazyDataNeeded(this.data);
  final AdminLazyData data;
  @override
  List<Object?> get props => [data];
}

// Toda escritura lleva el motivo que queda en la auditoría del servidor
// (Parte A).

class AdminUpdatePricingRequested extends AdminEvent {
  final PricingRule rule;
  final String reason;
  const AdminUpdatePricingRequested(this.rule, this.reason);
  @override
  List<Object?> get props => [rule, reason];
}

/// Borrar una tarifa pasa a desactivarla.
class AdminDeactivatePricingRequested extends AdminEvent {
  final PricingRule rule;
  final String reason;
  const AdminDeactivatePricingRequested(this.rule, this.reason);
  @override
  List<Object?> get props => [rule, reason];
}

class AdminChangeBookingStatusRequested extends AdminEvent {
  final Booking booking;
  final BookingStatus status;
  final String reason;
  const AdminChangeBookingStatusRequested(
    this.booking,
    this.status,
    this.reason,
  );
  @override
  List<Object?> get props => [booking.id, status, reason];
}

/// Central decide tras un «no aparece»: cancelar con o sin recargo.
class AdminNoShowDecided extends AdminEvent {
  final Booking booking;
  final double fee;
  final String reason;
  const AdminNoShowDecided(this.booking, this.fee, this.reason);
  @override
  List<Object?> get props => [booking.id, fee, reason];
}

class AdminAssignDriverRequested extends AdminEvent {
  final Booking booking;
  final String driverId;
  final String reason;
  const AdminAssignDriverRequested(this.booking, this.driverId, this.reason);
  @override
  List<Object?> get props => [booking.id, driverId, reason];
}

class AdminAdjustFinalPriceRequested extends AdminEvent {
  final Booking booking;
  final double finalPrice;
  final String reason;
  const AdminAdjustFinalPriceRequested(
    this.booking,
    this.finalPrice,
    this.reason,
  );
  @override
  List<Object?> get props => [booking.id, finalPrice, reason];
}

class AdminRefundPaymentRequested extends AdminEvent {
  final Payment payment;
  final String reason;
  const AdminRefundPaymentRequested(this.payment, this.reason);
  @override
  List<Object?> get props => [payment.id, reason];
}

class AdminRecordPaymentRequested extends AdminEvent {
  final Booking booking;
  final String method;
  final String reference;
  final String reason;
  const AdminRecordPaymentRequested(
    this.booking,
    this.method,
    this.reference,
    this.reason,
  );
  @override
  List<Object?> get props => [booking.id, method, reference, reason];
}

/// Corrige un cobro registrado a mano; el valor anterior queda auditado.
class AdminCorrectPaymentRequested extends AdminEvent {
  final Payment payment;
  final double? amountBs;
  final String? method;
  final String? reference;
  final String reason;
  const AdminCorrectPaymentRequested(
    this.payment, {
    this.amountBs,
    this.method,
    this.reference,
    required this.reason,
  });
  @override
  List<Object?> get props => [payment.id, amountBs, method, reference, reason];
}

class AdminBackfillSettlementsRequested extends AdminEvent {
  const AdminBackfillSettlementsRequested();
}

class AdminUpdateFinanceSettingsRequested extends AdminEvent {
  final Map<String, dynamic> fields;
  final String reason;
  const AdminUpdateFinanceSettingsRequested(this.fields, this.reason);
  @override
  List<Object?> get props => [fields, reason];
}

class AdminResolveAlertRequested extends AdminEvent {
  final String alertId;
  final String note;
  const AdminResolveAlertRequested(this.alertId, {this.note = ''});
  @override
  List<Object?> get props => [alertId, note];
}

class AdminAcknowledgeIncidentRequested extends AdminEvent {
  final String incidentId;
  const AdminAcknowledgeIncidentRequested(this.incidentId);
  @override
  List<Object?> get props => [incidentId];
}

class AdminCloseIncidentRequested extends AdminEvent {
  final String incidentId;
  final String note;
  const AdminCloseIncidentRequested(this.incidentId, this.note);
  @override
  List<Object?> get props => [incidentId, note];
}

/// «Forzar verificación» con motivo obligatorio (adminOverrideVerify).
class AdminForceVerifyRequested extends AdminEvent {
  final String bookingId;
  final String reason;
  const AdminForceVerifyRequested(this.bookingId, this.reason);
  @override
  List<Object?> get props => [bookingId, reason];
}

class AdminVerifyDriverRequested extends AdminEvent {
  final String driverId;

  /// El admin revisó la condición del vehículo: solo así se activa.
  final bool vehicleReviewed;
  final String vehicleNote;
  final String reason;
  const AdminVerifyDriverRequested(
    this.driverId, {
    this.vehicleReviewed = false,
    this.vehicleNote = '',
    required this.reason,
  });
  @override
  List<Object?> get props => [driverId, vehicleReviewed, vehicleNote, reason];
}

class AdminToggleUserStatusRequested extends AdminEvent {
  final String userId;
  final bool active;
  const AdminToggleUserStatusRequested(this.userId, this.active);
  @override
  List<Object?> get props => [userId, active];
}

class AdminDriverDocumentsUpdateRequested extends AdminEvent {
  final DriverProfile profile;
  final Vehicle? vehicle;
  final DriverDocumentsEdit edit;
  final String reason;
  const AdminDriverDocumentsUpdateRequested(
    this.profile,
    this.vehicle,
    this.edit,
    this.reason,
  );
  @override
  List<Object?> get props => [profile.userId, vehicle?.id, edit, reason];
}

class AdminToggleVehicleStatusRequested extends AdminEvent {
  final String vehicleId;
  final bool active;
  final String reason;
  const AdminToggleVehicleStatusRequested(
    this.vehicleId,
    this.active,
    this.reason,
  );
  @override
  List<Object?> get props => [vehicleId, active, reason];
}

class AdminToggleMaintenanceModeRequested extends AdminEvent {
  final bool active;
  final String reason;
  const AdminToggleMaintenanceModeRequested(this.active, this.reason);
  @override
  List<Object?> get props => [active, reason];
}

class AdminUpdateGlobalSettingsRequested extends AdminEvent {
  final Map<String, dynamic> fields;
  final String reason;
  const AdminUpdateGlobalSettingsRequested(this.fields, this.reason);
  @override
  List<Object?> get props => [fields, reason];
}

class AdminSetLeadHandledRequested extends AdminEvent {
  final String leadId;
  final bool handled;
  const AdminSetLeadHandledRequested(this.leadId, this.handled);
  @override
  List<Object?> get props => [leadId, handled];
}

class AdminUpdateUserRoleRequested extends AdminEvent {
  final String userId;
  final UserRole role;
  const AdminUpdateUserRoleRequested(this.userId, this.role);
  @override
  List<Object?> get props => [userId, role];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminState extends Equatable {
  const AdminState({
    this.bookings = const [],
    this.payments = const [],
    this.users = const [],
    this.drivers = const [],
    this.pricingRules = const [],
    this.vehicles = const [],
    this.auditLogs = const [],
    this.alerts = const [],
    this.incidents = const [],
    this.globalSettings = const {},
    this.financeSettings = const {},
    this.bookingsLimit = 1000,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.messageSeq = 0,
    this.loadError,
    this.lazyLoaded = const {},
  });

  final List<Booking> bookings;
  final List<Payment> payments;
  final List<User> users;
  final List<DriverProfile> drivers;
  final List<PricingRule> pricingRules;
  final List<Vehicle> vehicles;
  final List<AuditLog> auditLogs;

  /// Avisos del servidor (adminAlerts), los más recientes primero.
  final List<AdminAlert> alerts;

  /// Incidentes SOS sin cerrar.
  final List<Incident> incidents;
  final Map<String, dynamic> globalSettings;
  final Map<String, dynamic> financeSettings;
  final int bookingsLimit;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  /// Sube con cada aviso, para que dos avisos iguales seguidos (p. ej. el
  /// mismo error al reintentar) se muestren los dos.
  final int messageSeq;

  /// Una lista en vivo falló al cargar; se mantiene hasta recargar.
  final String? loadError;

  /// Listas de una sola pestaña que ya llegaron (E15): hasta entonces la
  /// pestaña muestra que carga, no «vacío» ni «sin configurar».
  final Set<AdminLazyData> lazyLoaded;

  bool get isMaintenanceMode => globalSettings['isMaintenanceMode'] ?? false;
  bool get pushNotificationsEnabled =>
      globalSettings['pushNotificationsEnabled'] ?? true;
  bool get twoFactorEnabled => globalSettings['twoFactorEnabled'] ?? false;
  bool get firstClassEnabled => globalSettings['firstClassEnabled'] ?? false;

  /// Comisión de la plataforma sobre cada viaje (0–100).
  double get commissionPct =>
      (financeSettings['platformCommissionPct'] as num?)?.toDouble() ??
      kDefaultCommissionPct;

  /// Viajes completados sin reparto confirmado por el servidor (anteriores a
  /// settleBooking, o con un precio ajustado aún sin recalcular). Sale de
  /// `bookings/{id}.settlement`: es el reparto calculado (comisión y parte
  /// del chófer), NO un registro de que al chófer se le pagó. No existe
  /// marca de «chófer pagado»: corregir un cobro reescribe el reparto aunque
  /// ya se le haya pagado por fuera (DEPLOY.md, «Reparto y pago al chófer»).
  int get unsettledCount => bookings
      .where(
        (b) =>
            b.status == BookingStatus.completed &&
            (b.settlement == null ||
                (b.settlement!.amount - b.chargedAmount).abs() >= 0.005),
      )
      .length;

  /// True si se cargó el máximo de reservas: las cifras pueden estar
  /// incompletas para periodos largos.
  bool get bookingsTruncated => bookings.length >= bookingsLimit;

  /// Cross-reference: get a user's display name by their ID
  String userName(String userId) {
    final u = userById(userId);
    if (u != null) return u.displayName;
    return userId.length > 8 ? userId.substring(0, 8) : userId;
  }

  /// Cross-reference: get a user by their ID
  User? userById(String userId) {
    for (final u in users) {
      if (u.id == userId) return u;
    }
    return null;
  }

  DriverProfile? driverById(String userId) {
    for (final d in drivers) {
      if (d.userId == userId) return d;
    }
    return null;
  }

  Payment? paymentFor(Booking b) => FinancialSummary.paymentIndex(payments)(b);

  /// Tarifa vigente (Firestore) o, si no existe, una en blanco por
  /// configurar.
  PricingRule effectiveRule(VehicleClass vc, ServiceType st) {
    final id = PricingRule.idFor(vc, st);
    for (final r in pricingRules) {
      if (r.id == id) return r;
    }
    return PricingRule.unconfigured(vc, st);
  }

  bool hasCustomRule(VehicleClass vc, ServiceType st) {
    final id = PricingRule.idFor(vc, st);
    return pricingRules.any((r) => r.id == id);
  }

  FinancialSummary finance(FinancePeriod period, {DateTime? now}) =>
      FinancialSummary.compute(
        bookings: bookings,
        payments: payments,
        commissionPct: commissionPct,
        period: period,
        now: now,
      );

  int get activeRidesCount =>
      bookings.where((b) => b.status == BookingStatus.inProgress).length;

  int get openAlertsCount => alerts.where((a) => !a.resolved).length;

  /// Incidentes que nadie ha reconocido todavía.
  int get unacknowledgedIncidents => incidents.where((i) => i.needsAck).length;

  int get pendingRidesCount =>
      bookings.where((b) => b.status == BookingStatus.pending).length;

  AdminState copyWith({
    List<Booking>? bookings,
    List<Payment>? payments,
    List<User>? users,
    List<DriverProfile>? drivers,
    List<PricingRule>? pricingRules,
    List<Vehicle>? vehicles,
    List<AuditLog>? auditLogs,
    List<AdminAlert>? alerts,
    List<Incident>? incidents,
    Map<String, dynamic>? globalSettings,
    Map<String, dynamic>? financeSettings,
    int? bookingsLimit,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? loadError,
    bool clearLoadError = false,
    Set<AdminLazyData>? lazyLoaded,
  }) {
    final notice = error != null || successMessage != null;
    return AdminState(
      bookings: bookings ?? this.bookings,
      payments: payments ?? this.payments,
      users: users ?? this.users,
      drivers: drivers ?? this.drivers,
      pricingRules: pricingRules ?? this.pricingRules,
      vehicles: vehicles ?? this.vehicles,
      auditLogs: auditLogs ?? this.auditLogs,
      alerts: alerts ?? this.alerts,
      incidents: incidents ?? this.incidents,
      globalSettings: globalSettings ?? this.globalSettings,
      financeSettings: financeSettings ?? this.financeSettings,
      bookingsLimit: bookingsLimit ?? this.bookingsLimit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      messageSeq: notice ? messageSeq + 1 : messageSeq,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      lazyLoaded: lazyLoaded ?? this.lazyLoaded,
    );
  }

  @override
  List<Object?> get props => [
        bookings,
        payments,
        users,
        drivers,
        pricingRules,
        vehicles,
        auditLogs,
        alerts,
        incidents,
        globalSettings,
        financeSettings,
        bookingsLimit,
        isLoading,
        error,
        successMessage,
        messageSeq,
        loadError,
        lazyLoaded,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;

  /// Registro de pasos de una reserva (detalle de la reserva).
  Stream<List<BookingEvent>> bookingEvents(String bookingId) =>
      _repo.watchBookingEvents(bookingId);

  Stream<List<IncidentLogEntry>> incidentLog(String incidentId) =>
      _repo.watchIncidentLog(incidentId);
  Stream<({double lat, double lng})?> incidentLocation(String incidentId) =>
      _repo.watchIncidentLocation(incidentId);
  Stream<({double lat, double lng})?> driverTracking(String bookingId) =>
      _repo.watchDriverTracking(bookingId);
  final List<StreamSubscription<dynamic>> _subs = [];

  AdminBloc({required AdminRepository adminRepository})
      : _repo = adminRepository,
        super(const AdminState()) {
    on<AdminDataRequested>(_onDataRequested);
    on<AdminLazyDataNeeded>(_onLazyDataNeeded);

    on<AdminUpdatePricingRequested>(
      (e, emit) => _perform(
        emit,
        _repo.updatePricingRule(e.rule, e.reason),
        'Tarifa ${e.rule.vehicleClass.label} · ${e.rule.serviceType.label} '
        'guardada',
      ),
    );
    on<AdminDeactivatePricingRequested>(
      (e, emit) => _perform(
        emit,
        _repo.deactivatePricingRule(e.rule, e.reason),
        'Tarifa desactivada: esa combinación no se puede reservar',
      ),
    );
    on<AdminChangeBookingStatusRequested>(
      (e, emit) => _perform(
        emit,
        _repo.changeBookingStatus(e.booking, e.status, e.reason),
        e.status == BookingStatus.cancelled
            ? 'Reserva cancelada'
            : 'Reserva marcada como "${e.status.displayLabel}"',
      ),
    );
    on<AdminNoShowDecided>(
      (e, emit) => _perform(
        emit,
        _repo.decideNoShow(e.booking, e.fee, e.reason),
        e.fee > 0
            ? 'Reserva cancelada con recargo de ${LuxFormat.money(e.fee)}'
            : 'Reserva cancelada sin recargo',
      ),
    );
    on<AdminAssignDriverRequested>(
      (e, emit) => _perform(
        emit,
        _repo.assignDriver(e.booking, e.driverId, e.reason),
        'Chófer asignado',
      ),
    );
    on<AdminAdjustFinalPriceRequested>(
      (e, emit) => _perform(
        emit,
        _repo.adjustFinalPrice(e.booking, e.finalPrice, e.reason),
        'Precio final actualizado',
      ),
    );
    on<AdminRefundPaymentRequested>(
      (e, emit) => _perform(
        emit,
        _repo.refundPayment(e.payment, e.reason),
        'Pago reembolsado',
      ),
    );
    on<AdminRecordPaymentRequested>(
      (e, emit) => _perform(
        emit,
        _repo.markPaymentCollected(e.booking, e.method, e.reference, e.reason),
        'Cobro registrado',
      ),
    );
    on<AdminCorrectPaymentRequested>(
      (e, emit) => _perform(
        emit,
        _repo.correctPayment(
          e.payment,
          amountBs: e.amountBs,
          method: e.method,
          reference: e.reference,
          reason: e.reason,
        ),
        'Cobro corregido',
      ),
    );
    on<AdminBackfillSettlementsRequested>((e, emit) async {
      final result = await _repo.backfillSettlements();
      result.fold(
        (f) => emit(state.copyWith(error: f.message)),
        (n) => emit(
          state.copyWith(
            successMessage: n == 0
                ? 'No había viajes pendientes de repartir'
                : '$n viajes repartidos',
          ),
        ),
      );
    });
    on<AdminUpdateFinanceSettingsRequested>(
      (e, emit) => _perform(
        emit,
        _repo.updateFinanceSettings(e.fields, e.reason),
        'Configuración financiera guardada',
      ),
    );
    on<AdminResolveAlertRequested>(
      (e, emit) => _perform(
        emit,
        _repo.resolveAlert(e.alertId, note: e.note),
        'Alerta revisada',
      ),
    );
    on<AdminAcknowledgeIncidentRequested>(
      (e, emit) => _perform(
        emit,
        _repo.acknowledgeIncident(e.incidentId),
        'Incidente reconocido',
      ),
    );
    on<AdminCloseIncidentRequested>(
      (e, emit) => _perform(
        emit,
        _repo.closeIncident(e.incidentId, e.note),
        'Incidente cerrado',
      ),
    );
    on<AdminForceVerifyRequested>(
      (e, emit) => _perform(
        emit,
        _repo.forceVerify(e.bookingId, e.reason),
        'Verificación forzada; quedó registrada con tu motivo',
      ),
    );
    on<AdminVerifyDriverRequested>(
      (e, emit) => _perform(
        emit,
        _repo.verifyDriver(
          e.driverId,
          vehicleReviewed: e.vehicleReviewed,
          vehicleNote: e.vehicleNote,
          reason: e.reason,
        ),
        e.vehicleReviewed
            ? 'Chófer verificado y vehículo activado'
            : 'Chófer verificado; el vehículo sigue inactivo',
      ),
    );
    on<AdminToggleUserStatusRequested>(
      (e, emit) => _perform(
        emit,
        _repo.toggleUserStatus(e.userId, e.active),
        e.active ? 'Usuario reactivado' : 'Usuario bloqueado',
      ),
    );
    on<AdminDriverDocumentsUpdateRequested>(
      (e, emit) => _perform(
        emit,
        _repo.updateDriverDocuments(e.profile, e.vehicle, e.edit, e.reason),
        'Datos del chófer actualizados',
      ),
    );
    on<AdminToggleVehicleStatusRequested>(
      (e, emit) => _perform(
        emit,
        _repo.toggleVehicleStatus(e.vehicleId, e.active, e.reason),
        e.active ? 'Vehículo activado' : 'Vehículo desactivado',
      ),
    );
    on<AdminToggleMaintenanceModeRequested>(
      (e, emit) => _perform(
        emit,
        _repo.toggleMaintenanceMode(e.active, e.reason),
        e.active ? 'Modo mantenimiento activado' : 'Reservas reanudadas',
      ),
    );
    on<AdminUpdateGlobalSettingsRequested>(
      (e, emit) => _perform(
        emit,
        _repo.updateGlobalSettings(e.fields, e.reason),
        'Configuración guardada',
      ),
    );
    on<AdminSetLeadHandledRequested>(
      (e, emit) => _perform(
        emit,
        _repo.setLeadHandled(e.leadId, e.handled),
        e.handled ? 'Solicitud atendida' : 'Solicitud pendiente',
      ),
    );
    on<AdminUpdateUserRoleRequested>(
      (e, emit) => _perform(
        emit,
        _repo.updateUserRole(e.userId, e.role),
        'Rol actualizado',
      ),
    );

    on<_AdminStreamUpdated>((e, emit) => emit(e.apply(state)));
    on<_AdminStreamFailed>((e, emit) {
      final msg = e.error.contains('permission-denied')
          ? 'No se pudo cargar ${e.what}: permiso denegado.'
          : 'No se pudo cargar ${e.what}.';
      emit(state.copyWith(isLoading: false, error: msg, loadError: msg));
    });
  }

  Future<void> _perform(
    Emitter<AdminState> emit,
    Future<Either<Failure, void>> action,
    String success,
  ) async {
    final result = await action;
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: success)),
    );
  }

  void _listen<T>(
    Stream<T> stream,
    String what,
    AdminState Function(AdminState, T) apply,
  ) {
    _subs.add(
      stream.listen(
        (data) => add(
          _AdminStreamUpdated((s) => apply(s, data).copyWith(isLoading: false)),
        ),
        onError: (Object e) =>
            add(_AdminStreamFailed(what, unexpectedErrorMessage(e))),
      ),
    );
  }

  Future<void> _onDataRequested(
    AdminDataRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        bookingsLimit: _repo.bookingsLimit,
        clearLoadError: true,
      ),
    );
    await _cancelSubs();

    _listen(
      _repo.watchAllBookings(),
      'las reservas',
      (s, d) => s.copyWith(bookings: d),
    );
    _listen(
      _repo.watchAllPayments(),
      'los pagos',
      (s, d) => s.copyWith(payments: d),
    );
    _listen(
      _repo.watchAllUsers(),
      'los usuarios',
      (s, d) => s.copyWith(users: d),
    );
    _listen(
      _repo.watchAllDrivers(),
      'los chóferes',
      (s, d) => s.copyWith(drivers: d),
    );
    _listen(
      _repo.watchPricingRules(),
      'las tarifas',
      (s, d) => s.copyWith(pricingRules: d),
    );
    _listen(
      _repo.watchAllVehicles(),
      'los vehículos',
      (s, d) => s.copyWith(vehicles: d),
    );
    _listen(
      _repo.watchAdminAlerts(),
      'las alertas',
      (s, d) => s.copyWith(alerts: d),
    );
    _listen(
      _repo.watchOpenIncidents(),
      'los incidentes',
      (s, d) => s.copyWith(incidents: d),
    );
    _listen(
      _repo.watchGlobalSettings(),
      'la configuración',
      (s, d) => s.copyWith(globalSettings: d),
    );
    _listen(
      _repo.watchFinanceSettings(),
      'la configuración financiera',
      (s, d) => s.copyWith(financeSettings: d),
    );
    // Al recargar, las de una pestaña ya abierta vuelven a escucharse.
    _lazyRequested.forEach(_startLazy);
  }

  /// Listas de una sola pestaña pedidas hasta ahora.
  final _lazyRequested = <AdminLazyData>{};

  void _onLazyDataNeeded(AdminLazyDataNeeded e, Emitter<AdminState> emit) {
    if (_lazyRequested.add(e.data)) _startLazy(e.data);
  }

  void _startLazy(AdminLazyData data) {
    Set<AdminLazyData> loaded(AdminState s) => {...s.lazyLoaded, data};
    switch (data) {
      case AdminLazyData.audit:
        _listen(
          _repo.watchAuditLogs(),
          'la auditoría',
          (s, d) => s.copyWith(auditLogs: d, lazyLoaded: loaded(s)),
        );
    }
  }

  Future<void> _cancelSubs() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  @override
  Future<void> close() async {
    await _cancelSubs();
    return super.close();
  }
}

// Internal stream events
class _AdminStreamUpdated extends AdminEvent {
  const _AdminStreamUpdated(this.apply);
  final AdminState Function(AdminState) apply;
  @override
  List<Object?> get props => [identityHashCode(this)];
}

class _AdminStreamFailed extends AdminEvent {
  const _AdminStreamFailed(this.what, this.error);
  final String what;
  final String error;
  @override
  List<Object?> get props => [what, error];
}
