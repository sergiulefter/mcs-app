import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/controllers/doctor_profile_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/doctor/screens/doctor_profile_edit_screen.dart';
import 'package:mcs_app/views/doctor/widgets/cards/doctor_request_card.dart';
import 'package:mcs_app/views/doctor/screens/doctor_notifications_screen.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/home/home_sections.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';

/// Doctor home screen - Dashboard with stats, availability, and recent requests
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key, this.onNavigateToRequests});

  final VoidCallback? onNavigateToRequests;

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeProfile());
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeConsultations());
  }

  Future<void> _primeProfile() async {
    final authController = context.read<AuthController>();
    final doctorId = authController.currentUser?.uid;
    if (doctorId == null) return;
    final profile = context.read<DoctorProfileController>();
    await profile.prime(doctorId, force: true);
  }

  Future<void> _primeConsultations({bool force = false}) async {
    final authController = context.read<AuthController>();
    final doctorId = authController.currentUser?.uid;
    if (doctorId == null) return;

    final controller = context.read<DoctorConsultationsController>();
    await controller.primeForDoctor(doctorId, force: force);
  }

  /// Get time-based greeting based on current hour
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'doctor.home.good_morning'.tr();
    } else if (hour < 17) {
      return 'doctor.home.good_afternoon'.tr();
    } else {
      return 'doctor.home.good_evening'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DoctorProfileController>();
    final doctor = profile.doctor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.isLoading && doctor == null)
                const Padding(
                  padding: EdgeInsets.only(top: AppTheme.spacing32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (doctor != null) ...[
                // Header with avatar, greeting, and notification button
                _buildHeader(context, doctor),

                // Profile Completion Banner (if incomplete)
                if (!doctor.isProfileComplete)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing24,
                    ),
                    child: ProfileCompletionBanner(
                      onCompleteProfile: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DoctorProfileEditScreen(),
                          ),
                        );
                        if (result == true) {
                          await profile.refresh();
                        }
                      },
                    ),
                  ),

                // Availability Status Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                  ),
                  child: _buildAvailabilityCard(context, doctor),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                  ),
                  child: Consumer<DoctorConsultationsController>(
                    builder: (context, controller, _) {
                      if (controller.isLoading &&
                          controller.consultations.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppTheme.spacing16,
                            ),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildStatsGrid(context, controller);
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Pending Requests Section
                Consumer<DoctorConsultationsController>(
                  builder: (context, controller, _) {
                    if (controller.isLoading &&
                        controller.consultations.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.spacing16,
                          ),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildPendingRequestsSection(context, controller);
                  },
                ),
                const SizedBox(height: AppTheme.spacing32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Header with avatar, greeting, online status, and notification button
  Widget _buildHeader(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing24,
        AppTheme.spacing32,
        AppTheme.spacing24,
        AppTheme.spacing8,
      ),
      child: Row(
        children: [
          // Avatar with online status indicator
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(color: colorScheme.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    doctor.fullName.isNotEmpty
                        ? doctor.fullName[0].toUpperCase()
                        : 'D',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Online status indicator
              if (doctor.isCurrentlyAvailable)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.spacing12),

          // Greeting and name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Dr. ${doctor.fullName}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Notification button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              iconSize: 20,
              color: colorScheme.onSurfaceVariant,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorNotificationsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Availability status card with toggle switch styling
  Widget _buildAvailabilityCard(BuildContext context, DoctorModel doctor) {
    final isAvailable = doctor.isCurrentlyAvailable;
    final isProfileComplete = doctor.isProfileComplete;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isAvailable ? colorScheme.secondary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'doctor.home.status_label'.tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  isAvailable
                      ? 'doctor.home.available_status'.tr()
                      : 'doctor.home.unavailable_status'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Show hint when toggle is disabled due to incomplete profile
                if (!isProfileComplete && !doctor.isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing4),
                    child: Text(
                      'doctor.home.availability_disabled_hint'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Toggle switch (visual representation)
          Container(
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isAvailable
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stats grid with 3 compact cards
  Widget _buildStatsGrid(
    BuildContext context,
    DoctorConsultationsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    final total = controller.consultations.length;
    final pending = controller.newCount;
    final completed = controller.completedCount;

    return Row(
      children: [
        // Total Patients card
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.group,
            value: _formatStatValue(total),
            label: 'doctor.home.total_patients'.tr(),
            iconColor: colorScheme.primary,
            iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),

        // Pending Reviews card (amber/warning styled)
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.rate_review,
            value: '$pending',
            label: 'doctor.home.pending_reviews'.tr(),
            iconColor: semantic.warning,
            iconBgColor: semantic.warning.withValues(alpha: 0.15),
            cardBgColor: semantic.warning.withValues(alpha: 0.08),
            labelColor: semantic.warning,
            isHighlighted: pending > 0,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),

        // Completed card
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.assignment_turned_in,
            value: '$completed',
            label: 'doctor.home.completed'.tr(),
            iconColor: const Color(0xFF9333EA), // Purple
            iconBgColor: const Color(0xFF9333EA).withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  /// Format stat value (e.g., 1200 -> 1.2k)
  String _formatStatValue(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  /// Individual stat card widget
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color iconBgColor,
    Color? cardBgColor,
    Color? labelColor,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: cardBgColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isHighlighted
              ? iconColor.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),

          // Label
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: labelColor ?? colorScheme.onSurfaceVariant,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Pending requests section with header and card list
  Widget _buildPendingRequestsSection(
    BuildContext context,
    DoctorConsultationsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentPending = controller.recentPendingConsultations
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
          child: Row(
            children: [
              Text(
                'doctor.home.pending_requests'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              // Count badge
              if (recentPending.isNotEmpty)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${recentPending.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              // View All button
              TextButton(
                onPressed: widget.onNavigateToRequests,
                child: Text(
                  'doctor.home.view_all'.tr(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Request cards
        if (recentPending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
            child: SurfaceCard(
              child: AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'doctor.home.no_requests'.tr(),
                subtitle: 'doctor.home.no_requests_desc'.tr(),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
            child: Column(
              children: recentPending
                  .map(
                    (consultation) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing12,
                      ),
                      child: DoctorRequestCard(
                        consultation: consultation,
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: controller,
                                child: RequestReviewScreen(
                                  consultationId: consultation.id,
                                ),
                              ),
                            ),
                          );
                          if (result == true) {
                            _primeConsultations(force: true);
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
