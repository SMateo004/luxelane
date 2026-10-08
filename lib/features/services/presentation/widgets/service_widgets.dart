import 'package:flutter/material.dart';

import '../../../home/presentation/pages/home_design.dart';

/// Cards in [columns] even columns.
class EvenGrid extends StatelessWidget {
  const EvenGrid({super.key, required this.columns, required this.children, this.minHeight = 0});
  final int columns;
  final List<Widget> children;

  /// Keeps cards in a row visually even without measuring intrinsic heights
  /// (which go stale when web fonts load after the first layout).
  final double minHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 16.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: w,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: columns > 1 ? minHeight : 0),
                  child: child,
                ),
              ),
          ],
        );
      });
}

/// "What's included" card: icon, title and a short body.
class IncludedCard extends StatelessWidget {
  const IncludedCard({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: LD.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: LD.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: bodyText(size: 15, color: LD.ink).copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body, style: bodyText(size: 13)),
            ]),
          ),
        ]),
      );
}
