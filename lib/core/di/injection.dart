import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get_it/get_it.dart';

import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/data/repositories/vehicle_repository_impl.dart';
import '../../features/booking/domain/usecases/booking_usecases.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/booking/presentation/bloc/vehicle_bloc.dart';
import '../../features/driver/presentation/bloc/driver_bloc.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/usecases/payment_usecases.dart';
import '../../features/payments/presentation/bloc/payment_bloc.dart';
import '../../features/profile/data/repositories/user_repository_impl.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/ride/data/repositories/ride_repository_impl.dart';
import '../../features/ride/domain/usecases/ride_usecases.dart';
import '../../features/ride/presentation/bloc/ride_bloc.dart';
import '../data/notification_repository_impl.dart';
import '../repositories/repositories.dart';
import '../services/maps_service.dart';
import '../services/notification_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  _registerFirebase();
  _registerServices();
  _registerRepositories();
  _registerUseCases();
  _registerBlocs();
}

void _registerServices() {
  sl.registerLazySingleton<MapsService>(() => MapsService());
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(userRepository: sl()),
  );
}

void _registerFirebase() {
  sl.registerLazySingleton<fb.FirebaseAuth>(() => fb.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instance,
  );
}

void _registerRepositories() {
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(firestore: sl()),
  );

  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(firestore: sl()),
  );

  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(firestore: sl()),
  );

  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(firestore: sl()),
  );

  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(firestore: sl(), functions: sl()),
  );

  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(firestore: sl()),
  );
}

void _registerUseCases() {
  // Auth
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));

  // Booking
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => WatchBookingUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatusUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetRiderBookingsUseCase(sl()));

  // Ride
  sl.registerLazySingleton(() => StartRideUseCase(sl()));
  sl.registerLazySingleton(() => WatchRideUseCase(sl()));
  sl.registerLazySingleton(() => CompleteRideUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRatingUseCase(sl()));
  sl.registerLazySingleton(() => AppendRoutePointUseCase(sl()));

  // Payment
  sl.registerLazySingleton(() => CreatePaymentIntentUseCase(sl()));
  sl.registerLazySingleton(() => CapturePaymentUseCase(sl()));
  sl.registerLazySingleton(() => RefundPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetRiderPaymentsUseCase(sl()));

  // Profile
  sl.registerLazySingleton(() => GetUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDriverLocationUseCase(sl()));
  sl.registerLazySingleton(() => SetDriverAvailabilityUseCase(sl()));
}

void _registerBlocs() {
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => BookingBloc(bookingRepository: sl()));
  sl.registerFactory(() => VehicleBloc(vehicleRepository: sl()));
  sl.registerFactory(() => RideBloc(rideRepository: sl()));
  sl.registerFactory(() => PaymentBloc(paymentRepository: sl()));
  sl.registerFactory(() => ProfileBloc(userRepository: sl(), bookingRepository: sl()));
  sl.registerFactory(() => AdminBloc(adminRepository: sl()));
  sl.registerFactory(() => NotificationBloc(notificationRepository: sl()));
  sl.registerFactory(() => DriverBloc(
        bookingRepository: sl(),
        userRepository: sl(),
        vehicleRepository: sl(),
        mapsService: sl(),
      ));
}
