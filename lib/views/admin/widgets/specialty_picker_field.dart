import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/medical_specialty.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A specialty picker field that opens a searchable bottom sheet.
///
/// Modern alternative to dropdown for large lists (26 specialties).
class SpecialtyPickerField extends StatelessWidget {
  /// The label text displayed above the field.
  final String label;

  /// The hint text displayed when no value is selected.
  final String hintText;

  /// The currently selected specialty (can be null).
  final MedicalSpecialty? value;

  /// Callback when a specialty is selected.
  final ValueChanged<MedicalSpecialty?> onChanged;

  /// Optional: Prefix icon for the field.
  final IconData? prefixIcon;

  /// Optional: Validator function for form validation.
  final FormFieldValidator<MedicalSpecialty>? validator;

  const SpecialtyPickerField({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
  });

  String _getDisplayText(MedicalSpecialty specialty) {
    return 'specialties.${specialty.name}'.tr();
  }

  Future<void> _showPicker(BuildContext context, FormFieldState<MedicalSpecialty> state) async {
    final result = await showModalBottomSheet<MedicalSpecialty>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpecialtyPickerSheet(
        selectedValue: value,
      ),
    );

    if (result != null) {
      state.didChange(result);
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormField<MedicalSpecialty>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<MedicalSpecialty> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Picker trigger button
            InkWell(
              onTap: () => _showPicker(context, state),
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
                    if (prefixIcon != null) ...[
                      Icon(
                        prefixIcon,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                    ],
                    Expanded(
                      child: Text(
                        value != null ? _getDisplayText(value!) : hintText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: value == null
                                  ? colorScheme.onSurfaceVariant
                                  : null,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
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

/// The bottom sheet content for specialty selection.
class _SpecialtyPickerSheet extends StatefulWidget {
  final MedicalSpecialty? selectedValue;

  const _SpecialtyPickerSheet({
    this.selectedValue,
  });

  @override
  State<_SpecialtyPickerSheet> createState() => _SpecialtyPickerSheetState();
}

class _SpecialtyPickerSheetState extends State<_SpecialtyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<MedicalSpecialty> get _filteredSpecialties {
    if (_searchQuery.isEmpty) {
      return MedicalSpecialty.values;
    }

    final query = _searchQuery.toLowerCase();
    return MedicalSpecialty.values.where((specialty) {
      // Search by enum name
      if (specialty.name.toLowerCase().contains(query)) {
        return true;
      }
      // Search by translated name
      final translatedName = 'specialties.${specialty.name}'.tr().toLowerCase();
      return translatedName.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'admin.create_doctor.field_specialty'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'common.search'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Specialty list
          Expanded(
            child: _filteredSpecialties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        Text(
                          'doctors.empty_state_title'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                    ),
                    itemCount: _filteredSpecialties.length,
                    itemBuilder: (context, index) {
                      final specialty = _filteredSpecialties[index];
                      final isSelected = specialty == widget.selectedValue;
                      final displayText = 'specialties.${specialty.name}'.tr();

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(specialty),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        title: Text(
                          displayText,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: colorScheme.primary,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
