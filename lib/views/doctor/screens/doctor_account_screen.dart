import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_profile_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/controllers/theme_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/screens/login_screen.dart';
import 'package:mcs_app/views/patient/widgets/cards/action_tile.dart';
import 'package:mcs_app/views/patient/widgets/cards/language_selection_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/list_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/profile_detail_row.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/doctor/screens/doctor_profile_edit_screen.dart';
import 'package:mcs_app/views/doctor/screens/availability_screen.dart';

/// Doctor account screen - Profile display, settings, and sign out
class DoctorAccountScreen extends StatefulWidget {
  const DoctorAccountScreen({super.key});

  @override
  State<DoctorAccountScreen> createState() => _DoctorAccountScreenState();
}

class _DoctorAccountScreenState extends State<DoctorAccountScreen> {
  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final profile = context.watch<DoctorProfileController>();
    final user = authController.currentUser;
    final doctor = profile.doctor;

    if (user == null || doctor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Header
              _buildDoctorHeader(context, doctor),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Profile Details Section
              SectionHeader(title: 'common.profile_details'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildProfileDetailsCard(context, doctor),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Quick Actions Section
              SectionHeader(title: 'common.quick_actions'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildQuickActionsCard(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Sign Out Button
              _buildSignOutButton(context),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(BuildContext context, DoctorModel doctor) {
    final doctorName = doctor.fullName;
    final specialty = doctor.specialty.name;
    final initials = _getInitials(doctorName);

    return Row(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Center(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        // Name and Specialty
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctorName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                specialty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              // Availability badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: doctor.isCurrentlyAvailable
                      ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  doctor.isCurrentlyAvailable
                      ? 'common.availability.available'.tr()
                      : 'common.availability.unavailable'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: doctor.isCurrentlyAvailable
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailsCard(BuildContext context, DoctorModel doctor) {
    final notProvidedText = 'account.not_provided'.tr();

    return ListCard(
      padding: EdgeInsets.zero,
      children: [
        ProfileDetailRow(
          icon: Icons.medical_services_outlined,
          label: 'common.specialty'.tr(),
          value: doctor.specialty.name,
          notProvidedText: notProvidedText,
        ),
        ProfileDetailRow(
          icon: Icons.work_history_outlined,
          label: 'common.experience'.tr(),
          value: 'common.years_format'.tr(namedArgs: {'years': doctor.experienceYears.toString()}),
          notProvidedText: notProvidedText,
        ),
        ProfileDetailRow(
          icon: Icons.language_outlined,
          label: 'common.languages'.tr(),
          value: doctor.languages.isNotEmpty ? doctor.languages.join(', ') : notProvidedText,
          notProvidedText: notProvidedText,
        ),
        ProfileDetailRow(
          icon: Icons.payments_outlined,
          label: 'doctor.account.price'.tr(),
          value: doctor.consultationPrice > 0
              ? '${doctor.consultationPrice.toStringAsFixed(0)} RON'
              : notProvidedText,
          notProvidedText: notProvidedText,
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return ListCard(
      padding: EdgeInsets.zero,
      children: [
        ActionTile(
          icon: Icons.edit_outlined,
          title: 'common.edit_profile'.tr(),
          subtitle: 'doctor.account.edit_profile_desc'.tr(),
          onTap: () async {
            final profileController = context.read<DoctorProfileController>();
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const DoctorProfileEditScreen(),
              ),
            );
            // Reload doctor data if profile was updated
            if (result == true) {
              await profileController.refresh();
            }
          },
        ),
        ActionTile(
          icon: Icons.event_busy_outlined,
          title: 'doctor.account.manage_availability'.tr(),
          subtitle: 'doctor.account.manage_availability_desc'.tr(),
          onTap: () async {
            final profileController = context.read<DoctorProfileController>();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AvailabilityScreen(),
              ),
            );
            // Reload doctor data after returning
            await profileController.refresh();
          },
        ),
        ActionTile(
          icon: Icons.language_outlined,
          title: 'account.change_language'.tr(),
          subtitle: 'account.change_language_desc'.tr(),
          onTap: () => _showLanguageDialog(context),
        ),
        Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return ActionTile(
              icon: Icons.palette_outlined,
              title: 'account.appearance'.tr(),
              subtitle: themeController.getThemeModeName(context),
              onTap: () => _showThemeDialog(context, themeController),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleSignOut(context),
        icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        label: Text(
          'auth.sign_out'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    String selectedLocale = context.locale.languageCode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('account.select_language'.tr()),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LanguageSelectionCard(
                languageName: 'English',
                languageCode: 'en',
                isSelected: selectedLocale == 'en',
                onTap: () async {
                  setState(() => selectedLocale = 'en');
                  await dialogContext.setLocale(const Locale('en'));
                  if (!dialogContext.mounted) return;
                  final authController = context.read<AuthController>();
                  await authController.updatePreferredLanguage('en');
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              LanguageSelectionCard(
                languageName: 'Română',
                languageCode: 'ro',
                isSelected: selectedLocale == 'ro',
                onTap: () async {
                  setState(() => selectedLocale = 'ro');
                  await dialogContext.setLocale(const Locale('ro'));
                  if (!dialogContext.mounted) return;
                  final authController = context.read<AuthController>();
                  await authController.updatePreferredLanguage('ro');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeController themeController) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('account.select_theme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioMenuButton<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeController.setThemeMode(value);
                }
              },
              child: Text('account.light_mode'.tr()),
            ),
            RadioMenuButton<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeController.setThemeMode(value);
                }
              },
              child: Text('account.dark_mode'.tr()),
            ),
            RadioMenuButton<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeController.setThemeMode(value);
                }
              },
              child: Text('account.system_mode'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authController = context.read<AuthController>();
    final consultationsController = context.read<ConsultationsController>();

    // Clear cached data before signing out
    consultationsController.clear();
    await authController.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
