import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/notification_bloc.dart';

// ---------------------------------------------------------------------------
// NotificationBell — drop-in icon button with unread badge
// ---------------------------------------------------------------------------

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final unread = state is NotificationLoaded ? state.unreadCount : 0;
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: color ?? LuxColors.white,
                size: 22,
              ),
              if (unread > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: LuxColors.sapphire,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _showNotificationSheet(context),
          tooltip: 'Notifications',
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    // Mark all as read when opening
    if (userId != null) {
      context.read<NotificationBloc>().add(
            NotificationAllMarkedRead(userId: userId),
          );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuxColors.blackSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationBloc>(),
        child: const _NotificationSheet(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Sheet
// ---------------------------------------------------------------------------

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: LuxSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LuxColors.blackBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LuxSpacing.lg,
                LuxSpacing.md,
                LuxSpacing.lg,
                LuxSpacing.sm,
              ),
              child: Row(
                children: [
                  const Text('Notifications',
                      style: LuxTypography.titleLarge),
                  const Spacer(),
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      final hasUnread = state is NotificationLoaded &&
                          state.unreadCount > 0;
                      if (!hasUnread) return const SizedBox.shrink();
                      final authState = context.read<AuthBloc>().state;
                      final userId = authState is AuthAuthenticated
                          ? authState.user.id
                          : null;
                      return TextButton(
                        onPressed: userId != null
                            ? () => context.read<NotificationBloc>().add(
                                  NotificationAllMarkedRead(userId: userId),
                                )
                            : null,
                        child: Text(
                          'Mark all read',
                          style: LuxTypography.caption
                              .copyWith(color: LuxColors.sapphire),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: LuxColors.blackBorder, height: 1),
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationInitial) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final notifications = state is NotificationLoaded
                      ? state.notifications
                      : <AppNotification>[];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              color: LuxColors.whiteTertiary, size: 48),
                          const SizedBox(height: LuxSpacing.md),
                          const Text('No notifications yet',
                              style: LuxTypography.bodyMedium),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: LuxSpacing.sm),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: LuxColors.blackBorder,
                      height: 1,
                      indent: LuxSpacing.lg,
                    ),
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return _NotificationTile(notification: n);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Tile
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  IconData get _icon {
    switch (notification.type) {
      case 'booking_confirmed':
        return Icons.check_circle_outline_rounded;
      case 'driver_arriving':
        return Icons.directions_car_outlined;
      case 'driver_arrived':
        return Icons.location_on_outlined;
      case 'ride_started':
        return Icons.play_circle_outline_rounded;
      case 'ride_completed':
        return Icons.flag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead
          ? Colors.transparent
          : LuxColors.sapphire.withAlpha(13),
      padding: const EdgeInsets.symmetric(
        horizontal: LuxSpacing.lg,
        vertical: LuxSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LuxColors.sapphire.withAlpha(26),
              borderRadius: BorderRadius.circular(LuxRadius.sm),
            ),
            child: Icon(_icon, color: LuxColors.sapphire, size: 18),
          ),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: LuxTypography.bodyMedium.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: LuxSpacing.sm),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: LuxTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: LuxTypography.caption
                      .copyWith(color: LuxColors.whiteTertiary),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Padding(
              padding: const EdgeInsets.only(left: LuxSpacing.sm, top: 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: LuxColors.sapphire,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
