import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
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
          showLuxSnackbar(context, context.l10n.paymentsError, isError: true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.paymentsMethodsTitle),
            leading: IconButton(
              tooltip: context.l10n.commonBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => context.push('/payment/add'),
                icon: const Icon(Icons.add, size: 18, color: LuxColors.accent),
                label: Text(
                  context.l10n.paymentsAdd.toUpperCase(),
                  style: LuxTypography.labelLarge
                      .copyWith(color: LuxColors.accent, fontSize: 11),
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
          SectionHeader(title: context.l10n.paymentsSavedCards),
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
            label: context.l10n.paymentsAddNewCard,
            onPressed: () => context.push('/payment/add'),
            icon: Icons.add,
          ),
          const SizedBox(height: LuxSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 14, color: LuxColors.whiteTertiary),
              const SizedBox(width: LuxSpacing.xs),
              Flexible(
                child: Text(context.l10n.paymentsSecured,
                    style: LuxTypography.caption),
              ),
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
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card_outlined,
                  size: 48, color: LuxColors.whiteTertiary),
              const SizedBox(height: LuxSpacing.md),
              Text(context.l10n.paymentsEmptyTitle,
                  style: LuxTypography.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: LuxSpacing.sm),
              Text(context.l10n.paymentsEmptyBody,
                  style: LuxTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: LuxSpacing.xl),
              LuxButton(label: context.l10n.paymentsAddCard, onPressed: onAdd),
            ],
          ),
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
  Widget build(BuildContext context) {
    final l = context.l10n;
    final brand = _capitalize(card['brand'] as String? ?? l.paymentsCardFallback);
    final last4 = card['last4'] ?? '****';
    final month = '${card['expMonth'] ?? ''}'.padLeft(2, '0');
    final year = '${card['expYear'] ?? ''}';
    return LuxCard(
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
                  color: LuxColors.accent, size: 20),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$brand •••• $last4',
                    style: LuxTypography.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l.paymentsCardExpires(month, year),
                    style: LuxTypography.caption,
                  ),
                  const SizedBox(height: LuxSpacing.xs),
                  // Below the card details so long labels (en/pt) never
                  // squeeze the row on narrow phones.
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: LuxSpacing.sm, vertical: LuxSpacing.xs),
                      decoration: BoxDecoration(
                        color: LuxColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(LuxRadius.sm),
                      ),
                      child: Text(l.paymentsDefault.toUpperCase(),
                          style: LuxTypography.caption
                              .copyWith(color: LuxColors.success)),
                    )
                  else
                    TextButton(
                      onPressed: onSetDefault,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(l.paymentsSetDefault.toUpperCase()),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.paymentsRemoveCard,
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: LuxColors.error),
              onPressed: onRemove,
            ),
          ],
        ),
      );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
