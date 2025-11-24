import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A prominent full-width call-to-action button with icon and subtitle.
///
/// Designed to be the primary action on a screen, featuring a large touch target,
/// icon, title, and optional subtitle for additional context.
///
/// Example:
/// ```dart
/// PrimaryCTAButton(
///   icon: Icons.search_outlined,
///   title: 'Browse Doctors',
///   subtitle: 'Find specialists for your medical concerns',
///   onPressed: () => Navigator.push(...),
/// )
/// ```
class PrimaryCTAButton extends StatelessWidget {
  /// The icon to display on the left side.
  final IconData icon;

  /// The main button text.
  final String title;

  /// Optional subtitle text below the title.
  final String? subtitle;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Optional background color (defaults to primary color).
  final Color? backgroundColor;

  /// Optional foreground color (defaults to onPrimary).
  final Color? foregroundColor;

  const PrimaryCTAButton({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fgColor = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: subtitle != null ? AppTheme.buttonHeight + 24 : AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: AppTheme.elevationLow,
          shadowColor: bgColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing20,
            vertical: AppTheme.spacing16,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: AppTheme.iconMedium,
                color: fgColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            // Text content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: fgColor.withValues(alpha: 0.9),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.arrow_forward_rounded,
              size: AppTheme.iconMedium,
              color: fgColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
