import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/doctor_consultation_detail_screen.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

/// Doctor-facing calendar view for consultations and availability.
class DoctorCalendarScreen extends StatefulWidget {
  const DoctorCalendarScreen({super.key});

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctor;

  bool _isDoctorLoading = true;
  bool _initialized = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeData());
  }

  Future<void> _primeData({bool force = false}) async {
    final auth = context.read<AuthController>();
    final controller = context.read<DoctorConsultationsController>();
    final doctorId = auth.currentUser?.uid;
    if (doctorId == null) return;

    setState(() => _isDoctorLoading = true);

    try {
      await controller.primeForDoctor(doctorId, force: force);
      final doctor = await _doctorService.fetchDoctorById(doctorId);

      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _isDoctorLoading = false;
        _initialized = true;
        _selectedDay ??= DateTime.now();
        _focusedDay = _selectedDay!;
      });
    } catch (e) {
      debugPrint('Error loading doctor data: $e');
      if (!mounted) return;
      setState(() {
        _isDoctorLoading = false;
        _initialized = true;
      });
    }
  }

  Future<void> _refresh() async {
    await _primeData(force: true);
  }

  void _goToToday() {
    setState(() {
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DoctorConsultationsController>(
          builder: (context, controller, _) {
            if ((_isDoctorLoading || controller.isLoading) && !_initialized) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredConsultations = _applyStatusFilter(
              controller.consultations,
            );
            final eventsByDay = _groupByDay(filteredConsultations);
            final selectedEvents = _selectedDay != null
                ? eventsByDay[_dayKey(_selectedDay!)] ?? const []
                : const <ConsultationModel>[];

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header with month/year and Today button
                  SliverToBoxAdapter(child: _buildHeader(context)),

                  // Calendar grid
                  SliverToBoxAdapter(
                    child: _buildCalendar(context, eventsByDay),
                  ),

                  // Status filter pills
                  SliverToBoxAdapter(child: _buildStatusFilters(context)),

                  // Selected day header and consultations
                  SliverToBoxAdapter(
                    child: _buildDaySummary(
                      context,
                      selectedEvents,
                      controller,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Header with month/year title and "Today" button
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthYear = DateFormat.yMMMM(
      context.locale.toLanguageTag(),
    ).format(_focusedDay);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing24,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            monthYear,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _goToToday,
            child: Text(
              'doctor.calendar.today_button'.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calendar grid with custom day cells
  Widget _buildCalendar(
    BuildContext context,
    Map<DateTime, List<ConsultationModel>> eventsByDay,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: AppTheme.spacing16,
      ),
      child: TableCalendar<ConsultationModel>(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2035),
        focusedDay: _focusedDay,
        locale: context.locale.languageCode,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerVisible: false, // We use custom header
        daysOfWeekHeight: 32,
        rowHeight: 44,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => eventsByDay[_dayKey(day)] ?? const [],
        holidayPredicate: _isVacationDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: true,
          cellMargin: EdgeInsets.zero,
          cellPadding: EdgeInsets.zero,
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final text = DateFormat.E(
              context.locale.languageCode,
            ).format(day).substring(0, 1).toUpperCase();
            return Center(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              eventsByDay[_dayKey(day)] ?? const [],
              isOutside: true,
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final isVacation = _isVacationDay(day);
            return _buildDayCell(
              context,
              day,
              eventsByDay[_dayKey(day)] ?? const [],
              isVacation: isVacation,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final isVacation = _isVacationDay(day);
            return _buildDayCell(
              context,
              day,
              eventsByDay[_dayKey(day)] ?? const [],
              isToday: true,
              isVacation: isVacation,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final isVacation = _isVacationDay(day);
            return _buildDayCell(
              context,
              day,
              eventsByDay[_dayKey(day)] ?? const [],
              isSelected: true,
              isVacation: isVacation,
            );
          },
          holidayBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              context,
              day,
              eventsByDay[_dayKey(day)] ?? const [],
              isVacation: true,
            );
          },
        ),
      ),
    );
  }

  /// Modern day cell with filled circle for selected, dot for events
  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<ConsultationModel> events, {
    bool isSelected = false,
    bool isToday = false,
    bool isVacation = false,
    bool isOutside = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Text color
    final textColor = isSelected
        ? colorScheme.onPrimary
        : isOutside
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
        : isVacation
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : colorScheme.onSurface;

    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number (with filled circle if selected)
          if (isSelected)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Text(
              '${day.day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),

          // Event indicator dot
          if (events.isNotEmpty && !isOutside)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Status filter pills (All, Pending, Completed)
  Widget _buildStatusFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filters = <String, String>{
      'all': 'doctor.calendar.filters.all'.tr(),
      'pending': 'doctor.calendar.filters.pending'.tr(),
      'completed': 'doctor.calendar.filters.completed'.tr(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final isSelected = _statusFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusCircular,
                    ),
                    border: isSelected
                        ? null
                        : Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Selected day summary with consultation cards
  Widget _buildDaySummary(
    BuildContext context,
    List<ConsultationModel> events,
    DoctorConsultationsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = _selectedDay != null
        ? DateFormat(
            'MMM d, yyyy',
            context.locale.toLanguageTag(),
          ).format(_selectedDay!)
        : '';

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Text(
            dateLabel.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Consultations or empty state
          if (events.isEmpty)
            AppEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'doctor.calendar.no_consultations_title'.tr(),
              subtitle: 'doctor.calendar.no_consultations_subtitle'.tr(),
            )
          else
            Column(
              children: events
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing16,
                      ),
                      child: _buildConsultationCard(context, event, controller),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Modern consultation card matching HTML design
  Widget _buildConsultationCard(
    BuildContext context,
    ConsultationModel consultation,
    DoctorConsultationsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final patient = controller.patientProfile(consultation.patientId);
    final patientName =
        patient?.displayName ?? 'doctor.requests.patient_unknown'.tr();
    final initials = _getInitials(patientName);

    final isCompleted = consultation.status == 'completed';
    final statusColor = isCompleted ? semantic.success : semantic.warning;
    final statusLabel = isCompleted
        ? 'common.status.completed'.tr()
        : 'common.status.pending'.tr();

    // Avatar colors based on name hash
    final avatarColors = _getAvatarColors(patientName, colorScheme);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row: avatar, name, status
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: avatarColors.background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: avatarColors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),

              // Name and type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      consultation.title,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
            child: Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),

          // Footer: time and action button
          Row(
            children: [
              // Time info
              Icon(
                isCompleted ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                _formatTimeInfo(consultation, isCompleted),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),

              // Action button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: DoctorConsultationDetailScreen(
                          consultationId: consultation.id,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  isCompleted
                      ? 'doctor.calendar.details_button'.tr()
                      : 'doctor.requests.review_button'.tr(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isCompleted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeInfo(ConsultationModel consultation, bool isCompleted) {
    final time = DateFormat('hh:mm a').format(consultation.createdAt);
    if (isCompleted) {
      return 'doctor.calendar.resolved_at'.tr(namedArgs: {'time': time});
    }
    return 'doctor.calendar.requested_for'.tr(namedArgs: {'time': time});
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  ({Color background, Color foreground}) _getAvatarColors(
    String name,
    ColorScheme colorScheme,
  ) {
    // Theme-aware avatar color palette
    final iconColors =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark
        ? AppIconColors.dark
        : AppIconColors.light;
    final colors = [
      (colorScheme.primary.withValues(alpha: 0.15), colorScheme.primary),
      (iconColors.help.withValues(alpha: 0.15), iconColors.help),
      (iconColors.privacy.withValues(alpha: 0.15), iconColors.privacy),
      (iconColors.time.withValues(alpha: 0.15), iconColors.time),
      (
        iconColors.notification.withValues(alpha: 0.15),
        iconColors.notification,
      ),
    ];
    final index = name.hashCode.abs() % colors.length;
    return (background: colors[index].$1, foreground: colors[index].$2);
  }

  Map<DateTime, List<ConsultationModel>> _groupByDay(
    List<ConsultationModel> consultations,
  ) {
    final Map<DateTime, List<ConsultationModel>> grouped = {};
    for (final consultation in consultations) {
      final key = _dayKey(consultation.createdAt);
      grouped.putIfAbsent(key, () => []).add(consultation);
    }
    return grouped;
  }

  List<ConsultationModel> _applyStatusFilter(
    List<ConsultationModel> consultations,
  ) {
    if (_statusFilter == 'all') return consultations;
    if (_statusFilter == 'pending') {
      return consultations
          .where((c) => c.status != 'completed' && c.status != 'cancelled')
          .toList();
    }
    return consultations.where((c) => c.status == _statusFilter).toList();
  }

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  bool _isVacationDay(DateTime day) {
    if (_doctor == null) return false;
    for (final vacation in _doctor!.vacationPeriods) {
      final start = _dayKey(vacation.startDate);
      final end = _dayKey(vacation.endDate);
      if ((day.isAfter(start) || isSameDay(day, start)) &&
          (day.isBefore(end) || isSameDay(day, end))) {
        return true;
      }
    }
    return false;
  }
}
