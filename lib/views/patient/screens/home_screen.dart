import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/navigation_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/buttons/primary_cta_button.dart';
import 'package:mcs_app/views/patient/widgets/home/home_sections.dart';
import 'complete_profile_screen.dart';
import 'help_center_screen.dart';
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

    if (authController.currentUser == null) return;

    final userId = authController.currentUser!.uid;
    if (consultationsController.hasDataForUser(userId)) {
      return;
    }

    await consultationsController.primeForUser(userId);
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
              HomeWelcomeHeader(
                greeting: _getGreeting(),
                name: user?.displayName ?? 'home.welcome'.tr(),
                onNotificationsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Profile Completion Banner (if incomplete)
              if (user != null && !user.profileCompleted)
                ProfileCompletionBanner(
                  onCompleteProfile: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CompleteProfileScreen(),
                      ),
                    );
                  },
                ),

              // Active Consultations Section with real data
              ActiveConsultationsSection(
                activeConsultations: activeConsultations,
                onViewAll: activeConsultations.isNotEmpty
                    ? () => _navigateToTab(context, 2)
                    : null,
                onConsultationTap: (consultation) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RequestDetailScreen(
                        consultation: consultation,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Primary CTA - Browse Doctors
              _buildPrimaryCTA(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Stats Dashboard Section with real data
              HomeStatsSection(
                totalCount: totalCount,
                pendingCount: pendingCount,
                completedCount: completedCount,
              ),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Secondary Quick Actions
              HomeQuickActions(
                onHelpCenterTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Medical Disclaimer
              const MedicalDisclaimerCard(),
            ],
          ),
        ),
      ),
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

  void _navigateToTab(BuildContext context, int tabIndex) {
    final navigationController = NavigationController.of(context);
    navigationController?.onTabChange(tabIndex);
  }
}
