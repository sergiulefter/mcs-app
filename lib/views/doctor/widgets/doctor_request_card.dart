import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/shared/widgets/status_badge.dart';
import 'package:mcs_app/views/shared/widgets/urgency_badge.dart';
import 'package:provider/provider.dart';

/// Reusable consultation preview card for doctor flows.
class DoctorRequestCard extends StatefulWidget {
  const DoctorRequestCard({
    super.key,
    required this.consultation,
    this.onTap,
  });

  final ConsultationModel consultation;
  final VoidCallback? onTap;

  @override
  State<DoctorRequestCard> createState() => _DoctorRequestCardState();
}

class _DoctorRequestCardState extends State<DoctorRequestCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    final controller = context.read<DoctorConsultationsController>();
    final patient = controller.patientProfile(consultation.patientId);
    final patientName = patient?.displayName ??
        'doctor.requests.patient_unknown'.tr();
    final patientEmail = patient?.email;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with status badge, urgency badge, and relative time
                _buildHeaderRow(context, consultation),
                const SizedBox(height: AppTheme.spacing12),

                // Title
                Text(
                  consultation.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing4),

                // Description (1 line only)
                Text(
                  consultation.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Patient info row
                _buildPatientRow(context, patientName, patientEmail, consultation.createdAt),

                // Action indicator (if applicable)
                _buildActionIndicator(context, consultation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, ConsultationModel consultation) {
    return Row(
      children: [
        // Status badge
        StatusBadge(status: consultation.status),

        // Urgency badge (only shows for priority)
        const SizedBox(width: AppTheme.spacing8),
        UrgencyBadge(urgency: consultation.urgency),
      ],
    );
  }

  Widget _buildPatientRow(
      BuildContext context, String patientName, String? patientEmail, DateTime createdAt) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
          ),
          child: Icon(
            Icons.person_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (patientEmail != null)
                Text(
                  patientEmail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Relative time
        Text(
          _formatRelativeTime(createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: AppTheme.spacing4),
        Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildActionIndicator(
      BuildContext context, ConsultationModel consultation) {
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final colorScheme = Theme.of(context).colorScheme;

    // Determine which action indicator to show (priority order)
    IconData? icon;
    String? text;
    Color? color;
    bool isProminent = false;

    if (consultation.status == 'pending') {
      icon = Icons.fiber_new_outlined;
      text = 'doctor.requests.actions.new_request'.tr();
      color = semantic?.warning ?? colorScheme.error;
      isProminent = true; // Make "New" badge more visible
    } else if (consultation.status == 'info_requested') {
      icon = Icons.hourglass_empty;
      text = 'doctor.requests.actions.awaiting_patient'.tr();
      color = semantic?.warning ?? colorScheme.error;
    } else if (consultation.status == 'in_review') {
      icon = Icons.rate_review_outlined;
      text = 'doctor.requests.actions.in_review'.tr();
      color = colorScheme.primary;
    } else if (consultation.doctorResponse != null &&
        consultation.status == 'completed') {
      icon = Icons.check_circle_outline;
      text = 'doctor.requests.actions.response_sent'.tr();
      color = semantic?.success ?? colorScheme.primary;
    }

    if (icon == null || text == null) {
      return const SizedBox.shrink();
    }

    // Prominent badge style for new requests
    if (isProminent) {
      return Padding(
        padding: const EdgeInsets.only(top: AppTheme.spacing12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12,
            vertical: AppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: color!.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppTheme.iconMedium,
                color: color,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Regular style for other indicators
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing12),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppTheme.iconSmall,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'consultations.time.just_now'.tr();
    } else if (difference.inHours < 24) {
      return 'consultations.time.hours_ago'
          .tr(namedArgs: {'count': difference.inHours.toString()});
    } else if (difference.inDays == 1) {
      return 'consultations.time.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'consultations.time.days_ago'
          .tr(namedArgs: {'count': difference.inDays.toString()});
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
