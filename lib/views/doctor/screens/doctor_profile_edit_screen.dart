import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/specialty_registry.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/patient/widgets/cards/list_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/profile_detail_row.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/admin/widgets/multi_select_chip_field.dart';
import 'package:mcs_app/views/doctor/widgets/skeletons/doctor_profile_edit_skeleton.dart';

/// Doctor profile edit screen - Edit bio, price, languages, education
class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({super.key});

  @override
  State<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorService _doctorService = DoctorService();

  // Form controllers
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();

  // Form state
  List<String> _selectedLanguages = [];
  List<String> _selectedSubspecialties = [];
  List<EducationEntry> _educationEntries = [];

  // Screen state
  DoctorModel? _doctor;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _languagesError;
  String? _educationError;
  String? _subspecialtiesError;

  // Available options
  final List<String> _languageOptions = ['RO', 'EN', 'FR', 'DE', 'HU', 'RU'];

  @override
  void initState() {
    super.initState();
    // Delay data loading to allow route transition animation to complete
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) {
        _loadDoctorData();
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorData() async {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final doctor = await _doctorService.fetchDoctorById(userId);
      if (mounted && doctor != null) {
        setState(() {
          _doctor = doctor;
          _bioController.text = doctor.bio;
          _priceController.text = doctor.consultationPrice > 0
              ? doctor.consultationPrice.toStringAsFixed(0)
              : '';
          _experienceController.text =
              doctor.experienceYears > 0 ? doctor.experienceYears.toString() : '';
          _selectedLanguages = List.from(doctor.languages);
          _selectedSubspecialties = List.from(doctor.subspecialties);
          _educationEntries = List.from(doctor.education);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    // Clear previous errors
    setState(() {
      _languagesError = null;
      _educationError = null;
      _subspecialtiesError = null;
    });

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Custom validation for languages
    if (_selectedLanguages.isEmpty) {
      setState(() {
      _languagesError = 'doctor.profile_edit.validation.languages_required'.tr();
    });
    return;
  }

    if (_selectedSubspecialties.isEmpty) {
      setState(() {
        _subspecialtiesError =
            'doctor.profile_edit.validation.subspecialties_required'.tr();
      });
      return;
    }

    // Custom validation for education
    if (_educationEntries.isEmpty) {
      setState(() {
        _educationError = 'doctor.profile_edit.validation.education_required'.tr();
      });
      return;
    }

    final userId = context.read<AuthController>().currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    // Check if profile was incomplete before this save
    final wasProfileIncomplete = _doctor != null && !_doctor!.isProfileComplete;

    try {
      final updateData = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'consultationPrice': double.tryParse(_priceController.text) ?? 0.0,
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'languages': _selectedLanguages,
        'subspecialties': _selectedSubspecialties,
        'education': _educationEntries.map((e) => e.toMap()).toList(),
      };

      // If completing profile for the first time, auto-set availability to true
      final willBeComplete =
          _bioController.text.trim().isNotEmpty && _educationEntries.isNotEmpty;
      if (wasProfileIncomplete && willBeComplete) {
        updateData['isAvailable'] = true;
      }

      await _doctorService.updateDoctorProfile(userId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('doctor.profile_edit.profile_updated'.tr()),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('doctor.profile_edit.profile_update_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('doctor.profile_edit.title'.tr()),
        ),
        body: const SafeArea(
          child: DoctorProfileEditSkeleton(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.profile_edit.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Read-Only Section
                _buildReadOnlySection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Professional Information Section
                SectionHeader(title: 'doctor.profile_edit.professional_info'.tr()),
                const SizedBox(height: AppTheme.spacing16),
                _buildProfessionalInfoSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Education Section
                _buildEducationSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Subspecialties Section
                SectionHeader(title: 'doctor.profile_edit.subspecialties'.tr()),
                const SizedBox(height: AppTheme.spacing16),
                MultiSelectChipField(
                  label: '',
                  options: SpecialtyRegistry.getSubspecialties(_doctor!.specialty),
                  selectedOptions: _selectedSubspecialties,
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedSubspecialties = selected;
                      _subspecialtiesError = null;
                    });
                  },
                  translationPrefix: 'subspecialties',
                  isRequired: true,
                  isOptional: false,
                  errorText: _subspecialtiesError,
                  optionalText: 'doctor.profile_edit.subspecialties_hint'.tr(),
                ),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Save Button
                _buildSaveButton(context),
                const SizedBox(height: AppTheme.spacing16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outlined,
              size: 20,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'doctor.profile_edit.read_only_section'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'doctor.profile_edit.read_only_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        ListCard(
          padding: EdgeInsets.zero,
          children: [
            ProfileDetailRow(
              icon: Icons.person_outlined,
              label: 'common.full_name'.tr(),
              value: _doctor!.fullName,
            ),
            ProfileDetailRow(
              icon: Icons.email_outlined,
              label: 'common.email'.tr(),
              value: _doctor!.email,
            ),
            ProfileDetailRow(
              icon: Icons.medical_services_outlined,
              label: 'common.specialty'.tr(),
              value: 'specialties.${_doctor!.specialty.name}'.tr(),
            ),
            ProfileDetailRow(
              icon: Icons.work_history_outlined,
              label: 'common.experience'.tr(),
              value: 'common.years_format'.tr(
                namedArgs: {'years': _doctor!.experienceYears.toString()},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio field
        AppTextField(
          label: 'doctor.profile_edit.bio'.tr(),
          hintText: 'doctor.profile_edit.bio_hint'.tr(),
          controller: _bioController,
          prefixIcon: Icons.description_outlined,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'doctor.profile_edit.validation.bio_required'.tr();
            }
            if (value.trim().length < AppConstants.bioMinLength) {
              return 'doctor.profile_edit.validation.bio_too_short'.tr(
                namedArgs: {'min': AppConstants.bioMinLength.toString()},
              );
            }
            if (value.trim().length > AppConstants.bioMaxLength) {
              return 'doctor.profile_edit.validation.bio_too_long'.tr(
                namedArgs: {'max': AppConstants.bioMaxLength.toString()},
              );
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'doctor.profile_edit.bio_helper'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Consultation price field
        AppTextField(
          label: 'doctor.profile_edit.consultation_price'.tr(),
          hintText: '350',
          controller: _priceController,
          prefixIcon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          isOptional: false,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'doctor.profile_edit.validation.price_required'.tr();
            }
            final price = double.tryParse(text);
            if (price == null || price <= 0) {
              return 'validation.invalid_price'.tr();
            }
            if (price > AppConstants.priceMax) {
              return 'validation.price_too_high'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Experience years field
        AppTextField(
          label: 'doctor.profile_edit.experience_years'.tr(),
          hintText: '10',
          controller: _experienceController,
          prefixIcon: Icons.work_history_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          isOptional: false,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'doctor.profile_edit.validation.experience_required'.tr();
            }
            final years = int.tryParse(text);
            if (years == null || years < AppConstants.experienceMinYears || years > AppConstants.experienceMaxYears) {
              return 'doctor.profile_edit.validation.experience_invalid'.tr(
                namedArgs: {
                  'min': AppConstants.experienceMinYears.toString(),
                  'max': AppConstants.experienceMaxYears.toString(),
                },
              );
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Languages selection
        MultiSelectChipField(
          label: 'doctor.profile_edit.languages_spoken'.tr(),
          options: _languageOptions,
          selectedOptions: _selectedLanguages,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedLanguages = selected;
              _languagesError = null;
            });
          },
          translationPrefix: 'languages',
          isRequired: true,
          errorText: _languagesError,
        ),
      ],
    );
  }

  Widget _buildEducationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SectionHeader(title: 'doctor.profile_edit.education_section'.tr()),
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: _showAddEducationDialog,
                icon: const Icon(Icons.add, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('doctor.profile_edit.add_education'.tr()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),

        if (_educationError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    _educationError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
        ],

        if (_educationEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'doctor.profile_edit.validation.education_required'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: _educationEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final education = entry.value;
              return _buildEducationCard(context, education, index);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEducationCard(
      BuildContext context, EducationEntry education, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  education.degree,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  education.institution,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  education.year.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditEducationDialog(index),
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'doctor.profile_edit.edit_education'.tr(),
              ),
              IconButton(
                onPressed: () => _confirmDeleteEducation(index),
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'doctor.profile_edit.delete_education'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(
                'doctor.profile_edit.save_profile'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
      ),
    );
  }

  void _showAddEducationDialog() {
    _showEducationDialog();
  }

  void _showEditEducationDialog(int index) {
    _showEducationDialog(
      existingEntry: _educationEntries[index],
      editIndex: index,
    );
  }

  void _showEducationDialog({
    EducationEntry? existingEntry,
    int? editIndex,
  }) {
    final institutionController =
        TextEditingController(text: existingEntry?.institution ?? '');
    final degreeController =
        TextEditingController(text: existingEntry?.degree ?? '');
    final yearController = TextEditingController(
        text: existingEntry?.year.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          existingEntry != null
              ? 'doctor.profile_edit.edit_education'.tr()
              : 'doctor.profile_edit.add_education'.tr(),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'doctor.profile_edit.institution'.tr(),
                  hintText: 'doctor.profile_edit.institution_hint'.tr(),
                  controller: institutionController,
                  prefixIcon: Icons.business_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'doctor.profile_edit.validation.institution_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                AppTextField(
                  label: 'doctor.profile_edit.degree'.tr(),
                  hintText: 'doctor.profile_edit.degree_hint'.tr(),
                  controller: degreeController,
                  prefixIcon: Icons.school_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'doctor.profile_edit.validation.degree_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                AppTextField(
                  label: 'doctor.profile_edit.year'.tr(),
                  hintText: 'doctor.profile_edit.year_hint'.tr(),
                  controller: yearController,
                  prefixIcon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'doctor.profile_edit.validation.year_required'.tr();
                    }
                    final year = int.tryParse(value);
                    if (year == null ||
                        year < 1950 ||
                        year > DateTime.now().year) {
                      return 'doctor.profile_edit.validation.year_invalid'.tr();
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newEntry = EducationEntry(
                  institution: institutionController.text.trim(),
                  degree: degreeController.text.trim(),
                  year: int.parse(yearController.text.trim()),
                );

                setState(() {
                  if (editIndex != null) {
                    _educationEntries[editIndex] = newEntry;
                  } else {
                    _educationEntries.add(newEntry);
                  }
                  _educationError = null;
                });

                Navigator.of(dialogContext).pop();
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEducation(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('doctor.profile_edit.delete_education'.tr()),
        content: Text('doctor.profile_edit.delete_education_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _educationEntries.removeAt(index);
              });
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
