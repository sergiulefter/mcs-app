import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/doctor/widgets/doctor_request_card.dart';
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.requests.title'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<DoctorConsultationsController>(
          builder: (context, controller, _) {
            if (controller.isLoading && !_initialized) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => _primeController(force: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.screenPadding,
                children: [
                  _buildFilters(controller),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  if (controller.error != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacing16),
                      child: Text(
                        controller.error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (controller.filteredConsultations.isEmpty)
                    AppEmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'doctor.requests.empty_title'.tr(),
                      subtitle: 'doctor.requests.empty_subtitle'.tr(),
                    )
                  else
                    ...controller.filteredConsultations.map(
                      (consultation) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacing16),
                        child: DoctorRequestCard(
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
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(DoctorConsultationsController controller) {
    final filters = <String, String>{
      'all': 'doctor.requests.filters.all'.tr(),
      'pending': 'doctor.requests.filters.pending'.tr(),
      'in_review': 'doctor.requests.filters.in_review'.tr(),
      'info_requested': 'doctor.requests.filters.info_requested'.tr(),
      'completed': 'doctor.requests.filters.completed'.tr(),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: ThemedFilterChip(
                label: entry.value,
                selected: controller.selectedStatus == entry.key,
                onSelected: (_) => controller.setStatusFilter(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}
