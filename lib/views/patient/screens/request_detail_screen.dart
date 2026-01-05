import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/views/patient/widgets/skeletons/request_detail_skeleton.dart';
import 'package:mcs_app/views/shared/widgets/detail_screen_header.dart';
import 'package:mcs_app/views/shared/widgets/timeline_message.dart';
import 'doctor_profile_screen.dart';
import 'respond_to_info_screen.dart';

/// Patient's consultation detail screen matching the HTML/CSS design.
/// Features: sticky header, doctor info with avatar, status badges,
/// description card, timeline conversation, and action buttons.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.consultation});

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
          _doctorFuture = _doctorService.fetchDoctorById(
            widget.consultation.doctorId!,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show skeleton during route animation
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              DetailScreenHeader(title: 'request_detail.title'.tr()),
              const Expanded(child: RequestDetailSkeleton()),
            ],
          ),
        ),
      );
    }

    final consultation = widget.consultation;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header
            DetailScreenHeader(title: 'request_detail.title'.tr()),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 120,
                ), // Space for action buttons
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section with doctor info and avatar
                    _buildTitleSection(context, consultation),

                    // Status badges
                    _buildStatusBadges(context, consultation),

                    // Your Request card (description)
                    _buildYourRequestCard(context, consultation),

                    // Doctor Response card (if exists)
                    if (consultation.doctorResponse != null)
                      _buildDoctorResponseCard(context, consultation),

                    // Timeline/conversation section
                    _buildTimelineSection(context, consultation),
                  ],
                ),
              ),
            ),

            // Fixed bottom action buttons
            _buildActionButtons(context, consultation),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing24,
        AppTheme.spacing24,
        AppTheme.spacing24,
        AppTheme.spacing8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and doctor info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                // Doctor info (inline)
                _buildDoctorInline(context),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),

          // Doctor avatar (48px with border)
          _buildDoctorAvatar(context),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (_doctorFuture == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.primaryContainer.withValues(alpha: 0.5),
          border: Border.all(
            color: isDark ? AppTheme.slate700 : Colors.white,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.person_outline,
          color: isDark ? AppTheme.slate500 : AppTheme.slate400,
          size: 24,
        ),
      );
    }

    return FutureBuilder<DoctorModel?>(
      future: _doctorFuture,
      builder: (context, snapshot) {
        Widget avatarContent;

        if (snapshot.connectionState == ConnectionState.waiting) {
          avatarContent = SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          avatarContent = Icon(
            Icons.person_outline,
            color: isDark ? AppTheme.slate500 : AppTheme.slate400,
            size: 24,
          );
        } else {
          final doctor = snapshot.data!;
          if (doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppTheme.slate700 : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  doctor.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.primaryContainer.withValues(alpha: 0.5),
                    child: Center(
                      child: Text(
                        _getInitials(doctor.fullName),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          avatarContent = Text(
            _getInitials(doctor.fullName),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.primaryContainer.withValues(alpha: 0.5),
            border: Border.all(
              color: isDark ? AppTheme.slate700 : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: avatarContent),
        );
      },
    );
  }

  Widget _buildDoctorInline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_doctorFuture == null) {
      return Text(
        'request_detail.doctor.unassigned_title'.tr(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? AppTheme.slate400 : AppTheme.slate500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return FutureBuilder<DoctorModel?>(
      future: _doctorFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'common.loading'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Text(
            'request_detail.doctor.unassigned_title'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              fontStyle: FontStyle.italic,
            ),
          );
        }

        final doctor = snapshot.data!;
        final specialty = 'specialties.${doctor.specialty.name}'.tr();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DoctorProfileScreen(doctor: doctor),
              ),
            );
          },
          child: Text(
            '${doctor.fullName} • $specialty',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final cleanName = name.replaceAll(
      RegExp(r'^Dr\.?\s*', caseSensitive: false),
      '',
    );
    final parts = cleanName.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildStatusBadges(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Wrap(
        spacing: AppTheme.spacing12,
        runSpacing: AppTheme.spacing8,
        children: [
          _buildStatusBadge(context, consultation.status, isDark),
          _buildUrgencyBadge(context, consultation.urgency, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, bool isDark) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    String label;
    bool showPulse = false;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = isDark
            ? Colors.blue.shade900.withValues(alpha: 0.3)
            : Colors.blue.shade50;
        textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        borderColor = isDark ? Colors.blue.shade800 : Colors.blue.shade200;
        label = 'common.status.pending'.tr();
        break;
      case 'in_review':
        bgColor = isDark
            ? Colors.amber.shade900.withValues(alpha: 0.3)
            : Colors.amber.shade50;
        textColor = isDark ? Colors.amber.shade300 : Colors.amber.shade800;
        borderColor = isDark ? Colors.amber.shade800 : Colors.amber.shade200;
        label = 'common.status.in_review'.tr();
        showPulse = true;
        break;
      case 'info_requested':
        bgColor = isDark
            ? Colors.orange.shade900.withValues(alpha: 0.3)
            : Colors.orange.shade50;
        textColor = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
        borderColor = isDark ? Colors.orange.shade800 : Colors.orange.shade200;
        label = 'common.status.info_requested'.tr();
        showPulse = true;
        break;
      case 'completed':
        bgColor = isDark
            ? Colors.green.shade900.withValues(alpha: 0.3)
            : Colors.green.shade50;
        textColor = isDark ? Colors.green.shade300 : Colors.green.shade800;
        borderColor = isDark ? Colors.green.shade800 : Colors.green.shade200;
        label = 'common.status.completed'.tr();
        break;
      case 'cancelled':
        bgColor = isDark ? AppTheme.slate800 : AppTheme.slate100;
        textColor = isDark ? AppTheme.slate400 : AppTheme.slate600;
        borderColor = isDark ? AppTheme.slate700 : AppTheme.slate200;
        label = 'common.status.cancelled'.tr();
        break;
      default:
        bgColor = isDark ? AppTheme.slate800 : AppTheme.slate100;
        textColor = isDark ? AppTheme.slate300 : AppTheme.slate600;
        borderColor = isDark ? AppTheme.slate700 : AppTheme.slate200;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPulse) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(BuildContext context, String urgency, bool isDark) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    String label;
    IconData? icon;

    switch (urgency.toLowerCase()) {
      case 'high':
      case 'urgent':
        bgColor = isDark
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.red.shade50;
        textColor = isDark ? Colors.red.shade300 : Colors.red.shade600;
        borderColor = isDark ? Colors.red.shade800 : Colors.red.shade200;
        label = 'common.urgency.high'.tr();
        icon = Icons.priority_high;
        break;
      case 'moderate':
      case 'medium':
        bgColor = isDark
            ? Colors.amber.shade900.withValues(alpha: 0.3)
            : Colors.amber.shade50;
        textColor = isDark ? Colors.amber.shade300 : Colors.amber.shade800;
        borderColor = isDark ? Colors.amber.shade800 : Colors.amber.shade200;
        label = 'common.urgency.moderate'.tr();
        break;
      case 'low':
      case 'general':
      default:
        bgColor = isDark
            ? Colors.teal.shade900.withValues(alpha: 0.3)
            : Colors.teal.shade50;
        textColor = isDark ? Colors.teal.shade300 : Colors.teal.shade800;
        borderColor = isDark ? Colors.teal.shade800 : Colors.teal.shade200;
        label = 'common.urgency.low'.tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourRequestCard(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.slate800 : AppTheme.slate100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                ),
                const SizedBox(width: 8),
                Text(
                  'request_detail.your_request'.tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              '"${consultation.description}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                height: 1.6,
              ),
            ),

            // Created date
            const SizedBox(height: 16),
            Text(
              '${DateFormat.yMMMd().format(consultation.createdAt)} at ${DateFormat.jm().format(consultation.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ),

            // Attachments (if any)
            if (consultation.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: consultation.attachments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final attachment = consultation.attachments[index];
                    return _buildAttachmentThumbnail(context, attachment);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentThumbnail(
    BuildContext context,
    AttachmentModel attachment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isImage = attachment.type == 'image';

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? AppTheme.slate800 : AppTheme.slate50,
        border: Border.all(
          color: isDark ? AppTheme.slate700 : AppTheme.slate200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: isImage
            ? Image.network(
                attachment.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAttachmentIcon(context, attachment),
              )
            : _buildAttachmentIcon(context, attachment),
      ),
    );
  }

  Widget _buildAttachmentIcon(
    BuildContext context,
    AttachmentModel attachment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    String label;

    switch (attachment.type) {
      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
        label = 'PDF';
        break;
      case 'image':
        icon = Icons.image_outlined;
        label = 'IMG';
        break;
      default:
        icon = Icons.description_outlined;
        label = 'FILE';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: isDark ? AppTheme.slate500 : AppTheme.slate400,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppTheme.slate500 : AppTheme.slate400,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorResponseCard(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final response = consultation.doctorResponse!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'request_detail.doctor_response.title'.tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Response text
            Text(
              response.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.slate200 : AppTheme.slate800,
                height: 1.6,
              ),
            ),

            // Recommendations (if present)
            if (response.recommendations != null &&
                response.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'request_detail.doctor_response.recommendations_label'
                              .tr(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      response.recommendations!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            // Response date
            const SizedBox(height: 12),
            Text(
              DateFormat.yMMMd().format(response.respondedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build timeline items from info requests
    final timelineItems = <Widget>[];

    for (final request in consultation.infoRequests) {
      // Doctor's question
      timelineItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
          child: TimelineMessage(
            sender: TimelineMessageSender.doctor,
            senderName: consultation.doctorName ?? 'Doctor',
            message: request.message,
            timestamp: request.requestedAt,
          ),
        ),
      );

      // Patient's response (if answered)
      if (request.isAnswered && request.answers != null) {
        final responseText = request.answers!.join('\n\n');
        final additionalInfo = request.additionalInfo;
        final fullResponse = additionalInfo != null
            ? '$responseText\n\n$additionalInfo'
            : responseText;

        timelineItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
            child: TimelineMessage(
              sender: TimelineMessageSender.patient,
              senderName: 'You',
              message: fullResponse,
              timestamp: request.respondedAt ?? DateTime.now(),
            ),
          ),
        );
      }
    }

    // Add waiting indicator if there's a pending info request
    final hasPendingRequest = consultation.infoRequests.any(
      (r) => !r.isAnswered,
    );
    if (hasPendingRequest) {
      timelineItems.add(
        TimelineWaitingIndicator(
          message: 'request_detail.waiting_your_response'.tr(),
        ),
      );
    }

    if (timelineItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline header
          Text(
            'request_detail.conversation'.tr().toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Timeline with line
          Stack(
            children: [
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
              ),
              Column(children: timelineItems),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if there's a pending info request to respond to
    final pendingInfoRequest = consultation.infoRequests
        .where((r) => !r.isAnswered)
        .firstOrNull;

    // For completed/cancelled, show no actions
    if (consultation.status == 'completed' ||
        consultation.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    // For pending requests, show cancel option
    if (consultation.status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.slate800 : AppTheme.slate200,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _showCancelDialog(context),
              icon: _isProcessing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text('request_detail.cancel_request'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
            ),
          ),
        ),
      );
    }

    // For info_requested status, show respond button
    if (pendingInfoRequest != null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.slate800 : AppTheme.slate200,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await navigator.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => RespondToInfoScreen(
                      consultation: consultation,
                      infoRequest: pendingInfoRequest,
                    ),
                  ),
                );
                if (result == true) {
                  navigator.pop();
                }
              },
              icon: const Icon(Icons.reply_outlined, size: 20),
              label: Text('request_detail.info_request.respond_button'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
    setState(() => _isProcessing = true);

    try {
      final consultationsController = context.read<ConsultationsController>();
      await consultationsController.cancelConsultation(widget.consultation.id);

      if (mounted) {
        setState(() => _isProcessing = false);
        NotificationsHelper().showSuccess(
          'request_detail.cancel_success'.tr(),
          context: context,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        NotificationsHelper().showError(e.toString(), context: context);
      }
    }
  }
}
