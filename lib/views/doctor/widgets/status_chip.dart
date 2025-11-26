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
    switch (status) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'in_review':
        return Theme.of(context).colorScheme.primary;
      case 'info_requested':
        return AppTheme.warningOrange;
      case 'completed':
        return Theme.of(context).colorScheme.secondary;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'doctor.requests.status.pending'.tr();
      case 'in_review':
        return 'doctor.requests.status.in_review'.tr();
      case 'info_requested':
        return 'doctor.requests.status.info_requested'.tr();
      case 'completed':
        return 'doctor.requests.status.completed'.tr();
      case 'cancelled':
        return 'doctor.requests.status.cancelled'.tr();
      default:
        return status;
    }
  }
}
