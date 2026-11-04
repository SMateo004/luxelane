import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_info_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../data/business_lead_repository.dart';

/// Luxelane para Empresas: qué ofrecemos y formulario de contacto. La
/// solicitud llega al panel admin.
class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String _travellers = '1–10';
  bool _sending = false;
  bool _sent = false;

  static const _ranges = ['1–10', '11–50', '51–200', 'Más de 200'];

  @override
  void dispose() {
    for (final c in [_company, _name, _email, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await sl<BusinessLeadRepository>().submit(
        company: _company.text,
        contactName: _name.text,
        email: _email.text,
        phone: _phone.text,
        travellers: _travellers,
        message: _message.text,
      );
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        showLuxSnackbar(
            context, 'No pudimos enviar tu solicitud. Inténtalo de nuevo.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  @override
  Widget build(BuildContext context) => LuxInfoPage(
        eyebrow: 'Para Empresas',
        title: 'Viajes corporativos, redefinidos.',
        lead: 'Chóferes privados para tu equipo y tus invitados, con '
            'facturación centralizada y un gerente de cuenta. Cuéntanos qué '
            'necesitas y te contactamos en menos de un día hábil.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _OpenAccountCard(),
            const SizedBox(height: LuxSpacing.lg),
            const Text('¿Prefieres que te contactemos?',
                style: LuxTypography.titleMedium),
            const SizedBox(height: LuxSpacing.sm),
            _sent ? _thanks() : _formView(),
          ],
        ),
      );

  Widget _thanks() => LuxCard(
        child: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: LuxColors.success, size: 32),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Text(
                'Gracias, ${_name.text.trim().split(' ').first}. Recibimos tu '
                'solicitud y te escribiremos a ${_email.text.trim()}.',
                style: LuxTypography.bodyLarge),
          ),
        ]),
      );

  Widget _formView() => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final b in const [
              'Facturación mensual centralizada para tu empresa',
              'Gerente de cuenta dedicado',
              'Reservas prioritarias para ejecutivos e invitados',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.check_rounded, size: 18, color: LD.sph),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: bodyText(size: 14.5))),
                ]),
              ),
            const SizedBox(height: 24),
            LuxTextField(
                label: 'Empresa', controller: _company, validator: _required),
            const SizedBox(height: 14),
            LuxTextField(
                label: 'Tu nombre', controller: _name, validator: _required),
            const SizedBox(height: 14),
            LuxTextField(
              label: 'Correo de trabajo',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final e = v?.trim() ?? '';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)
                    ? null
                    : 'Escribe un correo válido';
              },
            ),
            const SizedBox(height: 14),
            LuxTextField(
                label: 'Teléfono',
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: _required),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _travellers,
              decoration: const InputDecoration(
                  labelText: '¿Cuántas personas viajarían?'),
              items: [
                for (final r in _ranges)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _travellers = v ?? _travellers),
            ),
            const SizedBox(height: 14),
            LuxTextField(
                label: 'Cuéntanos qué necesitas (opcional)',
                controller: _message,
                maxLines: 4),
            const SizedBox(height: 24),
            LuxButton(
                label: 'Enviar solicitud',
                loading: _sending,
                onPressed: _sending ? null : _submit),
          ],
        ),
      );
}

/// Alta directa de la cuenta de empresa (equipo, límites y extracto
/// mensual). Si el usuario ya pertenece a una empresa, lleva a su panel.
class _OpenAccountCard extends StatelessWidget {
  const _OpenAccountCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final hasCompany = auth is AuthAuthenticated && auth.user.companyId != null;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              hasCompany ? 'Tu cuenta de empresa' : 'Abre tu cuenta de empresa',
              style: LuxTypography.titleMedium),
          const SizedBox(height: 6),
          Text(
            hasCompany
                ? 'Gestiona tu equipo, los límites y los extractos mensuales.'
                : 'Registra la empresa, invita a tu equipo con límites por '
                    'persona y recibe un solo extracto al mes con cada viaje.',
            style: LuxTypography.bodyMedium
                .copyWith(color: LuxColors.inkSecondary),
          ),
          const SizedBox(height: LuxSpacing.md),
          LuxButton(
            label: hasCompany ? 'Ir a mi empresa' : 'Abrir cuenta de empresa',
            onPressed: () =>
                context.go(hasCompany ? '/empresa' : '/empresas/registro'),
          ),
        ],
      ),
    );
  }
}
