import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/legal.dart';
import '../../../../core/di/injection.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/presentation/pages/home_design.dart';
import 'legal_content.dart';

// ============================================================
// Public pages: Términos, Privacidad, Contacto, Eliminar cuenta.
// Light editorial style, readable width, work on web and mobile.
// ============================================================

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: LD.bg,
        appBar: AppBar(
          backgroundColor: LD.bg,
          foregroundColor: LD.ink,
          elevation: 0,
          title: Text(title,
              style: const TextStyle(fontFamily: kSans, fontSize: 15, fontWeight: FontWeight.w500, color: LD.ink)),
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
      );
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) {
    if (!LegalInfo.isDraft) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxPalette.warning.withValues(alpha: 0.12),
        border: Border.all(color: LuxPalette.warning),
      ),
      child: Text(
        context.l10n.legalDraftBanner,
        style: bodyText(size: 13, color: LD.ink),
      ),
    );
  }
}

/// Renders a [LegalDocument] in the active language.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.documentFor});

  /// Builds the document for the current locale.
  final LegalDocument Function(Locale locale) documentFor;

  factory LegalPage.privacy() => const LegalPage(documentFor: privacyPolicyFor);
  factory LegalPage.terms() => const LegalPage(documentFor: termsOfServiceFor);

  @override
  Widget build(BuildContext context) {
    final document = documentFor(Localizations.localeOf(context));
    return _PageFrame(
      title: document.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DraftBanner(),
          Semantics(
            header: true,
            child: Text(document.title, style: displayText(size: 40, weight: FontWeight.w400)),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.legalLastUpdated(legalLastUpdated), style: uiLabel(spacing: 0.6)),
          const SizedBox(height: 24),
          Text(document.intro, style: bodyText(color: LD.ink)),
          for (final section in document.sections) ...[
            const SizedBox(height: 28),
            Semantics(
              header: true,
              child: Text(section.title, style: displayText(size: 24, weight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            for (final p in section.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(p, style: bodyText(size: 14)),
              ),
          ],
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonCouldNotOpenApp)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = LegalInfo.supportWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
    return _PageFrame(
      title: l.legalContactTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DraftBanner(),
          Text(l.legalContactHeadline, style: displayText(size: 40, weight: FontWeight.w400)),
          const SizedBox(height: 12),
          Text(l.legalContactIntro, style: bodyText()),
          const SizedBox(height: 28),
          if (LegalInfo.hasWhatsApp)
            _ContactTile(
              icon: Icons.chat_outlined,
              label: l.commonWhatsApp,
              value: LegalInfo.supportWhatsApp,
              onTap: () => _open(context, Uri.parse('https://wa.me/$digits')),
            ),
          if (LegalInfo.hasEmail)
            _ContactTile(
              icon: Icons.mail_outline,
              label: l.legalContactEmail,
              value: LegalInfo.supportEmail,
              onTap: () => _open(context, Uri(scheme: 'mailto', path: LegalInfo.supportEmail)),
            ),
          if (!LegalInfo.hasEmail && !LegalInfo.hasWhatsApp)
            Text(l.legalContactComingSoon, style: bodyText(color: LD.ink3)),
          const SizedBox(height: 28),
          Text(LegalInfo.companyName, style: uiLabel(size: 12, spacing: 0.4, color: LD.ink)),
          const SizedBox(height: 4),
          Text(l.legalCompanyDetails(LegalInfo.nit, LegalInfo.address), style: bodyText(size: 13, color: LD.ink3)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border.all(color: LD.border)),
              child: Row(
                children: [
                  Icon(icon, color: LD.accent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label.toUpperCase(), style: uiLabel(color: LD.accent)),
                        const SizedBox(height: 4),
                        Text(value, style: bodyText(size: 16, color: LD.ink)),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, size: 18, color: LD.ink3),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Self-service account deletion (also the public "deletion URL" app
/// stores ask for).
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirm = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await sl<FirebaseFunctions>().httpsCallable('deleteAccount').call<void>();
      if (!mounted) return;
      context.read<AuthBloc>().add(const LogoutRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.legalDeleteSuccess)),
      );
      context.go('/');
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final l = context.l10n;
      setState(
          () => _error = (e.message ?? '').contains('active-trip') ? l.legalDeleteActiveTrip : l.legalDeleteFailed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.l10n.legalDeleteConnectionError);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final keyword = l.legalDeleteKeyword;
    final authed = context.watch<AuthBloc>().state is AuthAuthenticated;
    return _PageFrame(
      title: l.legalDeleteTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.legalDeleteHeadline, style: displayText(size: 40, weight: FontWeight.w400)),
          const SizedBox(height: 16),
          Text(l.legalDeleteIntro, style: bodyText(color: LD.ink)),
          const SizedBox(height: 8),
          for (final line in [
            l.legalDeleteEffectProfile,
            l.legalDeleteEffectBookings,
            l.legalDeleteEffectTrips,
            l.legalDeleteEffectDriver,
            l.legalDeleteEffectPermanent,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 9, right: 10),
                    child: Icon(Icons.circle, size: 5, color: LD.accent),
                  ),
                  Expanded(child: Text(line, style: bodyText(size: 14))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (!authed) ...[
            Text(l.legalDeleteSignInPrompt, style: bodyText(color: LD.ink)),
            const SizedBox(height: 16),
            _PrimaryButton(label: l.legalDeleteSignIn, onTap: () => context.push('/login')),
          ] else ...[
            Text(l.legalDeleteConfirmPrompt(keyword), style: bodyText(color: LD.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirm,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              style: bodyText(size: 16, color: LD.ink),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: keyword,
                hintStyle: bodyText(color: LD.ink3),
                border: const OutlineInputBorder(borderSide: BorderSide(color: LD.border)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: LD.border)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: bodyText(size: 13, color: LuxPalette.error)),
            ],
            const SizedBox(height: 16),
            _PrimaryButton(
              label: l.legalDeleteButton,
              danger: true,
              loading: _deleting,
              onTap: _confirm.text.trim().toUpperCase() == keyword && !_deleting ? _delete : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.danger = false, this.loading = false});
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: danger ? LuxPalette.error : LD.cta,
            foregroundColor: danger ? Colors.white : LD.onCta,
            disabledBackgroundColor: LD.bg3,
            disabledForegroundColor: LD.ink3,
            shape: const RoundedRectangleBorder(),
          ),
          child: loading
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label.toUpperCase(),
                  style:
                      const TextStyle(fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2)),
        ),
      );
}
