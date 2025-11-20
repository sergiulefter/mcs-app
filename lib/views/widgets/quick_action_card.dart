import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// A reusable card widget for quick actions with icon, title, and description.
///
/// Designed to be used in a Row with other QuickActionCards wrapped in Expanded.
/// Features touch feedback, shadow, and consistent styling.
///
/// Example:
/// ```dart
/// Row(
///   children: [
///     Expanded(
///       child: QuickActionCard(
///         icon: Icons.medical_services_outlined,
///         title: 'Request Opinion',
///         description: 'Get a second opinion',
///         color: Theme.of(context).colorScheme.primary,
///         onTap: () => Navigator.push(...),
///       ),
///     ),
///     SizedBox(width: AppTheme.spacing16),
///     Expanded(
///       child: QuickActionCard(
///         icon: Icons.search_outlined,
///         title: 'Browse Doctors',
///         description: 'Find specialists',
///         color: Theme.of(context).colorScheme.secondary,
///         onTap: () => Navigator.push(...),
///       ),
///     ),
///   ],
/// )
/// ```
class QuickActionCard extends StatelessWidget {
  /// The icon to display in the colored container.
  final IconData icon;

  /// The main title text.
  final String title;

  /// The description text below the title.
  final String description;

  /// The accent color for the icon and its background.
  final Color color;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Optional: Custom icon size (defaults to iconLarge - 32px).
  final double? iconSize;

  /// Optional: Custom container size for the icon (defaults to 48px).
  final double? iconContainerSize;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.iconSize,
    this.iconContainerSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? AppTheme.iconLarge;
    final effectiveContainerSize = iconContainerSize ?? 48.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall * 1.5),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    blurRadius: AppTheme.elevationLow,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: effectiveContainerSize,
              height: effectiveContainerSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: effectiveIconSize,
                color: color,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(),
            ),
          ],
        ),
      ),
    );
  }
}
