import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Card widget for displaying doctor information in admin management screens.
/// Includes action buttons for edit and delete operations.
class AdminDoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminDoctorCard({
    super.key,
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final specialtyKey = doctor.specialty.toString().split('.').last;

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
            // Header row with avatar, name, and specialty
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(doctor.fullName),
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                // Name and specialty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'specialties.$specialtyKey'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: doctor.isCurrentlyAvailable
                        ? colorScheme.secondary.withValues(alpha: 0.1)
                        : colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    doctor.isCurrentlyAvailable
                        ? 'admin.doctors.available'.tr()
                        : 'admin.doctors.unavailable'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: doctor.isCurrentlyAvailable
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
                  icon: Icons.email_outlined,
                  label: doctor.email,
                ),
                const SizedBox(width: AppTheme.spacing12),
                _buildInfoChip(
                  context,
                  icon: Icons.work_outline,
                  label: '${doctor.experienceYears} ${'admin.doctors.years'.tr()}',
                ),
              ],
            ),
            const Divider(height: AppTheme.spacing24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('admin.doctors.edit'.tr()),
                ),
                const SizedBox(width: AppTheme.spacing8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    'admin.doctors.delete'.tr(),
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
}
