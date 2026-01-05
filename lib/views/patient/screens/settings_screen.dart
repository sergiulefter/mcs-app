import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/theme_controller.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/views/patient/screens/patient_profile_edit_screen.dart';
import 'package:mcs_app/views/patient/screens/login_screen.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                    // Account Section
                    _buildSectionHeader(context, 'common.account'.tr()),
                    _buildSectionContainer(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.person_outline,
                          iconColor: Colors.blue,
                          iconBgColor: Colors.blue.withValues(alpha: 0.1),
                          title: 'account.edit_profile'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PatientProfileEditScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1),
                        _buildSettingsTile(
                          context,
                          icon: Icons.lock_outline,
                          iconColor: Colors.orange,
                          iconBgColor: Colors.orange.withValues(alpha: 0.1),
                          title: 'account.change_password'.tr(),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'account.change_password_coming_soon'.tr(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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

                    // Notifications Section
                    _buildSectionHeader(
                      context,
                      'profile.settings_title'.tr(),
                    ), // Using 'Settings' as section header proxy or 'Notifications' if key existed, reusing generic for now or "Notifications" hardcoded if needed but aiming for keys
                    _buildSectionContainer(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.notifications_none_outlined,
                          iconColor: Colors.pink, // rose-500
                          iconBgColor: Colors.pink.withValues(alpha: 0.1),
                          title: 'profile.push_notifications'.tr(),
                          trailing: Switch(
                            value: true, // Dummy value
                            onChanged: (val) {},
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                        _buildSettingsTile(
                          context,
                          icon: Icons.mail_outline,
                          iconColor: Colors.lightBlue, // sky-500
                          iconBgColor: Colors.lightBlue.withValues(alpha: 0.1),
                          title: 'profile.email_alerts'.tr(),
                          trailing: Switch(
                            value: false, // Dummy value
                            onChanged: (val) {},
                          ),
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
                          iconColor: Colors.green, // emerald-600
                          iconBgColor: Colors.green.withValues(alpha: 0.1),
                          title: 'common.languages'.tr(),
                          value: context.locale.languageCode == 'en'
                              ? 'English (US)'
                              : 'Română',
                          onTap: () => _showLanguageDialog(context),
                        ),
                        const Divider(height: 1, thickness: 1),
                        _buildSettingsTile(
                          context,
                          icon: Icons.schedule,
                          iconColor: Colors.amber, // amber-600
                          iconBgColor: Colors.amber.withValues(alpha: 0.1),
                          title: 'profile.time_zone'.tr(),
                          value: 'profile.system_default'.tr(),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Support Section
                    _buildSectionHeader(context, 'profile.support'.tr()),
                    _buildSectionContainer(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.help_outline,
                          iconColor: Colors.deepPurple, // violet-600
                          iconBgColor: Colors.deepPurple.withValues(alpha: 0.1),
                          title: 'home.help_center'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpCenterScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1),
                        _buildSettingsTile(
                          context,
                          icon: Icons.security,
                          iconColor: Colors.teal, // teal-600
                          iconBgColor: Colors.teal.withValues(alpha: 0.1),
                          title: 'profile.privacy_security'.tr(),
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
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

                    const SizedBox(height: 32),
                    // Sign Out (Optional placement here or just keep in header/account screen, but design had home nav. Adding useful logout here too as fallback)
                    // Back to Admin Dashboard (Only for Admins)
                    Consumer<AuthController>(
                      builder: (context, authController, _) {
                        if (authController.currentUser?.userType != 'admin') {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Pop until we find the dashboard or empty the stack
                                  // Since we pushed MainShell from AdminDashboard, popping until first should work
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text('Back to Admin Dashboard'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

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
            ).colorScheme.outlineVariant.withValues(alpha: 0.2),
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
              'profile.settings_title'.tr(),
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
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
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
              else
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
}
