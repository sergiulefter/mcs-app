import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/user_model.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/admin/widgets/cards/admin_user_card.dart';
import 'package:mcs_app/views/admin/widgets/skeletons/admin_user_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';

/// Admin screen for managing users (patients) - list, search, delete.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Wait for route transition animation to complete before loading data
    // Skeletons show immediately, only Firebase call is deferred
    Future.delayed(AppConstants.mediumDuration, () {
      if (mounted) {
        _loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _adminService.fetchAllPatients();
      if (mounted) {
        setState(() {
          _allUsers = users;
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

  List<UserModel> get _filteredUsers {
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isEmpty) {
      return _allUsers;
    }
    return _allUsers.where((user) {
      return user.email.toLowerCase().contains(searchQuery) ||
          (user.displayName?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.users.delete_title'.tr()),
        content: Text(
          'admin.users.delete_message'.tr(
            namedArgs: {'name': user.displayName ?? user.email},
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
        await _adminService.deleteUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin.users.delete_success'.tr()),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin.users.delete_error'.tr()),
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
        title: Text('admin.manage_users.title'.tr()),
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
          child: AdminUserCardSkeleton(),
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
              'admin.users.error_loading'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          // Search bar
          SearchBar(
            controller: _searchController,
            hintText: 'admin.users.search_hint'.tr(),
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

          // Results count
          Text(
            'admin.users.results_count'.tr(
              namedArgs: {'count': filteredUsers.length.toString()},
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // User list or empty state
          if (filteredUsers.isEmpty)
            AppEmptyState(
              icon: Icons.people_outlined,
              title: 'admin.users.empty_title'.tr(),
              subtitle: 'admin.users.empty_subtitle'.tr(),
              iconColor: Theme.of(context).colorScheme.primary,
            )
          else
            ...filteredUsers.map((user) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                  child: AdminUserCard(
                    user: user,
                    onDelete: () => _deleteUser(user),
                  ),
                )),
        ],
      ),
    );
  }
}
