import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/locale_sync.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/mfa_enroll_page.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/driver_documents_group.dart';
import '../widgets/language_selector.dart';

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(
            ProfileLoadRequested(userId: authState.user.id),
          );
    }
  }

  void _showEditSheet(User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuxColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _EditProfileSheet(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.profileTitle),
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final user = state is ProfileLoaded
                    ? state.user
                    : state is ProfileUpdated
                        ? state.user
                        : null;
                return TextButton(
                  onPressed: user != null ? () => _showEditSheet(user) : null,
                  child: Text(context.l10n.profileEdit),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (prev, next) =>
              next is ProfileLoaded &&
              next.message != null &&
              (prev is! ProfileLoaded || prev.messageSeq != next.messageSeq),
          listener: (context, state) {
            final s = state as ProfileLoaded;
            showLuxSnackbar(context, s.message!, isError: s.isError);
          },
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const LuxSkeletonList(count: 5, itemHeight: 64);
            }
            if (state is ProfileError) {
              return Center(
                child: Text(state.message, style: LuxTypography.bodyMedium),
              );
            }
            final User user;
            int totalRides = 0;
            double? rating;
            DriverProfile? driverProfile;
            if (state is ProfileLoaded) {
              user = state.user;
              totalRides = state.totalRides;
              rating = state.rating;
              driverProfile = state.driverProfile;
            } else if (state is ProfileUpdated) {
              user = state.user;
            } else {
              return const SizedBox();
            }
            return _ProfileBody(
              user: user,
              totalRides: totalRides,
              rating: rating,
              driverProfile: driverProfile,
              onEdit: () => _showEditSheet(user),
              onPreferences: (p) => context.read<ProfileBloc>().add(
                    ProfileUpdateRequested(
                      user: user.copyWith(ridePreferences: p),
                      silent: true,
                    ),
                  ),
            );
          },
        ),
      );
}

// ---------------------------------------------------------------------------
// _ProfileBody
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.totalRides,
    required this.onEdit,
    required this.onPreferences,
    this.rating,
    this.driverProfile,
  });

  final User user;
  final DriverProfile? driverProfile;
  final int totalRides;
  final double? rating;
  final VoidCallback onEdit;
  final ValueChanged<RidePreferences> onPreferences;

  @override
  Widget build(BuildContext context) {
    final rider = user.role == UserRole.rider;
    final prefs = user.ridePreferences;
    var i = 0;
    Widget item(Widget w) => LuxFadeIn(index: i++, child: w);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LuxSpacing.md,
        LuxSpacing.sm,
        LuxSpacing.md,
        LuxSpacing.xxl,
      ),
      children: [
        item(
          _ProfileHeader(
            user: user,
            totalRides: totalRides,
            rating: rating,
            onEdit: onEdit,
          ),
        ),
        if (rider) ...[
          const SizedBox(height: LuxSpacing.xl),
          item(SectionHeader(title: context.l10n.profileRideStyle)),
          const SizedBox(height: LuxSpacing.sm),
          item(_RidePreferencesGroup(prefs: prefs, onChanged: onPreferences)),
        ],
        if (driverProfile != null) ...[
          const SizedBox(height: LuxSpacing.xl),
          item(SectionHeader(title: context.l10n.profileDriverDocuments)),
          const SizedBox(height: LuxSpacing.sm),
          item(_DriverDocumentsSection(profile: driverProfile!)),
        ],
        const SizedBox(height: LuxSpacing.xl),
        item(SectionHeader(title: AppLocalizations.of(context).languageTitle)),
        const SizedBox(height: LuxSpacing.sm),
        item(LanguageSelector(sync: sl<LocaleSync>())),
        const SizedBox(height: LuxSpacing.xl),
        item(SectionHeader(title: context.l10n.profileAccount)),
        const SizedBox(height: LuxSpacing.sm),
        item(
          LuxGroup(
            children: [
              LuxListRow(
                icon: Icons.mail_outline_rounded,
                title: context.l10n.profileEmail,
                subtitle: user.email,
              ),
              LuxListRow(
                icon: Icons.phone_outlined,
                title: context.l10n.profilePhone,
                subtitle: user.phone.isNotEmpty
                    ? user.phone
                    : context.l10n.profilePhoneMissing,
                onTap: onEdit,
              ),
              if (rider)
                LuxListRow(
                  icon: Icons.credit_card_outlined,
                  title: context.l10n.profilePaymentMethods,
                  onTap: () => context.push('/payment'),
                ),
              // Obligatoria para chóferes y administradores (decisión 2).
              if (!rider)
                LuxListRow(
                  icon: Icons.shield_outlined,
                  title: context.l10n.profileTwoStep,
                  subtitle: context.l10n.profileAuthenticatorApp,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MfaEnrollPage(accountName: user.email),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: LuxSpacing.xl),
        item(SectionHeader(title: context.l10n.profileLegal)),
        const SizedBox(height: LuxSpacing.sm),
        item(
          LuxGroup(
            children: [
              LuxListRow(
                icon: Icons.description_outlined,
                title: context.l10n.profileTerms,
                onTap: () => context.push('/legal/terminos'),
              ),
              LuxListRow(
                icon: Icons.shield_outlined,
                title: context.l10n.profilePrivacy,
                onTap: () => context.push('/legal/privacidad'),
              ),
            ],
          ),
        ),
        const SizedBox(height: LuxSpacing.xl),
        item(
          LuxOutlinedButton(
            label: context.l10n.profileSignOut,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ),
        const SizedBox(height: LuxSpacing.xs),
        item(
          LuxButton.ghost(
            label: context.l10n.profileDeleteAccount,
            onPressed: () => _confirmDeleteAccount(context),
          ),
        ),
        const SizedBox(height: LuxSpacing.md),
        const Center(
          child: Text('Luxelane · v1.0.0', // i18n-ignore: marca y versión
              style: LuxTypography.caption),
        ),
      ],
    );
  }
}

/// Cómo le gusta viajar. Cada cambio se guarda al instante y el chófer lo
/// verá en su próxima reserva.
class _RidePreferencesGroup extends StatelessWidget {
  const _RidePreferencesGroup({required this.prefs, required this.onChanged});
  final RidePreferences prefs;
  final ValueChanged<RidePreferences> onChanged;

  @override
  Widget build(BuildContext context) => LuxGroup(
        footer: context.l10n.profilePreferencesFooter,
        children: [
          LuxSwitchRow(
            icon: Icons.volume_off_outlined,
            title: context.l10n.profileQuietRide,
            subtitle: context.l10n.profileQuietRideDetail,
            value: prefs.quiet,
            onChanged: (v) => onChanged(prefs.copyWith(quiet: v)),
          ),
          LuxSwitchRow(
            icon: Icons.music_note_outlined,
            title: context.l10n.profileSoftMusic,
            value: prefs.music,
            onChanged: (v) => onChanged(prefs.copyWith(music: v)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.thermostat_outlined,
                      size: 20,
                      color: LuxColors.inkSecondary,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      context.l10n.profileTemperature,
                      style: LuxTypography.bodyLarge.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LuxSegmented<CabinTemperature?>(
                  values: const [null, ...CabinTemperature.values],
                  selected: prefs.temperature,
                  labelOf: (t) =>
                      t?.label ?? context.l10n.profileTemperatureAny,
                  height: 40,
                  onChanged: (t) => onChanged(
                    t == null
                        ? prefs.copyWith(clearTemperature: true)
                        : prefs.copyWith(temperature: t),
                  ),
                ),
              ],
            ),
          ),
          LuxSwitchRow(
            icon: Icons.luggage_outlined,
            title: context.l10n.profileLuggageHelp,
            value: prefs.luggageHelp,
            onChanged: (v) => onChanged(prefs.copyWith(luggageHelp: v)),
          ),
          LuxSwitchRow(
            icon: Icons.door_front_door_outlined,
            title: context.l10n.profileOpenDoor,
            value: prefs.openDoor,
            onChanged: (v) => onChanged(prefs.copyWith(openDoor: v)),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Eliminar cuenta
// ---------------------------------------------------------------------------

Future<void> _confirmDeleteAccount(BuildContext context) async {
  final auth = context.read<AuthBloc>();
  final deleted = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (deleted != true) return;
  // El servidor ya borró el acceso: se cierra la sesión local.
  auth.add(const LogoutRequested());
  if (context.mounted) {
    showLuxSnackbar(context, context.l10n.profileAccountDeleted);
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _delete({bool retried = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await sl<AuthRepository>().deleteAccount();
    if (!mounted) return;
    final failure = result.fold((f) => f, (_) => null);
    if (failure == null) return Navigator.of(context).pop(true);
    // Sesión antigua (más de 5 minutos): se confirma la identidad y se
    // repite una sola vez.
    if (!retried && failure.message == kReauthRequiredMessage) {
      if (await ReauthDialog.show(context) && mounted) {
        return _delete(retried: true);
      }
      if (!mounted) return;
    }
    setState(() {
      _busy = false;
      _error = failure.message;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: LuxColors.error),
        title: Text(context.l10n.profileDeleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.profileDeleteBody),
            if (_error != null) ...[
              const SizedBox(height: LuxSpacing.md),
              Text(
                _error!,
                style:
                    LuxTypography.bodyMedium.copyWith(color: LuxColors.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(context.l10n.profileCancel),
          ),
          FilledButton(
            onPressed: _busy ? null : _delete,
            style: FilledButton.styleFrom(backgroundColor: LuxColors.error),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(context.l10n.profileDelete),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Edit Profile Bottom Sheet
// ---------------------------------------------------------------------------

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});
  final User user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _phone = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final updated = widget.user.copyWith(
      displayName: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    // El resultado (guardado o error) lo muestra la pantalla de perfil.
    context.read<ProfileBloc>().add(ProfileUpdateRequested(user: updated));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LuxSpacing.lg,
        LuxSpacing.lg,
        LuxSpacing.lg,
        LuxSpacing.lg + bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.l10n.profileEditTitle,
                    style: LuxTypography.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: LuxColors.inkTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxTextField(
              label: context.l10n.profileName,
              controller: _name,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.trim().isEmpty
                  ? context.l10n.profileRequired
                  : null,
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              label: context.l10n.profilePhone,
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) => v == null || v.trim().length < 6
                  ? context.l10n.profilePhoneInvalid
                  : null,
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxButton(label: context.l10n.profileSaveChanges, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.totalRides,
    required this.onEdit,
    this.rating,
  });
  final User user;
  final int totalRides;
  final double? rating;
  final VoidCallback onEdit;

  String get _initials {
    final parts =
        user.displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'L';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _role(AppLocalizations l10n) => switch (user.role) {
        UserRole.admin => l10n.profileRoleAdmin,
        UserRole.driver => l10n.profileRoleDriver,
        UserRole.rider => l10n.profileMemberSince(user.createdAt.year),
      };

  @override
  Widget build(BuildContext context) => LuxPressable(
        onTap: onEdit,
        semanticLabel: context.l10n.profileEditTitle,
        scale: 0.99,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LuxSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: LuxColors.sapphireTint,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        _initials,
                        style: const TextStyle(
                          fontFamily:
                              'Cormorant Garamond', // i18n-ignore: tipografía
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: LuxColors.sapphire,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.headlineLarge.copyWith(
                        fontSize: 28,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _role(context.l10n),
                        if (totalRides > 0)
                          context.l10n.profileRides(totalRides),
                        if (rating != null) '★ ${rating!.toStringAsFixed(1)}',
                      ].join(' · '),
                      style: LuxTypography.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: LuxColors.inkTertiary),
            ],
          ),
        ),
      );
}

/// Carga el vehículo del chófer y permite cambiar su color (lo único que
/// edita; el resto lo cambia central).
class _DriverDocumentsSection extends StatefulWidget {
  const _DriverDocumentsSection({required this.profile});
  final DriverProfile profile;

  @override
  State<_DriverDocumentsSection> createState() =>
      _DriverDocumentsSectionState();
}

class _DriverDocumentsSectionState extends State<_DriverDocumentsSection> {
  final _vehicles = sl<VehicleRepository>();
  Vehicle? _vehicle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _vehicles.getVehicleByDriver(widget.profile.userId);
    if (!mounted) return;
    setState(() => _vehicle = r.fold((_) => null, (v) => v));
  }

  Future<void> _editColor() async {
    final v = _vehicle;
    if (v == null) return;
    final controller = TextEditingController(text: v.color);
    final color = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.profileVehicleColorTitle),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.profileColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.l10n.profileSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (color == null || color.isEmpty || !mounted) return;
    final r = await _vehicles.updateVehicleAppearance(v.id, color: color);
    if (!mounted) return;
    r.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) => DriverDocumentsGroup(
        profile: widget.profile,
        vehicle: _vehicle,
        onEditColor: _vehicle == null ? null : _editColor,
      );
}
