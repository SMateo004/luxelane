import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';

class SectionChip extends StatelessWidget {
  const SectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: LuxSpacing.lg, vertical: LuxSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? LuxColors.sapphire : LuxColors.blackElevated,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? LuxColors.sapphire : LuxColors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: LuxTypography.bodyMedium.copyWith(
              color: selected ? LuxColors.black : LuxColors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
}

class AdminNavItem extends StatelessWidget {
  const AdminNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        selected: selected,
        onTap: onTap,
        leading: Icon(icon, color: selected ? LuxColors.sapphire : LuxColors.whiteTertiary),
        title: Text(label,
            style: LuxTypography.bodyLarge.copyWith(
              color: selected ? LuxColors.sapphire : LuxColors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
        dense: true,
      );
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: LuxColors.sapphire, size: 20),
                const Spacer(),
                if (trend != null && trend!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: LuxSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: LuxColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(LuxRadius.sm),
                    ),
                    child: Text(trend!,
                        style: LuxTypography.caption
                            .copyWith(color: LuxColors.success)),
                  ),
              ],
            ),
            const SizedBox(height: LuxSpacing.sm),
            Text(value,
                style: LuxTypography.headlineMedium
                    .copyWith(color: LuxColors.white)),
            Text(label, style: LuxTypography.caption),
          ],
        ),
      );
}
