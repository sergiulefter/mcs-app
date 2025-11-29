import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Status chip for doctor consultation states.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'pending':
        return semantic.warning;
      case 'in_review':
        return colorScheme.primary;
      case 'info_requested':
        return semantic.warning;
      case 'completed':
        return colorScheme.secondary;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'common.status.pending'.tr();
      case 'in_review':
        return 'common.status.in_review'.tr();
      case 'info_requested':
        return 'common.status.info_requested'.tr();
      case 'completed':
        return 'common.status.completed'.tr();
      case 'cancelled':
        return 'common.status.cancelled'.tr();
      default:
        return status;
    }
  }
}
