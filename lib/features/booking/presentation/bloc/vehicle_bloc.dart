import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
  @override
  List<Object?> get props => [];
}

class VehiclesLoadRequested extends VehicleEvent {
  const VehiclesLoadRequested({required this.vehicleClass});
  final VehicleClass vehicleClass;
  @override
  List<Object?> get props => [vehicleClass];
}

class VehicleClassSelected extends VehicleEvent {
  const VehicleClassSelected({required this.vehicleClass});
  final VehicleClass vehicleClass;
  @override
  List<Object?> get props => [vehicleClass];
}

class VehiclePriceEstimated extends VehicleEvent {
  const VehiclePriceEstimated({
    required this.origin,
    required this.destination,
    required this.vehicleClass,
  });
  final Place origin;
  final Place destination;
  final VehicleClass vehicleClass;
  @override
  List<Object?> get props => [vehicleClass];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class VehicleState extends Equatable {
  const VehicleState();
  @override
  List<Object?> get props => [];
}

class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoading extends VehicleState {
  const VehicleLoading();
}

class VehicleLoaded extends VehicleState {
  const VehicleLoaded(this.vehicles);
  final List<Vehicle> vehicles;
  @override
  List<Object?> get props => [vehicles];
}

class VehicleSelected extends VehicleState {
  const VehicleSelected({required this.vehicleClass, required this.price});
  final VehicleClass vehicleClass;
  final double price;
  @override
  List<Object?> get props => [vehicleClass, price];
}

class VehicleError extends VehicleState {
  const VehicleError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  VehicleBloc({required VehicleRepository vehicleRepository})
      : _repo = vehicleRepository,
        super(const VehicleInitial()) {
    on<VehiclesLoadRequested>(_onLoad);
    on<VehicleClassSelected>(_onSelect);
    on<VehiclePriceEstimated>(_onEstimate);
  }

  final VehicleRepository _repo;

  static const Map<VehicleClass, double> _basePrices = {
    VehicleClass.business:    75,
    VehicleClass.firstClass:  140,
    VehicleClass.businessVan: 90,
    VehicleClass.electric:    60,
  };

  Future<void> _onLoad(
    VehiclesLoadRequested event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading());
    final result = await _repo.getAvailableVehicles(event.vehicleClass);
    result.fold(
      (f) => emit(VehicleError(f.message)),
      (v) => emit(VehicleLoaded(v)),
    );
  }

  void _onSelect(VehicleClassSelected event, Emitter<VehicleState> emit) {
    emit(VehicleSelected(
      vehicleClass: event.vehicleClass,
      price: _basePrices[event.vehicleClass] ?? 0,
    ));
  }

  Future<void> _onEstimate(
    VehiclePriceEstimated event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleSelected(
      vehicleClass: event.vehicleClass,
      price: _basePrices[event.vehicleClass] ?? 0,
    ));
  }
}
