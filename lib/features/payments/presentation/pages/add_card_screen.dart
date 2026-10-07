import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/payment_bloc.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  CardFieldInputDetails? _cardDetails;
  bool _loading = false;

  Future<void> _submit() async {
    if (_cardDetails == null || !(_cardDetails!.complete)) {
      showLuxSnackbar(context, context.l10n.paymentsCardIncomplete, isError: true);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    if (user.stripeCustomerId == null || user.stripeCustomerId!.isEmpty) {
      showLuxSnackbar(context, context.l10n.paymentsAccountNotSetUp, isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final pm = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (!mounted) return;

      context.read<PaymentBloc>().add(
            CardAdded(
              stripeCustomerId: user.stripeCustomerId!,
              paymentMethodId: pm.id,
            ),
          );
    } catch (e) {
      debugPrint('[AddCard] createPaymentMethod failed: $e');
      if (mounted) {
        setState(() => _loading = false);
        showLuxSnackbar(context, context.l10n.paymentsError, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is CardOperationSuccess) {
          setState(() => _loading = false);
          showLuxSnackbar(context, context.l10n.paymentsCardAdded);
          context.pop();
        }
        if (state is PaymentError) {
          setState(() => _loading = false);
          showLuxSnackbar(context, context.l10n.paymentsError, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.paymentsAddMethodTitle),
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: context.l10n.paymentsCardDetails),
              const SizedBox(height: LuxSpacing.lg),
              Container(
                padding: const EdgeInsets.all(LuxSpacing.sm),
                decoration: BoxDecoration(
                  color: LuxColors.blackElevated,
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                  border: Border.all(color: LuxColors.blackBorder),
                ),
                child: CardField(
                  style: const TextStyle(color: LuxColors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onCardChanged: (card) =>
                      setState(() => _cardDetails = card),
                ),
              ),
              const SizedBox(height: LuxSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: LuxColors.whiteTertiary),
                  const SizedBox(width: LuxSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.paymentsSecuredPci,
                      style: LuxTypography.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.xl),
              LuxButton(
                label: context.l10n.paymentsAddCard,
                onPressed: _loading ? null : _submit,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
