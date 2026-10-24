import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_info_page.dart';
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
  // Campo trampa: fuera de la pantalla y del lector; un bot lo rellena.
  final _website = TextEditingController();
  String _travellers = '1–10';
  bool _sending = false;
  bool _sent = false;

  static const _ranges = ['1–10', '11–50', '51–200', 'Más de 200'];

  @override
  void dispose() {
    for (final c in [_company, _name, _email, _phone, _message, _website]) {
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
        website: _website.text,
      );
      if (mounted) setState(() => _sent = true);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        showLuxSnackbar(
          context,
          businessLeadErrorMessage(e.code, e.details),
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        showLuxSnackbar(
          context,
          'No pudimos enviar tu solicitud. Inténtalo de nuevo.',
          isError: true,
        );
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
        child: _sent ? _thanks() : _formView(),
      );

  Widget _thanks() => LuxCard(
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: LuxColors.success,
              size: 32,
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Text(
                'Gracias, ${_name.text.trim().split(' ').first}. Recibimos tu '
                'solicitud y te escribiremos a ${_email.text.trim()}.',
                style: LuxTypography.bodyLarge,
              ),
            ),
          ],
        ),
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
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: LD.sph),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b, style: bodyText(size: 14.5))),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            LuxTextField(
              label: 'Empresa',
              controller: _company,
              validator: _required,
            ),
            const SizedBox(height: 14),
            LuxTextField(
              label: 'Tu nombre',
              controller: _name,
              validator: _required,
            ),
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
              validator: _required,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _travellers,
              decoration: const InputDecoration(
                labelText: '¿Cuántas personas viajarían?',
              ),
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
              maxLines: 4,
            ),
            Offstage(
              child: ExcludeSemantics(
                child: TextField(
                  key: const ValueKey('lead-website'),
                  controller: _website,
                  enableInteractiveSelection: false,
                ),
              ),
            ),
            const SizedBox(height: 24),
            LuxButton(
              label: 'Enviar solicitud',
              loading: _sending,
              onPressed: _sending ? null : _submit,
            ),
          ],
        ),
      );
}
