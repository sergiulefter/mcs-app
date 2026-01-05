import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Horizontal scrollable pill-style segment filter for patient consultations.
/// Matches the HTML/CSS design with shadow on selected, border on unselected.
class ConsultationSegmentFilter extends StatelessWidget {
  final String selectedSegment;
  final ValueChanged<String> onSegmentChanged;
  final VoidCallback? onFilterTap;
  final int? activeCount;
  final int? completedCount;

  const ConsultationSegmentFilter({
    super.key,
    required this.selectedSegment,
    required this.onSegmentChanged,
    this.onFilterTap,
    this.activeCount,
    this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      child: Row(
        children: [
          _buildPillButton(
            context,
            key: 'active',
            label: 'consultations.segments.active'.tr(),
          ),
          const SizedBox(width: AppTheme.spacing12),
          _buildPillButton(
            context,
            key: 'completed',
            label: 'common.status.completed'.tr(),
          ),
          const SizedBox(width: AppTheme.spacing12),
          _buildPillButton(context, key: 'all', label: 'common.all'.tr()),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onSegmentChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isDark ? AppTheme.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
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
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.slate300 : AppTheme.slate600),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
