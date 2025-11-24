import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable date picker field widget with external label and formatted display.
///
/// Shows a tappable field that opens the Material date picker dialog.
/// Displays the selected date in a formatted string or hint text.
///
/// Example:
/// ```dart
/// AppDatePickerField(
///   label: 'Date of Birth',
///   hintText: 'Select your date of birth',
///   selectedDate: _selectedDate,
///   onDateSelected: (date) {
///     setState(() => _selectedDate = date);
///   },
///   firstDate: DateTime(1900),
///   lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
/// )
/// ```
class AppDatePickerField extends StatelessWidget {
  /// The label text displayed above the field.
  final String label;

  /// The hint text displayed when no date is selected.
  final String hintText;

  /// The currently selected date (can be null).
  final DateTime? selectedDate;

  /// Callback when a date is selected.
  final ValueChanged<DateTime> onDateSelected;

  /// Optional: The earliest selectable date (defaults to 1900).
  final DateTime? firstDate;

  /// Optional: The latest selectable date (defaults to now).
  final DateTime? lastDate;

  /// Optional: The initial date to show in the picker.
  final DateTime? initialDate;

  /// Optional: Custom date format (defaults to 'dd/MM/yyyy').
  final String dateFormat;

  /// Optional: Prefix icon (defaults to calendar icon).
  final IconData? prefixIcon;

  /// Optional: Whether the field is optional (shows indicator).
  final bool isOptional;

  /// Optional: Text for the optional indicator.
  final String? optionalText;

  /// Optional: Error text to display below the field.
  final String? errorText;

  const AppDatePickerField({
    super.key,
    required this.label,
    required this.hintText,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.dateFormat = 'dd/MM/yyyy',
    this.prefixIcon,
    this.isOptional = false,
    this.optionalText,
    this.errorText,
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
        // Date Picker Field
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(
                prefixIcon ?? Icons.calendar_today_outlined,
              ),
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
              ),
              errorText: errorText,
              // Border handled by theme's InputDecorationTheme (theme-aware)
            ),
            child: Text(
              selectedDate != null
                  ? DateFormat(dateFormat).format(selectedDate!)
                  : hintText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selectedDate != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? now;
    final effectiveInitialDate = initialDate ??
        selectedDate ??
        effectiveLastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
