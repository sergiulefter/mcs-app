import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_profile_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/views/doctor/screens/doctor_settings_screen.dart';

/// Doctor account screen matching the patient account screen design.
/// Shows profile overview, professional details, and info cards.
class DoctorAccountScreen extends StatelessWidget {
  const DoctorAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final profile = context.watch<DoctorProfileController>();
    final user = authController.currentUser;
    final doctor = profile.doctor;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null || doctor == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'account.no_user_logged_in'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                child: Column(
                  children: [
                    // Profile Overview (Avatar + Name + Specialty)
                    _buildProfileOverview(context, doctor),
                    const SizedBox(height: 32),

                    // Contact Information Card
                    _buildInfoCard(
                      context,
                      title: 'profile.contact_info'.tr(),
                      icon: Icons.contact_mail_outlined,
                      children: [
                        _buildInfoRow(
                          context,
                          label: 'common.email'.tr(),
                          value: user.email,
                          isFirst: true,
                        ),
                        _buildInfoRow(
                          context,
                          label: 'common.phone'.tr(),
                          value: user.phone ?? 'account.not_provided'.tr(),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Professional Details Card
                    _buildInfoCard(
                      context,
                      title: 'doctor.account.professional_info'.tr(),
                      icon: Icons.medical_services_outlined,
                      children: [
                        _buildInfoRow(
                          context,
                          label: 'common.specialty'.tr(),
                          value: 'specialties.${doctor.specialty.name}'.tr(),
                          isFirst: true,
                        ),
                        _buildInfoRow(
                          context,
                          label: 'common.experience'.tr(),
                          value: 'common.years_format'.tr(
                            namedArgs: {
                              'years': doctor.experienceYears.toString(),
                            },
                          ),
                        ),
                        _buildInfoRow(
                          context,
                          label: 'common.languages'.tr(),
                          value: doctor.languages.isNotEmpty
                              ? doctor.languages.join(', ')
                              : 'account.not_provided'.tr(),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Practice Info Card (like Medical Basics for patients)
                    _buildPracticeInfoCard(context, doctor),

                    const SizedBox(height: 16),
                    Text(
                      'profile.medical_records_updated'.tr(
                        namedArgs: {
                          'date': DateFormat(
                            'MMM d, h:mm a',
                          ).format(doctor.lastActive ?? doctor.createdAt),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Spacer for centering title
          Text(
            'profile.profile_setup'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  final profileController = context
                      .read<DoctorProfileController>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: profileController,
                        child: const DoctorSettingsScreen(),
                      ),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverview(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;
    final specialty = 'specialties.${doctor.specialty.name}'.tr();
    final initials = _getInitials(doctor.fullName);

    return Column(
      children: [
        // Avatar
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primaryContainer,
            border: Border.all(color: colorScheme.surface, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          doctor.fullName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Specialty
        Text(
          specialty,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Availability Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: doctor.isCurrentlyAvailable
                ? colorScheme.secondary.withValues(alpha: 0.1)
                : colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: doctor.isCurrentlyAvailable
                  ? colorScheme.secondary.withValues(alpha: 0.2)
                  : colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            doctor.isCurrentlyAvailable
                ? 'common.availability.available'.tr()
                : 'common.availability.unavailable'.tr(),
            style: TextStyle(
              color: doctor.isCurrentlyAvailable
                  ? colorScheme.secondary
                  : colorScheme.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937)
                : const Color(0xFFF9FAFB),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeInfoCard(BuildContext context, DoctorModel doctor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.work_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'doctor.account.practice_info'.tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937)
                : const Color(0xFFF9FAFB),
          ),
          // Grid Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildPracticeItem(
                  context,
                  label: 'doctor.account.price'.tr(),
                  value: doctor.consultationPrice > 0
                      ? '${doctor.consultationPrice.toStringAsFixed(0)} RON'
                      : '-',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                ),
                _buildPracticeItem(
                  context,
                  label: 'common.experience'.tr(),
                  value: '${doctor.experienceYears} yrs',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                ),
                _buildPracticeItem(
                  context,
                  label: 'common.languages'.tr(),
                  value: doctor.languages.isNotEmpty
                      ? doctor.languages.length.toString()
                      : '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'DR';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }
}
