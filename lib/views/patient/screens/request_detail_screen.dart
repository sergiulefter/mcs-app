import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/doctor/widgets/urgency_badge.dart';
import 'doctor_profile_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.consultation,
  });

  final ConsultationModel consultation;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late final DoctorService _doctorService;
  Future<DoctorModel?>? _doctorFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _doctorService = DoctorService();
    if (widget.consultation.doctorId != null) {
      _doctorFuture = _doctorService.fetchDoctorById(widget.consultation.doctorId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();

    return Scaffold(
      appBar: AppBar(
        title: Text('request_detail.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(context, consultation, colorScheme, semantic),
            const SizedBox(height: AppTheme.sectionSpacing),
            _buildSectionCard(
              context,
              title: 'request_detail.request_info'.tr(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabelValue(
                    context,
                    label: 'request_detail.title_label'.tr(),
                    value: consultation.title,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLabelValue(
                    context,
                    label: 'request_detail.description_label'.tr(),
                    value: consultation.description,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLabelValue(
                    context,
                    label: 'request_detail.created_at'.tr(),
                    value: DateFormat.yMMMMd().format(consultation.createdAt),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLabelValue(
                    context,
                    label: 'request_detail.updated_at'.tr(),
                    value: DateFormat.yMMMMd().format(consultation.updatedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sectionSpacing),
            _buildTimelineSection(context, consultation, colorScheme),
            const SizedBox(height: AppTheme.sectionSpacing),
            _buildDoctorSection(context),
            if (consultation.doctorResponse != null) ...[
              const SizedBox(height: AppTheme.sectionSpacing),
              _buildDoctorResponse(context),
            ],
            const SizedBox(height: AppTheme.sectionSpacing),
            _buildAttachmentsPlaceholder(context),
            const SizedBox(height: AppTheme.sectionSpacing),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context, consultation),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    ConsultationModel consultation,
    ColorScheme colorScheme,
    AppSemanticColors? semantic,
  ) {
    final statusColor = consultation.getStatusColor(context);
    final statusText = 'consultations.status.${consultation.status}'.tr();

    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          UrgencyBadge(urgency: consultation.urgency),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          child,
        ],
      ),
    );
  }

  Widget _buildLabelValue(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(
    BuildContext context,
    ConsultationModel consultation,
    ColorScheme colorScheme,
  ) {
    final items = [
      _TimelineItem(
        label: 'request_detail.timeline.created'.tr(),
        date: consultation.createdAt,
        color: colorScheme.primary,
      ),
      _TimelineItem(
        label: 'request_detail.timeline.updated'.tr(),
        date: consultation.updatedAt,
        color: colorScheme.secondary,
      ),
      if (consultation.completedAt != null)
        _TimelineItem(
          label: 'request_detail.timeline.completed'.tr(),
          date: consultation.completedAt!,
          color: colorScheme.primary,
        ),
    ];

    return _buildSectionCard(
      context,
      title: 'request_detail.timeline.title'.tr(),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            DateFormat.yMMMMd().format(item.date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDoctorSection(BuildContext context) {
    if (_doctorFuture == null) return const SizedBox.shrink();

    return FutureBuilder<DoctorModel?>(
      future: _doctorFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionCard(
            context,
            title: 'request_detail.doctor.title'.tr(),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildSectionCard(
            context,
            title: 'request_detail.doctor.title'.tr(),
            child: AppEmptyState(
              icon: Icons.medical_services_outlined,
              title: 'request_detail.doctor.unassigned_title'.tr(),
              subtitle: 'request_detail.doctor.unassigned_subtitle'.tr(),
              iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        final doctor = snapshot.data!;
        return _buildSectionCard(
          context,
          title: 'request_detail.doctor.title'.tr(),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DoctorProfileScreen(doctor: doctor),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: AppTheme.iconLarge,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'specialties.${doctor.specialty.name}'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorResponse(BuildContext context) {
    final response = widget.consultation.doctorResponse!;
    return _buildSectionCard(
      context,
      title: 'request_detail.doctor_response.title'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMMd().format(response.respondedAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            response.text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (response.recommendations != null &&
              response.recommendations!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildLabelValue(
              context,
              label: 'request_detail.doctor_response.recommendations_label'.tr(),
              value: response.recommendations ?? '',
            ),
          ],
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.spacing12,
            runSpacing: AppTheme.spacing8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_outlined,
                    size: AppTheme.iconSmall,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'request_detail.doctor_response.follow_up_needed'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: (response.followUpNeeded
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Text(
                  response.followUpNeeded
                      ? 'common.yes'.tr()
                      : 'common.no'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: response.followUpNeeded
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPlaceholder(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'request_detail.attachments.title'.tr(),
      child: AppEmptyState(
        icon: Icons.attach_file_outlined,
        title: 'request_detail.attachments.placeholder_title'.tr(),
        subtitle: 'request_detail.attachments.placeholder_subtitle'.tr(),
        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildActionButtons(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    // Show cancel button for pending consultations
    if (consultation.status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: OutlinedButton.icon(
          onPressed: _isProcessing ? null : () => _showCancelDialog(context),
          icon: const Icon(Icons.cancel_outlined),
          label: Text('request_detail.cancel_request'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          ),
        ),
      );
    }

    return null;
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('request_detail.cancel_dialog_title'.tr()),
        content: Text('request_detail.cancel_dialog_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('request_detail.cancel_confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cancelConsultation();
    }
  }

  Future<void> _cancelConsultation() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final consultationsController = context.read<ConsultationsController>();
      await consultationsController.cancelConsultation(widget.consultation.id);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('request_detail.cancel_success'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('request_detail.cancel_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _TimelineItem {
  final String label;
  final DateTime date;
  final Color color;

  _TimelineItem({
    required this.label,
    required this.date,
    required this.color,
  });
}
