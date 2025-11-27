import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/screens/login_screen.dart';
import 'package:mcs_app/views/patient/screens/main_shell.dart';
import 'package:mcs_app/views/patient/widgets/cards/stat_card.dart';
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

  void _navigateToCreateDoctor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateDoctorScreen(),
      ),
    ).then((_) => _loadStatistics()); // Refresh stats when returning
  }

  void _navigateToDoctorManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DoctorManagementScreen(),
      ),
    ).then((_) => _loadStatistics()); // Refresh stats when returning
  }

  void _navigateToUserManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserManagementScreen(),
      ),
    ).then((_) => _loadStatistics()); // Refresh stats when returning
  }

  void _navigateToSystemSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SystemSettingsScreen(),
      ),
    );
  }

  void _navigateToPatientApp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MainShell(),
      ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.dashboard_title'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadStatistics,
            tooltip: 'common.refresh'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _handleSignOut(context),
            tooltip: 'admin.sign_out'.tr(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatistics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppTheme.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Statistics Section
                _buildSectionHeader(context, 'admin.statistics'.tr()),
                const SizedBox(height: AppTheme.spacing16),
                _buildStatisticsSection(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Quick Actions Section
                _buildSectionHeader(context, 'admin.quick_actions'.tr()),
                const SizedBox(height: AppTheme.spacing16),

                // Management Cards
                _buildManageDoctorsCard(context),
                const SizedBox(height: AppTheme.spacing12),
                _buildManageUsersCard(context),
                const SizedBox(height: AppTheme.spacing12),
                _buildCreateDoctorCard(context),
                const SizedBox(height: AppTheme.spacing12),
                _buildSystemSettingsCard(context),
                const SizedBox(height: AppTheme.spacing12),
                _buildViewPatientAppCard(context),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Info Section
                _buildInfoSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                'admin.stats_error'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
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

    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Column(
      children: [
        // First row: Patients and Doctors
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.people_outlined,
                value: '${_stats?['totalPatients'] ?? 0}',
                label: 'admin.stats.patients'.tr(),
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: StatCard(
                icon: Icons.medical_services_outlined,
                value: '${_stats?['totalDoctors'] ?? 0}',
                label: 'admin.stats.doctors'.tr(),
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        // Second row: Total and Pending Consultations
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.assignment_outlined,
                value: '${_stats?['totalConsultations'] ?? 0}',
                label: 'admin.stats.consultations'.tr(),
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: StatCard(
                icon: Icons.pending_outlined,
                value: '${_stats?['pendingConsultations'] ?? 0}',
                label: 'admin.stats.pending'.tr(),
                color: semantic.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            Icons.admin_panel_settings_outlined,
            size: AppTheme.iconXLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'admin.welcome'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          user?.email ?? 'admin.admin_user'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconMedium,
                  color: color,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageDoctorsCard(BuildContext context) {
    return _buildActionCard(
      context: context,
      icon: Icons.medical_services_outlined,
      title: 'admin.manage_doctors.title'.tr(),
      subtitle: 'admin.manage_doctors.subtitle'.tr(),
      color: Theme.of(context).colorScheme.secondary,
      onTap: () => _navigateToDoctorManagement(context),
    );
  }

  Widget _buildManageUsersCard(BuildContext context) {
    return _buildActionCard(
      context: context,
      icon: Icons.people_outlined,
      title: 'admin.manage_users.title'.tr(),
      subtitle: 'admin.manage_users.subtitle'.tr(),
      color: Theme.of(context).colorScheme.primary,
      onTap: () => _navigateToUserManagement(context),
    );
  }

  Widget _buildCreateDoctorCard(BuildContext context) {
    return _buildActionCard(
      context: context,
      icon: Icons.person_add_outlined,
      title: 'admin.create_doctor.button'.tr(),
      subtitle: 'admin.create_doctor.description'.tr(),
      color: Theme.of(context).colorScheme.tertiary,
      onTap: () => _navigateToCreateDoctor(context),
    );
  }

  Widget _buildSystemSettingsCard(BuildContext context) {
    return _buildActionCard(
      context: context,
      icon: Icons.settings_outlined,
      title: 'admin.system_settings.title'.tr(),
      subtitle: 'admin.system_settings.subtitle'.tr(),
      color: Theme.of(context).hintColor,
      onTap: () => _navigateToSystemSettings(context),
    );
  }

  Widget _buildViewPatientAppCard(BuildContext context) {
    return _buildActionCard(
      context: context,
      icon: Icons.visibility_outlined,
      title: 'admin.view_patient_app'.tr(),
      subtitle: 'admin.view_patient_app_desc'.tr(),
      color: Theme.of(context).colorScheme.outline,
      onTap: () => _navigateToPatientApp(context),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: AppTheme.iconMedium,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.info_title'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'admin.info_description'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
