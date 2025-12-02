import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable filter chip with consistent styling across screens.
class ThemedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final bool hideIconWhenSelected;

  const ThemedFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.hideIconWhenSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedLabelColor = colorScheme.onPrimary;

    return FilterChip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? selectedLabelColor : colorScheme.onSurface,
            ),
      ),
      avatar: icon != null && !(hideIconWhenSelected && selected)
          ? Icon(
              icon,
              size: AppTheme.iconSmall,
              color: selected ? selectedLabelColor : colorScheme.onSurface,
            )
          : null,
      selected: selected,
      onSelected: onSelected,
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      checkmarkColor: selectedLabelColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}
