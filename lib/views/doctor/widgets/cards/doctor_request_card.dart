import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:provider/provider.dart';

/// Reusable consultation preview card for doctor flows.
/// Matches the modern HTML/CSS design with avatar, urgency badge, and review button.
class DoctorRequestCard extends StatefulWidget {
  const DoctorRequestCard({super.key, required this.consultation, this.onTap});

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
    final patientName =
        patient?.displayName ?? 'doctor.requests.patient_unknown'.tr();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient avatar
              _buildAvatar(context, patientName),
              const SizedBox(width: AppTheme.spacing16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and patient info
                    Text(
                      consultation.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      patientName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Divider and footer row
                    const SizedBox(height: AppTheme.spacing12),
                    Container(
                      padding: const EdgeInsets.only(top: AppTheme.spacing8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Timestamp and urgency badge
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppTheme.spacing8,
                              runSpacing: AppTheme.spacing4,
                              children: [
                                Text(
                                  _formatReceivedTime(consultation.createdAt),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                                _buildUrgencyBadge(
                                  context,
                                  consultation.urgency,
                                ),
                              ],
                            ),
                          ),

                          // Review button
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'doctor.requests.review_button'.tr(),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: AppTheme.spacing2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build patient avatar with initials fallback
  Widget _buildAvatar(BuildContext context, String patientName) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getInitials(patientName);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Get initials from name (e.g., "John Doe" -> "JD")
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Build urgency badge with appropriate colors
  Widget _buildUrgencyBadge(BuildContext context, String urgency) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    Color bgColor;
    Color textColor;
    String label;

    switch (urgency.toLowerCase()) {
      case 'high':
      case 'urgent':
        bgColor = colorScheme.error.withValues(alpha: 0.1);
        textColor = colorScheme.error;
        label = 'common.urgency.high'.tr();
        break;
      case 'moderate':
      case 'medium':
        bgColor = semantic.warning.withValues(alpha: 0.1);
        textColor = semantic.warning;
        label = 'common.urgency.moderate'.tr();
        break;
      case 'low':
      case 'general':
      default:
        bgColor = colorScheme.secondary.withValues(alpha: 0.1);
        textColor = colorScheme.secondary;
        label = 'common.urgency.low'.tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Format relative time as "Received: X ago"
  String _formatReceivedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'consultations.time.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      timeAgo = '1 day';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} days';
    } else {
      timeAgo = DateFormat('MMM d').format(dateTime);
    }

    return 'Received: $timeAgo ago';
  }
}
