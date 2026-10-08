import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../company/presentation/widgets/company_profile_entry.dart';
import '../../../loyalty/presentation/loyalty_widgets.dart';
import '../bloc/profile_bloc.dart';

// ---------------------------------------------------------------------------
// Preference keys
// ---------------------------------------------------------------------------
abstract class _PrefKeys {
  static const language     = 'pref_language';
  static const currency     = 'pref_currency';
  static const notifications = 'pref_notifications';
}

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _language      = 'English';
  String _currency      = 'USD';
  String _notifications = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPrefs();
  }

  void _loadProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(
            ProfileLoadRequested(userId: authState.user.id),
          );
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _language      = prefs.getString(_PrefKeys.language)      ?? 'English';
      _currency      = prefs.getString(_PrefKeys.currency)      ?? 'USD';
      _notifications = prefs.getString(_PrefKeys.notifications) ?? 'Todas';
    });
  }

  Future<void> _savePref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _showEditSheet(User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuxColors.blackSurface,
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
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
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
            int totalRides    = 0;
            double? rating;
            if (state is ProfileLoaded) {
              user       = state.user;
              totalRides = state.totalRides;
              rating     = state.rating;
            } else if (state is ProfileUpdated) {
              user = state.user;
            } else {
              return const SizedBox();
            }
            return _ProfileBody(
              user: user,
              totalRides: totalRides,
              rating: rating,
              language: _language,
              currency: _currency,
              notifications: _notifications,
              onLanguageChanged: (v) {
                setState(() => _language = v);
                _savePref(_PrefKeys.language, v);
              },
              onCurrencyChanged: (v) {
                setState(() => _currency = v);
                _savePref(_PrefKeys.currency, v);
              },
              onNotificationsChanged: (v) {
                setState(() => _notifications = v);
                _savePref(_PrefKeys.notifications, v);
              },
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
    this.rating,
    required this.language,
    required this.currency,
    required this.notifications,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onNotificationsChanged,
  });

  final User user;
  final int totalRides;
  final double? rating;
  final String language;
  final String currency;
  final String notifications;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
        padding: const EdgeInsets.all(LuxSpacing.md),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: LuxSpacing.xl),
          SectionHeader(title: l.profileSectionAccount),
          const SizedBox(height: LuxSpacing.md),
          _InfoTile(
              icon: Icons.email_outlined,
              label: l.authEmailLabel,
              value: user.email),
          _InfoTile(
              icon: Icons.phone_outlined,
              label: l.authPhoneLabel,
              value: user.phone.isNotEmpty ? user.phone : '—'),
          const SizedBox(height: LuxSpacing.xl),
          SectionHeader(title: l.profileSectionStats),
          const SizedBox(height: LuxSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      label: l.profileStatTrips,
                      value: totalRides.toString())),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                  child: _StatCard(
                      label: l.profileStatRating,
                      value: rating != null
                          ? NumberFormat('0.0').format(rating)
                          : '—')),

            ],
          ),
          if (user.role == UserRole.rider) const LoyaltyProfileCard(),
          CompanyProfileEntry(uid: user.id),
          if (user.role == UserRole.driver) ...[
            const SizedBox(height: LuxSpacing.xl),
            SectionHeader(title: l.docTitle),
            const SizedBox(height: LuxSpacing.sm),
            _LinkTile(icon: Icons.verified_user_outlined, label: l.docProfileLink, path: '/driver/documents'),
          ],
          const SizedBox(height: LuxSpacing.xl),
          SectionHeader(title: l.profileSectionHelp),
          const SizedBox(height: LuxSpacing.sm),
          _LinkTile(icon: Icons.help_outline_rounded, label: l.supportHelpCenter, path: '/ayuda'),
          _LinkTile(icon: Icons.support_agent_outlined, label: l.profileContactHelp, path: '/contacto'),
          _LinkTile(icon: Icons.description_outlined, label: l.authConsentTermsLink, path: '/terminos'),
          _LinkTile(icon: Icons.privacy_tip_outlined, label: l.authConsentPrivacyLink, path: '/privacidad'),
          const SizedBox(height: LuxSpacing.xl),
          LuxOutlinedButton(
            label: l.profileSignOut,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          const SizedBox(height: LuxSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () => context.push('/eliminar-cuenta'),
              style: TextButton.styleFrom(
                foregroundColor: LuxColors.error,
                minimumSize: const Size(0, 48),
              ),
              child: Text(l.profileDeleteAccount),
            ),
          ),
          const SizedBox(height: LuxSpacing.sm),
          Center(
              child: Text(l.profileVersion('1.0.0'),
                  style: LuxTypography.caption)),
          const SizedBox(height: LuxSpacing.md),
        ],
      );
  }
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
    _name  = TextEditingController(text: widget.user.displayName);
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
    final message = context.l10n.profileUpdated;
    final messenger = ScaffoldMessenger.of(context);
    context.read<ProfileBloc>().add(ProfileUpdateRequested(user: updated));
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
                      color: LuxColors.whiteTertiary),
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
  const _ProfileHeader({required this.user});
  final User user;

  String get _initials {
    final parts = user.displayName.trim().split(' ');
    if (parts.isEmpty) return 'L';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: LuxColors.blackElevated,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(_initials,
                    style: const TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: LuxColors.accent,
                    ))
                : null,
          ),
          const SizedBox(height: LuxSpacing.md),
          Text(user.displayName,
              style: LuxTypography.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: LuxSpacing.sm, vertical: LuxSpacing.xs),
            decoration: BoxDecoration(
              color: LuxColors.accentSubtle,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
              border:
                  Border.all(color: LuxColors.accent.withOpacity(0.4)),
            ),
            child: Text(
              user.role.localizedLabel(context.l10n).toUpperCase(),
              style: LuxTypography.caption.copyWith(
                color: LuxColors.accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: LuxColors.blackBorder))),
        child: Row(
          children: [
            Icon(icon, color: LuxColors.whiteTertiary, size: 18),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: LuxTypography.caption),
                  const SizedBox(height: 2),
                  Text(value, style: LuxTypography.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Column(
          children: [
            Text(value,
                style: LuxTypography.headlineLarge
                    .copyWith(color: LuxColors.accent)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: LuxTypography.caption),
          ],
        ),
      );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 52,
        leading: Icon(icon, color: LuxColors.accent),
        title: Text(label, style: LuxTypography.bodyLarge),
        trailing: const Icon(Icons.chevron_right_rounded, color: LuxColors.whiteTertiary),
        onTap: () => context.push(path),
      );
}
