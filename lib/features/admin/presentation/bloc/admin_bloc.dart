import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
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

class AdminVerifyDriverRequested extends AdminEvent {
  final String driverId;
  const AdminVerifyDriverRequested(this.driverId);
  @override
  List<Object?> get props => [driverId];
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

class AdminDeleteBookingRequested extends AdminEvent {
  final String bookingId;
  const AdminDeleteBookingRequested(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
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
    this.users = const [],
    this.drivers = const [],
    this.pricingRules = const [],
    this.vehicles = const [],
    this.auditLogs = const [],
    this.globalSettings = const {},
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final List<Booking> bookings;
  final List<User> users;
  final List<DriverProfile> drivers;
  final List<PricingRule> pricingRules;
  final List<Vehicle> vehicles;
  final List<AuditLog> auditLogs;
  final Map<String, dynamic> globalSettings;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  bool get isMaintenanceMode => globalSettings['isMaintenanceMode'] ?? false;
  bool get pushNotificationsEnabled => globalSettings['pushNotificationsEnabled'] ?? true;
  bool get twoFactorEnabled => globalSettings['twoFactorEnabled'] ?? false;

  /// Cross-reference: get a user's display name by their ID
  String userName(String userId) {
    try {
      return users.firstWhere((u) => u.id == userId).displayName;
    } catch (_) {
      return userId.length > 8 ? userId.substring(0, 8) : userId;
    }
  }

  /// Cross-reference: get a user by their ID
  User? userById(String userId) {
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  // Revenue computed properties
  double get totalRevenue => bookings
      .where((b) => b.status == BookingStatus.completed)
      .fold(0.0, (sum, b) => sum + (b.finalPrice ?? b.estimatedPrice));

  int get activeRidesCount => bookings
      .where((b) => b.status == BookingStatus.inProgress)
      .length;

  int get pendingRidesCount => bookings
      .where((b) => b.status == BookingStatus.pending)
      .length;

  int get completedRidesCount => bookings
      .where((b) => b.status == BookingStatus.completed)
      .length;

  double get todayRevenue {
    final today = DateTime.now();
    return bookings
        .where((b) =>
            b.status == BookingStatus.completed &&
            b.createdAt.year == today.year &&
            b.createdAt.month == today.month &&
            b.createdAt.day == today.day)
        .fold(0.0, (sum, b) => sum + (b.finalPrice ?? b.estimatedPrice));
  }

  AdminState copyWith({
    List<Booking>? bookings,
    List<User>? users,
    List<DriverProfile>? drivers,
    List<PricingRule>? pricingRules,
    List<Vehicle>? vehicles,
    List<AuditLog>? auditLogs,
    Map<String, dynamic>? globalSettings,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AdminState(
      bookings: bookings ?? this.bookings,
      users: users ?? this.users,
      drivers: drivers ?? this.drivers,
      pricingRules: pricingRules ?? this.pricingRules,
      vehicles: vehicles ?? this.vehicles,
      auditLogs: auditLogs ?? this.auditLogs,
      globalSettings: globalSettings ?? this.globalSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        bookings, users, drivers, pricingRules, vehicles,
        auditLogs, globalSettings, isLoading, error, successMessage,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _driversSub;
  StreamSubscription? _pricingSub;
  StreamSubscription? _vehiclesSub;
  StreamSubscription? _auditSub;
  StreamSubscription? _settingsSub;

  AdminBloc({required AdminRepository adminRepository})
      : _repo = adminRepository,
        super(const AdminState()) {
    on<AdminDataRequested>(_onDataRequested);
    on<AdminUpdatePricingRequested>(_onUpdatePricing);
    on<AdminVerifyDriverRequested>(_onVerifyDriver);
    on<AdminToggleUserStatusRequested>(_onToggleUserStatus);
    on<AdminToggleVehicleStatusRequested>(_onToggleVehicleStatus);
    on<AdminToggleMaintenanceModeRequested>(_onToggleMaintenance);
    on<AdminUpdateGlobalSettingsRequested>(_onUpdateGlobalSettings);
    on<AdminDeleteBookingRequested>(_onDeleteBooking);
    on<AdminUpdateUserRoleRequested>(_onUpdateUserRole);

    // Internal stream updates
    on<_InternalBookingsUpdated>((e, emit) => emit(state.copyWith(bookings: e.data, isLoading: false)));
    on<_InternalUsersUpdated>((e, emit) => emit(state.copyWith(users: e.data, isLoading: false)));
    on<_InternalDriversUpdated>((e, emit) => emit(state.copyWith(drivers: e.data, isLoading: false)));
    on<_InternalPricingUpdated>((e, emit) => emit(state.copyWith(pricingRules: e.data, isLoading: false)));
    on<_InternalVehiclesUpdated>((e, emit) => emit(state.copyWith(vehicles: e.data, isLoading: false)));
    on<_InternalAuditLogsUpdated>((e, emit) => emit(state.copyWith(auditLogs: e.data, isLoading: false)));
    on<_InternalSettingsUpdated>((e, emit) => emit(state.copyWith(globalSettings: e.data, isLoading: false)));
  }

  Future<void> _onDataRequested(AdminDataRequested event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _bookingsSub?.cancel();
    await _usersSub?.cancel();
    await _driversSub?.cancel();
    await _pricingSub?.cancel();
    await _vehiclesSub?.cancel();
    await _auditSub?.cancel();
    await _settingsSub?.cancel();

    _bookingsSub = _repo.watchAllBookings().listen((data) => add(_InternalBookingsUpdated(data)));
    _usersSub    = _repo.watchAllUsers().listen((data) => add(_InternalUsersUpdated(data)));
    _driversSub  = _repo.watchAllDrivers().listen((data) => add(_InternalDriversUpdated(data)));
    _pricingSub  = _repo.watchPricingRules().listen((data) => add(_InternalPricingUpdated(data)));
    _vehiclesSub = _repo.watchAllVehicles().listen((data) => add(_InternalVehiclesUpdated(data)));
    _auditSub    = _repo.watchAuditLogs().listen((data) => add(_InternalAuditLogsUpdated(data)));
    _settingsSub = _repo.watchGlobalSettings().listen((data) => add(_InternalSettingsUpdated(data)));
  }

  Future<void> _onToggleMaintenance(AdminToggleMaintenanceModeRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.toggleMaintenanceMode(event.active);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: event.active ? 'Maintenance ON' : 'Maintenance OFF')),
    );
  }

  Future<void> _onToggleVehicleStatus(AdminToggleVehicleStatusRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.toggleVehicleStatus(event.vehicleId, event.active);
    result.fold((f) => emit(state.copyWith(error: f.message)), (_) => null);
  }

  Future<void> _onUpdatePricing(AdminUpdatePricingRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.updatePricingRule(event.rule);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: 'Pricing rule updated')),
    );
  }

  Future<void> _onVerifyDriver(AdminVerifyDriverRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.verifyDriver(event.driverId);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: 'Driver verified successfully')),
    );
  }

  Future<void> _onToggleUserStatus(AdminToggleUserStatusRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.toggleUserStatus(event.userId, event.active);
    result.fold((f) => emit(state.copyWith(error: f.message)), (_) => null);
  }

  Future<void> _onUpdateGlobalSettings(AdminUpdateGlobalSettingsRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.updateGlobalSettings(event.fields);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: 'Settings saved')),
    );
  }

  Future<void> _onDeleteBooking(AdminDeleteBookingRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.deleteBooking(event.bookingId);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: 'Booking deleted')),
    );
  }

  Future<void> _onUpdateUserRole(AdminUpdateUserRoleRequested event, Emitter<AdminState> emit) async {
    final result = await _repo.updateUserRole(event.userId, event.role);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(successMessage: 'User role updated')),
    );
  }

  @override
  Future<void> close() {
    _bookingsSub?.cancel();
    _usersSub?.cancel();
    _driversSub?.cancel();
    _pricingSub?.cancel();
    _vehiclesSub?.cancel();
    _auditSub?.cancel();
    _settingsSub?.cancel();
    return super.close();
  }
}

// Internal stream events
class _InternalBookingsUpdated extends AdminEvent {
  final List<Booking> data;
  const _InternalBookingsUpdated(this.data);
  @override List<Object?> get props => [data];
}
class _InternalUsersUpdated extends AdminEvent {
  final List<User> data;
  const _InternalUsersUpdated(this.data);
  @override List<Object?> get props => [data];
}
class _InternalDriversUpdated extends AdminEvent {
  final List<DriverProfile> data;
  const _InternalDriversUpdated(this.data);
  @override List<Object?> get props => [data];
}
class _InternalPricingUpdated extends AdminEvent {
  final List<PricingRule> data;
  const _InternalPricingUpdated(this.data);
  @override List<Object?> get props => [data];
}
class _InternalVehiclesUpdated extends AdminEvent {
  final List<Vehicle> data;
  const _InternalVehiclesUpdated(this.data);
  @override List<Object?> get props => [data];
}
class _InternalAuditLogsUpdated extends AdminEvent {
  final List<AuditLog> data;
  const _InternalAuditLogsUpdated(this.data);
  @override List<Object?> get props => [data];
}
class _InternalSettingsUpdated extends AdminEvent {
  final Map<String, dynamic> data;
  const _InternalSettingsUpdated(this.data);
  @override List<Object?> get props => [data];
}
