import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
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

  // Gender keys for translation
  final List<String> _genderKeys = [
    'male',
    'female',
    'other',
    'prefer_not_to_say',
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

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(now.year - 120);
    final DateTime maxDate = DateTime(now.year - 18);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'profile.date_of_birth_hint'.tr(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.textOnPrimary,
              surface: AppTheme.backgroundWhite,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleCompleteProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('validation.select_date_of_birth'.tr()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('validation.select_gender'.tr()),
            backgroundColor: AppTheme.errorRed,
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
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(authController.errorMessage ?? 'errors.profile_save_failed'.tr()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _handleSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing32,
            vertical: AppTheme.spacing24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                const SizedBox(height: AppTheme.spacing32),

                // Header
                _buildHeader(),
                const SizedBox(height: AppTheme.spacing32),

                // Form Fields
                _buildNameField(),
                const SizedBox(height: AppTheme.spacing16),
                _buildDateOfBirthField(),
                const SizedBox(height: AppTheme.spacing16),
                _buildGenderField(),
                const SizedBox(height: AppTheme.spacing16),
                _buildPhoneField(),
                const SizedBox(height: AppTheme.spacing32),

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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            Text(
              'profile.step_of'.tr(namedArgs: {'current': '1', 'total': '1'}),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        LinearProgressIndicator(
          value: 1.0,
          backgroundColor: AppTheme.dividerColor,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.person_add_outlined,
            size: AppTheme.iconXLarge,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'profile.complete_title'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'profile.complete_subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.full_name'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'auth.name_hint'.tr(),
            prefixIcon: const Icon(
              Icons.person_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
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
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.date_of_birth'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'profile.date_of_birth_hint'.tr(),
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppTheme.textSecondary,
              ),
              errorText: null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    const BorderSide(color: AppTheme.dividerColor, width: 1),
              ),
            ),
            child: Text(
              _selectedDateOfBirth != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                  : 'profile.date_of_birth_hint'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _selectedDateOfBirth != null
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.gender'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            hintText: 'profile.gender_hint'.tr(),
            prefixIcon: const Icon(
              Icons.wc_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
          items: _genderKeys.map((String genderKey) {
            return DropdownMenuItem<String>(
              value: genderKey,
              child: Text('profile.$genderKey'.tr()),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'validation.select_gender'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'profile.phone'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'profile.optional'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'profile.phone_hint'.tr(),
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
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
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textOnPrimary,
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
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textTertiary,
          ),
      textAlign: TextAlign.center,
    );
  }
}
