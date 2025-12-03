import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

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
class AppDropdownField extends StatefulWidget {
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
  State<AppDropdownField> createState() => _AppDropdownFieldState();
}

class _AppDropdownFieldState extends State<AppDropdownField> {
  bool _isOpen = false;
  final MenuController _menuController = MenuController();

  String _getItemDisplayText(String item) {
    // Use custom builder if provided
    if (widget.itemTextBuilder != null) {
      return widget.itemTextBuilder!(item);
    }

    // Use translation prefix if provided
    if (widget.translationPrefix != null) {
      return '${widget.translationPrefix}.$item'.tr();
    }

    // Return raw item
    return item;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormField<String>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label Row
            Row(
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (widget.isOptional) ...[
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    widget.optionalText ?? '(Optional)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Custom Dropdown with MenuAnchor for open/close callbacks
            MenuAnchor(
              controller: _menuController,
              onOpen: () => setState(() => _isOpen = true),
              onClose: () => setState(() => _isOpen = false),
              menuChildren: widget.items.map((item) {
                final isSelected = item == widget.value;
                return MenuItemButton(
                  onPressed: () {
                    state.didChange(item);
                    widget.onChanged(item);
                    _menuController.close();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getItemDisplayText(item),
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                );
              }).toList(),
              child: InkWell(
                onTap: () {
                  if (_menuController.isOpen) {
                    _menuController.close();
                  } else {
                    _menuController.open();
                  }
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) {
                    if (states.contains(WidgetState.pressed)) {
                      return colorScheme.onSurface.withValues(alpha: 0.06);
                    }
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)) {
                      return colorScheme.onSurface.withValues(alpha: 0.03);
                    }
                    return null;
                  },
                ),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    border: Border.all(
                      color: state.hasError
                          ? colorScheme.error
                          : Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                      ],
                      Expanded(
                        child: Text(
                          widget.value != null
                              ? _getItemDisplayText(widget.value!)
                              : widget.hintText,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: widget.value == null
                                        ? colorScheme.onSurfaceVariant
                                        : null,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Error text
            if (state.hasError) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                state.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}
