import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationWatchStarted extends NotificationEvent {
  const NotificationWatchStarted({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class NotificationCreated extends NotificationEvent {
  const NotificationCreated({required this.notification});
  final AppNotification notification;
  @override
  List<Object?> get props => [notification.id];
}

class NotificationMarkedRead extends NotificationEvent {
  const NotificationMarkedRead({
    required this.userId,
    required this.notificationId,
  });
  final String userId;
  final String notificationId;
  @override
  List<Object?> get props => [notificationId];
}

class NotificationAllMarkedRead extends NotificationEvent {
  const NotificationAllMarkedRead({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });
  final List<AppNotification> notifications;
  final int unreadCount;
  @override
  List<Object?> get props => [notifications, unreadCount];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required NotificationRepository notificationRepository})
      : _repo = notificationRepository,
        super(const NotificationInitial()) {
    on<NotificationWatchStarted>(_onWatch);
    on<NotificationCreated>(_onCreate);
    on<NotificationMarkedRead>(_onMarkRead);
    on<NotificationAllMarkedRead>(_onMarkAllRead);
  }

  final NotificationRepository _repo;

  Future<void> _onWatch(
    NotificationWatchStarted event,
    Emitter<NotificationState> emit,
  ) async {
    await emit.forEach<List<AppNotification>>(
      _repo.watchNotifications(event.userId),
      onData: (notifications) => NotificationLoaded(
        notifications: notifications,
        unreadCount: notifications.where((n) => !n.isRead).length,
      ),
      onError: (_, __) => const NotificationLoaded(
        notifications: [],
        unreadCount: 0,
      ),
    );
  }

  Future<void> _onCreate(
    NotificationCreated event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.createNotification(event.notification);
  }

  Future<void> _onMarkRead(
    NotificationMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.markAsRead(event.userId, event.notificationId);
  }

  Future<void> _onMarkAllRead(
    NotificationAllMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.markAllRead(event.userId);
  }
}
