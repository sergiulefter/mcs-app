import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/user_model.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Card widget for displaying patient/user information in admin management screens.
/// Includes action button for delete operation.
class AdminUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDelete;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with avatar and name
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(user.displayName ?? user.email),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'admin.users.no_name'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ),
                // Profile status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: user.profileCompleted
                        ? colorScheme.secondary.withValues(alpha: 0.1)
                        : colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    user.profileCompleted
                        ? 'admin.users.profile_complete'.tr()
                        : 'admin.users.profile_incomplete'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: user.profileCompleted
                              ? colorScheme.secondary
                              : colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            // Info row
            Row(
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: 'admin.users.joined'.tr(
                    namedArgs: {'date': _formatDate(user.createdAt)},
                  ),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.spacing12),
                  _buildInfoChip(
                    context,
                    icon: Icons.phone_outlined,
                    label: user.phone!,
                  ),
                ],
              ],
            ),
            const Divider(height: AppTheme.spacing24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    'admin.users.delete'.tr(),
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label}) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
