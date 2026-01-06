import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/views/admin/widgets/skeletons/admin_doctor_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'create_doctor_screen.dart';

/// Admin screen for managing doctors - list, search, filter, edit, delete.
class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  final AdminService _adminService = AdminService();
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchController = TextEditingController();

  List<DoctorModel> _allDoctors = [];
  bool _isLoading = true;
  String? _error;

  // Filter state
  String _selectedFilter = 'all'; // 'all', 'available', 'unavailable'

  @override
  void initState() {
    super.initState();
    // Wait for route transition animation to complete before loading data
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) {
        _loadDoctors();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctors = await _doctorService.fetchAllDoctors();
      if (mounted) {
        setState(() {
          _allDoctors = doctors;
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

  List<DoctorModel> get _filteredDoctors {
    final searchQuery = _searchController.text.toLowerCase();
    return _allDoctors.where((doctor) {
      // Search filter
      final matchesSearch =
          searchQuery.isEmpty ||
          doctor.fullName.toLowerCase().contains(searchQuery) ||
          doctor.email.toLowerCase().contains(searchQuery) ||
          doctor.specialty.toString().toLowerCase().contains(searchQuery);

      // Availability filter
      final matchesFilter =
          _selectedFilter == 'all' ||
          (_selectedFilter == 'available' && doctor.isCurrentlyAvailable) ||
          (_selectedFilter == 'unavailable' && !doctor.isCurrentlyAvailable);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _navigateToEditDoctor(DoctorModel doctor) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CreateDoctorScreen(doctorToEdit: doctor),
          ),
        )
        .then((_) => _loadDoctors());
  }

  Future<void> _deleteDoctor(DoctorModel doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.doctors.delete_title'.tr()),
        content: Text(
          'admin.doctors.delete_message'.tr(
            namedArgs: {'name': doctor.fullName},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _adminService.deleteDoctor(doctor.uid);
        if (mounted) {
          NotificationsHelper().showSuccess(
            'admin.doctors.delete_success'.tr(),
            context: context,
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          NotificationsHelper().showError(e.toString(), context: context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header section
            _buildHeaderSection(context),

            // Scrollable content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                  ? _buildErrorState(context)
                  : _buildDoctorList(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the fixed header section with title, search, filters, and table header.
  Widget _buildHeaderSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with back button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    'admin.manage_doctors.title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.slate800 : AppTheme.slate100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppTheme.spacing12),
                  Icon(Icons.search, color: AppTheme.slate400, size: 20),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'admin.doctors.search_hint'.tr(),
                        hintStyle: TextStyle(color: AppTheme.slate400),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: AppTheme.slate400,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: AppTheme.spacing12),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'common.all'.tr(),
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip(
                    context,
                    label: 'common.availability.available'.tr(),
                    isSelected: _selectedFilter == 'available',
                    onTap: () => setState(() => _selectedFilter = 'available'),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip(
                    context,
                    label: 'common.availability.unavailable'.tr(),
                    isSelected: _selectedFilter == 'unavailable',
                    onTap: () =>
                        setState(() => _selectedFilter = 'unavailable'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.slate800.withValues(alpha: 0.5)
                  : AppTheme.slate50,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.slate800 : AppTheme.slate200,
                ),
                bottom: BorderSide(
                  color: isDark ? AppTheme.slate800 : AppTheme.slate200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'admin.doctors.column_doctor'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    'admin.doctors.column_status'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'admin.doctors.column_actions'.tr(),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a filter chip button matching the HTML design.
  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppTheme.slate900)
              : (isDark ? AppTheme.slate800 : AppTheme.slate100),
          borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppTheme.slate900 : Colors.white)
                  : (isDark ? AppTheme.slate300 : AppTheme.slate600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacing12),
          child: AdminDoctorCardSkeleton(),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'admin.doctors.error_loading'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton.icon(
              onPressed: _loadDoctors,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList(BuildContext context) {
    final filteredDoctors = _filteredDoctors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filteredDoctors.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.medical_services_outlined,
          title: 'admin.doctors.empty_title'.tr(),
          subtitle: 'admin.doctors.empty_subtitle'.tr(),
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: filteredDoctors.length,
        itemBuilder: (context, index) {
          final doctor = filteredDoctors[index];
          final isEven = index % 2 == 0;

          return _buildDoctorRow(context, doctor, isEven, isDark);
        },
      ),
    );
  }

  /// Builds a doctor row matching the HTML table design.
  Widget _buildDoctorRow(
    BuildContext context,
    DoctorModel doctor,
    bool isEven,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final specialtyKey = doctor.specialty.toString().split('.').last;

    // Background color with alternating rows
    final bgColor = isEven
        ? (isDark ? AppTheme.surfaceDark : Colors.white)
        : (isDark
              ? AppTheme.slate900.withValues(alpha: 0.4)
              : AppTheme.slate50);

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () => _navigateToEditDoctor(doctor),
        splashColor: isDark
            ? AppTheme.blue900.withValues(alpha: 0.1)
            : AppTheme.blue50.withValues(alpha: 0.5),
        highlightColor: isDark
            ? AppTheme.blue900.withValues(alpha: 0.1)
            : AppTheme.blue50.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.slate800 : AppTheme.slate100,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar with availability indicator
              _buildAvatarWithStatus(context, doctor, isDark),
              const SizedBox(width: AppTheme.spacing12),

              // Doctor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: doctor.isCurrentlyAvailable
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'specialties.$specialtyKey'.tr()} • ID: #${doctor.uid.substring(0, 4).toUpperCase()}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Availability badge
              SizedBox(
                width: 110,
                child: Center(
                  child: _buildAvailabilityBadge(context, doctor, isDark),
                ),
              ),

              // Action buttons
              SizedBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.edit_outlined,
                      onTap: () => _navigateToEditDoctor(doctor),
                      hoverColor: colorScheme.primary,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      context,
                      icon: Icons.delete_outlined,
                      onTap: () => _deleteDoctor(doctor),
                      hoverColor: isDark ? AppTheme.red400 : AppTheme.red600,
                      isDark: isDark,
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

  /// Builds an avatar with availability status indicator.
  Widget _buildAvatarWithStatus(
    BuildContext context,
    DoctorModel doctor,
    bool isDark,
  ) {
    final hasPhoto = doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppTheme.slate800 : Colors.white,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: hasPhoto
                ? Image.network(
                    doctor.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialsAvatar(
                          context,
                          doctor.fullName,
                          doctor.isCurrentlyAvailable,
                        ),
                  )
                : _buildInitialsAvatar(
                    context,
                    doctor.fullName,
                    doctor.isCurrentlyAvailable,
                  ),
          ),
        ),
        // Availability dot
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: doctor.isCurrentlyAvailable
                  ? const Color(0xFF22C55E) // green-500
                  : AppTheme.slate400,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppTheme.slate800 : Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(
    BuildContext context,
    String name,
    bool isAvailable,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getInitials(name);

    return Container(
      color: colorScheme.secondary.withValues(alpha: isAvailable ? 0.1 : 0.05),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: isAvailable
                ? colorScheme.secondary
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Builds the availability badge with proper colors.
  Widget _buildAvailabilityBadge(
    BuildContext context,
    DoctorModel doctor,
    bool isDark,
  ) {
    final isAvailable = doctor.isCurrentlyAvailable;

    // Colors matching HTML
    final bgColor = isAvailable
        ? (isDark
              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
              : const Color(0xFFDCFCE7)) // green-100
        : (isDark ? AppTheme.slate800 : AppTheme.slate100);

    final textColor = isAvailable
        ? (isDark
              ? const Color(0xFF4ADE80)
              : const Color(0xFF15803D)) // green-400/700
        : (isDark ? AppTheme.slate400 : AppTheme.slate600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Text(
        isAvailable
            ? 'common.availability.available'.tr().toUpperCase()
            : 'common.availability.unavailable'.tr().toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Builds an action button (edit/delete).
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required Color hoverColor,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        hoverColor: hoverColor.withValues(alpha: isDark ? 0.2 : 0.1),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, size: 20, color: AppTheme.slate400),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
