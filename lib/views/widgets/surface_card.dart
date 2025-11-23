import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Consistent surface card used across screens to avoid repeating decoration code.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showShadow;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border:
            borderColor != null ? Border.all(color: borderColor!, width: borderWidth) : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  blurRadius: AppTheme.elevationLow,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
