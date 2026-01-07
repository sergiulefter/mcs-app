import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/badge_colors.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/doctor/screens/request_more_info_screen.dart';
import 'package:mcs_app/views/doctor/screens/response_form_screen.dart';
import 'package:mcs_app/views/doctor/widgets/skeletons/request_review_skeleton.dart';
import 'package:mcs_app/views/shared/widgets/detail_screen_header.dart';
import 'package:mcs_app/views/shared/widgets/timeline_message.dart';
import 'package:provider/provider.dart';

/// Doctor's request review screen matching the HTML/CSS design.
/// Features: sticky header, patient info with avatar, status badges,
/// patient report card, timeline conversation, and fixed action buttons.
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
              DetailScreenHeader(title: 'doctor.requests.detail.title'.tr()),
              const Expanded(child: RequestReviewSkeleton()),
            ],
          ),
        ),
      );
    }

    final controller = context.watch<DoctorConsultationsController>();
    final consultation = controller.consultationById(widget.consultationId);

    if (consultation == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              DetailScreenHeader(title: 'doctor.requests.detail.title'.tr()),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    final patient = controller.patientProfile(consultation.patientId);
    final patientName =
        patient?.displayName ?? 'doctor.requests.patient_unknown'.tr();

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header
            DetailScreenHeader(title: 'doctor.requests.detail.title'.tr()),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 120,
                ), // Space for fixed buttons
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section with patient info and avatar
                    _buildTitleSection(
                      context,
                      consultation,
                      patientName,
                      patient,
                    ),

                    // Status badges
                    _buildStatusBadges(context, consultation),

                    // Patient Report card
                    _buildPatientReportCard(context, consultation),

                    // Timeline/conversation section
                    _buildTimelineSection(
                      context,
                      consultation,
                      patientName,
                      patient,
                    ),
                  ],
                ),
              ),
            ),

            // Fixed bottom action buttons
            _buildActionButtons(context, consultation, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    ConsultationModel consultation,
    String patientName,
    dynamic patient,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Build patient info subtitle (name • age gender)
    String patientInfo = patientName;
    if (patient != null) {
      final age = patient.dateOfBirth != null
          ? DateTime.now().year - patient.dateOfBirth!.year
          : null;
      final gender = patient.gender;
      final parts = <String>[];
      if (age != null) parts.add('$age');
      if (gender != null) parts.add(gender);
      if (parts.isNotEmpty) {
        patientInfo = '$patientName • ${parts.join(' ')}';
      }
    }

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
          // Title and subtitle
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
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  patientInfo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),

          // Patient avatar (48px with border)
          Container(
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
            child: ClipOval(
              child: patient?.photoUrl != null && patient!.photoUrl!.isNotEmpty
                  ? Image.network(
                      patient.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarInitials(context, patientName),
                    )
                  : _buildAvatarInitials(context, patientName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitials(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getInitials(name);

    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
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
          // Status badge
          _buildStatusBadge(context, consultation.status, isDark),
          // Urgency badge
          _buildUrgencyBadge(context, consultation.urgency),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, bool isDark) {
    final badgeColors = Theme.of(context).extension<AppBadgeColors>()!;
    final style = badgeColors.forStatus(status);
    final label = 'common.status.$status'.tr();
    final showPulse = status == 'in_review' || status == 'info_requested';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(color: style.text.withValues(alpha: 0.3)),
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
                color: style.text,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: style.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(BuildContext context, String urgency) {
    final badgeColors = Theme.of(context).extension<AppBadgeColors>()!;
    final style = badgeColors.forUrgency(urgency);

    String label;
    IconData? icon;
    switch (urgency.toLowerCase()) {
      case 'high':
      case 'urgent':
        label = 'common.urgency.high'.tr();
        icon = Icons.priority_high;
        break;
      case 'moderate':
      case 'medium':
        label = 'common.urgency.moderate'.tr();
        break;
      case 'low':
      case 'general':
      default:
        label = 'common.urgency.low'.tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(color: style.text.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: style.text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: style.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientReportCard(
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
            // Header with icon
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                ),
                const SizedBox(width: 8),
                Text(
                  'doctor.requests.detail.patient_report'.tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description in quotes
            Text(
              '"${consultation.description}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                height: 1.6,
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

  Widget _buildTimelineSection(
    BuildContext context,
    ConsultationModel consultation,
    String patientName,
    dynamic patient,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReviewStarted =
        consultation.status == 'in_review' ||
        consultation.status == 'info_requested' ||
        consultation.status == 'completed';

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
              senderName: patientName,
              message: fullResponse,
              timestamp: request.respondedAt ?? DateTime.now(),
              avatarUrl: patient?.photoUrl,
            ),
          ),
        );
      }
    }

    // Add waiting indicator if there are pending info requests
    final hasPendingRequest = consultation.infoRequests.any(
      (r) => !r.isAnswered,
    );
    if (hasPendingRequest) {
      timelineItems.add(
        TimelineWaitingIndicator(
          message: 'doctor.requests.detail.waiting_patient_response'.tr(),
        ),
      );
    } else if (isReviewStarted && consultation.doctorResponse == null) {
      // Show waiting for doctor action
      timelineItems.add(
        TimelineWaitingIndicator(
          message: 'doctor.requests.detail.waiting_doctor_action'.tr(),
        ),
      );
    }

    if (timelineItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline header (optional)
          if (consultation.infoRequests.isNotEmpty) ...[
            Text(
              'doctor.requests.detail.conversation'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Timeline line decoration
          Stack(
            children: [
              // Vertical line
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
              ),

              // Timeline items
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: timelineItems,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ConsultationModel consultation,
    DoctorConsultationsController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Don't show actions for completed/cancelled
    if (consultation.status == 'completed' ||
        consultation.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    // Check conditions
    final canStartReview = consultation.status == 'pending';
    final isReviewStarted =
        consultation.status == 'in_review' ||
        consultation.status == 'info_requested';
    final hasPendingInfoRequest = consultation.infoRequests.any(
      (r) => !r.isAnswered,
    );

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
        child: Row(
          children: [
            // Request Info button (ghost style)
            if (isReviewStarted && !hasPendingInfoRequest)
              Expanded(
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
                  icon: const Icon(Icons.chat_outlined, size: 20),
                  label: Text('doctor.requests.detail.request_info'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                    ),
                    foregroundColor: isDark
                        ? AppTheme.slate200
                        : AppTheme.slate700,
                  ),
                ),
              ),

            if (isReviewStarted && !hasPendingInfoRequest)
              const SizedBox(width: AppTheme.spacing12),

            // Primary action button
            Expanded(
              flex: canStartReview
                  ? 1
                  : (isReviewStarted && !hasPendingInfoRequest ? 2 : 1),
              child: ElevatedButton.icon(
                onPressed: _statusBusy
                    ? null
                    : () => canStartReview
                          ? _startReview(controller, consultation)
                          : _navigateToResponse(controller, consultation),
                icon: Icon(
                  canStartReview
                      ? Icons.play_arrow
                      : Icons.check_circle_outline,
                  size: 20,
                ),
                label: Text(
                  canStartReview
                      ? 'doctor.requests.detail.start_review'.tr()
                      : 'doctor.requests.detail.submit_diagnosis'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startReview(
    DoctorConsultationsController controller,
    ConsultationModel consultation,
  ) async {
    setState(() => _statusBusy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await controller.updateStatus(consultation.id, 'in_review');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('doctor.requests.detail.status_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _statusBusy = false);
      }
    }
  }

  void _navigateToResponse(
    DoctorConsultationsController controller,
    ConsultationModel consultation,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: ResponseFormScreen(consultationId: consultation.id),
        ),
      ),
    );
  }
}
