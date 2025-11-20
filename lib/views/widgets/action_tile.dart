import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// A reusable tappable tile with icon, title, subtitle, and chevron.
///
/// Used for action items in settings/account screens. Follows Material
/// design patterns with InkWell for touch feedback.
///
/// Example:
/// ```dart
/// ActionTile(
///   icon: Icons.edit_outlined,
///   title: 'Edit Profile',
///   subtitle: 'Update your personal information',
///   onTap: () => Navigator.push(...),
/// )
/// ```
class ActionTile extends StatelessWidget {
  /// The icon to display in the colored container.
  final IconData icon;

  /// The main title text (larger, bold).
  final String title;

  /// The subtitle/description text (smaller, secondary color).
  final String subtitle;

  /// Callback when the tile is tapped.
  final VoidCallback onTap;

  /// Optional: Custom icon color (defaults to primaryBlue).
  final Color? iconColor;

  /// Optional: Custom icon background color (defaults to primaryBlue with 0.1 opacity).
  final Color? iconBackgroundColor;

  /// Optional: Whether to show the chevron icon (defaults to true).
  final bool showChevron;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final effectiveIconBgColor =
        iconBackgroundColor ?? colorScheme.primary.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: AppTheme.iconMedium,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(),
                  ),
                ],
              ),
            ),
            // Chevron Icon
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
