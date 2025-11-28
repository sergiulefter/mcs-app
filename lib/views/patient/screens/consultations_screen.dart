import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/controllers/navigation_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/consultation_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/consultation_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/filters/consultation_segment_filter.dart';
import 'package:mcs_app/views/patient/widgets/filters/themed_filter_chip.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'request_detail_screen.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final consultationsController = context.watch<ConsultationsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('consultations.title'.tr()),
      ),
      body: consultationsController.isLoading
          ? _buildLoadingState()
          : consultationsController.error != null
              ? _buildErrorState()
              : _buildConsultationsContent(consultationsController),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Show segment filter even during loading
        Consumer<ConsultationsController>(
          builder: (context, controller, _) => ConsultationSegmentFilter(
            selectedSegment: controller.selectedSegment,
            onSegmentChanged: controller.setSegmentFilter,
            onFilterTap: () => _showFilterBottomSheet(context),
            activeCount: null,
            completedCount: null,
          ),
        ),
        // Skeleton cards
        Expanded(
          child: ListView.separated(
            padding: AppTheme.screenPadding,
            itemCount: 4,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppTheme.spacing16),
            itemBuilder: (context, index) => const ConsultationCardSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppEmptyState(
              icon: Icons.error_outline,
              title: 'consultations.error_title'.tr(),
              subtitle: 'consultations.error_subtitle'.tr(),
              iconColor:
                  Theme.of(context).extension<AppSemanticColors>()?.error ??
                      Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: _fetchConsultations,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationsContent(ConsultationsController controller) {
    final consultations = controller.segmentFilteredConsultations;

    return RefreshIndicator(
      onRefresh: _fetchConsultations,
      child: Column(
        children: [
          // Segment filter
          ConsultationSegmentFilter(
            selectedSegment: controller.selectedSegment,
            onSegmentChanged: controller.setSegmentFilter,
            onFilterTap: () => _showFilterBottomSheet(context),
            activeCount: controller.activeCount,
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
                    padding: AppTheme.screenPadding,
                    itemCount: consultations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppTheme.spacing16),
                    itemBuilder: (context, index) {
                      final consultation = consultations[index];
                      return ConsultationCard(
                        consultation: consultation,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  RequestDetailScreen(consultation: consultation),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent(ConsultationsController controller) {
    final segment = controller.selectedSegment;

    // Different empty states based on segment
    String title;
    String subtitle;
    IconData icon;
    VoidCallback? action;
    String? actionLabel;

    switch (segment) {
      case 'active':
        title = 'consultations.empty.active_title'.tr();
        subtitle = 'consultations.empty.active_subtitle'.tr();
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        title = 'consultations.empty.completed_title'.tr();
        subtitle = 'consultations.empty.completed_subtitle'.tr();
        icon = Icons.history_outlined;
        break;
      case 'all':
      default:
        title = 'consultations.empty_state_title'.tr();
        subtitle = 'consultations.empty_state_subtitle'.tr();
        icon = Icons.assignment_outlined;
        // Add action to navigate to doctors
        action = () {
          final nav = NavigationController.of(context);
          nav?.onTabChange(1); // Navigate to Doctors tab
        };
        actionLabel = 'consultations.empty.browse_doctors'.tr();
        break;
    }

    return Column(
      children: [
        AppEmptyState(
          icon: icon,
          title: title,
          subtitle: subtitle,
          iconColor: Theme.of(context).colorScheme.primary,
        ),
        if (action != null && actionLabel != null) ...[
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton(
            onPressed: action,
            child: Text(actionLabel),
          ),
        ],
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final consultationsController = context.read<ConsultationsController>();

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
      {'key': 'pending', 'label': 'consultations.status.pending'.tr()},
      {'key': 'in_review', 'label': 'consultations.status.in_review'.tr()},
      {'key': 'completed', 'label': 'consultations.status.completed'.tr()},
      {'key': 'cancelled', 'label': 'consultations.status.cancelled'.tr()},
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
              'consultations.filter_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Status filters
            Text(
              'consultations.filter_status'.tr(),
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
