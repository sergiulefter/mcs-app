import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/medical_specialty.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/utils/app_theme.dart';

import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/utils/validators.dart';
import 'package:mcs_app/views/admin/widgets/forms/specialty_picker_field.dart';

/// Screen for admin to create new doctor accounts or edit existing ones.
/// In create mode: Creates Firebase Auth user + Firestore documents for doctors.
/// In edit mode: Updates the existing doctor's Firestore document.
class CreateDoctorScreen extends StatefulWidget {
  /// Optional doctor to edit. If null, the screen is in "create" mode.
  final DoctorModel? doctorToEdit;

  const CreateDoctorScreen({super.key, this.doctorToEdit});

  @override
  State<CreateDoctorScreen> createState() => _CreateDoctorScreenState();
}

class _CreateDoctorScreenState extends State<CreateDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _scrollHelper = FormScrollHelper();

  // GlobalKeys for scroll-to-error functionality
  final _fullNameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _specialtyKey = GlobalKey();
  final _experienceKey = GlobalKey();
  final _priceKey = GlobalKey();
  final _languagesKey = GlobalKey();

  /// Whether we are editing an existing doctor (true) or creating a new one (false)
  bool get _isEditMode => widget.doctorToEdit != null;

  // Section 1: Basic Information
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

  // Inline error messages for Firebase auth errors
  String? _emailError;
  String? _passwordError;
  String? _specialtyError;

  // Available languages
  final List<String> _availableLanguages = ['EN', 'RO', 'FR', 'DE', 'HU', 'RU'];

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing an existing doctor
    if (_isEditMode) {
      _populateFormWithDoctor(widget.doctorToEdit!);
    }
  }

  /// Populate form fields with existing doctor data for edit mode
  void _populateFormWithDoctor(DoctorModel doctor) {
    _fullNameController.text = doctor.fullName;
    _emailController.text = doctor.email;
    _selectedSpecialty = doctor.specialty;
    _experienceYearsController.text = doctor.experienceYears > 0
        ? doctor.experienceYears.toString()
        : '';
    _priceController.text = doctor.consultationPrice > 0
        ? doctor.consultationPrice.toString()
        : '';
    _selectedLanguages = List<String>.from(doctor.languages);
    _initiallyAvailable = doctor.isAvailable;
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _experienceYearsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleSubmit() async {
    // Clear previous errors
    _scrollHelper.clearErrors();
    setState(() {
      _emailError = null;
      _passwordError = null;
      _specialtyError = null;
      _languagesError = null;
    });

    // Track if any validation fails
    bool hasError = false;

    // Validate form fields (fullName, email, password, experience, price)
    if (!_formKey.currentState!.validate()) {
      hasError = true;
    }

    // Validate specialty selection
    if (_selectedSpecialty == null) {
      setState(() {
        _specialtyError = 'admin.create_doctor.validation.specialty_required'
            .tr();
      });
      _scrollHelper.setError('specialty');
      hasError = true;
    }

    // Validate languages
    if (_selectedLanguages.isEmpty) {
      setState(() {
        _languagesError = 'admin.create_doctor.validation.languages_required'
            .tr();
      });
      _scrollHelper.setError('languages');
      hasError = true;
    }

    // If any validation failed, scroll to first error and return
    if (hasError) {
      _scrollHelper.scrollToFirstError(context);
      return;
    }

    // For edit mode, just update
    if (_isEditMode) {
      await _handleUpdate();
      return;
    }

    // Create mode: Use Cloud Function (no admin password needed)
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse optional fields
      final experienceText = _experienceYearsController.text.trim();
      final priceText = _priceController.text.trim();

      // Create doctor data
      final doctorData = DoctorModel(
        uid: '', // Will be set by Cloud Function
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        specialty: _selectedSpecialty!,
        experienceYears: experienceText.isNotEmpty
            ? int.parse(experienceText)
            : 0,
        bio: '', // Doctor will fill this during profile completion
        consultationPrice: priceText.isNotEmpty ? double.parse(priceText) : 0,
        languages: _selectedLanguages,
        isAvailable: _initiallyAvailable,
        createdAt: DateTime.now(),
      );

      // Create doctor via Cloud Function
      await _adminService.createDoctor(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        doctorData: doctorData,
      );

      if (mounted) {
        // Show success message
        NotificationsHelper().showSuccess(
          'admin.create_doctor.success'.tr(),
          context: context,
        );

        // Clear form for next doctor
        _clearForm();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        // Map Cloud Function errors to appropriate fields
        final errorCode = e.code;

        if (errorCode == 'already-exists') {
          setState(() {
            _emailError = 'admin.create_doctor.error_email_exists'.tr();
          });
          _scrollHelper.setError('email');
          _formKey.currentState!.validate();
          _scrollHelper.scrollToFirstError(context);
        } else if (errorCode == 'invalid-argument' &&
            e.message?.contains('email') == true) {
          setState(() {
            _emailError = 'admin.create_doctor.error_invalid_email'.tr();
          });
          _scrollHelper.setError('email');
          _formKey.currentState!.validate();
          _scrollHelper.scrollToFirstError(context);
        } else if (errorCode == 'invalid-argument' &&
            e.message?.contains('password') == true) {
          setState(() {
            _passwordError = 'admin.create_doctor.error_weak_password'.tr();
          });
          _scrollHelper.setError('password');
          _formKey.currentState!.validate();
          _scrollHelper.scrollToFirstError(context);
        } else if (errorCode == 'permission-denied') {
          // Admin not authorized
          NotificationsHelper().showError(
            'admin.create_doctor.error_not_authorized'.tr(),
            context: context,
          );
        } else {
          // Generic error
          NotificationsHelper().showError(e.toString(), context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        // Generic error
        NotificationsHelper().showError(e.toString(), context: context);
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
    _experienceYearsController.clear();
    _priceController.clear();
    setState(() {
      _selectedSpecialty = null;
      _selectedLanguages = ['RO'];
      _initiallyAvailable = false;
      _languagesError = null;
      _emailError = null;
      _passwordError = null;
      _specialtyError = null;
    });
  }

  /// Handle updating an existing doctor (edit mode)
  Future<void> _handleUpdate() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse optional fields
      final experienceText = _experienceYearsController.text.trim();
      final priceText = _priceController.text.trim();

      // Build update data map (only editable fields)
      final updateData = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'specialty': _selectedSpecialty!.name,
        'experienceYears': experienceText.isNotEmpty
            ? int.parse(experienceText)
            : 0,
        'consultationPrice': priceText.isNotEmpty ? double.parse(priceText) : 0,
        'languages': _selectedLanguages,
        'isAvailable': _initiallyAvailable,
      };

      // Update doctor in Firestore
      await _adminService.updateDoctor(widget.doctorToEdit!.uid, updateData);

      if (mounted) {
        // Show success message
        NotificationsHelper().showSuccess(
          'admin.edit_doctor.success'.tr(),
          context: context,
        );

        // Navigate back to doctor management
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationsHelper().showError(e.toString(), context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register fields in order for scroll-to-error
    _scrollHelper.register('fullName', _fullNameKey);
    _scrollHelper.register('email', _emailKey);
    _scrollHelper.register('password', _passwordKey);
    _scrollHelper.register('specialty', _specialtyKey);
    _scrollHelper.register('experience', _experienceKey);
    _scrollHelper.register('price', _priceKey);
    _scrollHelper.register('languages', _languagesKey);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar
                    _buildAppBar(context),

                    // Profile Photo Section
                    _buildProfilePhotoSection(context),

                    // Form Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Basic Information
                          _buildSectionTitle(
                            context,
                            'admin.create_doctor.section_basic'.tr(),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          _buildBasicInfoSection(context),

                          // Divider
                          _buildSectionDivider(context),

                          // Section 2: Professional Details
                          _buildSectionTitle(
                            context,
                            'admin.create_doctor.section_professional'.tr(),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          _buildProfessionalSection(context),

                          // Divider
                          _buildSectionDivider(context),

                          // Section 3: Consultation Settings
                          _buildSectionTitle(
                            context,
                            'admin.create_doctor.section_consultation'.tr(),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          _buildConsultationSection(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyFooter(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the top app bar with back button and centered title.
  Widget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withValues(alpha: 0.95)
            : AppTheme.backgroundLight.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // Centered title
          Expanded(
            child: Text(
              _isEditMode
                  ? 'admin.edit_doctor.title'.tr()
                  : 'admin.create_doctor.title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Spacer to balance the back button
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Builds the profile photo upload section.
  Widget _buildProfilePhotoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
      child: Column(
        children: [
          // Photo placeholder with upload icon
          GestureDetector(
            onTap: () {
              // TODO: Implement photo upload
              NotificationsHelper().showInfo(
                'Photo upload coming soon',
                context: context,
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.5 : 0.3,
                      ),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                // Edit badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppTheme.backgroundDark
                            : AppTheme.backgroundLight,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'admin.create_doctor.profile_photo'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'admin.create_doctor.profile_photo_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a section title.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  /// Builds a section divider.
  Widget _buildSectionDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacing24,
        horizontal: AppTheme.spacing8,
      ),
      child: Container(
        height: 1,
        color: isDark ? AppTheme.slate700 : AppTheme.slate200,
      ),
    );
  }

  /// Builds a modern input field matching the HTML design.
  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    GlobalKey? fieldKey,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return KeyedSubtree(
      key: fieldKey ?? GlobalKey(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.slate200 : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            readOnly: readOnly,
            onChanged: onChanged,
            validator: validator,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? AppTheme.slate600 : AppTheme.slate400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: AppTheme.spacing16,
                  right: AppTheme.spacing12,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 52),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(color: colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(color: colorScheme.error, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Full Name
        _buildInputField(
          context,
          label: 'common.full_name'.tr(),
          hint: 'admin.create_doctor.field_full_name_hint'.tr(),
          controller: _fullNameController,
          icon: Icons.person_outlined,
          fieldKey: _fullNameKey,
          textInputAction: TextInputAction.next,
          validator: Validators.validateName,
        ),

        // Email - only show in create mode
        if (!_isEditMode) ...[
          const SizedBox(height: AppTheme.spacing16),
          _buildInputField(
            context,
            label: 'common.email'.tr(),
            hint: 'admin.create_doctor.field_email_hint'.tr(),
            controller: _emailController,
            icon: Icons.mail_outlined,
            fieldKey: _emailKey,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (_emailError != null) return _emailError;
              return Validators.validateEmail(value);
            },
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
        ],

        // In edit mode, show email as read-only info
        if (_isEditMode) ...[
          const SizedBox(height: AppTheme.spacing16),
          _buildInputField(
            context,
            label: 'common.email'.tr(),
            hint: '',
            controller: _emailController,
            icon: Icons.mail_outlined,
            readOnly: true,
          ),
        ],

        // Password - only show in create mode
        if (!_isEditMode) ...[
          const SizedBox(height: AppTheme.spacing16),
          _buildInputField(
            context,
            label: 'admin.create_doctor.field_password'.tr(),
            hint: '••••••••',
            controller: _passwordController,
            icon: Icons.lock_outlined,
            fieldKey: _passwordKey,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: _togglePasswordVisibility,
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ),
            validator: (value) {
              if (_passwordError != null) return _passwordError;
              return Validators.validatePassword(value);
            },
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProfessionalSection(BuildContext context) {
    return Column(
      children: [
        // Specialty Picker
        KeyedSubtree(
          key: _specialtyKey,
          child: SpecialtyPickerField(
            label: 'admin.create_doctor.field_specialty'.tr(),
            hintText: 'admin.create_doctor.field_specialty_hint'.tr(),
            value: _selectedSpecialty,
            prefixIcon: Icons.medical_services_outlined,
            onChanged: (value) {
              setState(() {
                _selectedSpecialty = value;
                if (_specialtyError != null) _specialtyError = null;
              });
            },
            validator: (value) {
              if (_specialtyError != null) return _specialtyError;
              if (value == null) {
                return 'admin.create_doctor.validation.specialty_required'.tr();
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Years of Experience
        _buildInputField(
          context,
          label: 'admin.create_doctor.field_experience'.tr(),
          hint: '0',
          controller: _experienceYearsController,
          icon: Icons.history_edu_outlined,
          fieldKey: _experienceKey,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: Validators.validateExperienceYearsOptional,
        ),
      ],
    );
  }

  Widget _buildConsultationSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Consultation Price
        _buildInputField(
          context,
          label: 'admin.create_doctor.field_price'.tr(),
          hint: '0.00',
          controller: _priceController,
          icon: Icons.attach_money_outlined,
          fieldKey: _priceKey,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          validator: Validators.validateConsultationPriceOptional,
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Languages
        KeyedSubtree(
          key: _languagesKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.create_doctor.field_languages'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.slate200 : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Wrap(
                spacing: AppTheme.spacing8,
                runSpacing: AppTheme.spacing8,
                children: _availableLanguages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedLanguages.remove(lang);
                        } else {
                          _selectedLanguages.add(lang);
                        }
                        _languagesError = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : (isDark ? AppTheme.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCircular,
                        ),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppTheme.slate700
                                    : AppTheme.slate200,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              Icons.check,
                              size: 18,
                              color: colorScheme.onPrimary,
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                          ],
                          Text(
                            lang,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : (isDark
                                            ? AppTheme.slate400
                                            : AppTheme.slate600),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_languagesError != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  _languagesError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Initially Available Toggle
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isDark ? AppTheme.slate700 : AppTheme.slate200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.create_doctor.field_available'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'admin.create_doctor.field_available_hint'.tr(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  /// Builds the sticky footer with submit and cancel buttons.
  Widget _buildStickyFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withValues(alpha: 0.8)
            : AppTheme.backgroundLight.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.slate700.withValues(alpha: 0.5)
                : AppTheme.slate200.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    elevation: 4,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'admin.edit_doctor.submit'.tr()
                                  : 'admin.create_doctor.submit'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(
                    'common.cancel'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
