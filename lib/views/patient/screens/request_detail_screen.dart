import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/badge_colors.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/patient/widgets/skeletons/request_detail_skeleton.dart';
import 'package:mcs_app/views/shared/widgets/status_badge.dart';
import 'package:mcs_app/views/shared/widgets/urgency_badge.dart';
import 'doctor_profile_screen.dart';
import 'respond_to_info_screen.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _doctorService = DoctorService();

    // Delay data loading to allow route animation to complete
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Start doctor fetch after delay
        if (widget.consultation.doctorId != null) {
          _doctorFuture =
              _doctorService.fetchDoctorById(widget.consultation.doctorId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton during route animation
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('request_detail.title'.tr()),
        ),
        body: const RequestDetailSkeleton(),
      );
    }

    final consultation = widget.consultation;
    final statusColor = consultation.getStatusColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('request_detail.title'.tr()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent colored header
            _buildHeader(context, consultation, statusColor),

            // Content with padding
            Padding(
              padding: AppTheme.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline stepper
                  _buildTimelineStepper(context, consultation),
                  const SizedBox(height: AppTheme.sectionSpacing),

                  // Description section (no card)
                  _buildDescriptionSection(context, consultation),

                  // Pending info request section (if there's an unanswered request)
                  if (consultation.infoRequests.any((r) => !r.isAnswered)) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildPendingInfoRequestSection(context, consultation),
                  ],

                  // Answered info requests history (if any answered)
                  if (consultation.infoRequests.any((r) => r.isAnswered)) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildInfoRequestHistory(context, consultation),
                  ],

                  // Doctor response (if exists) - emphasized card
                  if (consultation.doctorResponse != null) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildDoctorResponse(context),
                  ],

                  // Attachments (only if has attachments)
                  if (consultation.attachments.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildAttachmentsSection(context, consultation),
                  ],

                  // Cancel button for pending requests
                  if (consultation.status == 'pending') ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _showCancelDialog(context),
                        icon: _isProcessing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined),
                        label: Text('request_detail.cancel_request'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing16,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.sectionSpacing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ConsultationModel consultation,
    Color statusColor,
  ) {
    // Get badge colors for header background tint
    final badgeColors = Theme.of(context).extension<AppBadgeColors>();
    final headerStyle = badgeColors?.forStatus(consultation.status);
    final headerBgColor = headerStyle?.bg ?? statusColor.withValues(alpha: 0.08);
    final headerBorderColor = headerStyle?.text.withValues(alpha: 0.2) ??
        statusColor.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: headerBgColor,
        border: Border(
          bottom: BorderSide(
            color: headerBorderColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and urgency badges
          Row(
            children: [
              StatusBadge(status: consultation.status),
              const SizedBox(width: AppTheme.spacing8),
              UrgencyBadge(urgency: consultation.urgency),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),

          // Title as headline
          Text(
            consultation.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Doctor info inline (clickable)
          _buildDoctorInline(context),
          const SizedBox(height: AppTheme.spacing12),

          // Created date
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: AppTheme.iconSmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '${'request_detail.created_at'.tr()}: ${DateFormat.yMMMMd().format(consultation.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInline(BuildContext context) {
    if (_doctorFuture == null) {
      return Row(
        children: [
          Icon(
            Icons.person_outline,
            size: AppTheme.iconSmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            'request_detail.doctor.unassigned_title'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      );
    }

    return FutureBuilder<DoctorModel?>(
      future: _doctorFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: AppTheme.iconSmall,
                height: AppTheme.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'common.loading'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Row(
            children: [
              Icon(
                Icons.person_outline,
                size: AppTheme.iconSmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'request_detail.doctor.unassigned_title'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          );
        }

        final doctor = snapshot.data!;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DoctorProfileScreen(doctor: doctor),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    doctor.fullName.isNotEmpty
                        ? doctor.fullName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'specialties.${doctor.specialty.name}'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: AppTheme.iconMedium,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineStepper(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Define timeline steps based on consultation status
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'request_detail.timeline.created'.tr(),
        date: consultation.createdAt,
        isCompleted: true,
      ),
      _TimelineStep(
        label: 'common.status.in_review'.tr(),
        date: consultation.status == 'in_review' ||
                consultation.status == 'info_requested' ||
                consultation.status == 'completed'
            ? consultation.updatedAt
            : null,
        isCompleted: consultation.status == 'in_review' ||
            consultation.status == 'info_requested' ||
            consultation.status == 'completed',
      ),
      _TimelineStep(
        label: 'common.status.completed'.tr(),
        date: consultation.completedAt,
        isCompleted: consultation.status == 'completed',
      ),
    ];

    // Handle cancelled status
    if (consultation.status == 'cancelled') {
      steps[1] = _TimelineStep(
        label: 'common.status.cancelled'.tr(),
        date: consultation.updatedAt,
        isCompleted: true,
        isCancelled: true,
      );
      steps.removeAt(2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'request_detail.timeline.title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        Row(
          children: steps.asMap().entries.expand((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return [
              // Step circle and label
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step.isCompleted
                            ? (step.isCancelled
                                ? colorScheme.error
                                : colorScheme.primary)
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: step.isCompleted
                            ? null
                            : Border.all(
                                color: colorScheme.outline,
                                width: 2,
                              ),
                      ),
                      child: step.isCompleted
                          ? Icon(
                              step.isCancelled ? Icons.close : Icons.check,
                              size: 18,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      step.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight:
                                step.isCompleted ? FontWeight.w600 : FontWeight.w400,
                            color: step.isCompleted
                                ? (step.isCancelled
                                    ? colorScheme.error
                                    : colorScheme.onSurface)
                                : colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (step.date != null) ...[
                      const SizedBox(height: AppTheme.spacing2),
                      Text(
                        DateFormat('MMM d').format(step.date!),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              // Connector line (except for last step)
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 40),
                    color: steps[index + 1].isCompleted
                        ? (steps[index + 1].isCancelled
                            ? colorScheme.error.withValues(alpha: 0.5)
                            : colorScheme.primary.withValues(alpha: 0.5))
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
            ];
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'request_detail.description_label'.tr()),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          consultation.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildPendingInfoRequestSection(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final warningColor = semantic?.warning ?? colorScheme.tertiary;

    // Get the latest unanswered info request
    final latestRequest = consultation.infoRequests.lastWhere(
      (r) => !r.isAnswered,
      orElse: () => consultation.infoRequests.last,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'request_detail.info_request.title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          backgroundColor: warningColor.withValues(alpha: 0.08),
          borderColor: warningColor.withValues(alpha: 0.3),
          showShadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: warningColor,
                    size: AppTheme.iconMedium,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      'request_detail.info_request.pending_response'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                latestRequest.message.length > AppConstants.messagePreviewTruncate
                    ? '${latestRequest.message.substring(0, AppConstants.messagePreviewTruncate)}...'
                    : latestRequest.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                '${latestRequest.questions.length} ${latestRequest.questions.length == 1 ? 'question' : 'questions'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final result = await navigator.push<bool>(
                      MaterialPageRoute(
                        builder: (_) => RespondToInfoScreen(
                          consultation: consultation,
                          infoRequest: latestRequest,
                        ),
                      ),
                    );
                    if (result == true) {
                      navigator.pop();
                    }
                  },
                  icon: const Icon(Icons.reply_outlined),
                  label: Text('request_detail.info_request.respond_button'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRequestHistory(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final answeredRequests =
        consultation.infoRequests.where((r) => r.isAnswered).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'request_detail.info_request.history_title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        ...answeredRequests
            .map((request) => _buildAnsweredInfoRequestCard(context, request)),
      ],
    );
  }

  Widget _buildAnsweredInfoRequestCard(
    BuildContext context,
    InfoRequestModel request,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final successColor = semantic?.success ?? Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      decoration: BoxDecoration(
        border: Border.all(
          color: successColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: AppTheme.cardPadding,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: successColor,
                  size: AppTheme.iconMedium,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'request_detail.info_request.doctor_asked'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'request_detail.info_request.responded_on'.tr(
                          namedArgs: {
                            'date': DateFormat.yMMMd()
                                .format(request.respondedAt ?? DateTime.now())
                          },
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Doctor's message
          Container(
            width: double.infinity,
            padding: AppTheme.cardPadding,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              request.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
          // Questions and answers
          ...request.questions.asMap().entries.map((entry) {
            final answer = request.answers != null &&
                    entry.key < request.answers!.length
                ? request.answers![entry.key]
                : null;
            return _buildQuestionAnswerItem(
              context,
              entry.key,
              entry.value,
              answer,
              successColor,
            );
          }),
          // Additional info (if provided)
          if (request.additionalInfo != null &&
              request.additionalInfo!.isNotEmpty)
            _buildPatientAdditionalInfo(context, request.additionalInfo!),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswerItem(
    BuildContext context,
    int index,
    String question,
    String? answer,
    Color successColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppTheme.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question label and text
          Text(
            'request_detail.info_request.question_label'.tr(
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
          // Answer section
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
                    'request_detail.info_request.your_answer'.tr(),
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
        ],
      ),
    );
  }

  Widget _buildPatientAdditionalInfo(
    BuildContext context,
    String additionalInfo,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: AppTheme.spacing16,
      ),
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
              Text(
                'request_detail.info_request.additional_info'.tr(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDoctorResponse(BuildContext context) {
    final response = widget.consultation.doctorResponse!;
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
              // Response header with icon
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

              // Response text
              Text(
                response.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),

              // Recommendations (if present)
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

              // Follow-up section
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

  Widget _buildAttachmentsSection(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'request_detail.attachments.title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          borderColor: Theme.of(context).dividerColor,
          showShadow: false,
          child: Column(
            children: consultation.attachments.map((attachment) {
              // Choose icon based on attachment type
              final icon = switch (attachment.type) {
                'image' => Icons.image_outlined,
                'pdf' => Icons.picture_as_pdf_outlined,
                _ => Icons.insert_drive_file_outlined,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: AppTheme.iconMedium,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        attachment.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
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

class _TimelineStep {
  final String label;
  final DateTime? date;
  final bool isCompleted;
  final bool isCancelled;

  _TimelineStep({
    required this.label,
    this.date,
    required this.isCompleted,
    this.isCancelled = false,
  });
}
