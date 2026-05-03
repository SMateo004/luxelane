import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';

class RideTypePage extends StatelessWidget {
  const RideTypePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const LuxelaneWordmark(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LuxSpacing.md),
              const SectionHeader(title: 'Choose Service'),
              const SizedBox(height: LuxSpacing.xl),
              _ServiceCard(
                serviceType: ServiceType.oneWay,
                icon: Icons.arrow_forward_rounded,
                onTap: () => context.go('/booking'),
              ),
              const SizedBox(height: LuxSpacing.md),
              _ServiceCard(
                serviceType: ServiceType.byTheHour,
                icon: Icons.schedule_rounded,
                onTap: () => context.go('/booking'),
              ),
            ],
          ),
        ),
      );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.serviceType,
    required this.icon,
    required this.onTap,
  });

  final ServiceType serviceType;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LuxCard(
        onTap: onTap,
        padding: const EdgeInsets.all(LuxSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: LuxColors.sapphireSubtle,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                border: Border.all(color: LuxColors.sapphire.withOpacity(0.3)),
              ),
              child: Icon(icon, color: LuxColors.sapphire, size: 28),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceType.label, style: LuxTypography.titleLarge),
                  const SizedBox(height: 4),
                  Text(serviceType.description, style: LuxTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: LuxColors.whiteTertiary),
          ],
        ),
      );
}
