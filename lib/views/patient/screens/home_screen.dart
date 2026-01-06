import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/navigation_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/views/patient/screens/request_detail_screen.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeConsultations();
    });
  }

  Future<void> _primeConsultations() async {
    final authController = context.read<AuthController>();
    final consultationsController = context.read<ConsultationsController>();

    if (authController.currentUser == null) return;

    final userId = authController.currentUser!.uid;
    await consultationsController.primeForUser(userId, force: true);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'home.good_morning'.tr();
    } else if (hour < 18) {
      return 'home.good_afternoon'.tr();
    } else {
      return 'home.good_evening'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final consultationsController = context.watch<ConsultationsController>();
    final user = authController.currentUser;

    // Dynamic Profile Data
    final profileImage = user?.photoUrl;
    final displayName = user?.displayName ?? 'User';

    // Dynamic Consultation Data
    final activeConsultations =
        consultationsController.recentActiveConsultations;
    final allConsultations = consultationsController.consultations;
    // Map recent consultations to activity items
    final recentActivity = allConsultations.take(3).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            backgroundImage:
                                profileImage != null && profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : null,
                            child:
                                (profileImage == null || profileImage.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Stack(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.notifications_outlined,
                            size: 22,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Active Request Status (Conditional)
              if (activeConsultations.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'home.active_request_status'.tr(),
                  Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 16),
                _buildActiveRequestCard(context, activeConsultations.first),
              ] else ...[
                // Placeholder or empty state for active requests?
                // Design suggests we should prompt to find a specialist if empty.
                _buildSectionHeader(
                  context,
                  'home.active_request_status'.tr(),
                  Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'home.no_active_consultations'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'home.consult_specialist_prompt'.tr(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Find a Specialist
              _buildSectionHeader(
                context,
                'home.find_specialist'.tr(),
                Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                padding: EdgeInsets.zero,
                children: [
                  _buildSpecialistItem(
                    context,
                    'specialties.general'.tr(),
                    Icons.medical_services_outlined,
                  ),
                  _buildSpecialistItem(
                    context,
                    'specialties.dentist'.tr(),
                    Icons.masks_outlined,
                  ),
                  _buildSpecialistItem(
                    context,
                    'specialties.vision'.tr(),
                    Icons.visibility_outlined,
                  ),
                  _buildSpecialistItem(
                    context,
                    'specialties.heart'.tr(),
                    Icons.favorite_outline,
                  ),
                  _buildSpecialistItem(
                    context,
                    'specialties.lungs'.tr(),
                    Icons.air,
                  ),
                  _buildSpecialistItem(
                    context,
                    'common.more'.tr(),
                    Icons.grid_view_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity (Dynamic)
              _buildSectionHeader(
                context,
                'home.recent_activity'.tr(),
                Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 16),
              if (recentActivity.isNotEmpty)
                Column(
                  children: recentActivity.map((consultation) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildConsultationActivityItem(
                        context,
                        consultation,
                      ),
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'home.no_recent_activity'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRequestCard(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textSlate900 = colorScheme.onSurface;
    final textSlate500 = colorScheme.onSurfaceVariant;
    final surfaceColor = Theme.of(context).cardColor;
    final dividerColor = Theme.of(context).dividerColor;
    // Map status to display
    final status = consultation.status;
    final doctorName =
        consultation.doctorName ?? 'common.waiting_for_doctor'.tr();
    final specialty =
        consultation.doctorSpecialty ?? 'specialties.general'.tr();
    final requestId = consultation.id
        .substring(consultation.id.length - 5)
        .toUpperCase(); // Last 5 chars

    // Status colors
    Color statusColor = const Color(0xFFF59E0B); // Amber default
    String statusText = status.toUpperCase().replaceAll('_', ' ');

    if (status == 'completed') {
      statusColor = Colors.green;
    } else if (status == 'in_review') {
      statusColor = const Color(0xFFF59E0B);
    } else if (status == 'pending') {
      statusColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1152D4).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.1,
                  ), // Use a themed color
                ),
                child: Center(
                  child: Text(
                    doctorName.isNotEmpty ? doctorName[0] : 'D',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: textSlate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                specialty,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSlate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request ID: #$requestId',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSlate500.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_ind_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusMessage(status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textSlate900,
                        ),
                      ),
                      Text(
                        _getStatusSubMessage(status),
                        style: TextStyle(fontSize: 12, color: textSlate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        RequestDetailScreen(consultation: consultation),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: surfaceColor,
                side: BorderSide(color: dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'common.view_details'.tr(),
                    style: TextStyle(
                      color: textSlate900,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: textSlate500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'home.status.pending'.tr();
      case 'in_review':
        return 'home.status.doctor_reviewing'.tr();
      case 'info_requested':
        return 'home.status.info_requested'.tr();
      case 'completed':
        return 'home.status.completed'.tr();
      case 'cancelled':
        return 'home.status.cancelled'.tr();
      default:
        return 'home.status.update_available'.tr();
    }
  }

  String _getStatusSubMessage(String status) {
    switch (status) {
      case 'pending':
        return 'home.status.pending_desc'.tr();
      case 'in_review':
        return 'home.status.doctor_reviewing_desc'.tr();
      case 'info_requested':
        return 'home.status.info_requested_desc'.tr();
      case 'completed':
        return 'home.status.completed_desc'.tr();
      default:
        return 'home.status.view_details'.tr();
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  Widget _buildSpecialistItem(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Icon background matching Admin Dashboard: bg-slate-50 dark:bg-slate-700
    final iconBgColor = isDark ? AppTheme.slate700 : AppTheme.slate50;

    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToTab(context, 1),
              borderRadius: BorderRadius.circular(16),
              highlightColor: colorScheme.primary.withValues(alpha: 0.1),
              splashColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Ink(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConsultationActivityItem(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final status = consultation.status;

    // Determine appearance based on status
    String title;
    IconData icon;
    Color color;
    bool isNew = false;

    if (status == 'completed') {
      title = 'home.status.request_approved'.tr();
      icon = Icons.verified;
      color = Theme.of(context).extension<AppSemanticColors>()!.success;
    } else if (status == 'in_review') {
      title = 'home.status.doctor_reviewing_title'.tr();
      icon = Icons.assignment_ind;
      color = Theme.of(context).colorScheme.primary;
      isNew = true;
    } else if (status == 'info_requested') {
      title = 'home.status.info_requested_title'.tr();
      icon = Icons.contact_support;
      color = Theme.of(context).extension<AppSemanticColors>()!.warning;
      isNew = true;
    } else if (status == 'pending') {
      title = 'home.status.request_pending'.tr();
      icon = Icons.hourglass_empty;
      color = Theme.of(context).colorScheme.outline;
    } else {
      title = 'home.status.request_update'.tr();
      icon = Icons.notifications;
      color = Theme.of(context).colorScheme.tertiary;
    }

    final dateStr = DateFormat('MMM d • h:mm a').format(consultation.updatedAt);
    final subtitle =
        '$dateStr • ${consultation.doctorSpecialty ?? 'specialties.general'.tr()}';

    return _buildActivityItem(
      context,
      title,
      subtitle,
      icon,
      color,
      isNew: isNew,
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isNew = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;

    return InkWell(
      onTap: () => _navigateToTab(context, 2),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.3 : 0.1),
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isNew) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'common.new'.tr(),
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    final navigationController = NavigationController.of(context);
    navigationController?.onTabChange(tabIndex);
  }
}
