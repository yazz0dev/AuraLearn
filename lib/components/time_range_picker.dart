import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeRangePicker extends StatefulWidget {
  final void Function(TimeOfDay startTime, TimeOfDay endTime) onTimeChange;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  const TimeRangePicker({
    super.key,
    required this.onTimeChange,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  TimeRangePickerState createState() => TimeRangePickerState();
}

class TimeRangePickerState extends State<TimeRangePicker>
    with TickerProviderStateMixin {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.initialEndTime ?? const TimeOfDay(hour: 17, minute: 0);

    // Initialize animations safely
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.elasticOut),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  String _formatTime12Hour(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dateTime); // 12-hour format with AM/PM
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive layout - adjust card width based on screen size
    final cardWidth = screenWidth < 400 ? 110.0 : 120.0;
    final padding = screenWidth < 400 ? 16.0 : 20.0;

    return _scaleAnimation != null && _animationController != null
        ? ScaleTransition(
            scale: _scaleAnimation!,
            child: _buildMainContent(theme, isDark, cardWidth, padding),
          )
        : _buildMainContent(theme, isDark, cardWidth, padding);
  }

  Widget _buildMainContent(ThemeData theme, bool isDark, double cardWidth, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withValues(alpha: 0.8),
                  const Color(0xFF334155).withValues(alpha: 0.6),
                ]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFFF8FAFC).withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
                      BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header - only show on larger screens
          if (MediaQuery.of(context).size.width > 360)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Study Schedule',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          if (MediaQuery.of(context).size.width > 360) const SizedBox(height: 16),

          // Time Selection Cards - Responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimePickerCard(
                    'Start Time',
                    _startTime,
                    theme,
                    isDark,
                    cardWidth,
                                      (newTime) {
                    setState(() {
                      _startTime = newTime;
                      widget.onTimeChange(_startTime, _endTime);
                    });
                  },
                  ),
                  Container(
                    height: 50,
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  _buildTimePickerCard(
                    'End Time',
                    _endTime,
                    theme,
                    isDark,
                    cardWidth,
                                      (newTime) {
                    setState(() {
                      _endTime = newTime;
                      widget.onTimeChange(_startTime, _endTime);
                    });
                  },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildDurationCard(theme, isDark),
        ],
      ),
    );
  }

  // Time validation logic - prevent invalid ranges instead of showing errors
  TimeOfDay _validateAndAdjustTime(TimeOfDay newTime, bool isStartTime) {
    if (isStartTime) {
      // For start time, ensure it's before end time
      final currentEndTime = TimeOfDay(hour: _endTime.hour, minute: _endTime.minute);
      if (newTime.hour > currentEndTime.hour ||
          (newTime.hour == currentEndTime.hour && newTime.minute >= currentEndTime.minute)) {
        // If new start time would be after or equal to end time, adjust end time to be 1 hour later
        final newEndHour = (newTime.hour + 1) % 24;
        _endTime = TimeOfDay(hour: newEndHour, minute: newTime.minute);
      }
      return newTime;
    } else {
      // For end time, ensure it's after start time
      final currentStartTime = TimeOfDay(hour: _startTime.hour, minute: _startTime.minute);
      if (newTime.hour < currentStartTime.hour ||
          (newTime.hour == currentStartTime.hour && newTime.minute <= currentStartTime.minute)) {
        // If new end time would be before or equal to start time, adjust start time to be 1 hour earlier
        final newStartHour = (newTime.hour - 1 + 24) % 24;
        _startTime = TimeOfDay(hour: newStartHour, minute: newTime.minute);
      }
      return newTime;
    }
  }

  Widget _buildTimePickerCard(
    String title,
    TimeOfDay time,
    ThemeData theme,
    bool isDark,
    double cardWidth,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final newTime = await _showCustomTimePicker(context, time, title == 'Start Time');
        if (newTime != null) {
          onTimeSelected(newTime);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime12Hour(time),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard(ThemeData theme, bool isDark) {
    final duration = (_endTime.hour * 60 + _endTime.minute) -
        (_startTime.hour * 60 + _startTime.minute);
    final hours = duration ~/ 60;
    final minutes = duration % 60;

    String durationText;
    Color durationColor;

    if (duration < 0) {
      durationText = "Invalid range";
      durationColor = Colors.red.shade400;
    } else if (duration == 0) {
      durationText = "No duration";
      durationColor = Colors.orange.shade400;
    } else {
      durationText = '${hours}h ${minutes}m';
      durationColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF334155), const Color(0xFF475569)]
              : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 20,
            color: durationColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Duration: $durationText',
            style: theme.textTheme.titleMedium?.copyWith(
              color: durationColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<TimeOfDay?> _showCustomTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
    bool isStartTime,
  ) async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return CustomTimePickerDialog(initialTime: initialTime);
      },
    );

    // Validate and adjust the time when dialog returns
    if (result != null) {
      return _validateAndAdjustTime(result, isStartTime);
    }

    return result;
  }
}

class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePickerDialog({super.key, required this.initialTime});

  @override
  CustomTimePickerDialogState createState() => CustomTimePickerDialogState();
}

class CustomTimePickerDialogState extends State<CustomTimePickerDialog>
    with TickerProviderStateMixin {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hourOfPeriod == 0 ? 12 : widget.initialTime.hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;
    _isAM = widget.initialTime.period == DayPeriod.am;

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.elasticOut),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  String _getFormattedTime() {
    final hour24 = _isAM
        ? (_selectedHour == 12 ? 0 : _selectedHour)
        : (_selectedHour == 12 ? 12 : _selectedHour + 12);
    final time = TimeOfDay(hour: hour24, minute: _selectedMinute);
    return _formatTime12Hour(time);
  }

  String _formatTime12Hour(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dateTime); // 12-hour format with AM/PM
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive dialog width
    final dialogWidth = screenWidth < 400 ? screenWidth * 0.9 : 320.0;
    final padding = screenWidth < 400 ? 16.0 : 24.0;

    return _scaleAnimation != null && _animationController != null
        ? ScaleTransition(
            scale: _scaleAnimation!,
            child: _buildDialogContent(theme, isDark, dialogWidth, padding),
          )
        : _buildDialogContent(theme, isDark, dialogWidth, padding);
  }

  Widget _buildDialogContent(ThemeData theme, bool isDark, double dialogWidth, double padding) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.schedule_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Time Display with Circular AM/PM Buttons
              Column(
                children: [
                  // Large Time Display with AM/PM Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getFormattedTime(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Circular AM/PM Buttons next to time display
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // AM Button
                              GestureDetector(
                                onTap: () => setState(() => _isAM = true),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isAM
                                        ? theme.colorScheme.primary
                                        : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade50),
                                    border: Border.all(
                                      color: _isAM
                                          ? theme.colorScheme.primary
                                          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'AM',
                                    style: TextStyle(
                                      color: _isAM
                                          ? Colors.white
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // PM Button
                              GestureDetector(
                                onTap: () => setState(() => _isAM = false),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !_isAM
                                        ? theme.colorScheme.primary
                                        : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade50),
                                    border: Border.all(
                                      color: !_isAM
                                          ? theme.colorScheme.primary
                                          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'PM',
                                    style: TextStyle(
                                      color: !_isAM
                                          ? Colors.white
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Hour and Minute Pickers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                        // Hour Picker
                  _buildPickerColumn(
                    context,
                    count: 12,
                    onChanged: (val) => setState(() => _selectedHour = val == 11 ? 12 : val + 1),
                    initialValue: _selectedHour == 12 ? 11 : _selectedHour - 1,
                    label: 'Hour',
                  ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      // Minute Picker
                      _buildPickerColumn(
                        context,
                        count: 60,
                        onChanged: (val) => setState(() => _selectedMinute = val),
                        initialValue: _selectedMinute,
                        label: 'Minute',
                        isMinute: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                                              onPressed: () {
                          final hour24 = _isAM
                              ? (_selectedHour == 12 ? 0 : _selectedHour)
                              : (_selectedHour == 12 ? 12 : _selectedHour + 12);
                          final newTime = TimeOfDay(hour: hour24, minute: _selectedMinute);
                          Navigator.of(context).pop(newTime);
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Set Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildPickerColumn(
    BuildContext context, {
    required int count,
    required ValueChanged<int> onChanged,
    required int initialValue,
    required String label,
    bool isMinute = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive column width - increased for better visibility
    final columnWidth = screenWidth < 400 ? 80.0 : 100.0;
    final columnHeight = screenWidth < 400 ? 140.0 : 160.0;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: columnWidth,
          height: columnHeight,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ListWheelScrollView.useDelegate(
              controller: FixedExtentScrollController(initialItem: initialValue),
              itemExtent: 44,
              perspective: 0.005,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final isSelected = index == (isMinute ? _selectedMinute : (_selectedHour == 12 ? 11 : _selectedHour - 1));
                  return Container(
                    alignment: Alignment.center,
                    child: Text(
                      isMinute
                          ? index.toString().padLeft(2, '0')
                          : (index == 11 ? '12' : (index + 1).toString()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: isSelected ? 22 : 16,
                      ),
                    ),
                  );
                },
                childCount: count,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
