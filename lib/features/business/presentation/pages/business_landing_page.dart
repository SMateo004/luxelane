import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/business_repository.dart';
import '../widgets/business_widgets.dart';

/// /empresas — qué ofrece Luxelane para Empresas y alta de la empresa.
class BusinessLandingPage extends StatelessWidget {
  const BusinessLandingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: LuxColors.bg,
        appBar: AppBar(
          title: const LuxelaneWordmark(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/empresas'),
          ),
        ),
        body: BusinessBody(children: [
          Text('LUXELANE PARA EMPRESAS',
              style: LuxTypography.caption
                  .copyWith(color: LuxColors.sapphire, letterSpacing: 2.4)),
          const SizedBox(height: 8),
          const Text('Viajes corporativos,\nuna sola factura al mes.',
              style: LuxTypography.displayMedium),
          const SizedBox(height: 12),
          const Text(
            'Tu equipo reserva chóferes premium con la cuenta de la empresa. '
            'Sin tarjetas personales ni reembolsos: a fin de mes recibes un '
            'extracto con cada viaje y pagas en un solo pago.',
            style: LuxTypography.bodyLarge,
          ),
          const SizedBox(height: LuxSpacing.lg),
          LayoutBuilder(builder: (c, box) {
            final wide = box.maxWidth >= 860;
            const benefits = _Benefits();
            const form = _RegistrationPanel();
            return wide
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: benefits),
                      SizedBox(width: LuxSpacing.lg),
                      Expanded(flex: 6, child: form),
                    ],
                  )
                : const Column(children: [
                    form,
                    SizedBox(height: LuxSpacing.lg),
                    benefits,
                  ]);
          }),
        ]),
      );
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  static const _items = [
    (
      Icons.receipt_long_outlined,
      'Ajuste mensual',
      'El día 1 preparamos el extracto del mes anterior: cada viaje, pasajero, '
          'centro de coste e importe, con tu descuento pactado.'
    ),
    (
      Icons.groups_outlined,
      'Tu equipo, tus reglas',
      'Invita a tus empleados por correo y fija un límite mensual por persona '
          'y un presupuesto para toda la empresa.'
    ),
    (
      Icons.insights_outlined,
      'Gasto en tiempo real',
      'Sigue desde tu panel lo que lleva gastado cada persona este mes.'
    ),
    (
      Icons.verified_outlined,
      'Mismo servicio premium',
      'Chóferes verificados, precio fijo antes de confirmar y seguimiento en '
          'el mapa.'
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (icon, title, body) in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
              child: LuxCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: LuxColors.sapphire),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: LuxTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text(body, style: LuxTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: LuxSpacing.sm),
          const Text('Cómo funciona', style: LuxTypography.titleLarge),
          const SizedBox(height: 8),
          for (final (n, t) in const [
            ('1', 'Registras la empresa con su NIT y datos de facturación.'),
            (
              '2',
              'Nuestro equipo la revisa y la aprueba (normalmente en 1 día hábil).'
            ),
            (
              '3',
              'Invitas a tu equipo; ellos eligen "Cuenta de empresa" al reservar.'
            ),
            (
              '4',
              'Cada mes recibes el extracto y lo pagas dentro del plazo pactado.'
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                    radius: 11,
                    backgroundColor: LuxColors.sapphireTint,
                    child: Text(n,
                        style: LuxTypography.caption
                            .copyWith(color: LuxColors.sapphire))),
                const SizedBox(width: 10),
                Expanded(child: Text(t, style: LuxTypography.bodyMedium)),
              ]),
            ),
        ],
      );
}

/// Alta de la empresa: pide sesión y, si ya hay empresa, lleva al panel.
class _RegistrationPanel extends StatefulWidget {
  const _RegistrationPanel();

  @override
  State<_RegistrationPanel> createState() => _RegistrationPanelState();
}

class _RegistrationPanelState extends State<_RegistrationPanel> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _taxId = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _taxId, _email, _contact, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final r = await sl<BusinessRepository>().registerCompany(
      name: _name.text,
      taxId: _taxId.text,
      billingEmail: _email.text,
      contactName: _contact.text,
      phone: _phone.text,
      address: _address.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (_) {
        showLuxSnackbar(context,
            'Solicitud enviada. Te avisaremos cuando aprobemos tu empresa.');
        context.go('/empresa');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registra tu empresa', style: LuxTypography.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Crea tu cuenta personal (o inicia sesión) y luego completa los '
              'datos de tu empresa. Serás su administrador.',
              style: LuxTypography.bodyMedium,
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxButton(
                label: 'Crear cuenta',
                onPressed: () =>
                    context.go('/register?from=/empresas/registro')),
            const SizedBox(height: 8),
            LuxOutlinedButton(
                label: 'Ya tengo cuenta',
                onPressed: () => context.go('/login?from=/empresas/registro')),
          ],
        ),
      );
    }
    final user = auth.user;
    if (user.companyId != null) {
      return LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ya tienes cuenta de empresa',
                style: LuxTypography.titleLarge),
            const SizedBox(height: 8),
            const Text(
                'Consulta su estado, tu equipo y los extractos en tu panel.',
                style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            LuxButton(
                label: 'Ir a mi empresa',
                onPressed: () => context.go('/empresa')),
          ],
        ),
      );
    }
    if (user.role != UserRole.rider) {
      return const LuxCard(
        child: Text(
            'Las cuentas de empresa se registran desde una cuenta de pasajero.',
            style: LuxTypography.bodyMedium),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyInvitesCard(
            email: user.email,
            emailVerified: sl<BusinessRepository>().emailVerified),
        LuxCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Registra tu empresa',
                    style: LuxTypography.titleLarge),
                const SizedBox(height: 4),
                Text(
                    'Serás el administrador de la cuenta, ${user.displayName}.',
                    style: LuxTypography.caption),
                const SizedBox(height: LuxSpacing.md),
                LuxTextField(
                  label: 'Razón social',
                  controller: _name,
                  prefixIcon: Icons.apartment_outlined,
                  validator: (v) => (v ?? '').trim().length < 2
                      ? 'Indica el nombre de la empresa'
                      : null,
                ),
                const SizedBox(height: 12),
                LuxTextField(
                  label: 'NIT',
                  controller: _taxId,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => RegExp(r'^\d{5,15}$')
                          .hasMatch((v ?? '').replaceAll(' ', ''))
                      ? null
                      : 'El NIT tiene entre 5 y 15 dígitos',
                ),
                const SizedBox(height: 12),
                LuxTextField(
                  label: 'Correo de facturación',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  validator: LuxValidators.email,
                ),
                const SizedBox(height: 12),
                LuxTextField(
                  label: 'Persona de contacto',
                  controller: _contact,
                  prefixIcon: Icons.person_outline,
                  validator: LuxValidators.name,
                ),
                const SizedBox(height: 12),
                LuxTextField(
                  label: 'Teléfono de la empresa',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: LuxValidators.phone,
                ),
                const SizedBox(height: 12),
                LuxTextField(
                  label: 'Dirección fiscal',
                  controller: _address,
                  prefixIcon: Icons.location_city_outlined,
                  validator: (v) => (v ?? '').trim().length < 5
                      ? 'Indica la dirección fiscal'
                      : null,
                ),
                const SizedBox(height: LuxSpacing.lg),
                LuxButton(
                  label: 'Enviar solicitud',
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
