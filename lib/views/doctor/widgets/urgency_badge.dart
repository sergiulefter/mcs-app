import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Urgency badge used across doctor flows.
class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.urgency});

  final String urgency;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(context, urgency);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        _urgencyLabel(urgency),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _urgencyLabel(String urgency) {
    switch (urgency) {
      case 'priority':
        return 'common.urgency.priority'.tr();
      default:
        return 'common.urgency.standard'.tr();
    }
  }

  Color _urgencyColor(BuildContext context, String urgency) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    switch (urgency) {
      case 'priority':
        return semantic.warning;
      default:
        return colorScheme.primary;
    }
  }
}
