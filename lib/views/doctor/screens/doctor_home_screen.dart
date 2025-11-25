import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/stat_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/home/home_sections.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/doctor/screens/doctor_profile_edit_screen.dart';

/// Doctor home screen - Dashboard with stats, availability, and recent requests
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctor;
  bool _isLoading = true;
  bool _isTogglingAvailability = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final doctor = await _doctorService.fetchDoctorById(userId);
      if (mounted) {
        setState(() {
          _doctor = doctor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAvailability() async {
    if (_doctor == null || _isTogglingAvailability) return;

    setState(() => _isTogglingAvailability = true);

    try {
      final newAvailability = !_doctor!.isAvailable;
      await _doctorService.updateAvailability(_doctor!.uid, newAvailability);

      if (mounted) {
        setState(() {
          _doctor = _doctor!.copyWith(isAvailable: newAvailability);
          _isTogglingAvailability = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAvailability
                  ? 'doctor.home.now_available'.tr()
                  : 'doctor.home.now_unavailable'.tr(),
            ),
            backgroundColor: newAvailability
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingAvailability = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('doctor.home.availability_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDoctorData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppTheme.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Profile Completion Banner (if incomplete)
                if (_doctor != null && !_doctor!.isProfileComplete)
                  ProfileCompletionBanner(
                    onCompleteProfile: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorProfileEditScreen(),
                        ),
                      );
                      // Reload doctor data if profile was updated
                      if (result == true) {
                        _loadDoctorData();
                      }
                    },
                  ),

                // Availability Toggle
                _buildAvailabilityCard(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Stats Section
                SectionHeader(title: 'doctor.home.stats_title'.tr()),
                const SizedBox(height: AppTheme.spacing16),
                _buildStatsRow(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Recent Requests Section
                SectionHeader(title: 'doctor.home.recent_requests'.tr()),
                const SizedBox(height: AppTheme.spacing16),
                _buildRecentRequestsCard(context),
                const SizedBox(height: AppTheme.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final doctorName = _doctor?.fullName ?? 'doctor.home.doctor'.tr();
    final specialty = _doctor?.specialty.name ?? '';

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

  Widget _buildAvailabilityCard(BuildContext context) {
    final isAvailable = _doctor?.isCurrentlyAvailable ?? false;
    final isProfileComplete = _doctor?.isProfileComplete ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    // Disable toggle if: toggling in progress, OR profile incomplete and trying to turn ON
    final bool canToggle = !_isTogglingAvailability &&
        (isProfileComplete || (_doctor?.isAvailable ?? false));

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
              Switch(
                value: _doctor?.isAvailable ?? false,
                onChanged: canToggle ? (_) => _toggleAvailability() : null,
                activeTrackColor: colorScheme.secondary.withValues(alpha: 0.5),
                activeThumbColor: colorScheme.secondary,
              ),
            ],
          ),
          // Show hint when toggle is disabled due to incomplete profile
          if (!isProfileComplete && !(_doctor?.isAvailable ?? false))
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

  Widget _buildStatsRow(BuildContext context) {
    // TODO: Replace with real data from Firestore
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          StatCard(
            value: '0',
            label: 'doctor.home.stats.pending'.tr(),
            icon: Icons.pending_actions_outlined,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: AppTheme.spacing12),
          StatCard(
            value: '0',
            label: 'doctor.home.stats.in_review'.tr(),
            icon: Icons.rate_review_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacing12),
          StatCard(
            value: '0',
            label: 'doctor.home.stats.completed'.tr(),
            icon: Icons.task_alt_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRequestsCard(BuildContext context) {
    // TODO: Replace with real data from Firestore
    return SurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'doctor.home.no_requests'.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'doctor.home.no_requests_desc'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
