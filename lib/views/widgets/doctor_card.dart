import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/doctor_model.dart';
import '../../utils/app_theme.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    this.onTap,
    this.availabilityLabel,
    this.availabilityDescription,
    this.availabilityColor,
    this.viewProfileLabel,
  });

  final DoctorModel doctor;
  final VoidCallback? onTap;
  final String? availabilityLabel;
  final String? availabilityDescription;
  final Color? availabilityColor;
  final String? viewProfileLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(initials: _initialsFromName(doctor.fullName)),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'specialties.${doctor.specialty.toString().split('.').last}'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            Wrap(
              spacing: AppTheme.spacing12,
              runSpacing: AppTheme.spacing8,
              children: [
                if (availabilityLabel != null)
                  _Badge(
                    icon: Icons.circle,
                    iconSize: 12,
                    iconColor: availabilityColor ?? AppTheme.secondaryGreen,
                    label: availabilityLabel!,
                  ),
                _Badge(
                  icon: Icons.badge_outlined,
                  label: doctor.experienceLabel,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              doctor.languagesLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    availabilityDescription ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right),
                  label: Text(viewProfileLabel ?? 'View profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.icon,
    this.iconColor,
    this.iconSize = AppTheme.iconSmall,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppTheme.textSecondary,
            ),
          if (icon != null) const SizedBox(width: AppTheme.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
