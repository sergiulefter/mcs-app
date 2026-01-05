import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/patient/widgets/skeletons/patient_profile_edit_skeleton.dart';
import 'package:mcs_app/utils/notifications_helper.dart';

/// Patient profile edit screen matching the doctor profile edit screen design.
/// Features: Cancel header, avatar section, form fields, fixed Save footer.
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
    if (!_formKey.currentState!.validate()) return;

    // Custom validations
    if (_selectedDateOfBirth == null) {
      NotificationsHelper().showError(
        'validation.select_date_of_birth'.tr(),
        context: context,
      );
      return;
    }

    if (_selectedGender == null) {
      NotificationsHelper().showError(
        'validation.select_sex'.tr(),
        context: context,
      );
      return;
    }

    setState(() => _isSaving = true);

    final authController = context.read<AuthController>();
    final currentLanguage = context.locale.languageCode;

    try {
      await authController.completeUserProfile(
        displayName: _nameController.text.trim(),
        dateOfBirth: _selectedDateOfBirth!,
        gender: _selectedGender!,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        preferredLanguage: currentLanguage,
      );

      if (!mounted) return;

      NotificationsHelper().showSuccess(
        'profile.edit.success'.tr(),
        context: context,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      NotificationsHelper().showError(e.toString(), context: context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(child: PatientProfileEditSkeleton()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
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

                      // Personal Information Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              'profile.edit.personal_info'.tr(),
                            ),
                            const SizedBox(height: 16),
                            _buildNameField(context),
                            const SizedBox(height: 16),
                            _buildDateOfBirthField(context),
                            const SizedBox(height: 16),
                            _buildSexField(context),
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

                      // Contact Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              'profile.edit.contact_info'.tr(),
                            ),
                            const SizedBox(height: 16),
                            _buildPhoneField(context),
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

                      // Account Info Section (read-only)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildAccountInfoSection(context),
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
        color: colorScheme.surface,
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
              'profile.edit.title'.tr(),
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
    final currentUser = context.read<AuthController>().currentUser;
    final displayName = currentUser?.displayName ?? '';
    final initials = _getInitials(displayName);
    final email = currentUser?.email ?? '';

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

          // Email (read-only, grayed out)
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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

  Widget _buildNameField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'common.full_name'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'auth.name_hint'.tr(),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.person_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 20,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
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
      ],
    );
  }

  Widget _buildDateOfBirthField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final formattedDate = _selectedDateOfBirth != null
        ? DateFormat.yMMMd(
            context.locale.toLanguageTag(),
          ).format(_selectedDateOfBirth!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.date_of_birth'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDateOfBirth ?? DateTime(now.year - 30),
              firstDate: DateTime(now.year - 120),
              lastDate: DateTime(now.year - 18),
            );
            if (date != null) {
              setState(() => _selectedDateOfBirth = date);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formattedDate ?? 'profile.date_of_birth_hint'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: formattedDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSexField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.sex'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: _sexKeys.map((sex) {
            final isSelected = _selectedGender == sex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: sex == _sexKeys.first ? 0 : 8,
                  right: sex == _sexKeys.last ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = sex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sex == 'male' ? Icons.male : Icons.female,
                          size: 20,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'profile.$sex'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'common.phone'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '(${('profile.optional'.tr())})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'profile.phone_hint'.tr(),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 20,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
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

  Widget _buildAccountInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = context.read<AuthController>().currentUser;

    final memberSince = currentUser?.createdAt != null
        ? DateFormat.yMMMd(
            context.locale.toLanguageTag(),
          ).format(currentUser!.createdAt)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'profile.edit.account_info'.tr()),
        const SizedBox(height: 8),
        Text(
          'profile.edit.account_info_hint'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // Member Since
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'account.member_since'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    memberSince,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
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
              elevation: 0,
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
                    'profile.edit.save_changes'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
