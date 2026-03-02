import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';

class AppEmptyHint extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const AppEmptyHint({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: SoftDecorations.floatingCard(
            color: SoftPalette.surface.withValues(alpha: 0.92),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: SoftPalette.textSecondary),
          ),
        ),
      ),
    );
  }
}
