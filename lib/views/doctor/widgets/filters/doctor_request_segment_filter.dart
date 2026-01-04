import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Horizontal scrollable pill-style segment filter for doctor requests.
class DoctorRequestSegmentFilter extends StatelessWidget {
  final String selectedSegment;
  final ValueChanged<String> onSegmentChanged;
  final VoidCallback? onFilterTap;
  final int? newCount;
  final int? inProgressCount;
  final int? completedCount;

  const DoctorRequestSegmentFilter({
    super.key,
    required this.selectedSegment,
    required this.onSegmentChanged,
    this.onFilterTap,
    this.newCount,
    this.inProgressCount,
    this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPillButton(
              context,
              key: 'new',
              label: 'doctor.requests.segments.new'.tr(),
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildPillButton(
              context,
              key: 'in_progress',
              label: 'doctor.requests.segments.in_progress'.tr(),
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildPillButton(
              context,
              key: 'completed',
              label: 'doctor.requests.segments.completed'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton(
    BuildContext context, {
    required String key,
    required String label,
  }) {
    final isSelected = selectedSegment == key;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onSegmentChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
          border: isSelected
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
