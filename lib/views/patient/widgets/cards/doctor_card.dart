import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';

class DoctorCard extends StatefulWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});

  final DoctorModel doctor;
  final VoidCallback? onTap;

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(context, doctor),
                const SizedBox(height: 12),
                _buildDivider(context),
                const SizedBox(height: 12),
                _buildBottomSection(context, doctor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, DoctorModel doctor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(context, doctor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Star
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'specialties.${doctor.specialty.toString().split('.').last}'
                              .tr(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              _buildAvailabilityBadge(context, doctor.isCurrentlyAvailable),
              const SizedBox(height: 8),
              _buildExperienceRow(context, doctor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, DoctorModel doctor) {
    // Placeholder image logic matching the design style
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        image: doctor.photoUrl != null
            ? DecorationImage(
                image: NetworkImage(doctor.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: doctor.photoUrl == null
          ? Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 40,
            )
          : null,
    );
  }

  Widget _buildAvailabilityBadge(BuildContext context, bool isAvailable) {
    if (isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).extension<AppSemanticColors>()!.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'common.availability.available_now'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).extension<AppSemanticColors>()!.success,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          // Assuming we can pass a date here later, generic 'Away' for now or from translation
          'common.availability.unavailable'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
  }

  Widget _buildExperienceRow(BuildContext context, DoctorModel doctor) {
    return Row(
      children: [
        Icon(Icons.school, size: 16, color: Theme.of(context).disabledColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${'common.years_format'.tr(namedArgs: {'years': doctor.experienceYears.toString()})} • ${'common.speaks'.tr(namedArgs: {'language': doctor.languages.isNotEmpty ? doctor.languages.first : 'EN'})}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).disabledColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildBottomSection(BuildContext context, DoctorModel doctor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'common.consultation_fee'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).disabledColor,
                ),
              ),
              Text(
                'doctors.price_format'.tr(
                  namedArgs: {
                    'price': doctor.consultationPrice.toStringAsFixed(0),
                  },
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
        ),
        MaterialButton(
          onPressed: widget.onTap,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          elevation: 0,
          highlightElevation: 0,
          hoverElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'common.book_appointment'.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
