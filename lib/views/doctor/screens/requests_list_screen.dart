import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/doctor/widgets/cards/doctor_request_card.dart';
import 'package:mcs_app/views/doctor/widgets/cards/doctor_request_card_skeleton.dart';
import 'package:mcs_app/views/doctor/widgets/filters/doctor_request_segment_filter.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:provider/provider.dart';

/// Doctor-facing list of consultation requests with segment filters.
/// Matches the modern HTML/CSS design.
class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({super.key});

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeController());
  }

  Future<void> _primeController({bool force = false}) async {
    final auth = context.read<AuthController>();
    final doctorId = auth.currentUser?.uid;
    if (doctorId == null) return;

    await context.read<DoctorConsultationsController>().primeForDoctor(
      doctorId,
      force: force,
    );
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header with title and segment filter
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacing16,
                      AppTheme.spacing16,
                      AppTheme.spacing16,
                      AppTheme.spacing8,
                    ),
                    child: Text(
                      'doctor.requests.incoming_title'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),

                  // Segment filter
                  Consumer<DoctorConsultationsController>(
                    builder: (context, controller, _) {
                      return DoctorRequestSegmentFilter(
                        selectedSegment: controller.selectedSegment,
                        onSegmentChanged: controller.setSegmentFilter,
                        newCount: controller.newCount,
                        inProgressCount: controller.inProgressCount,
                        completedCount: controller.completedCount,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: Consumer<DoctorConsultationsController>(
                builder: (context, controller, _) {
                  if (controller.isLoading && !_initialized) {
                    return _buildLoadingState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => _primeController(force: true),
                    child: _buildContent(controller),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: 4,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.spacing16),
      itemBuilder: (context, index) => const DoctorRequestCardSkeleton(),
    );
  }

  Widget _buildContent(DoctorConsultationsController controller) {
    final consultations = controller.segmentFilteredConsultations;
    final colorScheme = Theme.of(context).colorScheme;

    if (consultations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [_buildEmptyStateContent(controller)],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: consultations.length + 1, // +1 for footer
      itemBuilder: (context, index) {
        if (index == consultations.length) {
          // Footer: "End of requests"
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
            child: Center(
              child: Text(
                'doctor.requests.end_of_requests'.tr().toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
          );
        }

        final consultation = consultations[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < consultations.length - 1 ? AppTheme.spacing16 : 0,
          ),
          child: DoctorRequestCard(
            consultation: consultation,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: controller,
                    child: RequestReviewScreen(consultationId: consultation.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateContent(DoctorConsultationsController controller) {
    final segment = controller.selectedSegment;

    // Different empty states based on segment
    String title;
    String subtitle;
    IconData icon;

    switch (segment) {
      case 'new':
        title = 'doctor.requests.empty.new_title'.tr();
        subtitle = 'doctor.requests.empty.new_subtitle'.tr();
        icon = Icons.inbox_outlined;
        break;
      case 'in_progress':
        title = 'doctor.requests.empty.in_progress_title'.tr();
        subtitle = 'doctor.requests.empty.in_progress_subtitle'.tr();
        icon = Icons.pending_actions_outlined;
        break;
      case 'completed':
        title = 'doctor.requests.empty.completed_title'.tr();
        subtitle = 'doctor.requests.empty.completed_subtitle'.tr();
        icon = Icons.check_circle_outline;
        break;
      default:
        title = 'doctor.requests.empty_title'.tr();
        subtitle = 'doctor.requests.empty_subtitle'.tr();
        icon = Icons.assignment_outlined;
        break;
    }

    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}
