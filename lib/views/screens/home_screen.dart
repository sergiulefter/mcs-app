import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/consultations_controller.dart';
import '../../models/consultation_model.dart';
import '../../utils/app_theme.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/consultation_card.dart';
import 'complete_profile_screen.dart';
import 'notifications_screen.dart';
import 'request_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchConsultations();
    });
  }

  Future<void> _fetchConsultations() async {
    final authController = context.read<AuthController>();
    final consultationsController = context.read<ConsultationsController>();

    if (authController.currentUser != null) {
      await consultationsController.fetchUserConsultations(
        authController.currentUser!.uid,
      );
    }
  }

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
    final consultationsController = context.watch<ConsultationsController>();
    final user = authController.currentUser;

    // Calculate stats from real consultation data
    final consultations = consultationsController.consultations;
    final totalCount = consultations.length;
    final pendingCount = consultations.where((c) => c.status == 'pending').length;
    final completedCount = consultations.where((c) => c.status == 'completed').length;

    // Get active consultations (pending or in_review) for display
    final activeConsultations = consultations
        .where((c) => c.status == 'pending' || c.status == 'in_review')
        .take(3)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Welcome Header
              _buildWelcomeHeader(context, user?.displayName),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Profile Completion Banner (if incomplete)
              if (user != null && !user.profileCompleted)
                _buildProfileCompletionBanner(context),

              // Active Consultations Section with real data
              _buildActiveConsultationsSection(context, activeConsultations),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Primary CTA - Browse Doctors
              _buildPrimaryCTA(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Stats Dashboard Section with real data
              _buildStatsSection(context, totalCount, pendingCount, completedCount),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Secondary Quick Actions
              _buildSecondaryActions(context),
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
    final name = displayName ?? 'home.welcome'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'home.welcome_subtitle'.tr(),
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

  Widget _buildStatsSection(
    BuildContext context,
    int totalCount,
    int pendingCount,
    int completedCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppTheme.spacing12;
        final cardWidth =
            (constraints.maxWidth - (spacing * 2)) / 3; // three cards + two gaps

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.your_stats'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    icon: Icons.assignment_outlined,
                    value: '$totalCount',
                    label: 'home.total_consultations'.tr(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    icon: Icons.pending_actions_outlined,
                    value: '$pendingCount',
                    label: 'home.pending_requests'.tr(),
                    color: Theme.of(context)
                        .extension<AppSemanticColors>()!
                        .warning,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    value: '$completedCount',
                    label: 'home.completed'.tr(),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryCTA(BuildContext context) {
    return PrimaryCTAButton(
      icon: Icons.search_outlined,
      title: 'home.browse_doctors'.tr(),
      subtitle: 'home.browse_doctors_subtitle'.tr(),
      onPressed: () {
        _navigateToTab(context, 1);
      },
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.notifications_outlined,
                  title: 'home.notifications'.tr(),
                  description: 'home.notifications_desc'.tr(),
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.help_outline,
                  title: 'home.help_center'.tr(),
                  description: 'home.help_center_desc'.tr(),
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () {
                    // TODO: Navigate to Help Center
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveConsultationsSection(
    BuildContext context,
    List<ConsultationModel> activeConsultations,
  ) {
    final hasConsultations = activeConsultations.isNotEmpty;

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
            if (hasConsultations)
              TextButton(
                onPressed: () {
                  _navigateToTab(context, 2);
                },
                child: Text('home.view_all'.tr()),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Show empty state or actual consultation cards
        if (!hasConsultations)
          OnboardingCard(
            icon: Icons.assignment_outlined,
            title: 'home.no_active_consultations'.tr(),
            description: 'home.no_active_consultations_desc'.tr(),
            actionText: 'home.learn_how'.tr(),
            onActionTap: () {
              // TODO: Navigate to help/tutorial
            },
          )
        else
          Column(
            children: activeConsultations.map((consultation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                child: ConsultationCard(
                  consultation: consultation,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RequestDetailScreen(
                          consultation: consultation,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
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


