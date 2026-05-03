import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(
            ProfileLoadRequested(userId: authState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            TextButton(
              onPressed: () {},
              child: Text('EDIT',
                  style: LuxTypography.labelLarge.copyWith(fontSize: 11)),
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
                  child: Text(state.message,
                      style: LuxTypography.bodyMedium));
            }
            final user = state is ProfileLoaded
                ? state.user
                : (state as ProfileUpdated).user;
            return _ProfileBody(user: user);
          },
        ),
      );
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(LuxSpacing.md),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: LuxSpacing.xl),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: LuxSpacing.md),
          _InfoTile(
              icon: Icons.email_outlined, label: 'Email', value: user.email),
          _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone.isNotEmpty ? user.phone : '—'),
          const SizedBox(height: LuxSpacing.xl),
          const SectionHeader(title: 'Statistics'),
          const SizedBox(height: LuxSpacing.md),
          const Row(
            children: [
              Expanded(child: _StatCard(label: 'Rides', value: '0')),
              SizedBox(width: LuxSpacing.sm),
              Expanded(child: _StatCard(label: 'Rating', value: '—')),
              SizedBox(width: LuxSpacing.sm),
              Expanded(child: _StatCard(label: 'Miles', value: '0')),
            ],
          ),
          const SizedBox(height: LuxSpacing.xl),
          const SectionHeader(title: 'Payment'),
          const SizedBox(height: LuxSpacing.md),
          LuxOutlinedButton(
            label: 'Manage Payment Methods',
            onPressed: () => context.push('/payment'),
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: LuxSpacing.xl),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: LuxSpacing.md),
          const _PrefTile(label: 'Language', value: 'English'),
          const _PrefTile(label: 'Currency', value: 'USD'),
          const _PrefTile(label: 'Notifications', value: 'All'),
          const SizedBox(height: LuxSpacing.xl),
          LuxOutlinedButton(
            label: 'Sign Out',
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          const SizedBox(height: LuxSpacing.md),
          const Center(
              child: Text('Luxelane v1.0.0', style: LuxTypography.caption)),
          const SizedBox(height: LuxSpacing.md),
        ],
      );
}

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
                ? Text(
                    _initials,
                    style: const TextStyle(
                      fontFamily: 'Cormorant',
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: LuxColors.sapphire,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: LuxSpacing.md),
          Text(user.displayName, style: LuxTypography.headlineLarge),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: LuxSpacing.sm, vertical: LuxSpacing.xs),
            decoration: BoxDecoration(
              color: LuxColors.sapphireSubtle,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
              border: Border.all(color: LuxColors.sapphire.withOpacity(0.4)),
            ),
            child: Text(
              user.role == UserRole.admin
                  ? 'ADMIN'
                  : user.role == UserRole.driver
                      ? 'DRIVER'
                      : 'RIDER',
              style: LuxTypography.caption.copyWith(
                color: LuxColors.sapphire,
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
                    .copyWith(color: LuxColors.sapphire)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: LuxTypography.caption),
          ],
        ),
      );
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.md),
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: LuxColors.blackBorder))),
        child: Row(
          children: [
            Expanded(child: Text(label, style: LuxTypography.bodyLarge)),
            Text(value, style: LuxTypography.bodyMedium),
            const SizedBox(width: LuxSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                color: LuxColors.whiteTertiary, size: 18),
          ],
        ),
      );
}
