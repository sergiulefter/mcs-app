import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/consultations_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/consultation_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/themed_filter_chip.dart';
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
    final filteredConsultations = consultationsController.filteredConsultations;

    return Scaffold(
      appBar: AppBar(
        title: Text('consultations.title'.tr()),
      ),
      body: consultationsController.isLoading
          ? _buildLoadingState()
          : consultationsController.error != null
              ? _buildErrorState()
              : _buildConsultationsContent(filteredConsultations),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
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
              child: Text('consultations.retry_button'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationsContent(List<dynamic> consultations) {
    return RefreshIndicator(
      onRefresh: _fetchConsultations,
      child: Column(
        children: [
          _buildStatusFilters(),
          Expanded(
            child: consultations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.screenPadding,
                    children: [
                      _buildEmptyStateContent(),
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

  Widget _buildEmptyStateContent() {
    final consultationsController = context.watch<ConsultationsController>();

    return AppEmptyState(
      icon: Icons.assignment_outlined,
      title: consultationsController.selectedStatus == 'all'
          ? 'consultations.empty_state_title'.tr()
          : 'consultations.empty_state_filtered_title'.tr(),
      subtitle: consultationsController.selectedStatus == 'all'
          ? 'consultations.empty_state_subtitle'.tr()
          : 'consultations.empty_state_filtered_subtitle'.tr(),
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildStatusFilters() {
    final consultationsController = context.watch<ConsultationsController>();
    final selectedStatus = consultationsController.selectedStatus;

    final statuses = [
      {'key': 'all', 'label': 'consultations.filter.all'.tr()},
      {'key': 'pending', 'label': 'consultations.filter.pending'.tr()},
      {'key': 'in_review', 'label': 'consultations.filter.in_review'.tr()},
      {'key': 'completed', 'label': 'consultations.filter.completed'.tr()},
      {'key': 'cancelled', 'label': 'consultations.filter.cancelled'.tr()},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing32,
        vertical: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = selectedStatus == status['key'];
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: ThemedFilterChip(
                label: status['label']!,
                selected: isSelected,
                onSelected: (_) =>
                    consultationsController.setStatusFilter(status['key']!),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


