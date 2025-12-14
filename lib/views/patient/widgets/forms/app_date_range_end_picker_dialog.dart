import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

/// A dialog that displays a calendar for selecting a date.
///
/// When [rangeStartDate] is provided, it highlights the range from that date
/// to the selected date for better UX when selecting vacation periods.
///
/// Returns the selected [DateTime] or null if cancelled.
Future<DateTime?> showAppCalendarPickerDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? rangeStartDate,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _AppCalendarPickerDialog(
      title: title,
      subtitle: subtitle,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
      rangeStartDate: rangeStartDate,
    ),
  );
}

class _AppCalendarPickerDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? rangeStartDate;

  const _AppCalendarPickerDialog({
    required this.title,
    this.subtitle,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.rangeStartDate,
  });

  @override
  State<_AppCalendarPickerDialog> createState() =>
      _AppCalendarPickerDialogState();
}

class _AppCalendarPickerDialogState extends State<_AppCalendarPickerDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDate;

  bool get _hasRangeStart => widget.rangeStartDate != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDay = widget.initialDate ?? widget.rangeStartDate ?? DateTime.now();

    // Ensure focused day is within bounds
    if (_focusedDay.isBefore(widget.firstDate)) {
      _focusedDay = widget.firstDate;
    } else if (_focusedDay.isAfter(widget.lastDate)) {
      _focusedDay = widget.lastDate;
    }
  }

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  bool _isInRange(DateTime day) {
    if (!_hasRangeStart || _selectedDate == null) return false;
    final dayKey = _dayKey(day);
    final startKey = _dayKey(widget.rangeStartDate!);
    final endKey = _dayKey(_selectedDate!);
    return (dayKey.isAfter(startKey) || isSameDay(dayKey, startKey)) &&
        (dayKey.isBefore(endKey) || isSameDay(dayKey, endKey));
  }

  bool _isRangeStart(DateTime day) =>
      _hasRangeStart && isSameDay(day, widget.rangeStartDate);

  bool _isRangeEnd(DateTime day) =>
      _hasRangeStart && _selectedDate != null && isSameDay(day, _selectedDate);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  widget.subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing16),
              TableCalendar(
                firstDay: widget.firstDate,
                lastDay: widget.lastDate,
                focusedDay: _focusedDay,
                locale: context.locale.languageCode,
                calendarFormat: CalendarFormat.month,
                availableGestures: AvailableGestures.horizontalSwipe,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) {
                  if (_hasRangeStart) {
                    return _isRangeStart(day) || _isRangeEnd(day);
                  }
                  return _selectedDate != null && isSameDay(day, _selectedDate);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle:
                      (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left, size: 24),
                  rightChevronIcon: const Icon(Icons.chevron_right, size: 24),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(2),
                  defaultTextStyle: textTheme.bodyMedium!,
                  weekendTextStyle: textTheme.bodyMedium!,
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: colorScheme.primary),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  todayTextStyle: textTheme.bodyMedium!.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  selectedTextStyle: textTheme.bodyMedium!.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildDayCell(context, day);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildDayCell(context, day, isToday: true);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildDayCell(context, day, isSelected: true);
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    return _buildDayCell(context, day, isDisabled: true);
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('common.cancel'.tr()),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  ElevatedButton(
                    onPressed: _selectedDate != null
                        ? () => Navigator.of(context).pop(_selectedDate)
                        : null,
                    child: Text('common.confirm'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
    bool isDisabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isStart = _isRangeStart(day);
    final isEnd = _isRangeEnd(day);
    final inRange = _isInRange(day);

    // For non-range mode, just highlight the selected date
    final isSimpleSelected = !_hasRangeStart &&
        _selectedDate != null &&
        isSameDay(day, _selectedDate);

    // Determine background color
    Color? backgroundColor;
    if (isStart || isEnd || isSimpleSelected) {
      backgroundColor = colorScheme.primary;
    } else if (inRange) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.15);
    }

    // Determine text color
    Color textColor;
    if (isDisabled) {
      textColor = Theme.of(context).hintColor;
    } else if (isStart || isEnd || isSimpleSelected) {
      textColor = colorScheme.onPrimary;
    } else if (inRange) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurface;
    }

    // Determine border radius for range effect
    BorderRadius borderRadius;
    if (_hasRangeStart) {
      if (isStart && isEnd) {
        borderRadius = BorderRadius.circular(AppTheme.radiusSmall);
      } else if (isStart) {
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusSmall),
          bottomLeft: Radius.circular(AppTheme.radiusSmall),
        );
      } else if (isEnd) {
        borderRadius = const BorderRadius.only(
          topRight: Radius.circular(AppTheme.radiusSmall),
          bottomRight: Radius.circular(AppTheme.radiusSmall),
        );
      } else if (inRange) {
        borderRadius = BorderRadius.zero;
      } else {
        borderRadius = BorderRadius.circular(AppTheme.radiusSmall);
      }
    } else {
      borderRadius = BorderRadius.circular(AppTheme.radiusSmall);
    }

    // Today border
    Border? border;
    if (isToday && !isStart && !isEnd && !isSimpleSelected) {
      border = Border.all(color: colorScheme.primary);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: (isStart || isEnd || isToday || isSimpleSelected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
    );
  }
}
