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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Direct HTML Color mappings for precise fidelity
    final bgLight = const Color(0xFFF6F6F8);
    final bgDark = const Color(0xFF101622);
    final surfaceLight = const Color(0xFFFFFFFF);
    final surfaceDark = const Color(0xFF1A2130);
    final textSlate900 = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSlate500 = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

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
      backgroundColor: isDark ? bgDark : bgLight,
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
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage:
                              profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: (profileImage == null || profileImage.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryBlue,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 12,
                              color: textSlate500,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$displayName 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textSlate900,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: isDark ? surfaceDark : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.notifications_outlined,
                            size: 22,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
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
                      // Notification Badge Logic (Placeholder)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? surfaceDark : Colors.white,
                              width: 1,
                            ),
                          ),
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
                  textSlate900,
                ),
                const SizedBox(height: 16),
                _buildActiveRequestCard(
                  context,
                  activeConsultations.first,
                  isDark,
                  textSlate900,
                  textSlate500,
                  bgLight,
                  bgDark,
                  surfaceLight,
                  surfaceDark,
                ),
              ] else ...[
                // Placeholder or empty state for active requests?
                // Design suggests we should prompt to find a specialist if empty.
                _buildSectionHeader(
                  context,
                  'home.active_request_status'.tr(),
                  textSlate900,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? surfaceDark : surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.3)
                          : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 48,
                          color: textSlate500.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'home.no_active_consultations'.tr(),
                          style: TextStyle(
                            color: textSlate900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'home.consult_specialist_prompt'.tr(),
                          style: TextStyle(color: textSlate500, fontSize: 14),
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
                textSlate900,
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _buildSpecialistItem(
                      context,
                      'specialties.general'.tr(),
                      Icons.medical_services_outlined,
                      true,
                    ),
                    _buildSpecialistItem(
                      context,
                      'specialties.dentist'.tr(),
                      Icons.masks_outlined,
                      false,
                    ),
                    _buildSpecialistItem(
                      context,
                      'specialties.vision'.tr(),
                      Icons.visibility_outlined,
                      false,
                    ),
                    _buildSpecialistItem(
                      context,
                      'specialties.heart'.tr(),
                      Icons.favorite_outline,
                      false,
                    ),
                    _buildSpecialistItem(
                      context,
                      'specialties.lungs'.tr(),
                      Icons.air,
                      false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recent Activity (Dynamic)
              _buildSectionHeader(
                context,
                'home.recent_activity'.tr(),
                textSlate900,
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
                      style: TextStyle(color: textSlate500),
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
    ConsultationModel consultation, // Using ConsultationModel
    bool isDark,
    Color textSlate900,
    Color textSlate500,
    Color bgLight,
    Color bgDark,
    Color surfaceLight,
    Color surfaceDark,
  ) {
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
      statusColor = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? surfaceDark : surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        ),
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
                  color: AppTheme.primaryBlue.withValues(
                    alpha: 0.1,
                  ), // Use a themed color
                ),
                child: Center(
                  child: Text(
                    doctorName.isNotEmpty ? doctorName[0] : 'D',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.8),
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
              color: isDark ? bgDark.withValues(alpha: 0.5) : bgLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_outlined,
                    color: AppTheme.primaryBlue,
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
                backgroundColor: isDark ? surfaceDark : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
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
    bool isActive,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isActive
        ? AppTheme.primaryBlue
        : (isDark ? const Color(0xFF1A2130) : Colors.white);
    final iconColor = isActive
        ? Colors.white
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () => _navigateToTab(context, 1),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: isActive ? null : Border.all(color: borderColor),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
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
      color = Colors.green;
    } else if (status == 'in_review') {
      title = 'home.status.doctor_reviewing_title'.tr();
      icon = Icons.assignment_ind;
      color = AppTheme.primaryBlue;
      isNew = true;
    } else if (status == 'info_requested') {
      title = 'home.status.info_requested_title'.tr();
      icon = Icons.contact_support;
      color = Colors.orange;
      isNew = true;
    } else if (status == 'pending') {
      title = 'home.status.request_pending'.tr();
      icon = Icons.hourglass_empty;
      color = Colors.grey;
    } else {
      title = 'home.status.request_update'.tr();
      icon = Icons.notifications;
      color = Colors.purple;
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
    final surface = isDark ? const Color(0xFF1A2130) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

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
