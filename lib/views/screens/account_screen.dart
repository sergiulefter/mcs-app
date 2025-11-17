import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/user_header_card.dart';
import '../widgets/profile_detail_row.dart';
import '../widgets/action_tile.dart';
import '../widgets/language_selection_card.dart';
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
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: Text(
            'account.no_user_logged_in'.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing24,
            vertical: AppTheme.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Section
              UserHeaderCard(
                displayName: user.displayName ?? '',
                email: user.email,
                photoUrl: user.photoUrl,
                userType: user.userType,
                fallbackName: 'account.not_set'.tr(),
              ),
              const SizedBox(height: AppTheme.spacing32),

              // Profile Details Section
              _buildSectionHeader(context, 'account.profile_details'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildProfileDetailsCard(context, user),
              const SizedBox(height: AppTheme.spacing32),

              // Quick Actions Section
              _buildSectionHeader(context, 'account.quick_actions'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildQuickActionsCard(context),
              const SizedBox(height: AppTheme.spacing32),

              // Account Section
              _buildSectionHeader(context, 'account.account_section'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              _buildAccountCard(context, user),
              const SizedBox(height: AppTheme.spacing32),

              // Sign Out Button
              _buildSignOutButton(context),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildProfileDetailsCard(BuildContext context, dynamic user) {
    final notProvidedText = 'account.not_provided'.tr();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: AppTheme.elevationLow,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileDetailRow(
            icon: Icons.cake_outlined,
            label: 'account.date_of_birth'.tr(),
            value: user.dateOfBirth != null
                ? DateFormat('dd MMMM yyyy').format(user.dateOfBirth!)
                : notProvidedText,
            notProvidedText: notProvidedText,
          ),
          _buildDivider(),
          ProfileDetailRow(
            icon: Icons.wc_outlined,
            label: 'account.sex'.tr(),
            value: user.gender != null
                ? 'profile.${user.gender}'.tr()
                : notProvidedText,
            notProvidedText: notProvidedText,
          ),
          _buildDivider(),
          ProfileDetailRow(
            icon: Icons.phone_outlined,
            label: 'account.phone'.tr(),
            value: user.phone ?? notProvidedText,
            notProvidedText: notProvidedText,
          ),
          _buildDivider(),
          ProfileDetailRow(
            icon: Icons.language_outlined,
            label: 'account.preferred_language'.tr(),
            value: _getLanguageName(user.preferredLanguage),
          ),
          _buildDivider(),
          ProfileDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'account.member_since'.tr(),
            value: DateFormat('dd MMMM yyyy').format(user.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: AppTheme.elevationLow,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
          _buildDivider(),
          ActionTile(
            icon: Icons.language_outlined,
            title: 'account.change_language'.tr(),
            subtitle: 'account.change_language_desc'.tr(),
            onTap: () => _showLanguageDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, dynamic user) {
    final notProvidedText = 'account.not_provided'.tr();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: AppTheme.elevationLow,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ActionTile(
            icon: Icons.lock_outline,
            title: 'account.change_password'.tr(),
            subtitle: 'account.change_password_desc'.tr(),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('account.change_password_coming_soon'.tr()),
                  backgroundColor: AppTheme.infoBlue,
                ),
              );
            },
          ),
          _buildDivider(),
          ProfileDetailRow(
            icon: Icons.fingerprint,
            label: 'account.user_id'.tr(),
            value: '${user.uid.substring(0, 12)}...',
            notProvidedText: notProvidedText,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.dividerColor,
      indent: AppTheme.spacing16,
      endIndent: AppTheme.spacing16,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleSignOut(context),
        icon: const Icon(Icons.logout, color: AppTheme.errorRed),
        label: Text(
          'auth.sign_out'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.errorRed),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('account.select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageSelectionCard(
              languageName: 'English',
              languageCode: 'en',
              isSelected: currentLocale == 'en',
              onTap: () {
                dialogContext.setLocale(const Locale('en'));
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('account.language_changed'.tr()),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
            LanguageSelectionCard(
              languageName: 'Română',
              languageCode: 'ro',
              isSelected: currentLocale == 'ro',
              onTap: () {
                dialogContext.setLocale(const Locale('ro'));
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('account.language_changed'.tr()),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
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
