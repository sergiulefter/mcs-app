import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/doctor/screens/request_review_screen.dart';
import 'package:mcs_app/views/doctor/widgets/doctor_request_card.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/patient/widgets/filters/themed_filter_chip.dart';
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

  CalendarFormat _calendarFormat = CalendarFormat.month;
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
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.calendar.title'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<DoctorConsultationsController>(
          builder: (context, controller, _) {
            if ((_isDoctorLoading || controller.isLoading) && !_initialized) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredConsultations =
                _applyStatusFilter(controller.consultations);
            final eventsByDay = _groupByDay(filteredConsultations);
            final selectedEvents = _selectedDay != null
                ? eventsByDay[_dayKey(_selectedDay!)] ?? const []
                : const <ConsultationModel>[];

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.screenPadding,
                children: [
                  _buildViewToggle(context),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildStatusFilters(context),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildCalendar(context, eventsByDay),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  _buildDaySummary(context, selectedEvents),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'doctor.calendar.view_label'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        Wrap(
          spacing: AppTheme.spacing8,
          children: [
            ChoiceChip(
              label: Text('doctor.calendar.view_month'.tr()),
              selected: _calendarFormat == CalendarFormat.month,
              onSelected: (_) =>
                  setState(() => _calendarFormat = CalendarFormat.month),
              labelStyle: Theme.of(context).textTheme.labelLarge,
              selectedColor: colorScheme.primary.withValues(alpha: 0.12),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            ChoiceChip(
              label: Text('doctor.calendar.view_week'.tr()),
              selected: _calendarFormat == CalendarFormat.week,
              onSelected: (_) =>
                  setState(() => _calendarFormat = CalendarFormat.week),
              labelStyle: Theme.of(context).textTheme.labelLarge,
              selectedColor: colorScheme.primary.withValues(alpha: 0.12),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    final filters = <String, String>{
      'all': 'common.all'.tr(),
      'pending': 'common.status.pending'.tr(),
      'in_review': 'common.status.in_review'.tr(),
      'info_requested': 'common.status.info_requested'.tr(),
      'completed': 'common.status.completed'.tr(),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: ThemedFilterChip(
                label: entry.value,
                selected: _statusFilter == entry.key,
                onSelected: (_) => setState(() => _statusFilter = entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    Map<DateTime, List<ConsultationModel>> eventsByDay,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TableCalendar<ConsultationModel>(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2035),
      focusedDay: _focusedDay,
      locale: context.locale.languageCode,
      calendarFormat: _calendarFormat,
      availableGestures: AvailableGestures.horizontalSwipe,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      rowHeight: 64,
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
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      headerStyle: HeaderStyle(
        titleCentered: false,
        formatButtonVisible: false,
        titleTextStyle: (textTheme.titleLarge ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w700,
        ),
        leftChevronIcon: const Icon(Icons.chevron_left),
        rightChevronIcon: const Icon(Icons.chevron_right),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: textTheme.labelLarge!,
        weekendStyle: textTheme.labelLarge!,
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        cellMargin: EdgeInsets.zero,
        cellPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colorScheme.primary),
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        selectedTextStyle:
            (textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        holidayDecoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        holidayTextStyle:
            (textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        weekendTextStyle: textTheme.bodyMedium!,
        defaultTextStyle: textTheme.bodyMedium!,
        markerDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          final colors = events
              .map((event) => _urgencyColor(context, event.urgency))
              .toSet()
              .take(3)
              .toList();
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: colors
                    .map(
                      (color) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
        disabledBuilder: (context, day, focusedDay) {
          final isVacation = _isVacationDay(day);
          return _buildDayCell(
            context,
            day,
            eventsByDay[_dayKey(day)] ?? const [],
            isDisabled: true,
            isVacation: isVacation,
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          final isVacation = _isVacationDay(day);
          return _buildDayCell(
            context,
            day,
            eventsByDay[_dayKey(day)] ?? const [],
            isSelected: isSameDay(day, _selectedDay),
            isToday: isSameDay(day, DateTime.now()),
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
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<ConsultationModel> events, {
    bool isSelected = false,
    bool isToday = false,
    bool isVacation = false,
    bool isDisabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Background - use subtle opacity for vacation days
    final background = isSelected
        ? colorScheme.primary
        : isToday
            ? colorScheme.primary.withValues(alpha: 0.12)
            : isVacation
                ? colorScheme.onSurface.withValues(alpha: 0.05)
                : colorScheme.surface;

    // Text color - slightly muted for vacation days
    final textColor = isSelected
        ? colorScheme.onPrimary
        : isDisabled
            ? Theme.of(context).hintColor
            : isVacation
                ? colorScheme.onSurface.withValues(alpha: 0.5)
                : colorScheme.onSurface;

    // Border - only for today indicator, none for other cells
    final border = isToday && !isSelected
        ? Border.all(color: colorScheme.primary, width: 1)
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing4),
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: border,
          ),
          child: Stack(
            children: [
              // Vacation icon indicator in top-right corner (subtle)
              if (isVacation)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.beach_access,
                    size: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              // Day number and event indicator
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                    ),
                    if (events.isNotEmpty && !isVacation)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySummary(
    BuildContext context,
    List<ConsultationModel> events,
  ) {
    final dateLabel = _selectedDay != null
        ? DateFormat.yMMMMd(context.locale.toLanguageTag()).format(_selectedDay!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctor.calendar.day_overview'.tr()),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
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
                    padding:
                        const EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: DoctorRequestCard(
                      consultation: event,
                      onTap: () {
                        final controller =
                            context.read<DoctorConsultationsController>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: controller,
                              child: RequestReviewScreen(
                                consultationId: event.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
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

  Color _urgencyColor(BuildContext context, String urgency) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    switch (urgency) {
      case 'priority':
        return semantic.warning;
      default:
        return colorScheme.primary;
    }
  }
}
