import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/user_model.dart';
import 'package:mcs_app/services/admin_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
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

  // Filter state
  String _selectedFilter = 'all'; // 'all', 'complete', 'incomplete'

  @override
  void initState() {
    super.initState();
    // Wait for route transition animation to complete before loading data
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
    return _allUsers.where((user) {
      // Search filter
      final matchesSearch =
          searchQuery.isEmpty ||
          user.email.toLowerCase().contains(searchQuery) ||
          (user.displayName?.toLowerCase().contains(searchQuery) ?? false);

      // Profile filter
      final matchesFilter =
          _selectedFilter == 'all' ||
          (_selectedFilter == 'complete' && user.profileCompleted) ||
          (_selectedFilter == 'incomplete' && !user.profileCompleted);

      return matchesSearch && matchesFilter;
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

    if ((confirmed ?? false) && mounted) {
      try {
        await _adminService.deleteUser(user.uid);
        if (mounted) {
          NotificationsHelper().showSuccess(
            'admin.users.delete_success'.tr(),
            context: context,
          );
          _loadUsers();
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
                  : _buildUserList(context),
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
                    'admin.manage_users.title'.tr(),
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
                  const Icon(Icons.search, color: AppTheme.slate400, size: 20),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'admin.users.search_hint'.tr(),
                        hintStyle: const TextStyle(color: AppTheme.slate400),
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
                      icon: const Icon(
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
                    label: 'admin.users.profile_complete'.tr(),
                    isSelected: _selectedFilter == 'complete',
                    onTap: () => setState(() => _selectedFilter = 'complete'),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip(
                    context,
                    label: 'admin.users.profile_incomplete'.tr(),
                    isSelected: _selectedFilter == 'incomplete',
                    onTap: () => setState(() => _selectedFilter = 'incomplete'),
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
                    'admin.users.column_user'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'admin.users.column_status'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'admin.users.column_actions'.tr(),
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

  Widget _buildUserList(BuildContext context) {
    final filteredUsers = _filteredUsers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filteredUsers.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.people_outlined,
          title: 'admin.users.empty_title'.tr(),
          subtitle: 'admin.users.empty_subtitle'.tr(),
          iconColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final isEven = index % 2 == 0;

          return _buildUserRow(context, user, isEven, isDark);
        },
      ),
    );
  }

  /// Builds a user row matching the table design.
  Widget _buildUserRow(
    BuildContext context,
    UserModel user,
    bool isEven,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Background color with alternating rows
    final bgColor = isEven
        ? (isDark ? AppTheme.surfaceDark : Colors.white)
        : (isDark
              ? AppTheme.slate900.withValues(alpha: 0.4)
              : AppTheme.slate50);

    // Format join date
    final joinDate = DateFormat('MMM d, yyyy').format(user.createdAt);

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          // Could navigate to user detail in the future
        },
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
              // Avatar with profile status indicator
              _buildAvatarWithStatus(context, user, isDark),
              const SizedBox(width: AppTheme.spacing12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'admin.users.unnamed'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.email} • ${'admin.users.joined'.tr()} $joinDate',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Profile status badge
              SizedBox(
                width: 80,
                child: Center(child: _buildProfileBadge(context, user, isDark)),
              ),

              // Delete button
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.delete_outlined,
                      onTap: () => _deleteUser(user),
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

  /// Builds an avatar with profile status indicator.
  Widget _buildAvatarWithStatus(
    BuildContext context,
    UserModel user,
    bool isDark,
  ) {
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;
    final isComplete = user.profileCompleted;

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
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialsAvatar(
                          context,
                          user.displayName ?? user.email,
                        ),
                  )
                : _buildInitialsAvatar(context, user.displayName ?? user.email),
          ),
        ),
        // Profile status dot
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isComplete
                  ? const Color(0xFF22C55E) // green-500
                  : AppTheme.amber600,
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

  Widget _buildInitialsAvatar(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getInitials(name);

    return Container(
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Builds the profile status badge.
  Widget _buildProfileBadge(BuildContext context, UserModel user, bool isDark) {
    final isComplete = user.profileCompleted;

    // Colors matching the doctor management screen pattern
    final bgColor = isComplete
        ? (isDark
              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
              : const Color(0xFFDCFCE7)) // green-100
        : (isDark
              ? AppTheme.amber600.withValues(alpha: 0.1)
              : const Color(0xFFFEF3C7)); // amber-100

    final textColor = isComplete
        ? (isDark
              ? const Color(0xFF4ADE80)
              : const Color(0xFF15803D)) // green-400/700
        : (isDark ? AppTheme.amber400 : AppTheme.amber600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Text(
        isComplete ? 'OK' : 'PENDING',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Builds an action button (delete).
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
