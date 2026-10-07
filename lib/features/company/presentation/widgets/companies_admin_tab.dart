import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/company_repository.dart';
import '../../domain/company.dart';
import '../company_l10n.dart';
import '../pages/company_portal_page.dart';

/// Admin panel → Empresas: create corporate accounts, suspend or reactivate
/// them and open each company's portal.
class CompaniesAdminTab extends StatelessWidget {
  const CompaniesAdminTab({super.key, this.repository});
  final CompanyRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<CompanyRepository>();
    final l = context.l10n;
    return StreamBuilder<List<Company>>(
      stream: repo.watchAllCompanies(),
      builder: (context, snap) {
        final companies = snap.data ?? const <Company>[];
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            SectionHeader(title: l.corpAdminTitle),
            const SizedBox(height: LuxSpacing.sm),
            Text(l.corpAdminIntro, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: LuxButton(
                label: l.corpCreateCompany,
                icon: Icons.add_business_outlined,
                width: 240,
                height: 44,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _CreateCompanyDialog(repo: repo),
                ),
              ),
            ),
            const SizedBox(height: LuxSpacing.lg),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const Center(child: CircularProgressIndicator(color: LuxColors.accent))
            else if (companies.isEmpty)
              EmptyState(icon: Icons.business_outlined, message: l.corpAdminEmpty)
            else
              for (final c in companies)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                  child: LuxCard(
                    child: Row(children: [
                      const Icon(Icons.business_outlined, color: LuxColors.accent),
                      const SizedBox(width: LuxSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, overflow: TextOverflow.ellipsis, style: LuxTypography.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${l.corpTaxIdShort(c.taxId)} · ${c.billingEmail}',
                              overflow: TextOverflow.ellipsis,
                              style: LuxTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: LuxSpacing.sm),
                      Tooltip(
                        message: c.active ? l.corpSuspend : l.corpReactivate,
                        child: Switch(
                          value: c.active,
                          activeColor: LuxColors.accent,
                          onChanged: (v) async {
                            final e = await repo.updateCompany(c.id, active: v);
                            if (!context.mounted) return;
                            showLuxSnackbar(
                              context,
                              e == null
                                  ? (v ? l.corpReactivated : l.corpSuspended)
                                  : localizedCompanyError(l, e),
                              isError: e != null,
                            );
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: l.corpOpenPortal,
                        icon: const Icon(Icons.open_in_new_rounded, color: LuxColors.whiteSecondary),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => CompanyPortalPage(companyId: c.id, repository: repo),
                        )),
                      ),
                    ]),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _CreateCompanyDialog extends StatefulWidget {
  const _CreateCompanyDialog({required this.repo});
  final CompanyRepository repo;

  @override
  State<_CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<_CreateCompanyDialog> {
  final _name = TextEditingController();
  final _taxId = TextEditingController();
  final _billing = TextEditingController();
  final _admin = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _taxId, _billing, _admin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final e = await widget.repo.createCompany(
      name: _name.text.trim(),
      taxId: _taxId.text.trim(),
      billingEmail: _billing.text.trim(),
      adminEmail: _admin.text.trim(),
    );
    if (!mounted) return;
    if (e == null) {
      Navigator.of(context).pop();
      showLuxSnackbar(context, l.corpCompanyCreated);
    } else {
      setState(() {
        _busy = false;
        _error = localizedCompanyError(l, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.corpCreateCompany, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LuxTextField(controller: _name, label: l.corpCompanyName),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(controller: _taxId, label: l.corpTaxId, keyboardType: TextInputType.number),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(
                  controller: _billing, label: l.corpBillingEmail, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(controller: _admin, label: l.corpAdminEmail, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: LuxSpacing.xs),
              Text(l.corpAdminEmailHint, style: LuxTypography.caption),
              if (_error != null) ...[
                const SizedBox(height: LuxSpacing.md),
                Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: Text(l.corpCreate, style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
