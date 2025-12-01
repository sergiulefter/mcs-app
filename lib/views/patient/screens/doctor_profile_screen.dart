import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/specialty_registry.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'create_request_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isBioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: AppTheme.screenPadding.copyWith(
                bottom: AppTheme.screenPadding.bottom + 100,
              ),
              children: [
                _buildHeader(context, doctor),
                const SizedBox(height: AppTheme.sectionSpacing),
                _buildQuickInfo(context, doctor),
                if (doctor.bio.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildBioSection(context, doctor),
                ],
                if (doctor.education.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildEducationSection(context, doctor),
                ],
                if (doctor.subspecialties.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildSubspecialtiesSection(context, doctor),
                ],
                const SizedBox(height: AppTheme.sectionSpacing),
                _buildAvailabilitySection(context, doctor),
              ],
            ),
            // Gradient scrim - fades content behind the floating area
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Button and text - floating
            Positioned(
              left: AppTheme.spacing16,
              right: AppTheme.spacing16,
              bottom: AppTheme.spacing16,
              child: _buildRequestButton(context, doctor),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.doctor.fullName,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DoctorModel doctor) {
    return SurfaceCard(
      padding: AppTheme.cardPadding,
      borderColor: Theme.of(context).dividerColor,
      showShadow: Theme.of(context).brightness == Brightness.light,
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(initials: _initialsFromName(doctor.fullName)),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      _getSpecialtyName(doctor.specialty),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              _Badge(
                icon: doctor.isCurrentlyAvailable
                    ? Icons.circle
                    : Icons.access_time,
                iconSize: doctor.isCurrentlyAvailable ? 12 : AppTheme.iconSmall,
                iconColor: doctor.isCurrentlyAvailable
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                label: doctor.isCurrentlyAvailable
                    ? 'common.availability.available_now'.tr()
                    : 'common.availability.currently_unavailable'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(BuildContext context, DoctorModel doctor) {
    final priceFormat = NumberFormat('#,##0.00', 'en_US');

    return SurfaceCard(
      padding: AppTheme.cardPadding,
      borderColor: Theme.of(context).dividerColor,
      showShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _InfoColumn(
              icon: Icons.language,
              label: 'common.languages'.tr(),
              value: doctor.languagesLabel,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _InfoColumn(
              icon: Icons.attach_money,
              label: 'doctor_profile.consultation_price'.tr(),
              value: '${priceFormat.format(doctor.consultationPrice)} ${'doctor_profile.currency'.tr()}',
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _InfoColumn(
              icon: Icons.badge_outlined,
              label: 'common.experience'.tr(),
              value: 'common.years_format'.tr(namedArgs: {'years': doctor.experienceYears.toString()}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(BuildContext context, DoctorModel doctor) {
    final bioLines = doctor.bio.split('\n').length;
    final shouldShowExpandButton = bioLines > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor_profile.about'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          borderColor: Theme.of(context).dividerColor,
          showShadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.bio,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                maxLines: _isBioExpanded ? null : 5,
                overflow: _isBioExpanded ? null : TextOverflow.ellipsis,
              ),
              if (shouldShowExpandButton) ...[
                const SizedBox(height: AppTheme.spacing12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isBioExpanded = !_isBioExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isBioExpanded
                            ? 'doctor_profile.read_less'.tr()
                            : 'doctor_profile.read_more'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Icon(
                        _isBioExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: AppTheme.iconSmall,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSection(BuildContext context, DoctorModel doctor) {
    final sortedEducation = [...doctor.education]
      ..sort((a, b) => b.year.compareTo(a.year));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor_profile.education'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        ...sortedEducation.map((education) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final iconColor = theme.colorScheme.onSurface;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: SurfaceCard(
              padding: AppTheme.cardPadding,
              borderColor: Theme.of(context).dividerColor,
              showShadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: isDark ? 0.25 : 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Icon(
                          Icons.school,
                          size: AppTheme.iconMedium,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              education.degree,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              education.institution,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      education.year.toString(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubspecialtiesSection(BuildContext context, DoctorModel doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor_profile.subspecialties'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          borderColor: Theme.of(context).dividerColor,
          showShadow: false,
          child: Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: doctor.subspecialties.map((subspecialty) {
              return _Badge(
                label: SpecialtyRegistry.translateSubspecialty(subspecialty),
                icon: Icons.medical_services_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(BuildContext context, DoctorModel doctor) {
    // Availability is already shown in the header badge and the footer handles
    // unavailable state with vacation details, so this section is redundant.
    return const SizedBox.shrink();
  }

  Widget _buildRequestButton(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final activeOrUpcomingVacations = doctor.vacationPeriods
        .where((vac) => vac.isActive() || vac.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Check if user has completed profile
    final user = context.watch<AuthController>().currentUser;
    final isProfileComplete = user?.profileCompleted ?? false;

    String? startDate;
    String? endDate;
    String? unavailableReason;
    if (!doctor.isCurrentlyAvailable &&
        activeOrUpcomingVacations.isNotEmpty) {
      final vac = activeOrUpcomingVacations.first;
      final dateFormat = DateFormat('dd MMM yyyy');
      startDate = dateFormat.format(vac.startDate);
      endDate = dateFormat.format(vac.endDate);
      if (vac.reason != null && vac.reason!.isNotEmpty) {
        unavailableReason = vac.reason!;
      }
    }

    if (doctor.isCurrentlyAvailable) {
      // Profile incomplete - show disabled state
      if (!isProfileComplete) {
        // Create solid opaque disabled colors by blending with surface
        final disabledBg = Color.alphaBlend(
          colorScheme.onSurface.withValues(alpha: 0.12),
          colorScheme.surface,
        );
        final disabledFg = Color.alphaBlend(
          colorScheme.onSurface.withValues(alpha: 0.38),
          colorScheme.surface,
        );
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.medical_services_outlined),
                label: Text('doctor_profile.request_consultation'.tr()),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: disabledBg,
                  disabledForegroundColor: disabledFg,
                  minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'doctor_profile.complete_profile_required'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }

      // Profile complete - show enabled button with colored shadow
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.3),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateRequestScreen(
                  doctor: doctor,
                ),
              ),
            );
          },
          icon: const Icon(Icons.medical_services_outlined),
          label: Text('doctor_profile.request_consultation'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
      );
    }

    // Doctor unavailable - show vacation info
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (startDate != null && endDate != null)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                children: [
                  TextSpan(text: 'doctor_profile.on_vacation_prefix'.tr()),
                  TextSpan(
                    text: ' $startDate ',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: 'doctor_profile.on_vacation_to'.tr()),
                  TextSpan(
                    text: ' $endDate',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          if (unavailableReason != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              unavailableReason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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

  String _getSpecialtyName(dynamic specialty) {
    // Extract enum value (e.g., "cardiology" from "MedicalSpecialty.cardiology")
    final specialtyKey = specialty.toString().split('.').last;
    return 'specialties.$specialtyKey'.tr();
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
                color: Theme.of(context).colorScheme.primary,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
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

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Calculate minimum height for 2 lines of labelSmall text
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final labelLineHeight =
        (labelStyle?.fontSize ?? 11) * (labelStyle?.height ?? 1.2);
    final twoLineLabelHeight = labelLineHeight * 2 + 4; // 2 lines + padding

    // Calculate minimum height for 2 lines of bodyMedium text (for value)
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final valueLineHeight =
        (valueStyle?.fontSize ?? 14) * (valueStyle?.height ?? 1.4);
    final twoLineValueHeight = valueLineHeight * 2 + 4; // 2 lines + padding

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppTheme.iconMedium,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacing8),
          SizedBox(
            height: twoLineLabelHeight,
            child: Center(
              child: Text(
                label,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          SizedBox(
            height: twoLineValueHeight,
            child: Center(
              child: Text(
                value,
                style: valueStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
