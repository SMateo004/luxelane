import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../../domain/card_payment_presenter.dart';
import '../bloc/payment_bloc.dart';

/// Tarjetas guardadas. Mientras la tarjeta no se pueda usar para pagar
/// (sin un CardPaymentPresenter registrado: proveedor sin decidir), no se
/// cargan ni se ofrece agregarlas (E42); vuelve todo al registrarlo.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, this.cardsEnabled});

  /// Para los tests; por defecto, si hay un CardPaymentPresenter registrado.
  final bool? cardsEnabled;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    if (_cardsEnabled) _loadCards();
  }

  Future<void> _loadCards() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    var customerId = authState.user.stripeCustomerId ?? '';
    if (customerId.isEmpty) {
      // El perfil de pagos no se creó al registrarse: se crea ahora.
      final result = await sl<PaymentRepository>().ensureStripeCustomer();
      if (!mounted) return;
      customerId = result.fold((_) => '', (id) => id);
      if (customerId.isEmpty) return;
    }
    context.read<PaymentBloc>().add(
          CardsLoadRequested(stripeCustomerId: customerId),
        );
  }

  /// Stripe solo está configurado en la app móvil.
  void _addCard() {
    if (kIsWeb) {
      showLuxSnackbar(
        context,
        context.l10n.paymentAddCardsOnPhone,
      );
      return;
    }
    context.push('/payment/add');
  }

  Future<void> _removeCard(String paymentMethodId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    if (authState.user.stripeCustomerId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.paymentRemoveCardTitle),
        content: Text(ctx.l10n.paymentRemoveCardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.paymentCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: LuxColors.error),
            child: Text(ctx.l10n.paymentRemove),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    context.read<PaymentBloc>().add(
          CardRemoved(
            stripeCustomerId: authState.user.stripeCustomerId!,
            paymentMethodId: paymentMethodId,
          ),
        );
  }

  bool get _cardsEnabled =>
      widget.cardsEnabled ?? sl.isRegistered<CardPaymentPresenter>();

  @override
  Widget build(BuildContext context) {
    if (!_cardsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.paymentMethodsTitle),
          leading: IconButton(
            tooltip: context.l10n.paymentBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          icon: Icons.payments_outlined,
          message: context.l10n.paymentPerBooking,
        ),
      );
    }
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is CardOperationSuccess) _loadCards();
        if (state is PaymentError && state.message == kReauthRequiredMessage) {
          confirmIdentityThenRetry(context).then((_) => _loadCards());
        } else if (state is PaymentError) {
          showLuxSnackbar(context, state.message, isError: true);
          // Tras un fallo se vuelve a mostrar la lista en vez de vaciarla.
          _loadCards();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.paymentMethodsTitle),
            leading: IconButton(
              tooltip: context.l10n.paymentBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.paymentAddCard,
                onPressed: _addCard,
                icon: const Icon(Icons.add_rounded, color: LuxColors.sapphire),
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  /// Última lista conocida: mientras se guarda un cambio se sigue viendo,
  /// atenuada, en lugar de desaparecer tras una rueda de carga.
  List<Map<String, dynamic>>? _lastCards;

  Widget _buildBody(PaymentState state) {
    if (state is CardsLoaded) _lastCards = state.cards;
    final cards = _lastCards;
    final busy = state is PaymentLoading;

    if (cards == null) {
      return busy
          ? const LuxSkeletonList(count: 2, itemHeight: 72)
          : _EmptyCards(onAdd: _addCard);
    }
    if (cards.isEmpty) return _EmptyCards(onAdd: _addCard);

    return AnimatedOpacity(
      opacity: busy ? 0.55 : 1,
      duration: LuxMotion.of(context, LuxMotion.base),
      child: IgnorePointer(
        ignoring: busy,
        child: ListView(
          padding: const EdgeInsets.all(LuxSpacing.md),
          children: [
            SectionHeader(title: context.l10n.paymentSavedCards),
            const SizedBox(height: LuxSpacing.sm),
            LuxGroup(
              footer: context.l10n.paymentSetDefaultHint,
              children: [
                for (final card in cards)
                  _CardTile(
                    card: card,
                    isDefault: card['isDefault'] == true,
                    onSetDefault: () => context.read<PaymentBloc>().add(
                          DefaultCardSet(paymentMethodId: card['id'] as String),
                        ),
                    onRemove: () => _removeCard(card['id'] as String),
                  ),
              ],
            ),
            const SizedBox(height: LuxSpacing.lg),
            LuxOutlinedButton(
              label: context.l10n.paymentAddCard,
              onPressed: _addCard,
              icon: Icons.add_rounded,
            ),
            const SizedBox(height: LuxSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: LuxColors.inkTertiary,
                ),
                const SizedBox(width: LuxSpacing.xs),
                Text(
                  context.l10n.paymentEncrypted,
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.credit_card_outlined,
        message: context.l10n.paymentEmptyCards,
        actionLabel: context.l10n.paymentAddCard,
        onAction: onAdd,
      );
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.isDefault,
    required this.onSetDefault,
    required this.onRemove,
  });

  final Map<String, dynamic> card;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  static String _brand(BuildContext context, String? b) => switch (b) {
        'visa' => 'Visa', // i18n-ignore: marca de la tarjeta
        'mastercard' => 'Mastercard', // i18n-ignore: marca de la tarjeta
        'amex' => 'American Express', // i18n-ignore: marca de la tarjeta
        null || '' => context.l10n.paymentMethodCard,
        _ => '${b[0].toUpperCase()}${b.substring(1)}',
      };

  @override
  Widget build(BuildContext context) {
    final exp =
        '${card['expMonth'].toString().padLeft(2, '0')}/${card['expYear'].toString().substring(2)}';
    final brand = _brand(context, card['brand'] as String?);
    final last4 = card['last4'] ?? '····';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDefault
            ? null
            : () {
                LuxHaptics.tap();
                onSetDefault();
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 24,
                decoration: BoxDecoration(
                  color: isDefault ? LuxColors.ink : LuxColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  size: 15,
                  color: isDefault ? Colors.white : LuxColors.inkSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$brand ·· $last4',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.bodyLarge.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDefault
                          ? context.l10n.paymentCardDefaultExpires(exp)
                          : context.l10n.paymentCardExpires(exp),
                      style: LuxTypography.caption.copyWith(
                        fontSize: 12,
                        color: isDefault
                            ? LuxColors.sapphire
                            : LuxColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: LuxMotion.of(context, LuxMotion.base),
                child: isDefault
                    ? const Padding(
                        key: ValueKey('on'),
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: LuxColors.sapphire,
                          size: 22,
                        ),
                      )
                    : const SizedBox(key: ValueKey('off'), width: 38),
              ),
              IconButton(
                tooltip: context.l10n.paymentRemoveCard,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: LuxColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
