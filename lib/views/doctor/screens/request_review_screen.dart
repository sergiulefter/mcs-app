import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/doctor/screens/request_more_info_screen.dart';
import 'package:mcs_app/views/doctor/screens/response_form_screen.dart';
import 'package:mcs_app/views/doctor/widgets/cards/patient_info_card.dart';
import 'package:mcs_app/views/doctor/widgets/skeletons/request_review_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/shared/widgets/status_badge.dart';
import 'package:mcs_app/views/shared/widgets/urgency_badge.dart';
import 'package:provider/provider.dart';

class RequestReviewScreen extends StatefulWidget {
  const RequestReviewScreen({super.key, required this.consultationId});

  final String consultationId;

  @override
  State<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends State<RequestReviewScreen> {
  bool _statusBusy = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Delay data access to allow route animation to complete
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton during route animation
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('doctor.requests.detail.title'.tr()),
        ),
        body: const SafeArea(
          child: RequestReviewSkeleton(),
        ),
      );
    }

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
              if (consultation.doctorResponse != null) ...[
                const SizedBox(height: AppTheme.sectionSpacing),
                _buildDoctorResponse(context, consultation.doctorResponse!),
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
        Text(
          consultation.title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
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

  Widget _buildDoctorResponse(
    BuildContext context,
    DoctorResponseModel response,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'request_detail.doctor_response.title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          backgroundColor: colorScheme.secondary.withValues(alpha: 0.05),
          borderColor: colorScheme.secondary.withValues(alpha: 0.2),
          showShadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.medical_information_outlined,
                      size: AppTheme.iconMedium,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'request_detail.doctor_response.from_doctor'.tr(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          DateFormat.yMMMMd().format(response.respondedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                response.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
              if (response.recommendations != null &&
                  response.recommendations!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing16),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: AppTheme.iconSmall,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            'request_detail.doctor_response.recommendations_label'
                                .tr(),
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        response.recommendations!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.refresh_outlined,
                    size: AppTheme.iconSmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      'request_detail.doctor_response.follow_up_needed'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: (response.followUpNeeded
                          ? colorScheme.secondary
                          : colorScheme.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                ),
                child: Text(
                  response.followUpNeeded ? 'common.yes'.tr() : 'common.no'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: response.followUpNeeded
                            ? colorScheme.secondary
                            : colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
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
          valueWidget: StatusBadge(status: consultation.status),
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
        const SizedBox(height: AppTheme.spacing16),
        ...requests.map((request) => _buildInfoRequestCard(context, request)),
      ],
    );
  }

  Widget _buildInfoRequestCard(BuildContext context, InfoRequestModel request) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final isAnswered = request.isAnswered;
    final statusColor = isAnswered
        ? (semantic?.success ?? Colors.green)
        : (semantic?.warning ?? Colors.amber);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isAnswered
              ? statusColor.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          _buildRequestHeader(context, request, isAnswered, statusColor),
          const Divider(height: 1),
          // Doctor's message
          _buildDoctorMessage(context, request),
          // Questions and answers
          ...request.questions.asMap().entries.map((entry) =>
              _buildQuestionAnswer(
                context,
                entry.key,
                entry.value,
                isAnswered && request.answers != null && entry.key < request.answers!.length
                    ? request.answers![entry.key]
                    : null,
                isAnswered,
              )),
          // Additional info (if answered and provided)
          if (isAnswered &&
              request.additionalInfo != null &&
              request.additionalInfo!.isNotEmpty)
            _buildAdditionalInfo(context, request.additionalInfo!),
          // Response timestamp or waiting message
          _buildResponseStatus(context, request, isAnswered, statusColor),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(
    BuildContext context,
    InfoRequestModel request,
    bool isAnswered,
    Color statusColor,
  ) {
    return Padding(
      padding: AppTheme.cardPadding,
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
            size: AppTheme.iconMedium,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'doctor.requests.detail.info_request_card.your_questions'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'doctor.requests.detail.info_request_card.asked_on'.tr(
                    namedArgs: {
                      'date': DateFormat.yMMMd().format(request.requestedAt)
                    },
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAnswered ? Icons.check_circle_outline : Icons.schedule,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isAnswered
                      ? 'doctor.requests.detail.info_request_card.answered'.tr()
                      : 'common.status.pending'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorMessage(BuildContext context, InfoRequestModel request) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'doctor.requests.detail.info_request_card.message_label'.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            request.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswer(
    BuildContext context,
    int index,
    String question,
    String? answer,
    bool isAnswered,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final successColor = semantic?.success ?? Colors.green;

    return Padding(
      padding: AppTheme.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question label and text
          Text(
            'doctor.requests.detail.info_request_card.question_label'.tr(
              namedArgs: {'number': (index + 1).toString()},
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            question,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          // Answer section (if answered)
          if (answer != null && answer.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: successColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'doctor.requests.detail.info_request_card.answer_label'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: successColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    answer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
          // Divider between questions (except last)
          if (index < 10) // Will be handled by parent
            const SizedBox(height: AppTheme.spacing8),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, String additionalInfo) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: AppTheme.spacing4),
              Flexible(
                child: Text(
                  'doctor.requests.detail.info_request_card.additional_info_label'
                      .tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            additionalInfo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseStatus(
    BuildContext context,
    InfoRequestModel request,
    bool isAnswered,
    Color statusColor,
  ) {
    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      child: Row(
        children: [
          Icon(
            isAnswered ? Icons.check_circle : Icons.schedule,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              isAnswered
                  ? 'doctor.requests.detail.info_request_card.responded_on'.tr(
                      namedArgs: {
                        'date': DateFormat.yMMMd()
                            .add_Hm()
                            .format(request.respondedAt ?? DateTime.now())
                      },
                    )
                  : 'doctor.requests.detail.info_request_card.waiting_response'
                      .tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ConsultationModel consultation) {
    final controller = context.read<DoctorConsultationsController>();

    // Only show Start Review for pending consultations
    final canStartReview = consultation.status == 'pending';
    // Only show response actions after review has started (in_review or info_requested)
    final isReviewStarted = consultation.status == 'in_review' ||
        consultation.status == 'info_requested';
    // Check if there's a pending info request (unanswered)
    final hasPendingInfoRequest =
        consultation.infoRequests.any((r) => !r.isAnswered);

    // Don't show actions section for completed consultations
    if (consultation.status == 'completed' || consultation.status == 'cancelled') {
      return const SizedBox.shrink();
    }

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
        if (isReviewStarted) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasPendingInfoRequest
                  ? null
                  : () {
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
              style: hasPendingInfoRequest
                  ? OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.help_outline),
              label: Text('doctor.requests.detail.request_more_info'.tr()),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasPendingInfoRequest
                  ? null
                  : () {
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
