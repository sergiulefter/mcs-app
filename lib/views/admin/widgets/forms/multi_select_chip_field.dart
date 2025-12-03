import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable multi-select chip field for selecting multiple options.
/// Used for languages, subspecialties, etc.
class MultiSelectChipField extends StatelessWidget {
  /// Label displayed above the chips
  final String label;

  /// List of available options to select from
  final List<String> options;

  /// Currently selected options
  final List<String> selectedOptions;

  /// Callback when selection changes
  final ValueChanged<List<String>> onSelectionChanged;

  /// Optional translation prefix for option labels
  /// If provided, options will be translated using '$translationPrefix.$option'.tr()
  final String? translationPrefix;

  /// Whether at least one option is required
  final bool isRequired;

  /// Error text to display when validation fails
  final String? errorText;

  /// Whether to show optional text
  final bool isOptional;

  /// Custom optional text
  final String? optionalText;

  const MultiSelectChipField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.translationPrefix,
    this.isRequired = false,
    this.errorText,
    this.isOptional = false,
    this.optionalText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row (only if label is not empty)
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (isOptional) ...[
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  optionalText ?? 'Optional',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],

        // Chips wrap
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            final displayText = translationPrefix != null
                ? '$translationPrefix.$option'.tr()
                : option;

            return FilterChip(
              label: Text(
                displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  // Don't allow deselecting if it's required and only one is selected
                  if (isRequired && newSelection.length == 1) {
                    return;
                  }
                  newSelection.remove(option);
                }
                onSelectionChanged(newSelection);
              },
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              checkmarkColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                side: BorderSide(
                  color: hasError
                      ? colorScheme.error
                      : isSelected
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : Theme.of(context).dividerColor,
                ),
              ),
            );
          }).toList(),
        ),

        // Error text
        if (hasError) ...[
          const SizedBox(height: AppTheme.spacing8),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
          ),
        ],
      ],
    );
  }
}
