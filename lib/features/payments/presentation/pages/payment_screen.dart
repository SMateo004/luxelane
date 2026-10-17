import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
    context
        .read<PaymentBloc>()
        .add(CardsLoadRequested(stripeCustomerId: customerId));
  }

  /// Stripe solo está configurado en la app móvil.
  void _addCard() {
    if (kIsWeb) {
      showLuxSnackbar(context,
          'Agrega tus tarjetas desde la app de Luxelane en tu teléfono.');
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
            'Dejará de estar disponible para tus próximas reservas.'),
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
        if (state is PaymentError) {
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton.icon(
                onPressed: _addCard,
                icon:
                    const Icon(Icons.add, size: 18, color: LuxColors.sapphire),
                label: Text(
                  'AGREGAR',
                  style: LuxTypography.labelLarge
                      .copyWith(color: LuxColors.sapphire, fontSize: 11),
                ),
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(PaymentState state) {
    if (state is PaymentLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CardsLoaded) {
      if (state.cards.isEmpty) {
        return _EmptyCards(onAdd: _addCard);
      }
      return ListView(
        padding: const EdgeInsets.all(LuxSpacing.md),
        children: [
          const SectionHeader(title: 'Tarjetas guardadas'),
          const SizedBox(height: LuxSpacing.md),
          ...state.cards.map(
            (card) => _CardTile(
              card: card,
              isDefault: card['isDefault'] == true,
              onSetDefault: () => context
                  .read<PaymentBloc>()
                  .add(DefaultCardSet(paymentMethodId: card['id'] as String)),
              onRemove: () => _removeCard(card['id'] as String),
            ),
          ),
          const SizedBox(height: LuxSpacing.lg),
          LuxOutlinedButton(
            label: 'Agregar nueva tarjeta',
            onPressed: _addCard,
            icon: Icons.add,
          ),
          const SizedBox(height: LuxSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: LuxColors.inkTertiary),
              SizedBox(width: LuxSpacing.xs),
              Text('Protegido por Stripe', style: LuxTypography.caption),
            ],
          ),
        ],
      );
    }

    // No Stripe customer yet
    return _EmptyCards(onAdd: _addCard);
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_outlined,
                size: 48, color: LuxColors.inkTertiary),
            const SizedBox(height: LuxSpacing.md),
            const Text('Sin métodos de pago', style: LuxTypography.titleMedium),
            const SizedBox(height: LuxSpacing.sm),
            const Text('Agrega una tarjeta para reservar viajes',
                style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.xl),
            LuxButton(label: 'Agregar tarjeta', onPressed: onAdd),
          ],
        ),
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

  @override
  Widget build(BuildContext context) => LuxCard(
        selected: isDefault,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 30,
              decoration: BoxDecoration(
                color: LuxColors.surfaceMuted,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: const Icon(Icons.credit_card_outlined,
                  color: LuxColors.sapphire, size: 20),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_capitalize(card['brand'] as String? ?? 'Tarjeta')} •••• ${card['last4'] ?? '****'}',
                    style: LuxTypography.bodyLarge,
                  ),
                  Text(
                    'Vence ${card['expMonth']}/${card['expYear']}',
                    style: LuxTypography.caption,
                  ),
                ],
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: LuxSpacing.sm, vertical: LuxSpacing.xs),
                decoration: BoxDecoration(
                  color: LuxColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                ),
                child: Text('PREDETERMINADA',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.success)),
              )
            else
              TextButton(
                onPressed: onSetDefault,
                child: const Text('PREDETERMINAR'),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: LuxColors.error),
              onPressed: onRemove,
            ),
          ],
        ),
      );

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
