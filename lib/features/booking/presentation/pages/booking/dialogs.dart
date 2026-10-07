part of '../booking_screen.dart';

// ── WEB AUTH GATE DIALOG ──────────────────────────────────────────────────────

class _WebAuthGateDialog extends StatefulWidget {
  const _WebAuthGateDialog();
  @override
  State<_WebAuthGateDialog> createState() => _WebAuthGateDialogState();
}

class _WebAuthGateDialogState extends State<_WebAuthGateDialog> {
  bool _showRegister = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _loading = true);
    if (_showRegister) {
      context.read<AuthBloc>().add(RegisterRequested(
            email: email, password: pass,
            displayName: _nameCtrl.text.trim().isNotEmpty
                ? _nameCtrl.text.trim()
                : email.split('@').first,
            phone: '', role: UserRole.rider));
    } else {
      context.read<AuthBloc>().add(LoginRequested(email: email, password: pass));
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthAuthenticated) Navigator.of(ctx).pop(true);
          if (state is AuthError) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: LuxColors.error));
          }
        },
        child: Dialog(
          backgroundColor: LuxColors.blackSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.lg),
            side: const BorderSide(color: LuxColors.blackBorder),
          ),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(LuxSpacing.xxl),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                        _showRegister ? 'Crear una cuenta' : 'Inicia sesión para continuar',
                        style: LuxTypography.headlineLarge.copyWith(fontSize: 24))),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded,
                              color: LuxColors.whiteTertiary)),
                    ]),
                    const SizedBox(height: LuxSpacing.sm),
                    Text(
                      _showRegister
                          ? 'Crea tu cuenta de Luxelane para completar la reserva.'
                          : 'Inicia sesión para confirmar tu reserva.',
                      style: LuxTypography.bodyMedium),
                    const SizedBox(height: LuxSpacing.xl),
                    if (_showRegister) ...[
                      LuxTextField(label: 'Nombre completo', hint: 'Tu nombre',
                          prefixIcon: Icons.person_outline,
                          controller: _nameCtrl, onChanged: (_) {}),
                      const SizedBox(height: LuxSpacing.md),
                    ],
                    LuxTextField(label: 'Correo electrónico', hint: 'tu@ejemplo.com',
                        prefixIcon: Icons.email_outlined, controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress, onChanged: (_) {}),
                    const SizedBox(height: LuxSpacing.md),
                    LuxTextField(label: 'Contraseña', hint: '••••••••',
                        prefixIcon: Icons.lock_outline, controller: _passCtrl,
                        obscureText: _obscure, onChanged: (_) {},
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: LuxColors.whiteTertiary, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )),
                    const SizedBox(height: LuxSpacing.xl),
                    LuxButton(label: _showRegister ? 'Crear cuenta' : 'Iniciar sesión',
                        loading: _loading, onPressed: _loading ? null : _submit),
                    const SizedBox(height: LuxSpacing.md),
                    TextButton(
                      onPressed: () => setState(() => _showRegister = !_showRegister),
                      child: Text(
                        _showRegister
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Crear una',
                        style: LuxTypography.bodyMedium.copyWith(color: LD.accent)),
                    ),
                  ]),
            ),
          ),
        ),
      );
}

// ── ADD GUEST DIALOG ──────────────────────────────────────────────────────────

InputDecoration _guestFieldDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(
    fontFamily: kSans,
    fontSize: 15,
    color: _kTextTertiary,
    fontWeight: FontWeight.w400,
  ),
  border: const UnderlineInputBorder(
      borderSide: BorderSide(color: _kBorder)),
  enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: _kBorder)),
  focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: _kTextPrimary, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(vertical: 10),
  filled: false,
  isDense: false,
);

const _kGuestValueStyle = TextStyle(
  fontFamily: kSans,
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: _kTextPrimary,
);

Widget _guestFieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text(
    text,
    style: const TextStyle(
      fontFamily: kSans,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _kTextPrimary,
    ),
  ),
);

class _AddGuestDialog extends StatefulWidget {
  const _AddGuestDialog({
    this.initialTitle     = 'Sr.',
    this.initialFirstName = '',
    this.initialLastName  = '',
    this.initialEmail     = '',
    this.initialPhone     = '',
  });

  final String initialTitle;
  final String initialFirstName;
  final String initialLastName;
  final String initialEmail;
  final String initialPhone;

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  static const _kTitles = ['Sr.', 'Sra.', 'Srta.', 'Dr.', 'Prof.'];

  late String _title;
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _title     = widget.initialTitle;
    _firstCtrl = TextEditingController(text: widget.initialFirstName);
    _lastCtrl  = TextEditingController(text: widget.initialLastName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(<String, String>{
      'title':     _title,
      'firstName': _firstCtrl.text.trim(),
      'lastName':  _lastCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'phone':     _phoneCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Header ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Añadir nuevo invitado',
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder, width: 1.5),
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.close, size: 18, color: _kTextSub),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Description ─────────────────────────────────────────────
              const Text(
                'Ingresa la información de tu invitado y bríndales un servicio premium. '
                'Los mantendremos informados sobre su trayecto durante todo el proceso. '
                'No te preocupes, no compartiremos ninguna información de pago o facturación con ellos.',
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 13,
                  color: _kTextSub,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 30),

              // ── Title dropdown ──────────────────────────────────────────
              _guestFieldLabel('Tratamiento'),
              DropdownButtonFormField<String>(
                value: _title,
                style: _kGuestValueStyle,
                dropdownColor: _kBg,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kTextPrimary, width: 1.5)),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  filled: false,
                  isDense: false,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kTextSub, size: 22),
                items: _kTitles.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: _kGuestValueStyle),
                )).toList(),
                onChanged: (v) => setState(() => _title = v!),
              ),

              const SizedBox(height: 26),

              // ── First name + Last name ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _guestFieldLabel('Nombre'),
                        TextField(
                          controller: _firstCtrl,
                          style: _kGuestValueStyle,
                          decoration: _guestFieldDecor('Nombre del invitado'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _guestFieldLabel('Apellido'),
                        TextField(
                          controller: _lastCtrl,
                          style: _kGuestValueStyle,
                          decoration: _guestFieldDecor('Apellido del invitado'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ── Email ───────────────────────────────────────────────────
              _guestFieldLabel('Correo electrónico'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: _kGuestValueStyle,
                decoration: _guestFieldDecor('Correo del invitado'),
              ),

              const SizedBox(height: 26),

              // ── Mobile number ───────────────────────────────────────────
              _guestFieldLabel('Número de móvil del invitado'),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: _kGuestValueStyle,
                decoration: _guestFieldDecor('Número de móvil del invitado').copyWith(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined, size: 17, color: _kTextSub),
                        SizedBox(width: 3),
                        Icon(Icons.language, size: 15, color: _kTextSub),
                        SizedBox(width: 3),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 15, color: _kTextSub),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Tu invitado recibirá las notificaciones del trayecto en este número',
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 11,
                  color: _kTextSub,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 30),

              // ── Confirm — right-aligned blue pill ───────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LD.cta,
                    foregroundColor: LD.onCta,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 44, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryAddressRow extends StatelessWidget {
  const _SummaryAddressRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF777777)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBBBBBB),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111111),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
