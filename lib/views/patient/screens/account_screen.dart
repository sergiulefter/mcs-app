import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/controllers/theme_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/seed_dev_data.dart';
import 'package:mcs_app/utils/seed_doctors.dart';
import 'package:mcs_app/views/admin/screens/admin_dashboard_screen.dart';
import 'package:mcs_app/views/patient/widgets/cards/action_tile.dart';
import 'package:mcs_app/views/patient/widgets/cards/language_selection_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/list_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/user_header_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/profile_detail_row.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'login_screen.dart';
import 'complete_profile_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'account.no_user_logged_in'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Section
              UserHeaderCard(
                displayName: user.displayName ?? '',
                email: user.email,
                photoUrl: user.photoUrl,
                userType: user.userType,
                isDoctor: user.isDoctor,
                fallbackName: 'account.not_set'.tr(),
              ),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Profile Details Section
              SectionHeader(title: 'common.profile_details'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildProfileDetailsCard(context, user),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Quick Actions Section
              SectionHeader(title: 'common.quick_actions'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildQuickActionsCard(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Admin Panel Section (only for admin users)
              if (user.userType == 'admin') ...[
                SectionHeader(title: 'admin.admin_panel_section'.tr()),
                const SizedBox(height: AppTheme.spacing16),
                _buildAdminPanelCard(context),
                const SizedBox(height: AppTheme.sectionSpacing),
              ],

              // Account Section
              SectionHeader(title: 'account.account_section'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildAccountCard(context, user),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Debug Section (only in debug mode)
              if (kDebugMode) ...[
                _buildDebugSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),
              ],

              // Sign Out Button
              _buildSignOutButton(context),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailsCard(BuildContext context, dynamic user) {
    final notProvidedText = 'account.not_provided'.tr();
    final localeName = context.locale.toLanguageTag();

    return ListCard(
      padding: EdgeInsets.zero,
      children: [
        ProfileDetailRow(
          icon: Icons.cake_outlined,
          label: 'account.date_of_birth'.tr(),
          value: user.dateOfBirth != null
              ? DateFormat('dd MMMM yyyy', localeName).format(user.dateOfBirth!)
              : notProvidedText,
          notProvidedText: notProvidedText,
        ),
        ProfileDetailRow(
          icon: Icons.wc_outlined,
          label: 'account.sex'.tr(),
          value: user.gender != null ? 'profile.${user.gender}'.tr() : notProvidedText,
          notProvidedText: notProvidedText,
        ),
        ProfileDetailRow(
          icon: Icons.phone_outlined,
          label: 'common.phone'.tr(),
          value: user.phone ?? notProvidedText,
          notProvidedText: notProvidedText,
        ),
        ProfileDetailRow(
          icon: Icons.language_outlined,
          label: 'account.preferred_language'.tr(),
          value: _getLanguageName(user.preferredLanguage),
        ),
        ProfileDetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'account.member_since'.tr(),
          value: DateFormat('dd MMMM yyyy', localeName).format(user.createdAt),
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
          title: 'account.edit_profile'.tr(),
          subtitle: 'account.edit_profile_desc'.tr(),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CompleteProfileScreen(),
              ),
            );
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

  Widget _buildAccountCard(BuildContext context, dynamic user) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ActionTile(
        icon: Icons.lock_outline,
        title: 'account.change_password'.tr(),
        subtitle: 'account.change_password_desc'.tr(),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('account.change_password_coming_soon'.tr()),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminPanelCard(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ActionTile(
        icon: Icons.admin_panel_settings_outlined,
        title: 'admin.go_to_admin_panel'.tr(),
        subtitle: 'admin.go_to_admin_panel_desc'.tr(),
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildDebugSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: colorScheme.error,
      borderWidth: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  'Debug Tools',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          ActionTile(
            icon: Icons.medical_services_outlined,
            title: 'Seed Doctors Database',
            subtitle: 'Add 7 sample doctors to Firestore (requires admin)',
            onTap: () => _handleSeedDoctors(context),
          ),
          ActionTile(
            icon: Icons.cloud_download_outlined,
            title: 'Seed Dev Data (Doctors + Consultations)',
            subtitle: 'Bulk seed hundreds of doctors & consultations (dev only)',
            onTap: () => _handleSeedDevData(context),
          ),
        ],
      ),
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

  Future<void> _handleSeedDoctors(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppTheme.spacing16),
                Text('Seeding doctors...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final seeder = DoctorSeeder();
      await seeder.seedDoctors();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Successfully seeded 7 doctors!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error seeding doctors: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
                  setState(() => selectedLocale = 'en'); // instant UI feedback
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
                  setState(() => selectedLocale = 'ro'); // instant UI feedback
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

  Future<void> _handleSeedDevData(BuildContext context) async {
    final authController = context.read<AuthController>();
    final currentUser = authController.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.no_user_logged_in'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Seeding dev data...'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    try {
      // Run the seeder script (requires Firebase initialized)
      await Future.sync(() => runDevSeeder(patientId: currentUser.uid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dev data seeded successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seeding failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ro':
        return 'Română';
      case 'en':
      default:
        return 'English';
    }
  }
}

