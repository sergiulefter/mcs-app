import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// A reusable widget for displaying profile information in a row format.
///
/// Shows an icon, label, and value. Supports "not provided" state with
/// italic styling and tertiary color.
///
/// Example:
/// ```dart
/// ProfileDetailRow(
///   icon: Icons.cake_outlined,
///   label: 'Date of Birth',
///   value: '15 March 1990',
/// )
/// ```
class ProfileDetailRow extends StatelessWidget {
  /// The icon to display in the colored container.
  final IconData icon;

  /// The label text (smaller, tertiary color).
  final String label;

  /// The value text (larger, primary or tertiary if not provided).
  final String value;

  /// Optional: Text to compare against for "not provided" styling.
  /// If [value] equals this, it will be styled as italic/tertiary.
  final String? notProvidedText;

  /// Optional: Custom icon color (defaults to primaryBlue).
  final Color? iconColor;

  /// Optional: Custom icon background color (defaults to primaryBlue with 0.1 opacity).
  final Color? iconBackgroundColor;

  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.notProvidedText,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isNotProvided = notProvidedText != null && value == notProvidedText;
    final effectiveIconColor = iconColor ?? AppTheme.primaryBlue;
    final effectiveIconBgColor = iconBackgroundColor ??
        AppTheme.primaryBlue.withValues(alpha: 0.1);

    return Padding(
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
          // Label and Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: isNotProvided
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
