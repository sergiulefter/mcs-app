import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/controllers/doctor_profile_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/patient/widgets/cards/stat_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/home/home_sections.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/doctor/screens/doctor_profile_edit_screen.dart';
import 'package:mcs_app/views/doctor/widgets/doctor_request_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';

/// Doctor home screen - Dashboard with stats, availability, and recent requests
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DoctorProfileController>();
    final doctor = profile.doctor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.isLoading && doctor == null)
                const Padding(
                  padding: EdgeInsets.only(top: AppTheme.spacing32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (doctor != null) ...[
              // Welcome Header
              _buildWelcomeHeader(context, doctor),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Profile Completion Banner (if incomplete)
              if (!doctor.isProfileComplete)
                ProfileCompletionBanner(
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

              // Availability status
              _buildAvailabilityCard(context, doctor),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Stats Section
              SectionHeader(title: 'doctor.home.stats_title'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              Consumer<DoctorConsultationsController>(
                builder: (context, controller, _) {
                  if (controller.isLoading && controller.consultations.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing16,
                        ),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return _buildStatsRow(context, controller);
                },
              ),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Recent Requests Section
              SectionHeader(title: 'doctor.home.recent_requests'.tr()),
              const SizedBox(height: AppTheme.spacing16),
              Consumer<DoctorConsultationsController>(
                builder: (context, controller, _) {
                  if (controller.isLoading && controller.consultations.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing16,
                        ),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return _buildRecentRequestsCard(context, controller);
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

  Widget _buildWelcomeHeader(BuildContext context, DoctorModel doctor) {
    final doctorName = doctor.fullName;
    final specialty = 'specialties.${doctor.specialty.name}'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'doctor.home.welcome'.tr(namedArgs: {'name': doctorName}),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (specialty.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            specialty,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilityCard(BuildContext context, DoctorModel doctor) {
    final isAvailable = doctor.isCurrentlyAvailable;
    final isProfileComplete = doctor.isProfileComplete;
    final colorScheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      backgroundColor: isAvailable
          ? colorScheme.secondary.withValues(alpha: 0.1)
          : colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? colorScheme.secondary.withValues(alpha: 0.2)
                      : colorScheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: isAvailable ? colorScheme.secondary : colorScheme.error,
                  size: AppTheme.iconLarge,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'doctor.home.availability'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      isAvailable
                          ? 'doctor.home.available'.tr()
                          : 'doctor.home.unavailable'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isAvailable
                                ? colorScheme.secondary
                                : colorScheme.error,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Show hint when toggle is disabled due to incomplete profile
          if (!isProfileComplete && !doctor.isAvailable)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing8),
              child: Text(
                'doctor.home.availability_disabled_hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    DoctorConsultationsController controller,
  ) {
    final total = controller.consultations.length;
    final pending =
        controller.consultations.where((c) => c.status == 'pending').length;
    final completed =
        controller.consultations.where((c) => c.status == 'completed').length;

    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppTheme.spacing12;
        final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: StatCard(
                value: '$total',
                label: 'common.total'.tr(),
                icon: Icons.assignment_outlined,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                value: '$pending',
                label: 'common.status.pending'.tr(),
                icon: Icons.pending_actions_outlined,
                color: semantic.warning,
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                value: '$completed',
                label: 'common.status.completed'.tr(),
                icon: Icons.task_alt_outlined,
                color: colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentRequestsCard(
    BuildContext context,
    DoctorConsultationsController controller,
  ) {
    final pending = controller.consultations
        .where((c) => c.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentPending = pending.take(3).toList();

    if (recentPending.isEmpty) {
      return SurfaceCard(
        child: AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'doctor.home.no_requests'.tr(),
          subtitle: 'doctor.home.no_requests_desc'.tr(),
        ),
      );
    }

    return Column(
      children: recentPending
          .map(
            (consultation) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
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
    );
  }
}
