import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/models/user_model.dart';
import 'package:mcs_app/views/patient/screens/settings_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, user),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  100,
                ), // Extra bottom padding for nav
                child: Column(
                  children: [
                    // Profile Overview (Avatar + Name)
                    _buildProfileOverview(context, user),
                    const SizedBox(height: 32),

                    // Cards
                    _buildInfoCard(
                      context,
                      title: 'profile.contact_info'.tr(),
                      icon: Icons.contact_mail_outlined,
                      children: [
                        _buildInfoRow(
                          context,
                          label: 'common.email'.tr(),
                          value: user.email,
                          isFirst: true,
                        ),
                        _buildInfoRow(
                          context,
                          label: 'common.phone'.tr(),
                          value: user.phone ?? 'account.not_provided'.tr(),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildInfoCard(
                      context,
                      title: 'profile.personal_details'.tr(),
                      icon: Icons.badge_outlined,
                      children: [
                        _buildInfoRow(
                          context,
                          label: 'account.date_of_birth'.tr(),
                          value: user.dateOfBirth != null
                              ? DateFormat(
                                  'MMM d, yyyy',
                                  context.locale.toString(),
                                ).format(user.dateOfBirth!)
                              : 'account.not_provided'.tr(),
                          isFirst: true,
                        ),
                        _buildInfoRow(
                          context,
                          label: 'account.sex'.tr(),
                          value: user.gender != null
                              ? 'profile.${user.gender}'.tr()
                              : 'account.not_provided'.tr(),
                        ),
                        _buildInfoRow(
                          context,
                          label: 'common.languages'.tr(),
                          value: _getLanguageName(user.preferredLanguage),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildMedicalBasicsCard(context, user),

                    const SizedBox(height: 16),
                    Text(
                      'profile.medical_records_updated'.tr(
                        namedArgs: {
                          'date': DateFormat(
                            'MMM d, h:mm a',
                          ).format(DateTime.now()), // Placeholder logic for now
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Spacer for centering title
          Text(
            'profile.profile_setup'.tr(), // "My Profile" equivalent title
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverview(BuildContext context, UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Avatar
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: user.photoUrl == null ? colorScheme.primaryContainer : null,
            border: Border.all(color: colorScheme.surface, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            image: user.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(user.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user.photoUrl == null
              ? Icon(
                  Icons.person,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          user.displayName ?? 'User',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // ID Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            '${'profile.patient_id'.tr()}: #${user.uid.substring(0, 5).toUpperCase()}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937) // gray-800
                : const Color(0xFFF9FAFB), // gray-50
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937) // gray-800
                      : const Color(0xFFF9FAFB), // gray-50
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalBasicsCard(BuildContext context, UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'profile.medical_basics'.tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937) // gray-800
                : const Color(0xFFF9FAFB), // gray-50
          ),
          // Grid Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildMedicalItem(
                  context,
                  label: 'profile.height'.tr(),
                  value: user.height ?? '-',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                ),
                _buildMedicalItem(
                  context,
                  label: 'profile.weight'.tr(),
                  value: user.weight ?? '-',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                ),
                _buildMedicalItem(
                  context,
                  label: 'profile.blood_type'.tr(),
                  value: user.bloodType ?? '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    if (code == 'ro') return 'Română';
    return 'English';
  }
}
