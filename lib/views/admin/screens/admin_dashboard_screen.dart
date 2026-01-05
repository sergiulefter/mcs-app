import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/screens/login_screen.dart';
import 'create_doctor_screen.dart';
import 'doctor_management_screen.dart';
import 'user_management_screen.dart';
import 'system_settings_screen.dart';

/// Admin dashboard with statistics, navigation to admin features.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();

  Map<String, int>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _adminService.getStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh stats silently without showing loading indicator.
  /// Used for background refresh after navigation to prevent layout glitch.
  Future<void> _refreshStatisticsSilently() async {
    try {
      final stats = await _adminService.getStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      // Silently fail on background refresh - user can pull to refresh
    }
  }

  void _navigateToCreateDoctor(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const CreateDoctorScreen()),
        )
        .then((_) => _refreshStatisticsSilently());
  }

  void _navigateToDoctorManagement(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const DoctorManagementScreen(),
          ),
        )
        .then((_) => _refreshStatisticsSilently());
  }

  void _navigateToUserManagement(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const UserManagementScreen()),
        )
        .then((_) => _refreshStatisticsSilently());
  }

  void _navigateToSystemSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.sign_out_title'.tr()),
        content: Text('admin.sign_out_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('admin.sign_out'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authController = context.read<AuthController>();
      final consultationsController = context.read<ConsultationsController>();

      // Clear cached data before signing out
      consultationsController.clear();
      await authController.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatistics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                _buildHeader(context),

                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spacing24),

                      // Overview Section
                      _buildSectionLabel(context, 'admin.statistics'.tr()),
                      const SizedBox(height: AppTheme.spacing16),
                      _buildStatisticsGrid(context),
                      const SizedBox(height: AppTheme.spacing32),

                      // Quick Actions Section
                      _buildSectionLabel(context, 'common.quick_actions'.tr()),
                      const SizedBox(height: AppTheme.spacing16),
                      _buildQuickActionsGrid(context),
                      const SizedBox(height: AppTheme.spacing32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header with welcome message and logout button.
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Subtle border color matching HTML: border-slate-200/50 dark:border-slate-800/50
    final borderColor = isDark
        ? AppTheme.slate800.withValues(alpha: 0.5)
        : AppTheme.slate200.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing24,
        AppTheme.spacing20,
        AppTheme.spacing24,
        AppTheme.spacing20,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.9)
            : AppTheme.backgroundLight.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.welcome'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'admin.dashboard_title'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Logout Button - icon only, with hover effect
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleSignOut(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              hoverColor: isDark
                  ? AppTheme.red900.withValues(alpha: 0.2)
                  : AppTheme.red50,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                child: Icon(
                  Icons.logout_outlined,
                  size: AppTheme.iconMedium,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an uppercase section label.
  Widget _buildSectionLabel(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.spacing4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  /// Builds the statistics grid with 4 stat cards.
  Widget _buildStatisticsGrid(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // First row: Patients and Doctors
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.group_outlined,
                label: 'admin.stats.patients'.tr(),
                value: '${_stats?['totalPatients'] ?? 0}',
                iconColor: isDark ? AppTheme.blue400 : AppTheme.blue600,
                iconBackgroundColor: isDark
                    ? AppTheme.blue900.withValues(alpha: 0.3)
                    : AppTheme.blue50,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'admin.stats.doctors'.tr(),
                value: '${_stats?['totalDoctors'] ?? 0}',
                iconColor: isDark ? AppTheme.emerald400 : AppTheme.emerald600,
                iconBackgroundColor: isDark
                    ? AppTheme.emerald900.withValues(alpha: 0.3)
                    : AppTheme.emerald50,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        // Second row: Consultations and Pending
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.assignment_outlined,
                label: 'admin.stats.consultations'.tr(),
                value: '${_stats?['totalConsultations'] ?? 0}',
                iconColor: isDark ? AppTheme.purple400 : AppTheme.purple600,
                iconBackgroundColor: isDark
                    ? AppTheme.purple900.withValues(alpha: 0.3)
                    : AppTheme.purple50,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.hourglass_top_outlined,
                label: 'common.status.pending'.tr(),
                value: '${_stats?['pendingConsultations'] ?? 0}',
                iconColor: isDark ? AppTheme.amber400 : AppTheme.amber600,
                iconBackgroundColor: isDark
                    ? AppTheme.amber900.withValues(alpha: 0.3)
                    : AppTheme.amber50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an individual stat card with modern design.
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color iconBackgroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Border matching HTML: border-slate-100 dark:border-slate-700
    final borderColor = isDark ? AppTheme.slate700 : AppTheme.slate100;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // p-1.5 = 6px
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error state for statistics loading failure.
  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              'admin.stats_error'.tr(),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: _loadStatistics,
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  /// Builds the quick actions grid with 4 action buttons.
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      children: [
        // First row: Manage Doctors and Manage Users
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'admin.manage_doctors.title'.tr(),
                onTap: () => _navigateToDoctorManagement(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.group_outlined,
                label: 'admin.manage_users.title'.tr(),
                onTap: () => _navigateToUserManagement(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        // Second row: Create Doctor and System Settings
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.person_add_outlined,
                label: 'admin.create_doctor.button'.tr(),
                onTap: () => _navigateToCreateDoctor(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.settings_outlined,
                label: 'admin.system_settings.title'.tr(),
                onTap: () => _navigateToSystemSettings(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an action card with secondary style and primary color on press.
  /// Matches HTML: bg-white dark:bg-slate-800 with hover:border-primary effect.
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Border color matching HTML: border-slate-200 dark:border-slate-700
    final borderColor = isDark ? AppTheme.slate700 : AppTheme.slate200;

    // Icon background matching HTML: bg-slate-50 dark:bg-slate-700
    final iconBgColor = isDark ? AppTheme.slate700 : AppTheme.slate50;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        // Highlight on press with primary color border effect
        highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Ink(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
