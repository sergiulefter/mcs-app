import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
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
      _doctorFuture =
          _doctorService.fetchDoctorById(widget.consultation.doctorId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    final statusColor = consultation.getStatusColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('request_detail.title'.tr()),
        actions: [
          // Cancel action in app bar for pending requests
          if (consultation.status == 'pending')
            TextButton(
              onPressed: _isProcessing ? null : () => _showCancelDialog(context),
              child: Text(
                'request_detail.cancel_request'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
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
    final statusText = 'common.status.${consultation.status}'.tr();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and urgency badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
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
                consultation.status == 'completed'
            ? consultation.updatedAt
            : null,
        isCompleted:
            consultation.status == 'in_review' || consultation.status == 'completed',
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
