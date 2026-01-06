import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/specialty_registry.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/views/doctor/widgets/skeletons/doctor_profile_edit_skeleton.dart';

/// Doctor profile edit screen matching the Stitch HTML/CSS design.
/// Features: Cancel header, avatar section, About Me, Languages, Subspecialties, Education.
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

  // Available options
  final List<String> _languageOptions = ['RO', 'EN', 'FR', 'DE', 'HU', 'RU'];

  @override
  void initState() {
    super.initState();
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) _loadDoctorData();
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
          _experienceController.text = doctor.experienceYears > 0
              ? doctor.experienceYears.toString()
              : '';
          _selectedLanguages = List.from(doctor.languages);
          _selectedSubspecialties = List.from(doctor.subspecialties);
          _educationEntries = List.from(doctor.education);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Custom validations
    if (_selectedLanguages.isEmpty) {
      NotificationsHelper().showError(
        'doctor.profile_edit.validation.languages_required'.tr(),
        context: context,
      );
      return;
    }

    if (_educationEntries.isEmpty) {
      NotificationsHelper().showError(
        'doctor.profile_edit.validation.education_required'.tr(),
        context: context,
      );
      return;
    }

    if (_selectedSubspecialties.isEmpty) {
      NotificationsHelper().showError(
        'doctor.profile_edit.validation.subspecialties_required'.tr(),
        context: context,
      );
      return;
    }

    final userId = context.read<AuthController>().currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

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

      final willBeComplete =
          _bioController.text.trim().isNotEmpty && _educationEntries.isNotEmpty;
      if (wasProfileIncomplete && willBeComplete) {
        updateData['isAvailable'] = true;
      }

      await _doctorService.updateDoctorProfile(userId, updateData);

      if (mounted) {
        NotificationsHelper().showSuccess(
          'doctor.profile_edit.profile_updated'.tr(),
          context: context,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        NotificationsHelper().showError(e.toString(), context: context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _doctor == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(child: DoctorProfileEditSkeleton()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Scrollable Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar Section
                      _buildAvatarSection(context),

                      // About Me Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              'doctor.profile_edit.about_me'.tr(),
                            ),
                            const SizedBox(height: 16),
                            _buildBioField(context),
                            const SizedBox(height: 20),
                            _buildPriceExperienceRow(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),

                      // Languages Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              'doctor.profile_edit.languages_spoken'.tr(),
                            ),
                            const SizedBox(height: 16),
                            _buildLanguagesChips(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subspecialties Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              'doctor.profile_edit.subspecialties'.tr(),
                            ),
                            const SizedBox(height: 16),
                            _buildSubspecialtiesChips(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),

                      // Education Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEducationSection(context),
                      ),

                      // Bottom spacing for fixed button
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Save Button Footer
            _buildSaveFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'common.cancel'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Title
          Expanded(
            child: Text(
              'doctor.profile_edit.title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Empty spacer for balance
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getInitials(_doctor!.fullName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Avatar with camera button
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                  border: Border.all(color: colorScheme.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name (read-only, grayed out)
          Text(
            _doctor!.fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),

          // Specialty (read-only, grayed out)
          Text(
            'specialties.${_doctor!.specialty.name}'.tr().toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBioField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'doctor.profile_edit.bio'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              'doctor.profile_edit.max_chars'.tr(namedArgs: {'max': '500'}),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioController,
          maxLines: 5,
          minLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'doctor.profile_edit.bio_hint'.tr(),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'doctor.profile_edit.validation.bio_required'.tr();
            }
            if (value.trim().length < AppConstants.bioMinLength) {
              return 'doctor.profile_edit.validation.bio_too_short'.tr(
                namedArgs: {'min': AppConstants.bioMinLength.toString()},
              );
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceExperienceRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Consultation Price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'doctor.profile_edit.consultation_price'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  prefixText: 'RON ',
                  prefixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'doctor.profile_edit.validation.price_required'.tr();
                  }
                  final price = double.tryParse(text);
                  if (price == null || price <= 0) {
                    return 'validation.invalid_price'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Experience
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'doctor.profile_edit.experience_years'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  suffixText: 'common.years'.tr(),
                  suffixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'doctor.profile_edit.validation.experience_required'
                        .tr();
                  }
                  final years = int.tryParse(text);
                  if (years == null || years < 0 || years > 70) {
                    return 'doctor.profile_edit.validation.experience_invalid'
                        .tr(namedArgs: {'min': '0', 'max': '70'});
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Selected languages
        ..._selectedLanguages.map(
          (lang) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'languages.$lang'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedLanguages.remove(lang)),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Unselected languages
        ..._languageOptions
            .where((lang) => !_selectedLanguages.contains(lang))
            .map(
              (lang) => GestureDetector(
                onTap: () => setState(() => _selectedLanguages.add(lang)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(
                    'languages.$lang'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildSubspecialtiesChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subspecialtyOptions = SpecialtyRegistry.getSubspecialties(
      _doctor!.specialty,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Selected subspecialties
        ..._selectedSubspecialties.map(
          (sub) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'subspecialties.$sub'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedSubspecialties.remove(sub)),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add button
        GestureDetector(
          onTap: () => _showSubspecialtyPicker(subspecialtyOptions),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'doctor.profile_edit.add_subspecialty'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          'doctor.profile_edit.education_section'.tr(),
        ),
        const SizedBox(height: 16),

        // Education cards
        ..._educationEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final education = entry.value;
          return _buildEducationCard(context, education, index);
        }),

        // Add education button
        GestureDetector(
          onTap: _showAddEducationDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'doctor.profile_edit.add_education'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationCard(
    BuildContext context,
    EducationEntry education,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // School icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // Education details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      education.institution,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      education.degree,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      education.year.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Delete button
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _confirmDeleteEducation(index),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          ),
          child: _isSaving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(
                  'doctor.profile_edit.save_profile'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  void _showSubspecialtyPicker(List<String> options) {
    final available = options
        .where((s) => !_selectedSubspecialties.contains(s))
        .toList();
    if (available.isEmpty) {
      NotificationsHelper().showInfo(
        'doctor.profile_edit.all_subspecialties_selected'.tr(),
        context: context,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Enable scroll control
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          // Wrap content in SingleChildScrollView
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'doctor.profile_edit.select_subspecialty'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...available.map(
                (sub) => ListTile(
                  title: Text('subspecialties.$sub'.tr()),
                  onTap: () {
                    setState(() => _selectedSubspecialties.add(sub));
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEducationDialog() {
    _showEducationDialog();
  }

  void _showEducationDialog({EducationEntry? existingEntry, int? editIndex}) {
    final institutionController = TextEditingController(
      text: existingEntry?.institution ?? '',
    );
    final degreeController = TextEditingController(
      text: existingEntry?.degree ?? '',
    );
    final yearController = TextEditingController(
      text: existingEntry?.year.toString() ?? '',
    );
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
                TextFormField(
                  controller: institutionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'doctor.profile_edit.institution'.tr(),
                    hintText: 'doctor.profile_edit.institution_hint'.tr(),
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'doctor.profile_edit.validation.institution_required'
                          .tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: degreeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'doctor.profile_edit.degree'.tr(),
                    hintText: 'doctor.profile_edit.degree_hint'.tr(),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'doctor.profile_edit.validation.degree_required'
                          .tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'doctor.profile_edit.year'.tr(),
                    hintText: 'doctor.profile_edit.year_hint'.tr(),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'doctor.profile_edit.validation.year_required'
                          .tr();
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
              setState(() => _educationEntries.removeAt(index));
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'DR';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }
}
