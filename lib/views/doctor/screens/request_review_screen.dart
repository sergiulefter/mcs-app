import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_more_info_screen.dart';
import 'package:mcs_app/views/doctor/screens/response_form_screen.dart';
import 'package:mcs_app/views/doctor/widgets/patient_info_card.dart';
import 'package:mcs_app/views/doctor/widgets/status_chip.dart';
import 'package:mcs_app/views/doctor/widgets/urgency_badge.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:provider/provider.dart';

class RequestReviewScreen extends StatefulWidget {
  const RequestReviewScreen({super.key, required this.consultationId});

  final String consultationId;

  @override
  State<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends State<RequestReviewScreen> {
  bool _statusBusy = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorConsultationsController>();
    final consultation = controller.consultationById(widget.consultationId);

    if (consultation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final patient = controller.patientProfile(consultation.patientId);
    final patientName =
        patient?.displayName ?? patient?.email ?? 'doctor.requests.patient_unknown'.tr();
    final dateText = DateFormat.yMMMd().add_Hm().format(consultation.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.requests.detail.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                consultation,
                patientName,
                patient?.email,
                patient?.phone,
                dateText,
              ),
              const SizedBox(height: AppTheme.sectionSpacing),
              _buildRequestDetails(context, consultation),
              const SizedBox(height: AppTheme.sectionSpacing),
              _buildAttachments(context, consultation.attachments),
              if (consultation.infoRequests.isNotEmpty) ...[
                const SizedBox(height: AppTheme.sectionSpacing),
                _buildInfoRequests(context, consultation.infoRequests),
              ],
              const SizedBox(height: AppTheme.sectionSpacing),
              _buildActions(context, consultation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ConsultationModel consultation,
    String patientName,
    String? patientEmail,
    String? patientPhone,
    String dateText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                consultation.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            StatusChip(status: consultation.status),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          consultation.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacing12),
        PatientInfoCard(
          name: patientName,
          email: patientEmail ?? '',
          phone: patientPhone,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Icon(Icons.schedule_outlined,
                size: AppTheme.iconSmall, color: Theme.of(context).hintColor),
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
    );
  }

  Widget _buildRequestDetails(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor.requests.detail.request_details'.tr()),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'doctor.requests.detail.request_details_subtitle'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: AppTheme.spacing12),
        _detailRow(
          context,
          label: 'doctor.requests.detail.urgency'.tr(),
          valueWidget: UrgencyBadge(urgency: consultation.urgency),
        ),
        const SizedBox(height: AppTheme.spacing8),
        _detailRow(
          context,
          label: 'doctor.requests.detail.status'.tr(),
          valueWidget: StatusChip(status: consultation.status),
        ),
        const SizedBox(height: AppTheme.spacing8),
        _detailRow(
          context,
          label: 'doctor.requests.detail.created_at'.tr(),
          value: DateFormat.yMMMd().format(consultation.createdAt),
        ),
        if (consultation.completedAt != null) ...[
          const SizedBox(height: AppTheme.spacing8),
          _detailRow(
            context,
            label: 'doctor.requests.detail.completed_at'.tr(),
            value: DateFormat.yMMMd().format(consultation.completedAt!),
          ),
        ],
        if (consultation.infoRequests.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing8),
          _detailRow(
            context,
            label: 'doctor.requests.detail.info_requests'.tr(),
            value: consultation.infoRequests.length.toString(),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachments(
    BuildContext context,
    List<AttachmentModel> attachments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor.requests.detail.attachments'.tr()),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'doctor.requests.detail.attachments_subtitle'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (attachments.isEmpty)
          AppEmptyState(
            icon: Icons.insert_drive_file_outlined,
            title: 'doctor.requests.detail.no_attachments_title'.tr(),
            subtitle: 'doctor.requests.detail.no_attachments_subtitle'.tr(),
          )
        else
          Column(
            children: attachments
                .map(
                  (attachment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      attachment.type == 'image'
                          ? Icons.image_outlined
                          : Icons.picture_as_pdf_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(attachment.name),
                    subtitle: Text(
                      DateFormat.yMMMd().format(attachment.uploadedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: Theme.of(context).hintColor),
                    onTap: () {},
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildInfoRequests(
    BuildContext context,
    List<InfoRequestModel> requests,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor.requests.detail.info_requests_title'.tr()),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'doctor.requests.detail.info_requests_subtitle'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Column(
          children: requests
              .map(
                (request) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(request.message),
                  subtitle: Text(
                    DateFormat.yMMMd().add_Hm().format(request.requestedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, ConsultationModel consultation) {
    final controller = context.read<DoctorConsultationsController>();

    final canStartReview = consultation.status == 'pending';
    final canRequestMoreInfo = consultation.status != 'completed';
    final canWriteResponse = consultation.status != 'completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor.requests.detail.actions'.tr()),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'doctor.requests.detail.actions_subtitle'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (canStartReview)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _statusBusy
                  ? null
                  : () async {
                      setState(() => _statusBusy = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final statusUpdatedText =
                          'doctor.requests.detail.status_updated'.tr();
                      try {
                        await controller.updateStatus(
                          consultation.id,
                          'in_review',
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(statusUpdatedText),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _statusBusy = false);
                        }
                      }
                    },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('doctor.requests.detail.start_review'.tr()),
            ),
          ),
        const SizedBox(height: AppTheme.spacing12),
        if (canRequestMoreInfo)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: RequestMoreInfoScreen(
                        consultationId: consultation.id,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: Text('doctor.requests.detail.request_more_info'.tr()),
            ),
          ),
        const SizedBox(height: AppTheme.spacing12),
        if (canWriteResponse)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: ResponseFormScreen(
                        consultationId: consultation.id,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text('doctor.requests.detail.write_response'.tr()),
            ),
          ),
      ],
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (valueWidget != null)
          valueWidget
        else if (value != null)
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }

}
