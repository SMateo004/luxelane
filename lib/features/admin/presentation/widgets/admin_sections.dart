import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/admin_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Dashboard  (Overview real con KPIs, gráfico y actividad reciente)
// ─────────────────────────────────────────────────────────────────────────────

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          showLuxSnackbar(context, state.successMessage!);
        }
        if (state.error != null) {
          showLuxSnackbar(context, state.error!, isError: true);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Maintenance banner ───────────────────────────────────────
              if (state.isMaintenanceMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuxSpacing.lg),
                  child: LuxCard(
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: LuxColors.error),
                        const SizedBox(width: LuxSpacing.md),
                        const Expanded(
                          child: Text(
                            'Maintenance Mode ACTIVE — Riders cannot book new trips.',
                            style: TextStyle(color: LuxColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                        LuxOutlinedButton(
                          label: 'Disable',
                          onPressed: () => context
                              .read<AdminBloc>()
                              .add(const AdminToggleMaintenanceModeRequested(false)),
                          width: 100,
                          height: 32,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── KPI row ──────────────────────────────────────────────────
              const SectionHeader(title: 'Overview'),
              const SizedBox(height: LuxSpacing.md),
              Wrap(
                spacing: LuxSpacing.md,
                runSpacing: LuxSpacing.md,
                children: [
                  _KpiTile(
                    label: 'Total Revenue',
                    value: 'Bs${state.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    sub: 'Today: Bs${state.todayRevenue.toStringAsFixed(0)}',
                    color: LuxColors.sapphire,
                  ),
                  _KpiTile(
                    label: 'Completed Rides',
                    value: '${state.completedRidesCount}',
                    icon: Icons.check_circle_outline_rounded,
                    sub: '${state.activeRidesCount} in progress',
                    color: LuxColors.success,
                  ),
                  _KpiTile(
                    label: 'Pending Bookings',
                    value: '${state.pendingRidesCount}',
                    icon: Icons.hourglass_top_rounded,
                    sub: 'Waiting for driver',
                    color: LuxColors.error,
                  ),
                  _KpiTile(
                    label: 'Registered Users',
                    value: '${state.users.length}',
                    icon: Icons.people_outline,
                    sub: '${state.drivers.length} drivers',
                    color: LuxColors.white,
                  ),
                ],
              ),

              // ── Revenue chart ─────────────────────────────────────────────
              const SizedBox(height: LuxSpacing.xl),
              const SectionHeader(title: 'Business Performance'),
              const SizedBox(height: LuxSpacing.md),
              LuxCard(
                padding: const EdgeInsets.all(LuxSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('7-Day Revenue Trend (Bs)', style: LuxTypography.titleLarge),
                    const SizedBox(height: LuxSpacing.xxl),
                    SizedBox(
                      height: 200,
                      child: _RevenueChart(bookings: state.bookings),
                    ),
                  ],
                ),
              ),

              // ── Recent bookings ───────────────────────────────────────────
              const SizedBox(height: LuxSpacing.xl),
              const SectionHeader(title: 'Recent Activity'),
              const SizedBox(height: LuxSpacing.md),
              BookingsTab(compact: true, state: state),
            ],
          ),
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.sub,
    required this.color,
  });
  final String label, value, sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 200,
        child: LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const Spacer(),
                  Text(label,
                      style:
                          LuxTypography.caption.copyWith(color: LuxColors.whiteTertiary)),
                ],
              ),
              const SizedBox(height: LuxSpacing.sm),
              Text(value,
                  style: LuxTypography.headlineLarge.copyWith(
                      color: color, fontFamily: 'Cormorant', fontSize: 36)),
              const SizedBox(height: 2),
              Text(sub, style: LuxTypography.caption),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenue Chart
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final dailyRevenue = <int, double>{};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      dailyRevenue[i] = bookings
          .where((b) =>
              b.status == BookingStatus.completed &&
              b.createdAt.year == day.year &&
              b.createdAt.month == day.month &&
              b.createdAt.day == day.day)
          .fold(0.0, (sum, b) => sum + (b.finalPrice ?? b.estimatedPrice));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: LuxColors.white.withOpacity(0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, _) => Text(
                'Bs${value.toInt()}',
                style: LuxTypography.caption.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final daysInPast = 6 - value.toInt();
                final labelDate = now.subtract(Duration(days: daysInPast));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('E').format(labelDate),
                      style: LuxTypography.caption),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
                7, (i) => FlSpot(i.toDouble(), dailyRevenue[i] ?? 0)),
            isCurved: true,
            color: LuxColors.sapphire,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: LuxColors.sapphire.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Bookings  (Listado real, filtros, precio en Bs, nombre real del rider)
// ─────────────────────────────────────────────────────────────────────────────

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key, this.compact = false, this.state});
  final bool compact;
  final AdminState? state;

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  BookingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, blocState) {
        final state = widget.state ?? blocState;
        var rows = widget.compact
            ? state.bookings.take(5).toList()
            : state.bookings;

        if (_filter != null && !widget.compact) {
          rows = rows.where((b) => b.status == _filter).toList();
        }

        if (state.isLoading && rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rows.isEmpty) {
          return const Center(child: Text('No bookings found'));
        }

        return Column(
          children: [
            // Filter bar (only when not compact)
            if (!widget.compact)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: LuxSpacing.lg, vertical: LuxSpacing.sm),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    ...BookingStatus.values.map((s) => Padding(
                          padding: const EdgeInsets.only(left: LuxSpacing.sm),
                          child: _FilterChip(
                            label: s.label.toUpperCase(),
                            selected: _filter == s,
                            onTap: () => setState(
                                () => _filter = _filter == s ? null : s),
                          ),
                        )),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                shrinkWrap: widget.compact,
                physics: widget.compact
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: widget.compact
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(LuxSpacing.lg),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const LuxDivider(),
                itemBuilder: (_, i) => _AdminBookingTile(
                  booking: rows[i],
                  riderName: state.userName(rows[i].riderId),
                  driverName: rows[i].driverId != null
                      ? state.userName(rows[i].driverId!)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? LuxColors.sapphire : LuxColors.blackElevated,
            borderRadius: BorderRadius.circular(LuxRadius.sm),
            border: Border.all(
                color: selected ? LuxColors.sapphire : LuxColors.blackBorder),
          ),
          child: Text(label,
              style: LuxTypography.caption.copyWith(
                  color: selected ? Colors.black : LuxColors.whiteTertiary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal)),
        ),
      );
}

class _AdminBookingTile extends StatelessWidget {
  const _AdminBookingTile({
    required this.booking,
    required this.riderName,
    this.driverName,
  });
  final Booking booking;
  final String riderName;
  final String? driverName;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            // ID badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: LuxColors.sapphireSubtle,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: Text(
                booking.id.substring(0, 6).toUpperCase(),
                style:
                    LuxTypography.caption.copyWith(color: LuxColors.sapphire),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rider: $riderName', style: LuxTypography.titleMedium),
                  if (driverName != null)
                    Text('Driver: $driverName',
                        style: LuxTypography.caption
                            .copyWith(color: LuxColors.whiteTertiary)),
                  Text(
                    '${booking.origin.address} → ${booking.destination.address}',
                    style: LuxTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(booking.scheduledAt),
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.whiteTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LuxSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Bs${booking.estimatedPrice.toStringAsFixed(0)}',
                    style: LuxTypography.titleMedium
                        .copyWith(color: LuxColors.sapphire)),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(width: LuxSpacing.sm),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: LuxColors.error, size: 18),
              tooltip: 'Delete booking',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.blackElevated,
        title: const Text('Delete booking?', style: LuxTypography.titleLarge),
        content: Text(
          'This will permanently delete booking #${booking.id.substring(0, 8)}. This action cannot be undone.',
          style: LuxTypography.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AdminBloc>()
                  .add(AdminDeleteBookingRequested(booking.id));
            },
            child:
                const Text('Delete', style: TextStyle(color: LuxColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Drivers  (Nombre real, verificar, toggle disponibilidad)
// ─────────────────────────────────────────────────────────────────────────────

class DriversTab extends StatelessWidget {
  const DriversTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.drivers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.drivers.isEmpty) {
          return const Center(child: Text('No drivers found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          itemCount: state.drivers.length,
          separatorBuilder: (_, __) => const LuxDivider(),
          itemBuilder: (_, i) {
            final driver = state.drivers[i];
            final user = state.userById(driver.userId);
            return _DriverTile(driver: driver, user: user);
          },
        );
      });
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, this.user});
  final DriverProfile driver;
  final User? user;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: LuxColors.blackElevated,
              child: Text(
                (user?.displayName.isNotEmpty == true)
                    ? user!.displayName[0].toUpperCase()
                    : '?',
                style:
                    LuxTypography.titleLarge.copyWith(color: LuxColors.sapphire),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? driver.userId.substring(0, 8),
                      style: LuxTypography.titleMedium),
                  Text(user?.email ?? '', style: LuxTypography.caption),
                  Text('License: ${driver.licenseNumber}',
                      style: LuxTypography.caption
                          .copyWith(color: LuxColors.whiteTertiary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: LuxColors.sapphire),
                    const SizedBox(width: 2),
                    Text(driver.rating.toStringAsFixed(1),
                        style: LuxTypography.bodyMedium),
                  ],
                ),
                Text('${driver.totalRides} rides',
                    style: LuxTypography.caption),
              ],
            ),
            const SizedBox(width: LuxSpacing.md),
            if (!driver.documentsVerified)
              LuxOutlinedButton(
                label: 'Verify',
                onPressed: () => context
                    .read<AdminBloc>()
                    .add(AdminVerifyDriverRequested(driver.userId)),
                width: 76,
                height: 32,
              )
            else
              const Tooltip(
                message: 'Documents verified',
                child: Icon(Icons.verified_rounded,
                    color: LuxColors.success, size: 20),
              ),
            const SizedBox(width: LuxSpacing.md),
            Tooltip(
              message: driver.isAvailable ? 'Online' : 'Offline',
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: driver.isAvailable
                      ? LuxColors.success
                      : LuxColors.whiteTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Vehicles
// ─────────────────────────────────────────────────────────────────────────────

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.vehicles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 48, color: LuxColors.whiteTertiary),
                SizedBox(height: LuxSpacing.md),
                Text('No vehicles registered yet',
                    style: LuxTypography.titleMedium),
                SizedBox(height: LuxSpacing.sm),
                Text('Vehicles linked to drivers appear here',
                    style: LuxTypography.caption),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          itemCount: state.vehicles.length,
          separatorBuilder: (_, __) => const LuxDivider(),
          itemBuilder: (_, i) => _VehicleTile(vehicle: state.vehicles[i]),
        );
      });
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LuxColors.blackElevated,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: const Icon(Icons.directions_car_filled_rounded,
                  color: LuxColors.sapphire, size: 24),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vehicle.make} ${vehicle.model} (${vehicle.year})',
                      style: LuxTypography.titleMedium),
                  Text(
                    'Plate: ${vehicle.plate} · Class: ${vehicle.vehicleClass.name.toUpperCase()}',
                    style: LuxTypography.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: vehicle.isActive
                    ? LuxColors.success.withOpacity(0.1)
                    : LuxColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: Text(
                vehicle.isActive ? 'ACTIVE' : 'INACTIVE',
                style: LuxTypography.caption.copyWith(
                    color: vehicle.isActive
                        ? LuxColors.success
                        : LuxColors.error),
              ),
            ),
            const SizedBox(width: LuxSpacing.sm),
            Switch.adaptive(
              value: vehicle.isActive,
              activeColor: LuxColors.sapphire,
              onChanged: (val) => context
                  .read<AdminBloc>()
                  .add(AdminToggleVehicleStatusRequested(vehicle.id, val)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Users  (nombre real, toggle activo, cambio de rol)
// ─────────────────────────────────────────────────────────────────────────────

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final filtered = state.users
            .where((u) =>
                _search.isEmpty ||
                u.displayName
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ||
                u.email.toLowerCase().contains(_search.toLowerCase()))
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.lg, LuxSpacing.md, LuxSpacing.lg, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: LuxTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search users…',
                  hintStyle: LuxTypography.caption,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: LuxColors.whiteTertiary, size: 20),
                  filled: true,
                  fillColor: LuxColors.blackElevated,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                    borderSide:
                        const BorderSide(color: LuxColors.blackBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                    borderSide:
                        const BorderSide(color: LuxColors.blackBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                    borderSide: const BorderSide(color: LuxColors.sapphire),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No users match the search'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const LuxDivider(),
                      itemBuilder: (_, i) =>
                          _UserTile(user: filtered[i]),
                    ),
            ),
          ],
        );
      });
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: LuxColors.blackElevated,
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0] : '?',
                style:
                    LuxTypography.bodyLarge.copyWith(color: LuxColors.sapphire),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: LuxTypography.titleMedium),
                  Text(user.email, style: LuxTypography.caption),
                  Text(
                    'Member since ${DateFormat('MMM yyyy').format(user.createdAt)}',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.whiteTertiary),
                  ),
                ],
              ),
            ),
            // Role badge + change role
            GestureDetector(
              onTap: () => _showRoleDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: LuxSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: user.role == UserRole.admin
                      ? LuxColors.sapphire.withOpacity(0.15)
                      : user.role == UserRole.driver
                          ? LuxColors.success.withOpacity(0.1)
                          : LuxColors.blackElevated,
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                  border: Border.all(
                    color: user.role == UserRole.admin
                        ? LuxColors.sapphire.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.role.name.toUpperCase(),
                      style: LuxTypography.caption.copyWith(
                        color: user.role == UserRole.admin
                            ? LuxColors.sapphire
                            : user.role == UserRole.driver
                                ? LuxColors.success
                                : LuxColors.whiteTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded,
                        size: 14, color: LuxColors.whiteTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Switch.adaptive(
              value: user.isActive,
              activeColor: LuxColors.sapphire,
              onChanged: (val) => context
                  .read<AdminBloc>()
                  .add(AdminToggleUserStatusRequested(user.id, val)),
            ),
          ],
        ),
      );

  void _showRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.blackElevated,
        title: Text('Change role for ${user.displayName}',
            style: LuxTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values
              .map((role) => RadioListTile<UserRole>(
                    value: role,
                    groupValue: user.role,
                    title: Text(role.name.toUpperCase(),
                        style: LuxTypography.bodyMedium),
                    activeColor: LuxColors.sapphire,
                    onChanged: (r) {
                      if (r != null) {
                        context
                            .read<AdminBloc>()
                            .add(AdminUpdateUserRoleRequested(user.id, r));
                        Navigator.pop(ctx);
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Pricing  (Edición real con formulario completo en Bs)
// ─────────────────────────────────────────────────────────────────────────────

class PricingTab extends StatelessWidget {
  const PricingTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Pricing Rules (Bs)'),
              const SizedBox(height: LuxSpacing.sm),
              const Text(
                'Prices reflect the DefaultPricing model. If pricingRules collection is empty, prices are calculated locally.',
                style: LuxTypography.caption,
              ),
              const SizedBox(height: LuxSpacing.lg),
              // Always show the local DefaultPricing values as editable cards
              ...VehicleClass.values.expand((vc) =>
                  ServiceType.values.map((st) {
                    final r = DefaultPricing.rules[vc]?[st];
                    if (r == null) return const SizedBox.shrink();
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child: _PricingCard(
                        vehicleClass: vc,
                        serviceType: st,
                        rules: r,
                      ),
                    );
                  })),
              if (state.pricingRules.isNotEmpty) ...[
                const SizedBox(height: LuxSpacing.xl),
                const SectionHeader(title: 'Firestore Pricing Rules'),
                const SizedBox(height: LuxSpacing.md),
                ...state.pricingRules.map((rule) =>
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child: LuxCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      rule.vehicleClass.name
                                          .toUpperCase(),
                                      style:
                                          LuxTypography.titleMedium),
                                  Text(rule.serviceType.name,
                                      style: LuxTypography.caption),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  rule.serviceType ==
                                          ServiceType.byTheHour
                                      ? 'Bs${rule.pricePerHourUsd}/h'
                                      : 'Bs${rule.basePriceUsd} base + Bs${rule.pricePerKmUsd}/km',
                                  style: LuxTypography.bodyMedium,
                                ),
                                Text('Min: Bs${rule.minimumPriceUsd}',
                                    style: LuxTypography.caption
                                        .copyWith(
                                            color: LuxColors.sapphire)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        );
      });
}

class _PricingCard extends StatefulWidget {
  const _PricingCard({
    required this.vehicleClass,
    required this.serviceType,
    required this.rules,
  });
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final Map<String, double> rules;

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _expanded = false;
  late TextEditingController _baseCtrl;
  late TextEditingController _perKmCtrl;
  late TextEditingController _perHourCtrl;
  late TextEditingController _minCtrl;

  @override
  void initState() {
    super.initState();
    _baseCtrl = TextEditingController(
        text: (widget.rules['base'] ?? 0).toStringAsFixed(0));
    _perKmCtrl = TextEditingController(
        text: (widget.rules['perKm'] ?? 0).toStringAsFixed(1));
    _perHourCtrl = TextEditingController(
        text: (widget.rules['perHour'] ?? 0).toStringAsFixed(0));
    _minCtrl = TextEditingController(
        text: (widget.rules['min'] ?? 0).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _perKmCtrl.dispose();
    _perHourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHourly = widget.serviceType == ServiceType.byTheHour;
    return LuxCard(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: LuxColors.sapphireSubtle,
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                  ),
                  child: Text(
                    widget.vehicleClass.name.toUpperCase(),
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.sapphire),
                  ),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Text(
                  isHourly ? 'By the Hour' : 'One Way',
                  style: LuxTypography.titleMedium,
                ),
                const Spacer(),
                Text(
                  isHourly
                      ? 'Bs${_perHourCtrl.text}/h'
                      : 'Bs${_baseCtrl.text} + Bs${_perKmCtrl.text}/km',
                  style: LuxTypography.bodyMedium
                      .copyWith(color: LuxColors.whiteTertiary),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: LuxColors.whiteTertiary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: LuxSpacing.md),
            const LuxDivider(),
            const SizedBox(height: LuxSpacing.md),
            Row(
              children: [
                if (!isHourly) ...[
                  Expanded(
                    child: _PriceField(
                        label: 'Base (Bs)', controller: _baseCtrl),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: _PriceField(
                        label: 'Per km (Bs)',
                        controller: _perKmCtrl),
                  ),
                ] else
                  Expanded(
                    child: _PriceField(
                        label: 'Per Hour (Bs)',
                        controller: _perHourCtrl),
                  ),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: _PriceField(
                      label: 'Minimum (Bs)', controller: _minCtrl),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                LuxButton(
                  label: 'Save Changes',
                  icon: Icons.save_outlined,
                  height: 38,
                  onPressed: () {
                    final rule = PricingRule(
                      id:
                          '${widget.vehicleClass.name}_${widget.serviceType.name}',
                      vehicleClass: widget.vehicleClass,
                      serviceType: widget.serviceType,
                      basePriceUsd:
                          double.tryParse(_baseCtrl.text) ?? 0,
                      pricePerKmUsd:
                          double.tryParse(_perKmCtrl.text) ?? 0,
                      pricePerHourUsd:
                          double.tryParse(_perHourCtrl.text) ?? 0,
                      minimumPriceUsd:
                          double.tryParse(_minCtrl.text) ?? 0,
                    );
                    context
                        .read<AdminBloc>()
                        .add(AdminUpdatePricingRequested(rule));
                    setState(() => _expanded = false);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LuxTypography.caption),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: LuxTypography.bodyMedium,
            decoration: InputDecoration(
              prefixText: 'Bs ',
              prefixStyle: LuxTypography.caption
                  .copyWith(color: LuxColors.sapphire),
              filled: true,
              fillColor: LuxColors.blackElevated,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                borderSide:
                    const BorderSide(color: LuxColors.blackBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                borderSide:
                    const BorderSide(color: LuxColors.blackBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                borderSide: const BorderSide(color: LuxColors.sapphire),
              ),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Audit   (log real de acciones administrativas)
// ─────────────────────────────────────────────────────────────────────────────

class AuditTab extends StatelessWidget {
  const AuditTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.auditLogs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.auditLogs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    size: 48, color: LuxColors.whiteTertiary),
                SizedBox(height: LuxSpacing.md),
                Text('No audit logs yet', style: LuxTypography.titleMedium),
                SizedBox(height: LuxSpacing.sm),
                Text('Admin actions will appear here in real time',
                    style: LuxTypography.caption),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          itemCount: state.auditLogs.length,
          separatorBuilder: (_, __) => const LuxDivider(),
          itemBuilder: (_, i) => _AuditTile(log: state.auditLogs[i]),
        );
      });
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.log});
  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM HH:mm').format(log.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(LuxSpacing.xs),
            decoration: BoxDecoration(
              color: LuxColors.blackElevated,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
            ),
            child: Icon(_getIcon(log.action),
                color: _getColor(log.action), size: 16),
          ),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: LuxTypography.bodyMedium,
                    children: [
                      TextSpan(
                        text: log.action
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _getColor(log.action)),
                      ),
                      const TextSpan(text: ' · '),
                      TextSpan(
                          text: log.targetType,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      TextSpan(
                          text:
                              ' (${log.targetId.length > 8 ? log.targetId.substring(0, 8) : log.targetId})',
                          style: LuxTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.details.isNotEmpty
                      ? log.details
                      : 'Admin: ${log.adminId}',
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ),
          Text(date, style: LuxTypography.caption),
        ],
      ),
    );
  }

  IconData _getIcon(String action) {
    if (action.contains('block')) return Icons.block_flipped;
    if (action.contains('unblock')) return Icons.check_circle_outline;
    if (action.contains('verify')) return Icons.verified_user_rounded;
    if (action.contains('vehicle')) return Icons.directions_car_rounded;
    if (action.contains('maintenance')) return Icons.construction_rounded;
    if (action.contains('delete')) return Icons.delete_outline_rounded;
    if (action.contains('role')) return Icons.manage_accounts_rounded;
    if (action.contains('settings')) return Icons.settings_outlined;
    return Icons.settings_suggest_rounded;
  }

  Color _getColor(String action) {
    if (action.contains('block') || action.contains('delete') ||
        action.contains('maintenance') && action.contains('enable')) {
      return LuxColors.error;
    }
    if (action.contains('verify') || action.contains('unblock')) {
      return LuxColors.success;
    }
    return LuxColors.sapphire;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Settings  (todas las opciones funcionales, guardadas en Firestore)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Global App Settings'),
              const SizedBox(height: LuxSpacing.lg),
              LuxCard(
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.construction_rounded,
                      title: 'Maintenance Mode',
                      subtitle:
                          'Disable all bookings and show maintenance screen to users.',
                      value: state.isMaintenanceMode,
                      onChanged: (val) => context
                          .read<AdminBloc>()
                          .add(AdminToggleMaintenanceModeRequested(val)),
                    ),
                    const LuxDivider(),
                    _SettingTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Push Notifications',
                      subtitle:
                          'Enable system-wide notifications for new bookings.',
                      value: state.pushNotificationsEnabled,
                      onChanged: (val) => context.read<AdminBloc>().add(
                            AdminUpdateGlobalSettingsRequested(
                                {'pushNotificationsEnabled': val}),
                          ),
                    ),
                    const LuxDivider(),
                    _SettingTile(
                      icon: Icons.security_rounded,
                      title: 'Two-Factor Admin Auth',
                      subtitle:
                          'Require 2FA for all administrative actions.',
                      value: state.twoFactorEnabled,
                      onChanged: (val) => context.read<AdminBloc>().add(
                            AdminUpdateGlobalSettingsRequested(
                                {'twoFactorEnabled': val}),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LuxSpacing.xl),
              const SectionHeader(title: 'Live Statistics'),
              const SizedBox(height: LuxSpacing.md),
              LuxCard(
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Total Bookings',
                        value: '${state.bookings.length}'),
                    const LuxDivider(),
                    _InfoRow(
                        label: 'Registered Users',
                        value: '${state.users.length}'),
                    const LuxDivider(),
                    _InfoRow(
                        label: 'Registered Drivers',
                        value: '${state.drivers.length}'),
                    const LuxDivider(),
                    _InfoRow(
                        label: 'Verified Drivers',
                        value:
                            '${state.drivers.where((d) => d.documentsVerified).length}'),
                    const LuxDivider(),
                    _InfoRow(
                        label: 'Vehicles Registered',
                        value: '${state.vehicles.length}'),
                    const LuxDivider(),
                    _InfoRow(
                        label: 'Total Revenue',
                        value:
                            'Bs${state.totalRevenue.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: LuxSpacing.xl),
              const SectionHeader(title: 'System Information'),
              const SizedBox(height: LuxSpacing.md),
              const LuxCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'App Version', value: '1.0.4+22'),
                    LuxDivider(),
                    _InfoRow(
                        label: 'Currency',
                        value: 'Bolivianos (Bs)'),
                    LuxDivider(),
                    _InfoRow(
                        label: 'Backend', value: 'Firebase / Firestore'),
                    LuxDivider(),
                    _InfoRow(
                        label: 'Platform', value: 'Flutter Web + Mobile'),
                  ],
                ),
              ),
            ],
          ),
        );
      });
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: LuxColors.sapphire, size: 24),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LuxTypography.titleMedium),
                  Text(subtitle, style: LuxTypography.caption),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeColor: LuxColors.sapphire,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: LuxTypography.bodyMedium
                    .copyWith(color: LuxColors.whiteTertiary)),
            Text(value,
                style: LuxTypography.bodyMedium.copyWith(
                    color: LuxColors.sapphire, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
