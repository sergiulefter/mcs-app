import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/widgets/urgency_badge.dart';

class ConsultationCard extends StatefulWidget {
  final ConsultationModel consultation;
  final VoidCallback onTap;

  const ConsultationCard({
    super.key,
    required this.consultation,
    required this.onTap,
  });

  @override
  State<ConsultationCard> createState() => _ConsultationCardState();
}

class _ConsultationCardState extends State<ConsultationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;

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

                // Doctor info row
                _buildDoctorRow(context, consultation),

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
        _buildStatusBadge(context, consultation),

        // Urgency badge (only for urgent/emergency)
        if (consultation.urgency != 'normal') ...[
          const SizedBox(width: AppTheme.spacing8),
          UrgencyBadge(urgency: consultation.urgency),
        ],

        const Spacer(),

        // Relative time
        Text(
          _formatRelativeTime(consultation.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
      BuildContext context, ConsultationModel consultation) {
    final badgeColor = consultation.getStatusColor(context);
    final statusText = 'consultations.status.${consultation.status}'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDoctorRow(BuildContext context, ConsultationModel consultation) {
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
                consultation.doctorName ??
                    'consultations.awaiting_assignment'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (consultation.doctorSpecialty != null)
                Text(
                  'specialties.${consultation.doctorSpecialty}'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
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

    if (consultation.status == 'info_requested') {
      icon = Icons.info_outline;
      text = 'consultations.actions.action_required'.tr();
      color = semantic?.warning ?? colorScheme.error;
    } else if (consultation.doctorResponse != null) {
      icon = Icons.check_circle_outline;
      text = 'consultations.actions.response_available'.tr();
      color = semantic?.success ?? colorScheme.primary;
    } else if (consultation.attachments.isNotEmpty) {
      icon = Icons.attach_file;
      text = 'consultations.actions.attachments_count'.tr(namedArgs: {
        'count': consultation.attachments.length.toString(),
      });
      color = colorScheme.onSurfaceVariant;
    }

    if (icon == null || text == null) {
      return const SizedBox.shrink();
    }

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
