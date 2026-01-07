import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/theme_controller.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/screens/login_screen.dart';
import 'package:mcs_app/utils/seed_dev_data.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColors = Theme.of(context).extension<AppIconColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    // Appearance Section
                    _buildSectionHeader(context, 'account.appearance'.tr()),
                    _buildSectionContainer(
                      context,
                      children: [
                        Consumer<ThemeController>(
                          builder: (context, themeController, _) {
                            final isDarkMode =
                                themeController.themeMode == ThemeMode.dark ||
                                (themeController.themeMode ==
                                        ThemeMode.system &&
                                    MediaQuery.of(context).platformBrightness ==
                                        Brightness.dark);

                            return _buildSettingsTile(
                              context,
                              icon: Icons.dark_mode_outlined,
                              iconColor: colorScheme.primary,
                              iconBgColor: colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              title: 'account.dark_mode'.tr(),
                              trailing: Switch(
                                value: isDarkMode,
                                onChanged: (value) {
                                  themeController.setThemeMode(
                                    value ? ThemeMode.dark : ThemeMode.light,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Localization Section
                    _buildSectionHeader(context, 'profile.localization'.tr()),
                    _buildSectionContainer(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.language,
                          iconColor: iconColors.language,
                          iconBgColor: iconColors.language.withValues(
                            alpha: 0.1,
                          ),
                          title: 'common.languages'.tr(),
                          value: context.locale.languageCode == 'en'
                              ? 'English (US)'
                              : 'Română',
                          onTap: () => _showLanguageDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Developer Options
                    _buildSectionHeader(context, 'Developer Options'),
                    _buildSectionContainer(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.storage,
                          iconColor: iconColors.developer,
                          iconBgColor: iconColors.developer.withValues(
                            alpha: 0.1,
                          ),
                          title: 'Seed Database',
                          onTap: () => _showSeedConfirmDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // App Version
                    Text(
                      'profile.app_version'.tr(
                        namedArgs: {'version': '4.2.0', 'build': '301'},
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                    // Sign Out
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _handleSignOut(context),
                        icon: Icon(Icons.logout, color: colorScheme.error),
                        label: Text(
                          'auth.sign_out'.tr(),
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: const CircleBorder(),
            ),
          ),
          Expanded(
            child: Text(
              'admin.system_settings.title'
                  .tr(), // Or generic 'Settings' if key missing
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Balance back button
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (value != null) ...[
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('account.select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, dialogContext, 'English (US)', 'en'),
            _buildLanguageOption(context, dialogContext, 'Română', 'ro'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    BuildContext dialogContext,
    String name,
    String code,
  ) {
    return ListTile(
      title: Text(name),
      trailing: context.locale.languageCode == code
          ? const Icon(Icons.check)
          : null,
      onTap: () async {
        await context.setLocale(Locale(code));
        if (!context.mounted) return;
        final authController = context.read<AuthController>();
        await authController.updatePreferredLanguage(code);
        if (!dialogContext.mounted) return;
        Navigator.pop(dialogContext);
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authController = context.read<AuthController>();
    await authController.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSeedConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Seed Database?'),
        content: const Text(
          'This will DELETE all existing doctors and consultations and replace them with generated test data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _runSeeder(context);
            },
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSeeder(BuildContext context) async {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await runDevSeeder(patientId: userId);
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database seeded successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding database: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
