import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/badge_colors.dart';

/// Urgency indicator badge for consultations.
///
/// Only displays for 'priority' urgency - standard urgency returns
/// an empty widget since it's the default state and doesn't need
/// visual indication.
///
/// Usage:
/// ```dart
/// UrgencyBadge(urgency: consultation.urgency)
/// ```
class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({
    super.key,
    required this.urgency,
  });

  /// The urgency level string (standard, priority)
  final String urgency;

  @override
  Widget build(BuildContext context) {
    // Standard urgency doesn't show a badge - it's the default
    if (urgency != 'priority') {
      return const SizedBox.shrink();
    }

    final badgeColors = Theme.of(context).extension<AppBadgeColors>();
    if (badgeColors == null) {
      return const SizedBox.shrink();
    }

    final style = badgeColors.forUrgency(urgency);
    if (style == null) {
      return const SizedBox.shrink();
    }

    final urgencyLabel = 'common.urgency.$urgency'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: style.text.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            style.icon,
            size: 14,
            color: style.text,
            semanticLabel: urgencyLabel,
          ),
          const SizedBox(width: 4),
          Text(
            urgencyLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.text,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
