import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable search bar widget with theme-aware styling.
///
/// Features:
/// - Theme-aware borders (automatic dark/light mode)
/// - Clear button (X) when text is entered
/// - Prefix search icon
/// - Consistent styling with AppTheme
/// - Localized hint text
///
/// Example:
/// ```dart
/// AppSearchBar(
///   controller: _searchController,
///   hintText: 'Search doctors...',
///   onChanged: (value) => setState(() {}),
///   onClear: () {
///     _searchController.clear();
///     setState(() {});
///   },
/// )
/// ```
class AppSearchBar extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;

  /// The hint text displayed when empty
  final String hintText;

  /// Callback when the text changes
  final ValueChanged<String>? onChanged;

  /// Callback when clear button is pressed
  final VoidCallback? onClear;

  /// Optional prefix icon (defaults to search icon)
  final IconData? prefixIcon;

  /// Optional validator for form validation
  final String? Function(String?)? validator;

  /// Whether the field is read-only
  final bool readOnly;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.isNotEmpty;

        return TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon ?? Icons.search_outlined),
            hintText: hintText,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            // Theme-aware borders - automatically adapts to dark/light mode
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            // Show clear button when there's text
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClear ??
                        () {
                          controller.clear();
                          onChanged?.call('');
                        },
                  )
                : null,
          ),
        );
      },
    );
  }
}
