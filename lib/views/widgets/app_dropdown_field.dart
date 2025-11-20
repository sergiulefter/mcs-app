import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_theme.dart';

/// A reusable dropdown field widget with external label and translation support.
///
/// Supports automatic translation of items using a key prefix.
/// Items can be translation keys that get resolved with .tr().
///
/// Example:
/// ```dart
/// AppDropdownField(
///   label: 'Sex',
///   hintText: 'Select your biological sex',
///   value: _selectedSex,
///   items: ['male', 'female'],
///   translationPrefix: 'profile',
///   prefixIcon: Icons.wc_outlined,
///   onChanged: (value) {
///     setState(() => _selectedSex = value);
///   },
///   validator: (value) {
///     if (value == null) return 'Please select your sex';
///     return null;
///   },
/// )
/// ```
class AppDropdownField extends StatelessWidget {
  /// The label text displayed above the field.
  final String label;

  /// The hint text displayed when no value is selected.
  final String hintText;

  /// The currently selected value (can be null).
  final String? value;

  /// The list of items (can be translation keys or raw strings).
  final List<String> items;

  /// Callback when a value is selected.
  final ValueChanged<String?> onChanged;

  /// Optional: Prefix for translation keys (e.g., 'profile' for 'profile.male').
  final String? translationPrefix;

  /// Optional: Prefix icon for the field.
  final IconData? prefixIcon;

  /// Optional: Validator function for form validation.
  final FormFieldValidator<String>? validator;

  /// Optional: Whether the field is optional (shows indicator).
  final bool isOptional;

  /// Optional: Text for the optional indicator.
  final String? optionalText;

  /// Optional: Custom display text builder for items.
  final String Function(String item)? itemTextBuilder;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.translationPrefix,
    this.prefixIcon,
    this.validator,
    this.isOptional = false,
    this.optionalText,
    this.itemTextBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (isOptional) ...[
              const SizedBox(width: AppTheme.spacing8),
              Text(
                optionalText ?? '(Optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        // Dropdown Field
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                  )
                : null,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(_getItemDisplayText(item)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  String _getItemDisplayText(String item) {
    // Use custom builder if provided
    if (itemTextBuilder != null) {
      return itemTextBuilder!(item);
    }

    // Use translation prefix if provided
    if (translationPrefix != null) {
      return '$translationPrefix.$item'.tr();
    }

    // Return raw item
    return item;
  }
}
