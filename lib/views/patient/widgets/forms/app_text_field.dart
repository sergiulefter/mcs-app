import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable text field widget with external label and consistent styling.
///
/// Follows the app's design pattern with label above the field, optional
/// prefix icon, and optional "optional" indicator.
///
/// Example:
/// ```dart
/// AppTextField(
///   label: 'Full Name',
///   hintText: 'Enter your full name',
///   controller: _nameController,
///   prefixIcon: Icons.person_outlined,
///   textCapitalization: TextCapitalization.words,
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Name is required';
///     }
///     return null;
///   },
/// )
/// ```
class AppTextField extends StatelessWidget {
  /// The label text displayed above the field.
  final String label;

  /// The hint text displayed inside the field.
  final String hintText;

  /// The controller for the text field.
  final TextEditingController controller;

  /// Optional: Icon to display at the start of the field.
  final IconData? prefixIcon;

  /// Optional: Icon to display at the end of the field.
  final IconData? suffixIcon;

  /// Optional: Callback when suffix icon is tapped.
  final VoidCallback? onSuffixIconTap;

  /// Optional: Focus node to control focus.
  final FocusNode? focusNode;

  /// Optional: Keyboard type for the field.
  final TextInputType? keyboardType;

  /// Optional: Text input action for the field.
  final TextInputAction? textInputAction;

  /// Optional: Text capitalization for the field.
  final TextCapitalization textCapitalization;

  /// Optional: Whether the field obscures text (for passwords).
  final bool obscureText;

  /// Optional: Validator function for form validation.
  final FormFieldValidator<String>? validator;

  /// Optional: Whether the field is optional (shows indicator).
  final bool isOptional;

  /// Optional: Text for the optional indicator (defaults to '(Optional)').
  final String? optionalText;

  /// Optional: Callback when field value changes.
  final ValueChanged<String>? onChanged;

  /// Optional: Callback when submit action is triggered.
  final ValueChanged<String>? onFieldSubmitted;

  /// Optional: Whether the field is enabled.
  final bool enabled;

  /// Optional: Input formatters for the field.
  final List<TextInputFormatter>? inputFormatters;

  /// Optional: Maximum number of lines.
  final int? maxLines;

  /// Optional: Minimum number of lines (for text areas).
  final int? minLines;

  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.validator,
    this.isOptional = false,
    this.optionalText,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
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
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        // Text Field
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          enabled: enabled,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                    ),
                    onPressed: onSuffixIconTap,
                  )
                : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
