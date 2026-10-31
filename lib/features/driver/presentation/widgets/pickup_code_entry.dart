import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/config/remote_flags.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/driver_bloc.dart';

/// Abre la pantalla del código para [booking]. Al verificarse se cierra y
/// el viaje pasa a «Verificada»: entonces aparece «Iniciar viaje».
Future<void> showPickupCodeEntry(BuildContext context, Booking booking) {
  final bloc = context.read<DriverBloc>();
  final repo = sl<TripFlowRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: LuxColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
    ),
    builder: (sheet) => ValueListenableBuilder<String?>(
      valueListenable: RemoteFlags.instance.dispatchPhone,
      builder: (_, phone, __) => PickupCodeEntry(
        locked: booking.pickupLocked,
        dispatchPhone: phone,
        onVerify: (code) => repo.verifyPickup(
          bookingId: booking.id,
          code: code,
          location: bloc.lastLocation,
        ),
        onVerified: () => Navigator.of(sheet).pop(),
      ),
    ),
  );
}

/// «Llamar a central»: solo con el número que puso el responsable en
/// config/global.dispatchPhone.
class CallDispatchButton extends StatelessWidget {
  const CallDispatchButton({super.key, required this.phone, this.onCall});

  final String? phone;
  final void Function(String phone)? onCall;

  @override
  Widget build(BuildContext context) {
    final p = phone;
    if (p == null || p.isEmpty) return const SizedBox.shrink();
    return LuxOutlinedButton(
      label: context.l10n.driverCallDispatch,
      icon: Icons.support_agent_rounded,
      onPressed: () =>
          onCall != null ? onCall!(p) : launchUrl(Uri(scheme: 'tel', path: p)),
    );
  }
}

/// El chófer escribe los 4 dígitos que le dicta el pasajero. Cinco códigos
/// incorrectos bloquean la verificación (lo decide el servidor).
class PickupCodeEntry extends StatefulWidget {
  const PickupCodeEntry({
    super.key,
    required this.onVerify,
    this.onVerified,
    this.dispatchPhone,
    this.onCallDispatch,
    this.locked = false,
  });

  final Future<Either<Failure, void>> Function(String code) onVerify;
  final VoidCallback? onVerified;
  final String? dispatchPhone;
  final void Function(String phone)? onCallDispatch;

  /// La reserva ya llegó bloqueada (pickupLocked).
  final bool locked;

  @override
  State<PickupCodeEntry> createState() => _PickupCodeEntryState();
}

class _PickupCodeEntryState extends State<PickupCodeEntry>
    with SingleTickerProviderStateMixin {
  static const _length = 4;

  String _digits = '';
  bool _busy = false;
  bool _verified = false;
  TripFailure? _error;
  late TripFailure? _blocked = widget.locked
      ? TripFailure(TripIssue.locked, L10n.current.driverCodeLockedSecurity)
      : null;

  // Se crea al montar: si se creara al primer uso, cerrar la hoja sin
  // haber fallado lo crearía en dispose().
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _press(String key) {
    if (_busy || _verified || _blocked != null) return;
    LuxHaptics.tap();
    setState(() {
      _error = null;
      if (key == '⌫') {
        if (_digits.isNotEmpty) {
          _digits = _digits.substring(0, _digits.length - 1);
        }
      } else if (_digits.length < _length) {
        _digits += key;
      }
    });
    if (_digits.length == _length) _submit();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await widget.onVerify(_digits);
    if (!mounted) return;
    final failure = result.fold((f) => f, (_) => null);
    if (failure == null) {
      LuxHaptics.success();
      setState(() {
        _busy = false;
        _verified = true;
      });
      // Un instante para ver el visto bueno antes de volver al viaje.
      final pause = LuxMotion.reduced(context)
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 1100);
      Timer(pause, () {
        if (mounted) widget.onVerified?.call();
      });
      return;
    }
    LuxHaptics.warning();
    final f = failure is TripFailure
        ? failure
        : TripFailure(TripIssue.other, failure.message);
    setState(() {
      _busy = false;
      switch (f.issue) {
        case TripIssue.locked:
        case TripIssue.expired:
        case TripIssue.unavailable:
        case TripIssue.notAllowed:
          _blocked = f;
        case TripIssue.network:
          // Se conservan los dígitos: reintentar no cuenta como fallo.
          _error = f;
        default:
          _error = f;
          _digits = '';
      }
    });
    if (f.issue == TripIssue.wrongCode && !LuxMotion.reduced(context)) {
      unawaited(_shake.forward(from: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = LuxMotion.of(context, LuxMotion.base);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuxSpacing.lg,
        LuxSpacing.lg,
        LuxSpacing.lg,
        LuxSpacing.xl,
      ),
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: LuxMotion.decelerate,
        switchOutCurve: LuxMotion.accelerate,
        child: _verified
            ? const _Verified(key: ValueKey('ok'))
            : _blocked != null
                ? _Blocked(
                    key: const ValueKey('blocked'),
                    failure: _blocked!,
                    dispatchPhone: widget.dispatchPhone,
                    onCallDispatch: widget.onCallDispatch,
                  )
                : _entry(context),
      ),
    );
  }

  Widget _entry(BuildContext context) => Column(
        key: const ValueKey('entry'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.driverCodeAsk,
            style: LuxTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuxSpacing.xs),
          Text(
            context.l10n.driverCodeHint,
            textAlign: TextAlign.center,
            style:
                LuxTypography.caption.copyWith(color: LuxColors.inkSecondary),
          ),
          const SizedBox(height: LuxSpacing.lg),
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 4) * 8 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Semantics(
              label: context.l10n.driverCodeSemantics(_digits.length, _length),
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _length; i++)
                    _Slot(
                      digit: i < _digits.length ? _digits[i] : null,
                      active: i == _digits.length && !_busy,
                      error: _error?.issue == TripIssue.wrongCode,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: LuxSpacing.md),
          SizedBox(
            height: 40,
            child: Center(
              child: _busy
                  ? const LuxLoadingDots(color: LuxColors.sapphire)
                  : _error != null
                      ? Text(
                          _error!.message,
                          textAlign: TextAlign.center,
                          style: LuxTypography.bodyMedium.copyWith(
                            color: LuxColors.error,
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
          if (_error?.issue == TripIssue.network &&
              _digits.length == _length) ...[
            LuxOutlinedButton(
              label: context.l10n.driverRetry,
              icon: Icons.refresh_rounded,
              height: 46,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: LuxSpacing.sm),
          ],
          _Keypad(onKey: _press, enabled: !_busy),
        ],
      );
}

class _Slot extends StatelessWidget {
  const _Slot({this.digit, this.active = false, this.error = false});
  final String? digit;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: LuxMotion.of(context, LuxMotion.fast),
        width: 56,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LuxColors.surfaceMuted,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
          border: Border.all(
            width: active || error ? 2 : 1,
            color: error
                ? LuxColors.error
                : active
                    ? LuxColors.sapphire
                    : LuxColors.border,
          ),
        ),
        child: Text(
          digit ?? '',
          style: LuxTypography.headlineLarge.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, required this.enabled});
  final void Function(String key) onKey;
  final bool enabled;

  static const _keys = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    '', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2,
        mainAxisSpacing: LuxSpacing.sm,
        crossAxisSpacing: LuxSpacing.sm,
        children: [
          for (final k in _keys)
            k.isEmpty
                ? const SizedBox.shrink()
                : Semantics(
                    button: true,
                    label: k == '⌫' ? context.l10n.driverCodeDelete : k,
                    excludeSemantics: true,
                    child: Material(
                      color: LuxColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(LuxRadius.sm),
                      child: InkWell(
                        key: ValueKey('key-$k'),
                        borderRadius: BorderRadius.circular(LuxRadius.sm),
                        onTap: enabled ? () => onKey(k) : null,
                        child: Center(
                          child: k == '⌫'
                              ? const Icon(
                                  Icons.backspace_outlined,
                                  color: LuxColors.ink,
                                )
                              : Text(k, style: LuxTypography.headlineMedium),
                        ),
                      ),
                    ),
                  ),
        ],
      );
}

class _Verified extends StatelessWidget {
  const _Verified({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: LuxSpacing.lg),
          const LuxSuccessMark(),
          const SizedBox(height: LuxSpacing.md),
          Text(
            context.l10n.driverCodeVerified,
            style: LuxTypography.titleLarge,
          ),
          const SizedBox(height: LuxSpacing.xs),
          Text(
            context.l10n.driverCodeVerifiedHint,
            style: LuxTypography.caption,
          ),
          const SizedBox(height: LuxSpacing.lg),
        ],
      );
}

class _Blocked extends StatelessWidget {
  const _Blocked({
    super.key,
    required this.failure,
    this.dispatchPhone,
    this.onCallDispatch,
  });

  final TripFailure failure;
  final String? dispatchPhone;
  final void Function(String phone)? onCallDispatch;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            failure.issue == TripIssue.expired
                ? Icons.schedule_rounded
                : Icons.lock_outline_rounded,
            size: 40,
            color: LuxColors.inkSecondary,
          ),
          const SizedBox(height: LuxSpacing.md),
          Text(
            context.l10n.driverCodeContactDispatch,
            textAlign: TextAlign.center,
            style: LuxTypography.titleLarge,
          ),
          const SizedBox(height: LuxSpacing.xs),
          Text(
            failure.message,
            textAlign: TextAlign.center,
            style: LuxTypography.bodyMedium,
          ),
          const SizedBox(height: LuxSpacing.lg),
          CallDispatchButton(phone: dispatchPhone, onCall: onCallDispatch),
        ],
      );
}
