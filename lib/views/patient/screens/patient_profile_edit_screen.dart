import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/patient/widgets/cards/list_card.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_date_picker_field.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_dropdown_field.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/patient/widgets/layout/profile_detail_row.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/patient/widgets/skeletons/patient_profile_edit_skeleton.dart';

/// Patient profile edit screen - dedicated screen for editing profile
/// (separate from the onboarding CompleteProfileScreen)
class PatientProfileEditScreen extends StatefulWidget {
  const PatientProfileEditScreen({super.key});

  @override
  State<PatientProfileEditScreen> createState() =>
      _PatientProfileEditScreenState();
}

class _PatientProfileEditScreenState extends State<PatientProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;

  // Inline error messages
  String? _dateOfBirthError;

  // Screen state
  bool _isLoading = true;
  bool _isSaving = false;

  // Keys for translation (biological sex for medical purposes)
  final List<String> _sexKeys = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    // Delay data loading to allow route transition animation to complete
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final currentUser = context.read<AuthController>().currentUser;
    if (currentUser != null) {
      setState(() {
        if (currentUser.displayName != null &&
            currentUser.displayName!.isNotEmpty) {
          _nameController.text = currentUser.displayName!;
        }
        if (currentUser.phone != null && currentUser.phone!.isNotEmpty) {
          _phoneController.text = currentUser.phone!;
        }
        if (currentUser.dateOfBirth != null) {
          _selectedDateOfBirth = currentUser.dateOfBirth;
        }
        if (currentUser.gender != null && currentUser.gender!.isNotEmpty) {
          _selectedGender = currentUser.gender;
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    // Clear previous errors
    setState(() {
      _dateOfBirthError = null;
    });

    // Validate form and custom fields
    bool hasError = false;

    if (!_formKey.currentState!.validate()) {
      hasError = true;
    }

    if (_selectedDateOfBirth == null) {
      setState(() {
        _dateOfBirthError = 'validation.select_date_of_birth'.tr();
      });
      hasError = true;
    }

    if (_selectedGender == null) {
      _formKey.currentState!.validate();
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isSaving = true);

    final authController = context.read<AuthController>();
    final currentLanguage = context.locale.languageCode;

    final success = await authController.completeUserProfile(
      displayName: _nameController.text.trim(),
      dateOfBirth: _selectedDateOfBirth!,
      gender: _selectedGender!,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      preferredLanguage: currentLanguage,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.edit.success'.tr()),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'profile.edit.error'.tr(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.edit.title'.tr()),
      ),
      body: SafeArea(
        child: _isLoading
            ? const PatientProfileEditSkeleton()
            : SingleChildScrollView(
                padding: AppTheme.screenPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Read-only section
                      _buildReadOnlySection(context),
                      const SizedBox(height: AppTheme.sectionSpacing),

                      // Editable section
                      _buildEditableSection(context),
                      const SizedBox(height: AppTheme.sectionSpacing),

                      // Save button
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
    final currentUser = context.read<AuthController>().currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    final email = currentUser?.email ?? '';
    final memberSince = currentUser?.createdAt != null
        ? DateFormat.yMMMd(context.locale.toLanguageTag())
            .format(currentUser!.createdAt)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with info icon
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: AppTheme.iconSmall,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'profile.edit.account_info'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'profile.edit.account_info_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Card with read-only details
        ListCard(
          padding: EdgeInsets.zero,
          children: [
            ProfileDetailRow(
              icon: Icons.email_outlined,
              label: 'common.email'.tr(),
              value: email,
            ),
            ProfileDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'account.member_since'.tr(),
              value: memberSince,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableSection(BuildContext context) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'profile.edit.personal_info'.tr()),
        const SizedBox(height: AppTheme.spacing16),

        // Full Name
        AppTextField(
          label: 'common.full_name'.tr(),
          hintText: 'auth.name_hint'.tr(),
          controller: _nameController,
          prefixIcon: Icons.person_outlined,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'validation.please_enter_full_name'.tr();
            }
            if (value.trim().length < AppConstants.nameMinLength) {
              return 'validation.name_too_short'.tr(
                namedArgs: {'min': AppConstants.nameMinLength.toString()},
              );
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Date of Birth
        AppDatePickerField(
          label: 'profile.date_of_birth'.tr(),
          hintText: 'profile.date_of_birth_hint'.tr(),
          selectedDate: _selectedDateOfBirth,
          onDateSelected: (date) {
            setState(() {
              _selectedDateOfBirth = date;
              if (_dateOfBirthError != null) _dateOfBirthError = null;
            });
          },
          firstDate: DateTime(now.year - 120),
          lastDate: DateTime(now.year - 18),
          errorText: _dateOfBirthError,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Sex
        AppDropdownField(
          label: 'profile.sex'.tr(),
          hintText: 'profile.sex_hint'.tr(),
          value: _selectedGender,
          items: _sexKeys,
          translationPrefix: 'profile',
          prefixIcon: Icons.wc_outlined,
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'validation.select_sex'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Phone
        AppTextField(
          label: 'common.phone'.tr(),
          hintText: 'profile.phone_hint'.tr(),
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          isOptional: true,
          optionalText: 'profile.optional'.tr(),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.length < AppConstants.phoneMinDigits) {
                return 'validation.invalid_phone'.tr();
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
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
          : Text('profile.edit.save_changes'.tr()),
    );
  }
}
