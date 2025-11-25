import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/medical_specialty.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/validators.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_dropdown_field.dart';
import 'package:mcs_app/views/admin/widgets/multi_select_chip_field.dart';

/// Screen for admin to create new doctor accounts.
/// Creates Firebase Auth user + Firestore documents for doctors.
class CreateDoctorScreen extends StatefulWidget {
  const CreateDoctorScreen({super.key});

  @override
  State<CreateDoctorScreen> createState() => _CreateDoctorScreenState();
}

class _CreateDoctorScreenState extends State<CreateDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();

  // Section 1: Basic Information
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  // Section 2: Professional Details
  MedicalSpecialty? _selectedSpecialty;
  final _experienceYearsController = TextEditingController();

  // Section 3: Consultation Settings
  final _priceController = TextEditingController();
  List<String> _selectedLanguages = ['RO'];
  bool _initiallyAvailable = false;

  // Form state
  bool _isSubmitting = false;
  String? _languagesError;

  // Available languages
  final List<String> _availableLanguages = ['RO', 'EN', 'FR', 'DE', 'HU', 'RU'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _experienceYearsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  bool _validateLanguages() {
    if (_selectedLanguages.isEmpty) {
      setState(() {
        _languagesError = 'admin.create_doctor.validation.languages_required'.tr();
      });
      return false;
    }
    setState(() {
      _languagesError = null;
    });
    return true;
  }

  /// Show dialog to confirm admin password before creating doctor
  /// Returns the password if confirmed, null if cancelled
  Future<String?> _showAdminPasswordDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('admin.create_doctor.confirm_password_title'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.create_doctor.confirm_password_message'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'admin.create_doctor.confirm_password_label'.tr(),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(passwordController.text);
                }
              },
              child: Text('common.confirm'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate specialty selection
    if (_selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin.create_doctor.validation.specialty_required'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate languages
    if (!_validateLanguages()) {
      return;
    }

    // Get admin email
    final adminEmail = FirebaseAuth.instance.currentUser?.email;
    if (adminEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin.create_doctor.error_not_logged_in'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Prompt for admin password confirmation
    final adminPassword = await _showAdminPasswordDialog();
    if (adminPassword == null) {
      // User cancelled
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse optional fields
      final experienceText = _experienceYearsController.text.trim();
      final priceText = _priceController.text.trim();

      // Create doctor data
      final doctorData = DoctorModel(
        uid: '', // Will be set by AdminService
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        specialty: _selectedSpecialty!,
        experienceYears: experienceText.isNotEmpty ? int.parse(experienceText) : 0,
        bio: '', // Doctor will fill this during profile completion
        consultationPrice: priceText.isNotEmpty ? double.parse(priceText) : 0,
        languages: _selectedLanguages,
        isAvailable: _initiallyAvailable,
        createdAt: DateTime.now(),
      );

      // Create doctor with Firebase Auth and Firestore
      await _adminService.createDoctorWithAuth(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        doctorData: doctorData,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin.create_doctor.success'.tr()),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );

        // Clear form for next doctor
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'admin.create_doctor.error_generic'.tr();

        // Handle specific Firebase Auth errors
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'admin.create_doctor.error_email_exists'.tr();
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'admin.create_doctor.error_weak_password'.tr();
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'admin.create_doctor.error_invalid_email'.tr();
        } else if (e.toString().contains('wrong-password') ||
            e.toString().contains('invalid-credential')) {
          errorMessage = 'admin.create_doctor.error_wrong_admin_password'.tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _fullNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _experienceYearsController.clear();
    _priceController.clear();
    setState(() {
      _selectedSpecialty = null;
      _selectedLanguages = ['RO'];
      _initiallyAvailable = false;
      _languagesError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.create_doctor.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Section 1: Basic Information
                _buildSectionHeader(
                  context,
                  'admin.create_doctor.section_basic'.tr(),
                  Icons.person_outlined,
                ),
                const SizedBox(height: AppTheme.spacing16),
                _buildBasicInfoSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Section 2: Professional Details
                _buildSectionHeader(
                  context,
                  'admin.create_doctor.section_professional'.tr(),
                  Icons.medical_services_outlined,
                ),
                const SizedBox(height: AppTheme.spacing16),
                _buildProfessionalSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Section 3: Consultation Settings
                _buildSectionHeader(
                  context,
                  'admin.create_doctor.section_consultation'.tr(),
                  Icons.settings_outlined,
                ),
                const SizedBox(height: AppTheme.spacing16),
                _buildConsultationSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Submit Button
                _buildSubmitButton(context),
                const SizedBox(height: AppTheme.spacing16),

                // Cancel Button
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                const SizedBox(height: AppTheme.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            Icons.person_add_outlined,
            size: AppTheme.iconXLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'admin.create_doctor.title'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'admin.create_doctor.subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppTheme.iconMedium,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Column(
      children: [
        // Full Name
        AppTextField(
          label: 'admin.create_doctor.field_full_name'.tr(),
          hintText: 'admin.create_doctor.field_full_name_hint'.tr(),
          controller: _fullNameController,
          prefixIcon: Icons.person_outlined,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: Validators.validateName,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Email
        AppTextField(
          label: 'admin.create_doctor.field_email'.tr(),
          hintText: 'admin.create_doctor.field_email_hint'.tr(),
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Password
        AppTextField(
          label: 'admin.create_doctor.field_password'.tr(),
          hintText: 'admin.create_doctor.field_password_hint'.tr(),
          controller: _passwordController,
          prefixIcon: Icons.lock_outlined,
          suffixIcon: _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixIconTap: _togglePasswordVisibility,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Phone (optional)
        AppTextField(
          label: 'admin.create_doctor.field_phone'.tr(),
          hintText: 'admin.create_doctor.field_phone_hint'.tr(),
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          isOptional: true,
          optionalText: 'profile.optional'.tr(),
          validator: Validators.validatePhone,
        ),
      ],
    );
  }

  Widget _buildProfessionalSection(BuildContext context) {
    // Get specialty names for dropdown
    final specialtyItems = MedicalSpecialty.values.map((s) => s.name).toList();

    return Column(
      children: [
        // Specialty Dropdown
        AppDropdownField(
          label: 'admin.create_doctor.field_specialty'.tr(),
          hintText: 'admin.create_doctor.field_specialty_hint'.tr(),
          value: _selectedSpecialty?.name,
          items: specialtyItems,
          prefixIcon: Icons.medical_services_outlined,
          onChanged: (value) {
            setState(() {
              _selectedSpecialty = value != null
                  ? MedicalSpecialtyExtension.fromString(value)
                  : null;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'admin.create_doctor.validation.specialty_required'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Years of Experience (optional)
        AppTextField(
          label: 'admin.create_doctor.field_experience'.tr(),
          hintText: 'admin.create_doctor.field_experience_hint'.tr(),
          controller: _experienceYearsController,
          prefixIcon: Icons.work_history_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          isOptional: true,
          optionalText: 'profile.optional'.tr(),
          validator: Validators.validateExperienceYearsOptional,
        ),
      ],
    );
  }

  Widget _buildConsultationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Consultation Price (optional)
        AppTextField(
          label: 'admin.create_doctor.field_price'.tr(),
          hintText: 'admin.create_doctor.field_price_hint'.tr(),
          controller: _priceController,
          prefixIcon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          isOptional: true,
          optionalText: 'profile.optional'.tr(),
          validator: Validators.validateConsultationPriceOptional,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Languages
        MultiSelectChipField(
          label: 'admin.create_doctor.field_languages'.tr(),
          options: _availableLanguages,
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
        const SizedBox(height: AppTheme.spacing16),

        // Initially Available Toggle
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.create_doctor.field_available'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'admin.create_doctor.field_available_hint'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _initiallyAvailable,
                onChanged: (value) {
                  setState(() {
                    _initiallyAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      child: _isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Text('admin.create_doctor.submit'.tr()),
    );
  }
}
