import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/doctor/widgets/doctor_request_card.dart';
import 'package:mcs_app/views/doctor/widgets/doctor_request_card_skeleton.dart';
import 'package:mcs_app/views/doctor/widgets/doctor_request_segment_filter.dart';
import 'package:mcs_app/views/patient/widgets/filters/themed_filter_chip.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:provider/provider.dart';

/// Doctor-facing list of consultation requests with status filters.
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

    await context
        .read<DoctorConsultationsController>()
        .primeForDoctor(doctorId, force: force);
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.requests.title'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<DoctorConsultationsController>(
          builder: (context, controller, _) {
            if (controller.isLoading && !_initialized) {
              return _buildLoadingState(controller);
            }

            return RefreshIndicator(
              onRefresh: () => _primeController(force: true),
              child: _buildContent(controller),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(DoctorConsultationsController controller) {
    return Column(
      children: [
        // Show segment filter even during loading
        DoctorRequestSegmentFilter(
          selectedSegment: controller.selectedSegment,
          onSegmentChanged: controller.setSegmentFilter,
          onFilterTap: () => _showFilterBottomSheet(context),
        ),
        // Skeleton cards
        Expanded(
          child: ListView.separated(
            padding: AppTheme.screenPadding,
            itemCount: 4,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppTheme.spacing16),
            itemBuilder: (context, index) => const DoctorRequestCardSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(DoctorConsultationsController controller) {
    final consultations = controller.segmentFilteredConsultations;

    return Column(
      children: [
        // Segment filter
        DoctorRequestSegmentFilter(
          selectedSegment: controller.selectedSegment,
          onSegmentChanged: controller.setSegmentFilter,
          onFilterTap: () => _showFilterBottomSheet(context),
          newCount: controller.newCount,
          inProgressCount: controller.inProgressCount,
          completedCount: controller.completedCount,
        ),
        // Content
        Expanded(
          child: consultations.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.screenPadding,
                  children: [
                    _buildEmptyStateContent(controller),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.screenPadding,
                  itemCount: consultations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppTheme.spacing16),
                  itemBuilder: (context, index) {
                    final consultation = consultations[index];
                    return DoctorRequestCard(
                      consultation: consultation,
                      onTap: () {
                        Navigator.push(
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
                      },
                    );
                  },
                ),
        ),
        // Error display
        if (controller.error != null)
          Padding(
            padding: AppTheme.screenPadding,
            child: Text(
              controller.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
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

  void _showFilterBottomSheet(BuildContext context) {
    final consultationsController =
        context.read<DoctorConsultationsController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedStatus: consultationsController.selectedStatus,
        onStatusChanged: (status) {
          consultationsController.setStatusFilter(status);
        },
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const _FilterBottomSheet({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final statuses = [
      {'key': 'all', 'label': 'common.all'.tr()},
      {'key': 'pending', 'label': 'common.status.pending'.tr()},
      {'key': 'in_review', 'label': 'common.status.in_review'.tr()},
      {'key': 'info_requested', 'label': 'common.status.info_requested'.tr()},
      {'key': 'completed', 'label': 'common.status.completed'.tr()},
      {'key': 'cancelled', 'label': 'common.status.cancelled'.tr()},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Title
            Text(
              'doctor.requests.filter_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Status filters
            Text(
              'doctor.requests.filter_status'.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: statuses.map((status) {
                final isSelected = _selectedStatus == status['key'];
                return ThemedFilterChip(
                  label: status['label']!,
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = status['key']!;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacing32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = 'all';
                      });
                    },
                    child: Text('common.clear'.tr()),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onStatusChanged(_selectedStatus);
                      Navigator.of(context).pop();
                    },
                    child: Text('common.apply'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
