import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../company/presentation/widgets/company_profile_entry.dart';
import '../../../company/presentation/widgets/company_invite_card.dart';
import '../../../loyalty/presentation/loyalty_widgets.dart';
import '../bloc/profile_bloc.dart';

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
                  child: Text(context.l10n.commonEdit.toUpperCase(),
                      style: LuxTypography.labelLarge.copyWith(fontSize: 11)),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.profileLoadError,
                        style: LuxTypography.bodyMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: LuxSpacing.sm),
                    TextButton(
                      onPressed: _loadProfile,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              );
            }
            final User user;
            int totalRides = 0;
            double? rating;
            if (state is ProfileLoaded) {
              user = state.user;
              totalRides = state.totalRides;
              rating = state.rating;
            } else if (state is ProfileUpdated) {
              user = state.user;
            } else {
              return const SizedBox();
            }
            return _ProfileBody(
              user: user,
              totalRides: totalRides,
              rating: rating,
              onEdit: () => _showEditSheet(user),
              onPreferences: (p) => context.read<ProfileBloc>().add(
                  ProfileUpdateRequested(
                      user: user.copyWith(ridePreferences: p), silent: true)),
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
  });

  final User user;
  final int totalRides;
  final double? rating;
  final VoidCallback onEdit;
  final ValueChanged<RidePreferences> onPreferences;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rider = user.role == UserRole.rider;
    final prefs = user.ridePreferences;
    var i = 0;
    Widget item(Widget w) => LuxFadeIn(index: i++, child: w);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          LuxSpacing.md, LuxSpacing.sm, LuxSpacing.md, LuxSpacing.xxl),
      children: [
        item(_ProfileHeader(
          user: user,
          totalRides: totalRides,
          rating: rating,
          onEdit: onEdit,
        )),
        if (rider) ...[
          const SizedBox(height: LuxSpacing.xl),
          item(const SectionHeader(title: 'Tu estilo de viaje')),
          const SizedBox(height: LuxSpacing.sm),
          item(_RidePreferencesGroup(prefs: prefs, onChanged: onPreferences)),
        ],
        const SizedBox(height: LuxSpacing.xl),
        item(SectionHeader(title: l.profileSectionAccount)),
        const SizedBox(height: LuxSpacing.sm),
        item(LuxGroup(children: [
          LuxListRow(
              icon: Icons.mail_outline_rounded,
              title: l.authEmailLabel,
              subtitle: user.email),
          LuxListRow(
            icon: Icons.phone_outlined,
            title: l.authPhoneLabel,
            subtitle:
                user.phone.isNotEmpty ? user.phone : 'Añádelo para tu chófer',
            onTap: onEdit,
          ),
          if (rider)
            LuxListRow(
              icon: Icons.credit_card_outlined,
              title: 'Métodos de pago',
              onTap: () => context.push('/payment'),
            ),
        ])),
        if (rider) item(const LoyaltyProfileCard()),
        if (rider) item(const CompanyInviteCard()),
        item(CompanyProfileEntry(uid: user.id)),
        if (user.role == UserRole.driver) ...[
          const SizedBox(height: LuxSpacing.xl),
          item(SectionHeader(title: l.docTitle)),
          const SizedBox(height: LuxSpacing.sm),
          item(LuxGroup(children: [
            LuxListRow(
              icon: Icons.verified_user_outlined,
              title: l.docProfileLink,
              onTap: () => context.push('/driver/documents'),
            ),
          ])),
        ],
        const SizedBox(height: LuxSpacing.xl),
        item(SectionHeader(title: l.profileSectionHelp)),
        const SizedBox(height: LuxSpacing.sm),
        item(LuxGroup(children: [
          LuxListRow(
            icon: Icons.help_outline_rounded,
            title: l.supportHelpCenter,
            onTap: () => context.push('/ayuda'),
          ),
          LuxListRow(
            icon: Icons.support_agent_outlined,
            title: l.profileContactHelp,
            onTap: () => context.push('/contacto'),
          ),
          LuxListRow(
            icon: Icons.description_outlined,
            title: l.authConsentTermsLink,
            onTap: () => context.push('/terminos'),
          ),
          LuxListRow(
            icon: Icons.shield_outlined,
            title: l.authConsentPrivacyLink,
            onTap: () => context.push('/privacidad'),
          ),
        ])),
        const SizedBox(height: LuxSpacing.xl),
        item(LuxOutlinedButton(
          label: l.profileSignOut,
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
        )),
        const SizedBox(height: LuxSpacing.xs),
        item(LuxButton.ghost(
          label: l.profileDeleteAccount,
          onPressed: () => _confirmDeleteAccount(context),
        )),
        const SizedBox(height: LuxSpacing.md),
        Center(
            child: Text(l.profileVersion('1.0.0'), style: LuxTypography.caption)),
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
        footer: 'Tu chófer lo sabrá antes de recogerte. Se aplica a tus '
            'próximas reservas.',
        children: [
          LuxSwitchRow(
            icon: Icons.volume_off_outlined,
            title: 'Viaje en silencio',
            subtitle: 'Sin conversación, salvo lo necesario',
            value: prefs.quiet,
            onChanged: (v) => onChanged(prefs.copyWith(quiet: v)),
          ),
          LuxSwitchRow(
            icon: Icons.music_note_outlined,
            title: 'Música suave',
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
                    const Icon(Icons.thermostat_outlined,
                        size: 20, color: LuxColors.inkSecondary),
                    const SizedBox(width: 16),
                    Text('Temperatura',
                        style: LuxTypography.bodyLarge.copyWith(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                LuxSegmented<CabinTemperature?>(
                  values: const [null, ...CabinTemperature.values],
                  selected: prefs.temperature,
                  labelOf: (t) => t?.label ?? 'Indistinta',
                  height: 40,
                  onChanged: (t) => onChanged(t == null
                      ? prefs.copyWith(clearTemperature: true)
                      : prefs.copyWith(temperature: t)),
                ),
              ],
            ),
          ),
          LuxSwitchRow(
            icon: Icons.luggage_outlined,
            title: 'Ayuda con el equipaje',
            value: prefs.luggageHelp,
            onChanged: (v) => onChanged(prefs.copyWith(luggageHelp: v)),
          ),
          LuxSwitchRow(
            icon: Icons.door_front_door_outlined,
            title: 'Abrirme la puerta',
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
  if (context.mounted) showLuxSnackbar(context, 'Tu cuenta fue eliminada.');
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await sl<AuthRepository>().deleteAccount();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _busy = false;
        _error = f.message;
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: LuxColors.error),
        title: const Text('¿Eliminar tu cuenta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Borraremos tu perfil, tus tarjetas guardadas y tus avisos, y '
              'no podrás volver a entrar con esta cuenta. Conservamos el '
              'registro de viajes y pagos que exige la ley.\n\n'
              'Esta acción no se puede deshacer.',
            ),
            if (_error != null) ...[
              const SizedBox(height: LuxSpacing.md),
              Text(_error!,
                  style: LuxTypography.bodyMedium
                      .copyWith(color: LuxColors.error)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _busy ? null : _delete,
            style: FilledButton.styleFrom(backgroundColor: LuxColors.error),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Eliminar'),
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
    final l = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          LuxSpacing.lg, LuxSpacing.lg, LuxSpacing.lg, LuxSpacing.lg + bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l.profileEditTitle, style: LuxTypography.titleLarge),
                ),
                IconButton(
                  tooltip: l.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: LuxColors.inkTertiary),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxTextField(
              label: l.profileNameLabel,
              controller: _name,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.commonRequired : null,
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              label: l.authPhoneLabel,
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) => v == null || v.trim().length < 6
                  ? 'Tu chófer lo necesita para contactarte'
                  : null,
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxButton(label: l.profileSaveChanges, onPressed: _save),
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

  String get _role => switch (user.role) {
        UserRole.admin => 'Administración',
        UserRole.driver => 'Chófer Luxelane',
        UserRole.rider => 'Miembro desde ${user.createdAt.year}',
      };

  @override
  Widget build(BuildContext context) => LuxPressable(
        onTap: onEdit,
        semanticLabel: 'Editar perfil',
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
                    ? Text(_initials,
                        style: const TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: LuxColors.sapphire,
                        ))
                    : null,
              ),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxTypography.headlineLarge
                            .copyWith(fontSize: 28, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _role,
                        if (totalRides > 0)
                          '$totalRides ${totalRides == 1 ? 'viaje' : 'viajes'}',
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
