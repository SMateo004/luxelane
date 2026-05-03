import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/payment_bloc.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _defaultCardId;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        authState.user.stripeCustomerId != null &&
        authState.user.stripeCustomerId!.isNotEmpty) {
      context.read<PaymentBloc>().add(
            CardsLoadRequested(
                stripeCustomerId: authState.user.stripeCustomerId!),
          );
    }
  }

  void _removeCard(String paymentMethodId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    if (authState.user.stripeCustomerId == null) return;

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
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Methods'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => context.push('/payment/add'),
                icon: const Icon(Icons.add, size: 18, color: LuxColors.sapphire),
                label: Text(
                  'ADD',
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
        return _EmptyCards(onAdd: () => context.push('/payment/add'));
      }
      return ListView(
        padding: const EdgeInsets.all(LuxSpacing.md),
        children: [
          const SectionHeader(title: 'Saved Cards'),
          const SizedBox(height: LuxSpacing.md),
          ...state.cards.map(
            (card) => _CardTile(
              card: card,
              isDefault: _defaultCardId == card['id'],
              onSetDefault: () =>
                  setState(() => _defaultCardId = card['id'] as String),
              onRemove: () => _removeCard(card['id'] as String),
            ),
          ),
          const SizedBox(height: LuxSpacing.lg),
          LuxOutlinedButton(
            label: 'Add New Card',
            onPressed: () => context.push('/payment/add'),
            icon: Icons.add,
          ),
          const SizedBox(height: LuxSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 14, color: LuxColors.whiteTertiary),
              SizedBox(width: LuxSpacing.xs),
              Text('Secured by Stripe',
                  style: LuxTypography.caption),
            ],
          ),
        ],
      );
    }

    // No Stripe customer yet
    return _EmptyCards(onAdd: () => context.push('/payment/add'));
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
                size: 48, color: LuxColors.whiteTertiary),
            const SizedBox(height: LuxSpacing.md),
            const Text('No payment methods',
                style: LuxTypography.titleMedium),
            const SizedBox(height: LuxSpacing.sm),
            const Text('Add a card to book rides',
                style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.xl),
            LuxButton(label: 'Add Card', onPressed: onAdd),
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
                color: LuxColors.blackElevated,
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
                    '${_capitalize(card['brand'] as String? ?? 'Card')} •••• ${card['last4'] ?? '****'}',
                    style: LuxTypography.bodyLarge,
                  ),
                  Text(
                    'Expires ${card['expMonth']}/${card['expYear']}',
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
                child: Text('DEFAULT',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.success)),
              )
            else
              TextButton(
                onPressed: onSetDefault,
                child: const Text('SET DEFAULT'),
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
