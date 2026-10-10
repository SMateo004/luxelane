import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/company_invite_service.dart';

/// Profile: "Acme te invitó a su cuenta de empresa". Hidden without an
/// invite. An unverified e-mail is verified first (sent from here).
class CompanyInviteCard extends StatefulWidget {
  const CompanyInviteCard({super.key, this.service});
  final CompanyInviteService? service;

  @override
  State<CompanyInviteCard> createState() => _CompanyInviteCardState();
}

class _CompanyInviteCardState extends State<CompanyInviteCard> {
  CompanyInviteService? _svc;
  CompanyInviteStatus _status = CompanyInviteStatus.none;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _svc = widget.service ?? (sl.isRegistered<CompanyInviteService>() ? sl<CompanyInviteService>() : null);
    _load();
  }

  Future<void> _load() async {
    final s = await _svc?.status();
    if (mounted && s != null) setState(() => _status = s);
  }

  Future<void> _join() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final e = await _svc!.join();
    if (!mounted) return;
    if (e == null) {
      showLuxSnackbar(context, l.companyInviteJoined(_status.company ?? ''));
      setState(() => _status = CompanyInviteStatus.none);
    } else {
      // Maybe verified in the meantime, or not yet: refresh the state.
      await _load();
      if (!mounted) return;
      setState(() => _error = e == 'company/email-not-verified' ? l.companyInviteNotVerified : l.adminActionFailed);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendVerification() async {
    final l = context.l10n;
    try {
      await _svc!.sendVerificationEmail();
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) showLuxSnackbar(context, l.adminActionFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = _status.company;
    if (company == null) return const SizedBox.shrink();
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: LuxSpacing.xl),
      child: LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.business_outlined, color: LuxColors.accent),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(child: Text(l.companyInviteTitle(company), style: LuxTypography.titleMedium)),
          ]),
          const SizedBox(height: LuxSpacing.sm),
          Text(_status.verified ? l.companyInviteBody : l.companyInviteVerifyFirst, style: LuxTypography.bodyMedium),
          if (_sent) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(l.companyInviteVerificationSent, style: LuxTypography.caption),
          ],
          if (_error != null) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
          ],
          const SizedBox(height: LuxSpacing.md),
          Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [
            if (!_status.verified)
              LuxOutlinedButton(
                label: l.companyInviteSendVerification,
                width: 260,
                height: 44,
                onPressed: _busy ? null : _sendVerification,
              ),
            LuxButton(
              label: _status.verified ? l.companyInviteJoin : l.companyInviteVerifiedJoin,
              width: 260,
              height: 44,
              loading: _busy,
              onPressed: _busy ? null : _join,
            ),
          ]),
        ]),
      ),
    );
  }
}
