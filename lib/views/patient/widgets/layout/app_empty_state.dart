import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable empty state widget with theme-aware styling.
///
/// Features:
/// - Theme-aware borders (automatic dark/light mode)
/// - Customizable icon, title, and subtitle
/// - Optional action button
/// - Consistent styling with AppTheme
/// - Professional appearance for "no data" states

class AppEmptyState extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The main title text
  final String title;

  /// The subtitle/description text
  final String subtitle;

  /// Optional icon color (defaults to primary blue)
  final Color? iconColor;

  /// Optional action button widget
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Container(
      padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          // Theme-aware border - automatically adapts to dark/light mode
          border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
            ),
            child: Icon(
              icon,
              size: AppTheme.iconLarge,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          // Optional action button
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacing24),
            action!,
          ],
        ],
      ),
    );
  }
}
