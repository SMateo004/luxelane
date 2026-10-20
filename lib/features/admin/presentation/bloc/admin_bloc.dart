import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../domain/admin_finance.dart';
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

class AdminUpdatePricingRequested extends AdminEvent {
  final PricingRule rule;
  const AdminUpdatePricingRequested(this.rule);
  @override
  List<Object?> get props => [rule];
}

class AdminResetPricingRequested extends AdminEvent {
  final PricingRule rule;
  const AdminResetPricingRequested(this.rule);
  @override
  List<Object?> get props => [rule];
}

class AdminChangeBookingStatusRequested extends AdminEvent {
  final Booking booking;
  final BookingStatus status;
  final String reason;
  const AdminChangeBookingStatusRequested(this.booking, this.status,
      {this.reason = ''});
  @override
  List<Object?> get props => [booking.id, status, reason];
}

class AdminAssignDriverRequested extends AdminEvent {
  final Booking booking;
  final String driverId;
  const AdminAssignDriverRequested(this.booking, this.driverId);
  @override
  List<Object?> get props => [booking.id, driverId];
}

class AdminAdjustFinalPriceRequested extends AdminEvent {
  final Booking booking;
  final double finalPrice;
  final String reason;
  const AdminAdjustFinalPriceRequested(
      this.booking, this.finalPrice, this.reason);
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
  const AdminRecordPaymentRequested(this.booking, this.method, this.reference);
  @override
  List<Object?> get props => [booking.id, method, reference];
}

class AdminBackfillSettlementsRequested extends AdminEvent {
  const AdminBackfillSettlementsRequested();
}

class AdminUpdateFinanceSettingsRequested extends AdminEvent {
  final Map<String, dynamic> fields;
  const AdminUpdateFinanceSettingsRequested(this.fields);
  @override
  List<Object?> get props => [fields];
}

class AdminResolveAlertRequested extends AdminEvent {
  final String alertId;
  final String note;
  const AdminResolveAlertRequested(this.alertId, {this.note = ''});
  @override
  List<Object?> get props => [alertId, note];
}

class AdminVerifyDriverRequested extends AdminEvent {
  final String driverId;

  /// El admin revisó la condición del vehículo: solo así se activa.
  final bool vehicleReviewed;
  final String vehicleNote;
  const AdminVerifyDriverRequested(this.driverId,
      {this.vehicleReviewed = false, this.vehicleNote = ''});
  @override
  List<Object?> get props => [driverId, vehicleReviewed, vehicleNote];
}

class AdminToggleUserStatusRequested extends AdminEvent {
  final String userId;
  final bool active;
  const AdminToggleUserStatusRequested(this.userId, this.active);
  @override
  List<Object?> get props => [userId, active];
}

class AdminToggleVehicleStatusRequested extends AdminEvent {
  final String vehicleId;
  final bool active;
  const AdminToggleVehicleStatusRequested(this.vehicleId, this.active);
  @override
  List<Object?> get props => [vehicleId, active];
}

class AdminToggleMaintenanceModeRequested extends AdminEvent {
  final bool active;
  const AdminToggleMaintenanceModeRequested(this.active);
  @override
  List<Object?> get props => [active];
}

class AdminUpdateGlobalSettingsRequested extends AdminEvent {
  final Map<String, dynamic> fields;
  const AdminUpdateGlobalSettingsRequested(this.fields);
  @override
  List<Object?> get props => [fields];
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
    this.globalSettings = const {},
    this.financeSettings = const {},
    this.bookingsLimit = 1000,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.messageSeq = 0,
    this.loadError,
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
  /// settleBooking, o con un precio ajustado aún sin recalcular).
  int get unsettledCount => bookings
      .where((b) =>
          b.status == BookingStatus.completed &&
          (b.settlement == null ||
              (b.settlement!.amount - b.chargedAmount).abs() >= 0.005))
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

  /// Tarifa vigente (Firestore o, si no existe, la de fábrica).
  PricingRule effectiveRule(VehicleClass vc, ServiceType st) {
    final id = PricingRule.idFor(vc, st);
    for (final r in pricingRules) {
      if (r.id == id) return r;
    }
    return PricingRule.fallback(vc, st);
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
    Map<String, dynamic>? globalSettings,
    Map<String, dynamic>? financeSettings,
    int? bookingsLimit,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? loadError,
    bool clearLoadError = false,
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
      globalSettings: globalSettings ?? this.globalSettings,
      financeSettings: financeSettings ?? this.financeSettings,
      bookingsLimit: bookingsLimit ?? this.bookingsLimit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      messageSeq: notice ? messageSeq + 1 : messageSeq,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
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
        globalSettings,
        financeSettings,
        bookingsLimit,
        isLoading,
        error,
        successMessage,
        messageSeq,
        loadError,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;
  final List<StreamSubscription<dynamic>> _subs = [];

  AdminBloc({required AdminRepository adminRepository})
      : _repo = adminRepository,
        super(const AdminState()) {
    on<AdminDataRequested>(_onDataRequested);

    on<AdminUpdatePricingRequested>((e, emit) => _perform(
        emit,
        _repo.updatePricingRule(e.rule),
        'Tarifa ${e.rule.vehicleClass.label} · ${e.rule.serviceType.label} '
        'guardada'));
    on<AdminResetPricingRequested>((e, emit) => _perform(emit,
        _repo.resetPricingRule(e.rule), 'Tarifa restablecida a la de fábrica'));
    on<AdminChangeBookingStatusRequested>((e, emit) => _perform(
        emit,
        _repo.changeBookingStatus(e.booking, e.status, reason: e.reason),
        e.status == BookingStatus.cancelled
            ? 'Reserva cancelada'
            : 'Reserva marcada como "${e.status.displayLabel}"'));
    on<AdminAssignDriverRequested>((e, emit) => _perform(
        emit, _repo.assignDriver(e.booking, e.driverId), 'Chófer asignado'));
    on<AdminAdjustFinalPriceRequested>((e, emit) => _perform(
        emit,
        _repo.adjustFinalPrice(e.booking, e.finalPrice, e.reason),
        'Precio final actualizado'));
    on<AdminRefundPaymentRequested>((e, emit) => _perform(
        emit, _repo.refundPayment(e.payment, e.reason), 'Pago reembolsado'));
    on<AdminRecordPaymentRequested>((e, emit) => _perform(
        emit,
        _repo.markPaymentCollected(e.booking, e.method, e.reference),
        'Cobro registrado'));
    on<AdminBackfillSettlementsRequested>((e, emit) async {
      final result = await _repo.backfillSettlements();
      result.fold(
        (f) => emit(state.copyWith(error: f.message)),
        (n) => emit(state.copyWith(
            successMessage: n == 0
                ? 'No había viajes pendientes de repartir'
                : '$n viajes repartidos')),
      );
    });
    on<AdminUpdateFinanceSettingsRequested>((e, emit) => _perform(
        emit,
        _repo.updateFinanceSettings(e.fields),
        'Configuración financiera guardada'));
    on<AdminResolveAlertRequested>((e, emit) => _perform(
        emit, _repo.resolveAlert(e.alertId, note: e.note), 'Alerta revisada'));
    on<AdminVerifyDriverRequested>((e, emit) => _perform(
        emit,
        _repo.verifyDriver(e.driverId,
            vehicleReviewed: e.vehicleReviewed, vehicleNote: e.vehicleNote),
        e.vehicleReviewed
            ? 'Chófer verificado y vehículo activado'
            : 'Chófer verificado; el vehículo sigue inactivo'));
    on<AdminToggleUserStatusRequested>((e, emit) => _perform(
        emit,
        _repo.toggleUserStatus(e.userId, e.active),
        e.active ? 'Usuario reactivado' : 'Usuario bloqueado'));
    on<AdminToggleVehicleStatusRequested>((e, emit) => _perform(
        emit,
        _repo.toggleVehicleStatus(e.vehicleId, e.active),
        e.active ? 'Vehículo activado' : 'Vehículo desactivado'));
    on<AdminToggleMaintenanceModeRequested>((e, emit) => _perform(
        emit,
        _repo.toggleMaintenanceMode(e.active),
        e.active ? 'Modo mantenimiento activado' : 'Reservas reanudadas'));
    on<AdminUpdateGlobalSettingsRequested>((e, emit) => _perform(
        emit, _repo.updateGlobalSettings(e.fields), 'Configuración guardada'));
    on<AdminUpdateUserRoleRequested>((e, emit) => _perform(
        emit, _repo.updateUserRole(e.userId, e.role), 'Rol actualizado'));

    on<_AdminStreamUpdated>((e, emit) => emit(e.apply(state)));
    on<_AdminStreamFailed>((e, emit) {
      final msg = e.error.contains('permission-denied')
          ? 'No se pudo cargar ${e.what}: permiso denegado.'
          : 'No se pudo cargar ${e.what}.';
      emit(state.copyWith(isLoading: false, error: msg, loadError: msg));
    });
  }

  Future<void> _perform(Emitter<AdminState> emit,
      Future<Either<Failure, void>> action, String success) async {
    final result = await action;
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: success)),
    );
  }

  void _listen<T>(
      Stream<T> stream, String what, AdminState Function(AdminState, T) apply) {
    _subs.add(stream.listen(
      (data) => add(_AdminStreamUpdated(
          (s) => apply(s, data).copyWith(isLoading: false))),
      onError: (Object e) => add(_AdminStreamFailed(what, e.toString())),
    ));
  }

  Future<void> _onDataRequested(
      AdminDataRequested event, Emitter<AdminState> emit) async {
    emit(state.copyWith(
        isLoading: true,
        bookingsLimit: _repo.bookingsLimit,
        clearLoadError: true));
    await _cancelSubs();

    _listen(_repo.watchAllBookings(), 'las reservas',
        (s, d) => s.copyWith(bookings: d));
    _listen(_repo.watchAllPayments(), 'los pagos',
        (s, d) => s.copyWith(payments: d));
    _listen(
        _repo.watchAllUsers(), 'los usuarios', (s, d) => s.copyWith(users: d));
    _listen(_repo.watchAllDrivers(), 'los chóferes',
        (s, d) => s.copyWith(drivers: d));
    _listen(_repo.watchPricingRules(), 'las tarifas',
        (s, d) => s.copyWith(pricingRules: d));
    _listen(_repo.watchAllVehicles(), 'los vehículos',
        (s, d) => s.copyWith(vehicles: d));
    _listen(_repo.watchAuditLogs(), 'la auditoría',
        (s, d) => s.copyWith(auditLogs: d));
    _listen(_repo.watchAdminAlerts(), 'las alertas',
        (s, d) => s.copyWith(alerts: d));
    _listen(_repo.watchGlobalSettings(), 'la configuración',
        (s, d) => s.copyWith(globalSettings: d));
    _listen(_repo.watchFinanceSettings(), 'la configuración financiera',
        (s, d) => s.copyWith(financeSettings: d));
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
