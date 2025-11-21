import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// A compact onboarding card for empty states with icon, title, and description.
///
/// Used to guide users when a section has no data yet.
/// More compact than full empty states, suitable for dashboard sections.
///
/// Example:
/// ```dart
/// OnboardingCard(
///   icon: Icons.assignment_outlined,
///   title: 'No consultations yet',
///   description: 'Your consultations will appear here',
/// )
/// ```
class OnboardingCard extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The title text.
  final String title;

  /// The description text.
  final String description;

  /// Optional action button text.
  final String? actionText;

  /// Optional action callback when button is tapped.
  final VoidCallback? onActionTap;

  const OnboardingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing20,
        vertical: AppTheme.spacing24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
            ),
            child: Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          // Optional action button
          if (actionText != null && onActionTap != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            TextButton(
              onPressed: onActionTap,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}
