import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/controllers/navigation_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/consultation_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/consultation_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'request_detail_screen.dart';

/// Patient consultations screen matching the HTML/CSS design.
/// Features sticky header with title and horizontal scrollable filter chips.
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
      try {
        await consultationsController.fetchUserConsultations(
          authController.currentUser!.uid,
        );
      } catch (e) {
        debugPrint('Error loading consultations: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading consultations: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _fetchConsultations,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultationsController = context.watch<ConsultationsController>();
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
              child:
                  consultationsController.isLoading &&
                      !consultationsController.hasPrimedForUser
                  ? _buildLoadingState()
                  : _buildConsultationsContent(consultationsController),
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
              'consultations.title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Segment filter (horizontal scrollable pills)
          Consumer<ConsultationsController>(
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
    ConsultationsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final segments = [
      {'key': 'active', 'label': 'consultations.segments.active'.tr()},
      {'key': 'completed', 'label': 'common.status.completed'.tr()},
      {'key': 'all', 'label': 'common.all'.tr()},
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
      itemBuilder: (context, index) => const ConsultationCardSkeleton(),
    );
  }

  Widget _buildConsultationsContent(ConsultationsController controller) {
    final consultations = controller.segmentFilteredConsultations;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _fetchConsultations,
      child: consultations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: [_buildEmptyStateContent(controller)],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                // Load more when user scrolls near the bottom
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
                  controller.fetchMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                itemCount:
                    consultations.length +
                    (controller.hasMore ? 1 : 1), // +1 for footer or loading
                itemBuilder: (context, index) {
                  // Loading indicator at the end
                  if (index == consultations.length && controller.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.spacing16,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Footer: "End of consultations"
                  if (index == consultations.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing24,
                      ),
                      child: Center(
                        child: Text(
                          'consultations.end_of_consultations'
                              .tr()
                              .toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.slate600
                                : AppTheme.slate400,
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
                      bottom: index < consultations.length - 1
                          ? AppTheme.spacing16
                          : 0,
                    ),
                    child: ConsultationCard(
                      consultation: consultation,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                RequestDetailScreen(consultation: consultation),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
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
          ElevatedButton(onPressed: action, child: Text(actionLabel)),
        ],
      ],
    );
  }
}
