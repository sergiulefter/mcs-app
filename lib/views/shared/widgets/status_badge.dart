import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/badge_colors.dart';

/// Unified status badge widget with muted, professional styling.
///
/// Displays consultation status with an icon and text label using
/// the app's badge color system. Each status has a unique icon
/// to ensure accessibility (not relying on color alone).
///
/// Usage:
/// ```dart
/// StatusBadge(status: consultation.status)
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  /// The consultation status string (pending, in_review, info_requested, completed, cancelled)
  final String status;

  @override
  Widget build(BuildContext context) {
    final badgeColors = Theme.of(context).extension<AppBadgeColors>();
    if (badgeColors == null) {
      // Fallback if extension not registered
      return _buildFallback(context);
    }

    final style = badgeColors.forStatus(status);
    final statusLabel = 'common.status.$status'.tr();

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
            semanticLabel: statusLabel,
          ),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.text,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'common.status.$status'.tr(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
