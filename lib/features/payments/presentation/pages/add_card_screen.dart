import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
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
      showLuxSnackbar(context, 'Enter complete card details', isError: true);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    if (user.stripeCustomerId == null || user.stripeCustomerId!.isEmpty) {
      showLuxSnackbar(context, 'Account not set up for payments', isError: true);
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
      if (mounted) {
        setState(() => _loading = false);
        showLuxSnackbar(context, e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is CardOperationSuccess) {
          setState(() => _loading = false);
          showLuxSnackbar(context, 'Card added successfully');
          context.pop();
        }
        if (state is PaymentError) {
          setState(() => _loading = false);
          showLuxSnackbar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Payment Method'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Card Details'),
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
              const Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 14, color: LuxColors.whiteTertiary),
                  SizedBox(width: LuxSpacing.xs),
                  Text(
                    'Secured by Stripe · PCI DSS compliant',
                    style: LuxTypography.caption,
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.xl),
              LuxButton(
                label: 'Add Card',
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
