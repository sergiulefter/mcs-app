import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/doctor/widgets/cards/doctor_request_card.dart';
import 'package:mcs_app/views/doctor/widgets/cards/doctor_request_card_skeleton.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header with title and segment filter
            _buildStickyHeader(context),

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

  Widget _buildStickyHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withValues(alpha: 0.95)
            : AppTheme.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing12,
              AppTheme.spacing16,
              AppTheme.spacing8,
            ),
            child: Text(
              'doctor.requests.incoming_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Segment filter (horizontal scrollable pills)
          Consumer<DoctorConsultationsController>(
            builder: (context, controller, _) {
              return _buildSegmentFilter(context, controller);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentFilter(
    BuildContext context,
    DoctorConsultationsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final segments = [
      {'key': 'new', 'label': 'doctor.requests.segments.new'.tr()},
      {
        'key': 'in_progress',
        'label': 'doctor.requests.segments.in_progress'.tr(),
      },
      {'key': 'completed', 'label': 'doctor.requests.segments.completed'.tr()},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      child: Row(
        children: segments.map((segment) {
          final isSelected = controller.selectedSegment == segment['key'];
          return Padding(
            padding: EdgeInsets.only(
              right: segment != segments.last ? AppTheme.spacing12 : 0,
            ),
            child: GestureDetector(
              onTap: () => controller.setSegmentFilter(segment['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : (isDark ? AppTheme.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  segment['label']!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.slate300 : AppTheme.slate600),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                style: TextStyle(
                  color: isDark ? AppTheme.slate600 : AppTheme.slate400,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
