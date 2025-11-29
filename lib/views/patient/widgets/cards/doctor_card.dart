import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';

class DoctorCard extends StatefulWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    this.onTap,
  });

  final DoctorModel doctor;
  final VoidCallback? onTap;

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final doctor = widget.doctor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Avatar + Doctor Info
                _buildDoctorInfoRow(context, doctor),
                const SizedBox(height: AppTheme.spacing16),

                // Divider
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Bottom section: Availability + Price
                _buildBottomRow(context, doctor),
                const SizedBox(height: AppTheme.spacing12),

                // CTA Button
                _buildCTAButton(context, doctor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoRow(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        _Avatar(initials: _initialsFromName(doctor.fullName)),
        const SizedBox(width: AppTheme.spacing16),

        // Info Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Verified Badge Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doctor.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (doctor.isProfileComplete) ...[
                    const SizedBox(width: AppTheme.spacing8),
                    _VerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),

              // Specialty
              Text(
                'specialties.${doctor.specialty.toString().split('.').last}'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacing8),

              // Experience Badge
              _ExperienceBadge(tier: doctor.experienceTier),
              const SizedBox(height: AppTheme.spacing8),

              // Price (separate row)
              Text(
                'doctors.price_format'.tr(namedArgs: {
                  'price': doctor.consultationPrice.toStringAsFixed(0),
                }),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              // Education Preview (if available)
              if (doctor.topEducation != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Expanded(
                      child: Text(
                        doctor.topEducation!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final isAvailable = doctor.isCurrentlyAvailable;

    return Row(
      children: [
        // Availability Indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable
                ? (semantic?.success ?? Colors.green)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          isAvailable
              ? 'common.availability.available_now'.tr()
              : 'common.availability.unavailable'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isAvailable
                    ? (semantic?.success ?? Colors.green)
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable = doctor.isCurrentlyAvailable;

    // Available: secondary (teal-green), softer than success green
    // Unavailable: neutral surface with primary text for visual interest
    final bgColor = isAvailable
        ? colorScheme.secondary
        : colorScheme.surfaceContainerHighest;
    final fgColor = isAvailable
        ? colorScheme.onSecondary
        : colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.onTap,
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('doctors.view_profile'.tr()),
            const SizedBox(width: AppTheme.spacing8),
            const Icon(Icons.arrow_forward, size: 18),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'doctors.verified'.tr(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.verified,
          size: 14,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ExperienceBadge extends StatelessWidget {
  const _ExperienceBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine label and color based on tier
    String label;
    Color badgeColor;

    switch (tier) {
      case '15+':
        label = 'doctors.experience.years_15'.tr();
        badgeColor = colorScheme.primary;
      case '10+':
        label = 'doctors.experience.years_10'.tr();
        badgeColor = colorScheme.primary.withValues(alpha: 0.8);
      case '5+':
        label = 'doctors.experience.years_5'.tr();
        badgeColor = colorScheme.secondary;
      default:
        label = 'doctors.experience.new'.tr();
        badgeColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
