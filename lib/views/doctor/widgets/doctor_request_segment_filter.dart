import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Segmented control
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  _buildSegment(
                    context,
                    key: 'new',
                    label: 'doctor.requests.segments.new'.tr(),
                  ),
                  const SizedBox(width: 6),
                  _buildSegment(
                    context,
                    key: 'in_progress',
                    label: 'common.status.in_review'.tr(),
                  ),
                  const SizedBox(width: 6),
                  _buildSegment(
                    context,
                    key: 'completed',
                    label: 'common.status.completed'.tr(),
                  ),
                ],
              ),
            ),
          ),

          // Filter icon button
          if (onFilterTap != null) ...[
            const SizedBox(width: AppTheme.spacing12),
            IconButton(
              onPressed: onFilterTap,
              icon: Icon(
                Icons.tune,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required String key,
    required String label,
  }) {
    final isSelected = selectedSegment == key;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSegmentChanged(key),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
