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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../bloc/payment_bloc.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    _loadCards();
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
        'Agrega tus tarjetas desde la app de Luxelane en tu teléfono.',
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
        title: const Text('¿Quitar esta tarjeta?'),
        content: const Text(
          'Dejará de estar disponible para tus próximas reservas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: LuxColors.error),
            child: const Text('Quitar'),
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

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Métodos de pago'),
            leading: IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Agregar tarjeta',
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
            const SectionHeader(title: 'Tarjetas guardadas'),
            const SizedBox(height: LuxSpacing.sm),
            LuxGroup(
              footer: 'Toca una tarjeta para usarla por defecto al reservar.',
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
              label: 'Agregar tarjeta',
              onPressed: _addCard,
              icon: Icons.add_rounded,
            ),
            const SizedBox(height: LuxSpacing.md),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: LuxColors.inkTertiary,
                ),
                SizedBox(width: LuxSpacing.xs),
                Text(
                  'Pagos cifrados y protegidos por Stripe',
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
        message: 'Paga sin pensarlo.',
        actionLabel: 'Agregar tarjeta',
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

  static String _brand(String? b) => switch (b) {
        'visa' => 'Visa',
        'mastercard' => 'Mastercard',
        'amex' => 'American Express',
        null || '' => 'Tarjeta',
        _ => '${b[0].toUpperCase()}${b.substring(1)}',
      };

  @override
  Widget build(BuildContext context) {
    final exp =
        '${card['expMonth'].toString().padLeft(2, '0')}/${card['expYear'].toString().substring(2)}';
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
                      '${_brand(card['brand'] as String?)} ·· ${card['last4'] ?? '····'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.bodyLarge.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDefault ? 'Predeterminada · vence $exp' : 'Vence $exp',
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
                tooltip: 'Quitar tarjeta',
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
