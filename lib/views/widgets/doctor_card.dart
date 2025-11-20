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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'specialties.${doctor.specialty.toString().split('.').last}'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    iconColor: availabilityColor ?? Theme.of(context).colorScheme.secondary,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    availabilityDescription ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
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
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? colorScheme.primary,
            ),
          if (icon != null) const SizedBox(width: AppTheme.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
