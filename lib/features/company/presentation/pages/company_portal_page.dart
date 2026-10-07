import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/company_repository.dart';
import '../../domain/company.dart';
import '../../domain/company_statement.dart';
import '../company_l10n.dart';

/// Portal for a company's admins: monthly statement, members and settings.
///
/// Luxelane admins open it from the admin panel with [companyId]; company
/// admins reach it from their profile and get their own company.
class CompanyPortalPage extends StatelessWidget {
  const CompanyPortalPage({super.key, this.companyId, this.repository, this.now});

  final String? companyId;
  final CompanyRepository? repository;

  /// Injected clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<CompanyRepository>();
    final l = context.l10n;
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    final platformAdmin = user?.role == UserRole.admin;

    Widget denied() => Scaffold(
          backgroundColor: LuxColors.black,
          appBar: AppBar(title: Text(l.corpPortalTitle)),
          body: EmptyState(icon: Icons.lock_outline, message: l.corpNoAccess),
        );

    if (user == null) return denied();
    if (companyId != null && platformAdmin) {
      return _Portal(repo: repo, companyId: companyId!, platformAdmin: true, now: now);
    }
    return StreamBuilder<CompanyMembership?>(
      stream: repo.watchMembership(user.id),
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: LuxColors.black,
            body: Center(child: CircularProgressIndicator(color: LuxColors.accent)),
          );
        }
        final m = snap.data;
        if (m == null || !m.isAdmin) return denied();
        return _Portal(repo: repo, companyId: m.companyId, platformAdmin: false, now: now);
      },
    );
  }
}

class _Portal extends StatelessWidget {
  const _Portal({required this.repo, required this.companyId, required this.platformAdmin, this.now});
  final CompanyRepository repo;
  final String companyId;
  final bool platformAdmin;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<Company?>(
      stream: repo.watchCompany(companyId),
      builder: (context, snap) {
        final company = snap.data;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: LuxColors.black,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: l.commonBack,
                onPressed: () => Navigator.of(context).canPop()
                    ? Navigator.of(context).pop()
                    : context.go('/profile'),
              ),
              title: Text(company?.name ?? l.corpPortalTitle, overflow: TextOverflow.ellipsis),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: LuxColors.accent,
                labelColor: LuxColors.white,
                unselectedLabelColor: LuxColors.whiteTertiary,
                tabs: [
                  Tab(text: l.corpTabStatement),
                  Tab(text: l.corpTabMembers),
                  Tab(text: l.corpTabSettings),
                ],
              ),
            ),
            body: company == null
                ? const Center(child: CircularProgressIndicator(color: LuxColors.accent))
                : Column(
                    children: [
                      if (!company.active)
                        Container(
                          width: double.infinity,
                          color: LuxColors.warning.withOpacity(0.15),
                          padding: const EdgeInsets.all(LuxSpacing.md),
                          child: Row(children: [
                            const Icon(Icons.pause_circle_outline, color: LuxColors.warning, size: 18),
                            const SizedBox(width: LuxSpacing.sm),
                            Expanded(
                              child: Text(l.corpSuspendedBanner,
                                  style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
                            ),
                          ]),
                        ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 960),
                            child: TabBarView(children: [
                              StatementTab(repo: repo, company: company, now: now),
                              MembersTab(repo: repo, company: company),
                              CompanySettingsTab(repo: repo, company: company),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ── Statement ───────────────────────────────────────────────────────────────

class StatementTab extends StatefulWidget {
  const StatementTab({super.key, required this.repo, required this.company, this.now});
  final CompanyRepository repo;
  final Company company;
  final DateTime? now;

  @override
  State<StatementTab> createState() => _StatementTabState();
}

class _StatementTabState extends State<StatementTab> {
  late DateTime _month = CompanyStatement.monthStart(widget.now ?? DateTime.now());
  late Stream<List<Booking>> _bookings = _watch();
  late final Stream<List<CompanyMember>> _members = widget.repo.watchMembers(widget.company.id);

  Stream<List<Booking>> _watch() =>
      widget.repo.watchBookings(widget.company.id, _month, CompanyStatement.nextMonth(_month));

  void _shift(int months) => setState(() {
        _month = DateTime(_month.year, _month.month + months);
        _bookings = _watch();
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = CompanyStatement.monthStart(widget.now ?? DateTime.now());
    return StreamBuilder<List<CompanyMember>>(
      stream: _members,
      builder: (context, mSnap) {
        final names = {for (final m in mSnap.data ?? const <CompanyMember>[]) m.uid: m.displayName};
        return StreamBuilder<List<Booking>>(
          stream: _bookings,
          builder: (context, snap) {
            final st = CompanyStatement.compute(snap.data ?? const [], _month);
            String traveler(String uid) => (names[uid]?.isNotEmpty ?? false) ? names[uid]! : l.corpFormerMember;
            return ListView(
              padding: const EdgeInsets.all(LuxSpacing.lg),
              children: [
                Row(children: [
                  IconButton(
                    tooltip: l.corpPrevMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM().format(_month),
                      textAlign: TextAlign.center,
                      style: LuxTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l.corpNextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _month.isBefore(current) ? () => _shift(1) : null,
                  ),
                ]),
                const SizedBox(height: LuxSpacing.md),
                _Kpis(children: [
                  _Kpi(l.corpKpiToInvoice, LuxMoney.format(st.total), l.corpKpiToInvoiceHint),
                  _Kpi(l.corpKpiCompleted, NumberFormat.decimalPattern().format(st.completed), null),
                  _Kpi(l.corpKpiUpcoming, NumberFormat.decimalPattern().format(st.upcoming), null),
                  _Kpi(l.corpKpiLateCancellations, NumberFormat.decimalPattern().format(st.lateCancellations),
                      l.corpKpiCancelled(st.cancelled)),
                ]),
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const Padding(
                    padding: EdgeInsets.all(LuxSpacing.xl),
                    child: Center(child: CircularProgressIndicator(color: LuxColors.accent)),
                  )
                else if (st.bookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: LuxSpacing.xl),
                    child: EmptyState(icon: Icons.receipt_long_outlined, message: l.corpNoRidesMonth),
                  )
                else ...[
                  if (st.completed > 0) ...[
                    const SizedBox(height: LuxSpacing.xl),
                    _GroupCard(
                      title: l.corpByCostCenter,
                      rows: [
                        for (final g in st.byCostCenter)
                          (label: g.key ?? l.corpNoCostCenter, trips: g.trips, amount: g.amount),
                      ],
                    ),
                    const SizedBox(height: LuxSpacing.md),
                    _GroupCard(
                      title: l.corpByTraveler,
                      rows: [
                        for (final g in st.byTraveler)
                          (label: traveler(g.key!), trips: g.trips, amount: g.amount),
                      ],
                    ),
                    const SizedBox(height: LuxSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _export(context, st, traveler),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(l.corpExportCsv),
                      ),
                    ),
                  ],
                  const SizedBox(height: LuxSpacing.lg),
                  SectionHeader(title: l.corpRidesOfMonth),
                  const SizedBox(height: LuxSpacing.md),
                  for (final b in st.bookings) _RideTile(booking: b, traveler: traveler(b.riderId)),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _export(BuildContext context, CompanyStatement st, String Function(String) traveler) async {
    final l = context.l10n;
    final csv = st.csv(
      headers: [
        l.corpColDate,
        l.corpColBookedBy,
        l.corpColPassenger,
        l.corpColFrom,
        l.corpColTo,
        l.corpColVehicle,
        l.corpCostCenter,
        l.corpReference,
        l.corpColAmount,
      ],
      date: (b) => DateFormat('yyyy-MM-dd HH:mm').format(b.effectivePickup),
      traveler: (b) => traveler(b.riderId),
      vehicle: (b) => b.vehicleClass.localizedLabel(l),
    );
    final file = 'luxelane-${widget.company.taxId}-${DateFormat('yyyy-MM').format(st.month)}.csv';
    if (downloadTextFile(file, csv)) {
      showLuxSnackbar(context, l.adminReportsDownloaded);
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    if (context.mounted) showLuxSnackbar(context, l.adminReportsCopied);
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth < 560 ? (c.maxWidth - LuxSpacing.md) / 2 : 220.0;
        return Wrap(
          spacing: LuxSpacing.md,
          runSpacing: LuxSpacing.md,
          children: [for (final k in children) SizedBox(width: w, child: k)],
        );
      });
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.sub);
  final String label, value;
  final String? sub;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
            const SizedBox(height: LuxSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: LuxTypography.headlineLarge.copyWith(
                      color: LuxColors.white, fontFamily: 'Cormorant Garamond', fontSize: 32)),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: LuxTypography.caption),
            ],
          ],
        ),
      );
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.rows});
  final String title;
  final List<({String label, int trips, double amount})> rows;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LuxTypography.titleMedium),
          const SizedBox(height: LuxSpacing.sm),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Text(r.label,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Text(l.adminReportsTooltipTrips(r.trips), style: LuxTypography.caption),
                const SizedBox(width: LuxSpacing.md),
                Text(LuxMoney.format(r.amount),
                    style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  const _RideTile({required this.booking, required this.traveler});
  final Booking booking;
  final String traveler;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = booking;
    final at = b.effectivePickup;
    final meta = [
      traveler,
      if (b.passengerName != null && b.passengerName != traveler) b.passengerName!,
      if (b.costCenter != null) b.costCenter!,
      if (b.billingReference != null) b.billingReference!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('${DateFormat.MMMd().format(at)} · ${DateFormat.jm().format(at)}',
                    style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
              ),
              BookingStatusChip(status: b.status),
            ]),
            const SizedBox(height: LuxSpacing.xs),
            Text(
              b.serviceType == ServiceType.byTheHour
                  ? b.origin.displayName
                  : l.corpRoute(b.origin.displayName, b.destination.displayName),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white),
            ),
            const SizedBox(height: LuxSpacing.xs),
            Row(children: [
              Expanded(
                child: Text(meta,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: LuxTypography.caption),
              ),
              const SizedBox(width: LuxSpacing.sm),
              Text(
                b.status == BookingStatus.cancelled ? '—' : LuxMoney.format(CompanyStatement.billable(b)),
                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.accent),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Members ─────────────────────────────────────────────────────────────────

class MembersTab extends StatefulWidget {
  const MembersTab({super.key, required this.repo, required this.company});
  final CompanyRepository repo;
  final Company company;

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final _email = TextEditingController();
  CompanyRole _role = CompanyRole.member;
  bool _busy = false;
  late final _members = widget.repo.watchMembers(widget.company.id);
  late final _invites = widget.repo.watchInvites(widget.company.id);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action, String success) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final l = context.l10n;
    showLuxSnackbar(context, error == null ? success : localizedCompanyError(l, error), isError: error != null);
  }

  Future<void> _add() async {
    final l = context.l10n;
    final email = _email.text.trim();
    if (email.isEmpty) return;
    await _run(() async {
      final e = await widget.repo.addMember(widget.company.id, email, _role);
      if (e == null) _email.clear();
      return e;
    }, l.corpMemberAdded);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.corpAddMember, style: LuxTypography.titleMedium),
              const SizedBox(height: LuxSpacing.xs),
              Text(l.corpAddMemberHint, style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(
                controller: _email,
                label: l.corpEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: LuxSpacing.md),
              Wrap(
                spacing: LuxSpacing.sm,
                runSpacing: LuxSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final r in CompanyRole.values)
                    ChoiceChip(
                      label: Text(r.localizedLabel(l)),
                      selected: _role == r,
                      onSelected: (_) => setState(() => _role = r),
                    ),
                  LuxButton(
                    label: l.corpAddMemberAction,
                    width: 200,
                    height: 44,
                    loading: _busy,
                    onPressed: _busy ? null : _add,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: LuxSpacing.xl),
        SectionHeader(title: l.corpMembers),
        const SizedBox(height: LuxSpacing.md),
        StreamBuilder<List<CompanyMember>>(
          stream: _members,
          builder: (context, snap) {
            final members = snap.data ?? const <CompanyMember>[];
            if (members.isEmpty) return Text(l.corpNoMembers, style: LuxTypography.bodyMedium);
            return Column(children: [
              for (final m in members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: LuxColors.accentSubtle,
                    child: Text(
                      (m.displayName.isNotEmpty ? m.displayName : m.email).characters.first.toUpperCase(),
                      style: const TextStyle(color: LuxColors.accent),
                    ),
                  ),
                  title: Text(m.displayName.isNotEmpty ? m.displayName : m.email,
                      overflow: TextOverflow.ellipsis, style: LuxTypography.bodyLarge),
                  subtitle: Text('${m.email} · ${m.role.localizedLabel(l)}',
                      overflow: TextOverflow.ellipsis, style: LuxTypography.caption),
                  trailing: PopupMenuButton<String>(
                    tooltip: l.corpMemberActions,
                    color: LuxColors.blackElevated,
                    onSelected: (v) => switch (v) {
                      'admin' => _run(() => widget.repo.setMemberRole(widget.company.id, m.uid, CompanyRole.admin),
                          l.corpMemberUpdated),
                      'member' => _run(() => widget.repo.setMemberRole(widget.company.id, m.uid, CompanyRole.member),
                          l.corpMemberUpdated),
                      _ => _confirmRemove(m),
                    },
                    itemBuilder: (_) => [
                      if (m.role != CompanyRole.admin)
                        PopupMenuItem(value: 'admin', child: Text(l.corpMakeAdmin)),
                      if (m.role != CompanyRole.member)
                        PopupMenuItem(value: 'member', child: Text(l.corpMakeMember)),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l.corpRemoveMember, style: const TextStyle(color: LuxColors.error)),
                      ),
                    ],
                  ),
                ),
            ]);
          },
        ),
        StreamBuilder<List<CompanyInvite>>(
          stream: _invites,
          builder: (context, snap) {
            final invites = snap.data ?? const <CompanyInvite>[];
            if (invites.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: LuxSpacing.xl),
                SectionHeader(title: l.corpPendingInvites),
                const SizedBox(height: LuxSpacing.xs),
                Text(l.corpPendingInvitesHint, style: LuxTypography.caption),
                const SizedBox(height: LuxSpacing.sm),
                for (final i in invites)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline, color: LuxColors.whiteTertiary),
                    title: Text(i.email, overflow: TextOverflow.ellipsis, style: LuxTypography.bodyLarge),
                    subtitle: Text(i.role.localizedLabel(l), style: LuxTypography.caption),
                    trailing: IconButton(
                      tooltip: l.corpCancelInvite,
                      icon: const Icon(Icons.close_rounded, color: LuxColors.whiteTertiary),
                      onPressed: () => _run(() => widget.repo.cancelInvite(i.email), l.corpInviteCancelled),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmRemove(CompanyMember m) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.blackElevated,
        title: Text(l.corpRemoveMember, style: LuxTypography.titleLarge),
        content: Text(l.corpRemoveMemberBody(m.displayName.isNotEmpty ? m.displayName : m.email),
            style: LuxTypography.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.corpRemoveMember, style: const TextStyle(color: LuxColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => widget.repo.removeMember(widget.company.id, m.uid), l.corpMemberRemoved);
  }
}

// ── Settings ────────────────────────────────────────────────────────────────

class CompanySettingsTab extends StatefulWidget {
  const CompanySettingsTab({super.key, required this.repo, required this.company});
  final CompanyRepository repo;
  final Company company;

  @override
  State<CompanySettingsTab> createState() => _CompanySettingsTabState();
}

class _CompanySettingsTabState extends State<CompanySettingsTab> {
  late final _name = TextEditingController(text: widget.company.name);
  late final _taxId = TextEditingController(text: widget.company.taxId);
  late final _email = TextEditingController(text: widget.company.billingEmail);
  final _newCenter = TextEditingController();
  late List<String> _centers = [...widget.company.costCenters];
  late bool _require = widget.company.requireCostCenter;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _taxId, _email, _newCenter]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCenter() {
    final c = _newCenter.text.trim();
    if (c.isEmpty || _centers.any((x) => x.toLowerCase() == c.toLowerCase())) return;
    setState(() {
      _centers = [..._centers, c];
      _newCenter.clear();
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _busy = true);
    final error = await widget.repo.updateCompany(
      widget.company.id,
      name: _name.text.trim(),
      taxId: _taxId.text.trim(),
      billingEmail: _email.text.trim(),
      costCenters: _centers,
      requireCostCenter: _require && _centers.isNotEmpty,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    showLuxSnackbar(context, error == null ? l.corpSettingsSaved : localizedCompanyError(l, error),
        isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        SectionHeader(title: l.corpBillingDetails),
        const SizedBox(height: LuxSpacing.md),
        LuxTextField(controller: _name, label: l.corpCompanyName),
        const SizedBox(height: LuxSpacing.md),
        LuxTextField(controller: _taxId, label: l.corpTaxId, keyboardType: TextInputType.number),
        const SizedBox(height: LuxSpacing.md),
        LuxTextField(controller: _email, label: l.corpBillingEmail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: LuxSpacing.xl),
        SectionHeader(title: l.corpCostCenters),
        const SizedBox(height: LuxSpacing.xs),
        Text(l.corpCostCentersHint, style: LuxTypography.caption),
        const SizedBox(height: LuxSpacing.md),
        Wrap(
          spacing: LuxSpacing.sm,
          runSpacing: LuxSpacing.sm,
          children: [
            for (final c in _centers)
              InputChip(
                label: Text(c),
                deleteButtonTooltipMessage: l.corpRemoveCostCenter,
                onDeleted: () => setState(() => _centers = _centers.where((x) => x != c).toList()),
              ),
          ],
        ),
        const SizedBox(height: LuxSpacing.md),
        Row(children: [
          Expanded(
            child: LuxTextField(
              controller: _newCenter,
              label: l.corpNewCostCenter,
            ),
          ),
          const SizedBox(width: LuxSpacing.sm),
          IconButton.filledTonal(
            tooltip: l.corpAddCostCenter,
            onPressed: _addCenter,
            icon: const Icon(Icons.add_rounded),
          ),
        ]),
        const SizedBox(height: LuxSpacing.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: LuxColors.accent,
          value: _require && _centers.isNotEmpty,
          onChanged: _centers.isEmpty ? null : (v) => setState(() => _require = v),
          title: Text(l.corpRequireCostCenter, style: LuxTypography.bodyLarge),
          subtitle: Text(l.corpRequireCostCenterHint, style: LuxTypography.caption),
        ),
        const SizedBox(height: LuxSpacing.lg),
        LuxButton(label: l.corpSave, loading: _busy, onPressed: _busy ? null : _save),
      ],
    );
  }
}
