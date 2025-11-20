import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/quick_action_card.dart';
import 'complete_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'home.good_morning'.tr();
    } else if (hour < 18) {
      return 'home.good_afternoon'.tr();
    } else {
      return 'home.good_evening'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(context, user?.displayName),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Profile Completion Banner (if incomplete)
              if (user != null && !user.profileCompleted)
                _buildProfileCompletionBanner(context),

              // Quick Actions Section
              _buildQuickActionsSection(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Active Consultations Section
              _buildActiveConsultationsSection(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Medical Disclaimer
              _buildMedicalDisclaimer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String? displayName) {
    final greeting = _getGreeting();
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          displayName ?? 'home.welcome'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          today,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sectionSpacing),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.tertiary,
                size: AppTheme.iconMedium,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'home.profile_incomplete'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'home.profile_incomplete_desc'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompleteProfileScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.tertiary),
              foregroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: Text('home.complete_profile_button'.tr()),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.medical_services_outlined,
                  title: 'home.request_opinion'.tr(),
                  description: 'home.request_opinion_desc'.tr(),
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                  // Navigate to Doctors tab (index 1) to start the flow
                  _navigateToTab(context, 1);
                },
              ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.search_outlined,
                  title: 'home.browse_doctors'.tr(),
                  description: 'home.browse_doctors_desc'.tr(),
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                  // Navigate to Doctors tab (index 1)
                  _navigateToTab(context, 1);
                },
              ),
            ),
          ],
        ),
        ],
      );
    }

  Widget _buildActiveConsultationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.active_consultations'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Consultations tab (index 2)
                _navigateToTab(context, 2);
              },
              child: Text('home.view_all'.tr()),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          width: double.infinity,
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'home.no_active_consultations'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'home.no_active_consultations_desc'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalDisclaimer(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: AppTheme.iconSmall,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              'home.medical_disclaimer'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    final navigationController = NavigationController.of(context);
    navigationController?.onTabChange(tabIndex);
  }
}
