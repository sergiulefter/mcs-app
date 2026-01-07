import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/badge_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build patient info subtitle
    final patientAge = patient?.dateOfBirth != null
        ? DateTime.now().year - patient!.dateOfBirth!.year
        : null;
    final patientGender = patient?.gender;
    String patientInfo = patientName;
    if (patientAge != null || patientGender != null) {
      final parts = <String>[];
      if (patientAge != null) parts.add('$patientAge');
      if (patientGender != null) {
        final genderLabel = 'profile.$patientGender'.tr();
        parts.add(genderLabel);
      }
      if (parts.isNotEmpty) {
        patientInfo = '$patientName • ${parts.join(' ')}';
      }
    }

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
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient avatar (56px as per design)
              _buildAvatar(context, patientName),
              const SizedBox(width: AppTheme.spacing16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      consultation.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Patient info subtitle
                    Text(
                      patientInfo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.slate400 : AppTheme.slate500,
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
                            color: isDark
                                ? AppTheme.slate700.withValues(alpha: 0.5)
                                : AppTheme.slate100,
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
                                        color: isDark
                                            ? AppTheme.slate500
                                            : AppTheme.slate400,
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
                                const SizedBox(width: 2),
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

  /// Build patient avatar with initials fallback (56px as per design)
  Widget _buildAvatar(BuildContext context, String patientName) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(patientName);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
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

  /// Build urgency badge with theme-aware colors
  Widget _buildUrgencyBadge(BuildContext context, String urgency) {
    final badgeColors = Theme.of(context).extension<AppBadgeColors>()!;
    final style = badgeColors.forUrgency(urgency);

    String label;
    switch (urgency.toLowerCase()) {
      case 'high':
      case 'urgent':
        label = 'common.urgency.high'.tr();
        break;
      case 'moderate':
      case 'medium':
        label = 'common.urgency.moderate'.tr();
        break;
      case 'low':
      case 'general':
      default:
        label = 'common.urgency.low'.tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: style.text,
          fontWeight: FontWeight.w500,
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
      return 'Received: $timeAgo';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      timeAgo = '1 day ago';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} days ago';
    } else {
      timeAgo = DateFormat('MMM d').format(dateTime);
      return 'Received: $timeAgo';
    }

    return 'Received: $timeAgo';
  }
}
