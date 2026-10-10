import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/auth_bloc.dart';

/// Where a suspended account is sent; only this and the help center open.
const accountSuspendedPath = '/cuenta-suspendida';

/// Signed in, not an admin, and turned off by an admin (users/{uid}.isActive).
bool isAccountSuspended(AuthState state) =>
    state is AuthAuthenticated && state.user.role != UserRole.admin && !state.user.isActive;

/// Router guard shared by the rider and chauffeur apps: keeps a suspended
/// account on [accountSuspendedPath] (help stays reachable) and sends a
/// reactivated one back to [home].
String? accountSuspensionRedirect(AuthState state, String going, {required String home}) {
  if (isAccountSuspended(state)) {
    return going == accountSuspendedPath || going == '/ayuda' ? null : accountSuspendedPath;
  }
  return going == accountSuspendedPath ? home : null;
}

class AccountSuspendedPage extends StatelessWidget {
  const AccountSuspendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: LuxColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pause_circle_outline_rounded, size: 56, color: LuxColors.accent),
                  const SizedBox(height: LuxSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(l.accountSuspendedTitle,
                        textAlign: TextAlign.center, style: LuxTypography.headlineMedium),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  Text(l.accountSuspendedBody, textAlign: TextAlign.center, style: LuxTypography.bodyMedium),
                  const SizedBox(height: LuxSpacing.xl),
                  LuxButton(
                    label: l.accountSuspendedContact,
                    icon: Icons.support_agent_outlined,
                    onPressed: () => context.push('/ayuda'),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  LuxOutlinedButton(
                    label: l.accountSuspendedSignOut,
                    onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
