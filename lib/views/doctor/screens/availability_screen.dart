import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/medical_specialty.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_date_picker_field.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';

/// Availability management screen - Toggle availability and manage vacation periods
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctor;
  bool _isLoading = true;
  // kept for future state expansion (e.g., disabling actions during async ops)

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final doctor = await _doctorService.fetchDoctorById(userId);
      if (mounted) {
        setState(() {
          _doctor = doctor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addVacationPeriod(DateRange vacation) async {
    final userId = context.read<AuthController>().currentUser?.uid;
    if (userId == null) return;

    try {
      await _doctorService.addVacationPeriod(userId, vacation);
      await _loadDoctorData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('doctor.availability.vacation_added'.tr()),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeVacationPeriod(int index) async {
    final userId = context.read<AuthController>().currentUser?.uid;
    if (userId == null) return;

    try {
      await _doctorService.removeVacationPeriod(userId, index);
      await _loadDoctorData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('doctor.availability.vacation_removed'.tr()),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('doctor.availability.title'.tr()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.availability.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability Status Section
              _buildAvailabilityStatusCard(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Vacation Periods Section
              _buildVacationSection(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Info Card
              _buildInfoCard(context),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatusCard(BuildContext context) {
    final isCurrentlyAvailable = _doctor?.isCurrentlyAvailable ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'doctor.availability.status_section'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: isCurrentlyAvailable
                  ? colorScheme.secondary.withValues(alpha: 0.1)
                  : colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrentlyAvailable
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                  color: isCurrentlyAvailable
                      ? colorScheme.secondary
                      : colorScheme.error,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  isCurrentlyAvailable
                      ? 'doctor.availability.available_for_consultations'.tr()
                      : 'doctor.availability.not_available'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCurrentlyAvailable
                            ? colorScheme.secondary
                            : colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

        ],
      ),
    );
  }

  Widget _buildVacationSection(BuildContext context) {
    final vacations = _doctor?.vacationPeriods ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SectionHeader(title: 'doctor.availability.vacation_section'.tr()),
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: _showAddVacationDialog,
                icon: const Icon(Icons.add, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('doctor.availability.add_vacation'.tr()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),

        if (vacations.isEmpty)
          _buildEmptyVacationsState(context)
        else
          Column(
            children: vacations.asMap().entries.map((entry) {
              final index = entry.key;
              final vacation = entry.value;
              return _buildVacationCard(context, vacation, index);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyVacationsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'doctor.availability.no_vacations'.tr(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'doctor.availability.no_vacations_desc'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVacationCard(BuildContext context, DateRange vacation, int index) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Determine status
    String status;
    Color statusColor;

    if (vacation.isActive()) {
      status = 'doctor.availability.vacation_active'.tr();
      statusColor = Theme.of(context).colorScheme.error;
    } else if (vacation.startDate.isAfter(now)) {
      status = 'doctor.availability.vacation_upcoming'.tr();
      statusColor = Theme.of(context).colorScheme.tertiary;
    } else {
      status = 'doctor.availability.vacation_past'.tr();
      statusColor = Theme.of(context).hintColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.date_range_outlined,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${dateFormat.format(vacation.startDate)} - ${dateFormat.format(vacation.endDate)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                if (vacation.reason != null && vacation.reason!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    vacation.reason!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDeleteVacation(index),
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'doctor.availability.delete_vacation'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'doctor.availability.info_title'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'doctor.availability.info_text'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVacationDialog() {
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? startDateError;
    String? endDateError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('doctor.availability.add_vacation'.tr()),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                AppDatePickerField(
                  label: 'doctor.availability.start_date'.tr(),
                  hintText: 'dd/MM/yyyy',
                  selectedDate: startDate,
                  onDateSelected: (date) {
                      setDialogState(() {
                        startDate = date;
                        startDateError = null;
                        // Reset end date if it's before start date
                        if (endDate != null && endDate!.isBefore(date)) {
                          endDate = null;
                        }
                    });
                  },
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  errorText: startDateError,
                ),
                const SizedBox(height: AppTheme.spacing16),
                AppDatePickerField(
                  label: 'doctor.availability.end_date'.tr(),
                    hintText: 'dd/MM/yyyy',
                    selectedDate: endDate,
                    onDateSelected: (date) {
                    setDialogState(() {
                      endDate = date;
                      endDateError = null;
                    });
                  },
                  firstDate: startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  errorText: endDateError,
                ),
                  const SizedBox(height: AppTheme.spacing16),
                  AppTextField(
                    label: 'doctor.availability.reason'.tr(),
                    hintText: 'doctor.availability.reason_hint'.tr(),
                    controller: reasonController,
                    prefixIcon: Icons.notes_outlined,
                    isOptional: false,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'doctor.availability.validation.reason_required'.tr();
                      }
                      if (text.length < AppConstants.availabilityReasonMinLength) {
                        return 'doctor.availability.validation.reason_too_short'.tr(
                          namedArgs: {'min': AppConstants.availabilityReasonMinLength.toString()},
                        );
                      }
                      if (text.length > AppConstants.availabilityReasonMaxLength) {
                        return 'doctor.availability.validation.reason_too_long'.tr(
                          namedArgs: {'max': AppConstants.availabilityReasonMaxLength.toString()},
                        );
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate dates manually (not part of Form)
                bool datesValid = true;

                if (startDate == null) {
                  setDialogState(() {
                    startDateError = 'doctor.availability.validation.start_date_required'.tr();
                  });
                  datesValid = false;
                }

                if (endDate == null) {
                  setDialogState(() {
                    endDateError = 'doctor.availability.validation.end_date_required'.tr();
                  });
                  datesValid = false;
                }

                if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
                  setDialogState(() {
                    endDateError = 'doctor.availability.validation.end_before_start'.tr();
                  });
                  datesValid = false;
                }

                // Validate form (reason field)
                final formValid = formKey.currentState!.validate();

                if (!datesValid || !formValid) return;

                final vacation = DateRange(
                  startDate: startDate!,
                  endDate: endDate!,
                  reason: reasonController.text.trim(),
                );

                Navigator.of(dialogContext).pop();
                _addVacationPeriod(vacation);
              },
              child: Text('common.save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteVacation(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('doctor.availability.delete_vacation'.tr()),
        content: Text('doctor.availability.delete_vacation_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _removeVacationPeriod(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
