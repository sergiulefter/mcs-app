import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/doctor_model.dart';
import '../../utils/app_theme.dart';

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
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppTheme.screenPadding,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildQuickInfo(context),
                  if (widget.doctor.bio.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildBioSection(context),
                  ],
                  if (widget.doctor.education.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildEducationSection(context),
                  ],
                  if (widget.doctor.subspecialties.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sectionSpacing),
                    _buildSubspecialtiesSection(context),
                  ],
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildAvailabilitySection(context),
                  const SizedBox(height: AppTheme.spacing32),
                ],
              ),
            ),
            _buildRequestButton(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
        children: [
          Row(
            children: [
              _Avatar(initials: _initialsFromName(widget.doctor.fullName)),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.fullName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      _getSpecialtyName(widget.doctor.specialty),
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
                icon: widget.doctor.isCurrentlyAvailable
                    ? Icons.check_circle_outline
                    : Icons.access_time,
                iconColor: widget.doctor.isCurrentlyAvailable
                    ? AppTheme.secondaryGreen
                    : AppTheme.textTertiary,
                label: widget.doctor.isCurrentlyAvailable
                    ? 'doctor_profile.available_now'.tr()
                    : 'doctor_profile.unavailable'.tr(),
              ),
              const SizedBox(width: AppTheme.spacing8),
              _Badge(
                icon: Icons.work_outline,
                iconColor: AppTheme.primaryBlue,
                label: 'doctor_profile.years_experience'.tr(
                  namedArgs: {'years': widget.doctor.experienceYears.toString()},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(BuildContext context) {
    final priceFormat = NumberFormat('#,##0.00', 'en_US');

    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoColumn(
              icon: Icons.language,
              label: 'doctor_profile.languages'.tr(),
              value: widget.doctor.languagesLabel,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppTheme.dividerColor,
          ),
          Expanded(
            child: _InfoColumn(
              icon: Icons.attach_money,
              label: 'doctor_profile.consultation_price'.tr(),
              value: '${priceFormat.format(widget.doctor.consultationPrice)} ${'doctor_profile.currency'.tr()}',
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppTheme.dividerColor,
          ),
          Expanded(
            child: _InfoColumn(
              icon: Icons.school_outlined,
              label: 'doctor_profile.experience'.tr(),
              value: 'doctor_profile.years'.tr(namedArgs: {'years': widget.doctor.experienceYears.toString()}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(BuildContext context) {
    final bioLines = widget.doctor.bio.split('\n').length;
    final shouldShowExpandButton = bioLines > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'doctor_profile.about'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.doctor.bio,
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
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Icon(
                        _isBioExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: AppTheme.iconSmall,
                        color: AppTheme.primaryBlue,
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

  Widget _buildEducationSection(BuildContext context) {
    final sortedEducation = [...widget.doctor.education]
      ..sort((a, b) => b.year.compareTo(a.year));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'doctor_profile.education'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        ...sortedEducation.map((education) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
              child: Container(
                padding: AppTheme.cardPadding,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacing8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: AppTheme.iconMedium,
                            color: AppTheme.primaryBlue,
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
            )),
      ],
    );
  }

  Widget _buildSubspecialtiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'doctor_profile.subspecialties'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: widget.doctor.subspecialties.map((subspecialty) {
              return _Badge(
                label: subspecialty,
                icon: Icons.medical_services_outlined,
                iconColor: AppTheme.primaryBlue,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(BuildContext context) {
    final activeVacations = widget.doctor.vacationPeriods
        .where((vacation) => vacation.isActive())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'doctor_profile.availability_status'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.doctor.isCurrentlyAvailable
                          ? AppTheme.secondaryGreen
                          : AppTheme.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Text(
                    widget.doctor.isCurrentlyAvailable
                        ? 'doctor_profile.available_now'.tr()
                        : 'doctor_profile.unavailable'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                widget.doctor.isCurrentlyAvailable
                    ? 'doctor_profile.accepting_consultations'.tr()
                    : 'doctor_profile.not_accepting_consultations'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (activeVacations.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing16),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: AppTheme.spacing16),
                ...activeVacations.map((vacation) {
                  final dateFormat = DateFormat('dd MMM yyyy');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: AppTheme.iconSmall,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            'doctor_profile.on_vacation'.tr(namedArgs: {
                              'start': dateFormat.format(vacation.startDate),
                              'end': dateFormat.format(vacation.endDate),
                            }),
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: widget.doctor.isCurrentlyAvailable
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('doctor_profile.request_submitted'.tr()),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.medical_services_outlined),
        label: Text(
          widget.doctor.isCurrentlyAvailable
              ? 'doctor_profile.request_consultation'.tr()
              : 'doctor_profile.unavailable_button'.tr(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: AppTheme.textOnPrimary,
          disabledBackgroundColor: AppTheme.dividerColor,
          disabledForegroundColor: AppTheme.textTertiary,
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
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
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;

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
              size: AppTheme.iconSmall,
              color: iconColor ?? AppTheme.textSecondary,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppTheme.iconMedium,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
