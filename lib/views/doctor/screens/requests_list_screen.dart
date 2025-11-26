import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/patient/widgets/filters/themed_filter_chip.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
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
                      (consultation) =>
                          _RequestCard(consultation: consultation),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.consultation});

  final ConsultationModel consultation;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DoctorConsultationsController>();
    final patient = controller.patientProfile(consultation.patientId);
    final patientName =
        patient?.displayName ?? patient?.email ?? 'doctor.requests.patient_unknown'.tr();
    final dateText = DateFormat.yMMMd().add_Hm().format(consultation.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: SurfaceCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: controller,
                  child:
                      RequestReviewScreen(consultationId: consultation.id),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      consultation.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _buildBadge(
                    context,
                    _urgencyLabel(consultation.urgency),
                    _urgencyColor(context, consultation.urgency),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                consultation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: AppTheme.iconSmall,
                      color: Theme.of(context).hintColor),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      patientName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  _buildBadge(
                    context,
                    _statusLabel(consultation.status),
                    consultation.getStatusColor(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: AppTheme.iconSmall,
                      color: Theme.of(context).hintColor),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'doctor.requests.status.pending'.tr();
      case 'in_review':
        return 'doctor.requests.status.in_review'.tr();
      case 'info_requested':
        return 'doctor.requests.status.info_requested'.tr();
      case 'completed':
        return 'doctor.requests.status.completed'.tr();
      case 'cancelled':
        return 'doctor.requests.status.cancelled'.tr();
      default:
        return status;
    }
  }

  String _urgencyLabel(String urgency) {
    switch (urgency) {
      case 'urgent':
        return 'doctor.requests.urgency.urgent'.tr();
      case 'emergency':
        return 'doctor.requests.urgency.emergency'.tr();
      default:
        return 'doctor.requests.urgency.normal'.tr();
    }
  }

  Color _urgencyColor(BuildContext context, String urgency) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (urgency) {
      case 'urgent':
        return AppTheme.warningOrange;
      case 'emergency':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }
}
