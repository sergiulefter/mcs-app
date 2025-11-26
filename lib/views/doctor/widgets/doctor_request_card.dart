import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/widgets/status_chip.dart';
import 'package:mcs_app/views/doctor/widgets/urgency_badge.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:provider/provider.dart';

/// Reusable consultation preview card for doctor flows.
class DoctorRequestCard extends StatelessWidget {
  const DoctorRequestCard({
    super.key,
    required this.consultation,
    this.onTap,
  });

  final ConsultationModel consultation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DoctorConsultationsController>();
    final patient = controller.patientProfile(consultation.patientId);
    final patientName =
        patient?.displayName ?? patient?.email ?? 'doctor.requests.patient_unknown'.tr();
    final dateText = DateFormat.yMMMd().add_Hm().format(consultation.createdAt);

    return SurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    consultation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                UrgencyBadge(urgency: consultation.urgency),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              consultation.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: AppTheme.iconSmall,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    patientName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                StatusChip(status: consultation.status),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: AppTheme.iconSmall,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
