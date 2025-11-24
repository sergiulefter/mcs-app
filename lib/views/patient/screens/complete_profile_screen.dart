import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_date_picker_field.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_dropdown_field.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'main_shell.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;

  // Keys for translation (biological sex for medical purposes)
  final List<String> _sexKeys = [
    'male',
    'female',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate name from signup
    final currentUser = context.read<AuthController>().currentUser;
    if (currentUser?.displayName != null) {
      _nameController.text = currentUser!.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('validation.select_date_of_birth'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('validation.select_gender'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final authController = context.read<AuthController>();

      // Get the current language from EasyLocalization (already set at signup)
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

        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainShell(initialIndex: 3),
            ),
          );
        } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(authController.errorMessage ?? 'errors.profile_save_failed'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainShell(initialIndex: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('profile.complete_title'.tr()),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: Text('common.skip'.tr()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Header
                _buildHeader(),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Form Fields
                AppTextField(
                  label: 'auth.full_name'.tr(),
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
                    if (value.trim().length < 2) {
                      return 'validation.name_too_short'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                AppDatePickerField(
                  label: 'profile.date_of_birth'.tr(),
                  hintText: 'profile.date_of_birth_hint'.tr(),
                  selectedDate: _selectedDateOfBirth,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDateOfBirth = date;
                    });
                  },
                  firstDate: DateTime(now.year - 120),
                  lastDate: DateTime(now.year - 18),
                ),
                const SizedBox(height: AppTheme.spacing16),

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

                AppTextField(
                  label: 'profile.phone'.tr(),
                  hintText: 'profile.phone_hint'.tr(),
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  isOptional: true,
                  optionalText: 'profile.optional'.tr(),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      // Basic phone validation - at least 10 digits
                      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length < 10) {
                        return 'validation.invalid_phone'.tr();
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Complete Button
                _buildCompleteButton(),
                const SizedBox(height: AppTheme.spacing16),

                // Info Text
                _buildInfoText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'profile.profile_setup'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(),
            ),
            Text(
              'profile.step_of'.tr(namedArgs: {'current': '1', 'total': '1'}),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        LinearProgressIndicator(
          value: 1.0,
          backgroundColor: Theme.of(context).dividerColor,
          valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
          'profile.complete_title'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'profile.complete_subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return ElevatedButton(
          onPressed:
              authController.isLoading ? null : _handleCompleteProfile,
          child: authController.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text('profile.complete_button'.tr()),
        );
      },
    );
  }

  Widget _buildInfoText() {
    return Text(
      'profile.skip_info'.tr(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(),
      textAlign: TextAlign.center,
    );
  }
}


