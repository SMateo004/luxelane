import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/company_repository.dart';
import '../../domain/company.dart';

/// Profile section for riders who belong to a corporate account. Company
/// admins get a link to the portal; members see which company they bill to.
class CompanyProfileEntry extends StatelessWidget {
  const CompanyProfileEntry({super.key, required this.uid, this.repository});

  final String uid;
  final CompanyRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (repository == null && !sl.isRegistered<CompanyRepository>()) return const SizedBox.shrink();
    final repo = repository ?? sl<CompanyRepository>();
    final l = context.l10n;
    return StreamBuilder<CompanyMembership?>(
      stream: repo.watchMembership(uid),
      builder: (context, m) {
        final membership = m.data;
        if (membership == null) return const SizedBox.shrink();
        return StreamBuilder<Company?>(
          stream: repo.watchCompany(membership.companyId),
          builder: (context, c) {
            final company = c.data;
            if (company == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: LuxSpacing.xl),
                SectionHeader(title: l.corpProfileSection),
                const SizedBox(height: LuxSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 52,
                  leading: const Icon(Icons.business_outlined, color: LuxColors.accent),
                  title: Text(company.name, style: LuxTypography.bodyLarge),
                  subtitle: Text(
                    !company.active
                        ? l.corpSuspendedShort
                        : membership.isAdmin
                            ? l.corpProfileAdminHint
                            : l.corpProfileMemberHint,
                    style: LuxTypography.caption,
                  ),
                  trailing: membership.isAdmin
                      ? const Icon(Icons.chevron_right_rounded, color: LuxColors.whiteTertiary)
                      : null,
                  onTap: membership.isAdmin ? () => context.push('/empresa') : null,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
