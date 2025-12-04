import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/admin/widgets/cards/admin_doctor_card.dart';
import 'package:mcs_app/views/admin/widgets/skeletons/admin_doctor_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/patient/widgets/filters/themed_filter_chip.dart';
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
    // Skeletons show immediately, only Firebase call is deferred
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
      final matchesSearch = searchQuery.isEmpty ||
          doctor.fullName.toLowerCase().contains(searchQuery) ||
          doctor.email.toLowerCase().contains(searchQuery) ||
          doctor.specialty.toString().toLowerCase().contains(searchQuery);

      // Availability filter
      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'available' && doctor.isCurrentlyAvailable) ||
          (_selectedFilter == 'unavailable' && !doctor.isCurrentlyAvailable);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _navigateToEditDoctor(DoctorModel doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateDoctorScreen(doctorToEdit: doctor),
      ),
    ).then((_) => _loadDoctors());
  }

  Future<void> _deleteDoctor(DoctorModel doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.doctors.delete_title'.tr()),
        content: Text(
          'admin.doctors.delete_message'.tr(namedArgs: {'name': doctor.fullName}),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin.doctors.delete_success'.tr()),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin.doctors.delete_error'.tr()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.manage_doctors.title'.tr()),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState(context)
                : _buildContent(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: AppTheme.screenPadding,
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

  Widget _buildContent(BuildContext context) {
    final filteredDoctors = _filteredDoctors;

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          // Search bar
          SearchBar(
            controller: _searchController,
            hintText: 'admin.doctors.search_hint'.tr(),
            onChanged: (_) => setState(() {}),
            leading: const Icon(Icons.search_outlined),
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) => value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ThemedFilterChip(
                  label: 'common.all'.tr(),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ThemedFilterChip(
                  label: 'common.availability.available'.tr(),
                  selected: _selectedFilter == 'available',
                  onSelected: (_) => setState(() => _selectedFilter = 'available'),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ThemedFilterChip(
                  label: 'common.availability.unavailable'.tr(),
                  selected: _selectedFilter == 'unavailable',
                  onSelected: (_) => setState(() => _selectedFilter = 'unavailable'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Results count
          Text(
            'admin.doctors.results_count'.tr(
              namedArgs: {'count': filteredDoctors.length.toString()},
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Doctor list or empty state
          if (filteredDoctors.isEmpty)
            AppEmptyState(
              icon: Icons.medical_services_outlined,
              title: 'admin.doctors.empty_title'.tr(),
              subtitle: 'admin.doctors.empty_subtitle'.tr(),
              iconColor: Theme.of(context).colorScheme.secondary,
            )
          else
            ...filteredDoctors.map((doctor) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                  child: AdminDoctorCard(
                    doctor: doctor,
                    onEdit: () => _navigateToEditDoctor(doctor),
                    onDelete: () => _deleteDoctor(doctor),
                  ),
                )),
        ],
      ),
    );
  }
}
