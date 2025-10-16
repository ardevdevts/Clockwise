import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../core/services/service_providers.dart';
import 'package:fl_chart/fl_chart.dart';

const List<Color> habitColors = [
  Color(0xFF00ADEF), // BMW Blue
  Color(0xFF00BFA5), // Teal
  Color(0xFFFF6B6B), // Coral
  Color(0xFFFFB300), // Amber
  Color(0xFF9C27B0), // Purple
  Color(0xFF00C853), // Green
  Color(0xFFFF4081), // Pink
  Color(0xFF00ACC1), // Cyan
];

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final selectedDate = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Habit>>(
          stream: database.watchActiveHabits(),
          builder: (context, snapshot) {
            // Show loading only if waiting AND no data yet
            final isLoading = !snapshot.hasData && 
                             snapshot.connectionState == ConnectionState.waiting;
            
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              );
            }

            final habits = snapshot.data ?? [];

            if (habits.isEmpty) {
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Habits',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showHabitDialog(context, database),
                          icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.track_changes_outlined,
                            size: 64,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No habits yet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to start building better routines!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.background,
                  floating: true,
                  snap: true,
                  toolbarHeight: 72,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Habits',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showHabitDialog(context, database),
                          icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) {
                          return const SizedBox(height: 12);
                        }
                        final habitIndex = index ~/ 2;
                        return _HabitCard(
                          habit: habits[habitIndex],
                          selectedDate: selectedDate,
                          database: database,
                          onTap: () => _showHabitDetail(context, habits[habitIndex]),
                          onEdit: () => _showHabitDialog(context, database, habit: habits[habitIndex]),
                          onDelete: () => _deleteHabit(context, database, habits[habitIndex]),
                        );
                      },
                      childCount: habits.length * 2 - 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showHabitDialog(BuildContext context, AppDatabase database, {Habit? habit}) async {
    final nameController = TextEditingController(text: habit?.name ?? '');
    final descriptionController = TextEditingController(text: habit?.description ?? '');
    String selectedColor = habit?.color ?? habitColors[0].value.toRadixString(16).substring(2);
    String goalType = habit?.goalType ?? 'boolean';
    double goalValue = habit?.goalValue ?? 1;
    String goalUnit = habit?.goalUnit ?? '';
    String interval = habit?.interval ?? 'daily';
    
    // Parse custom days (0=Sunday, 1=Monday, etc.)
    Set<int> selectedDays = {};
    if (habit?.customDays != null && habit!.customDays!.isNotEmpty) {
      selectedDays = habit.customDays!.split(',').map((e) => int.parse(e)).toSet();
    }
    
    int intervalDaysValue = habit?.intervalDays ?? 2;

    // Load existing reminders if editing
    final List<ReminderTimeData> reminderTimes = [];
    if (habit != null) {
      final reminderService = ref.read(reminderServiceProvider);
      final existingReminders = await reminderService.getHabitReminders(habit.id);
      reminderTimes.addAll(existingReminders.map((r) => ReminderTimeData(
        id: r.id,
        time: TimeOfDay.fromDateTime(r.remindAt),
      )));
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit == null ? 'New Habit' : 'Edit Habit',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name
                  _MinimalTextField(
                    controller: nameController,
                    hint: 'Habit name',
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  _MinimalTextField(
                    controller: descriptionController,
                    hint: 'Description (optional)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Color Picker
                  const Text(
                    'Color',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: habitColors.map((color) {
                      final colorHex = color.value.toRadixString(16).substring(2);
                      final isSelected = selectedColor == colorHex;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = colorHex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: AppColors.textPrimary, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Frequency
                  const Text(
                    'Frequency',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedControl(
                    options: const ['daily', 'custom', 'interval'],
                    selected: interval,
                    onChanged: (value) => setState(() => interval = value),
                  ),
                  const SizedBox(height: 16),

                  // Custom days selector
                  if (interval == 'custom') ...[
                    const Text(
                      'Select Days',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DaySelector(
                      selectedDays: selectedDays,
                      onDaysChanged: (days) => setState(() => selectedDays = days),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Interval days selector
                  if (interval == 'interval') ...[
                    Row(
                      children: [
                        const Text(
                          'Every',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: _MinimalTextField(
                            controller: TextEditingController(text: intervalDaysValue.toString())
                              ..selection = TextSelection.fromPosition(
                                TextPosition(offset: intervalDaysValue.toString().length),
                              ),
                            hint: 'Days',
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                intervalDaysValue = parsed;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'days',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Goal Type
                  const Text(
                    'Goal Type',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedControl(
                    options: const ['boolean', 'unit'],
                    selected: goalType,
                    onChanged: (value) => setState(() => goalType = value),
                  ),
                  
                  if (goalType == 'unit') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _MinimalTextField(
                            controller: TextEditingController(
                              text: goalValue.toString(),
                            )..selection = TextSelection.fromPosition(
                                TextPosition(offset: goalValue.toString().length),
                              ),
                            hint: 'Goal value',
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null) goalValue = parsed;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _MinimalTextField(
                            controller: TextEditingController(text: goalUnit),
                            hint: 'Unit (e.g., km, reps)',
                            onChanged: (val) => goalUnit = val,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  
                  // Reminders Section
                  const Text(
                    'Reminders',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // List of reminder times
                  if (reminderTimes.isNotEmpty) ...[
                    ...reminderTimes.map((reminderData) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: AppColors.accentBlue),
                          const SizedBox(width: 12),
                          Text(
                            reminderData.time.format(context),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          ),
                          const Spacer(),
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentBlue),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: reminderData.time,
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppColors.accentBlue,
                                        surface: AppColors.elevatedSurface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  reminderData.time = time;
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                reminderTimes.remove(reminderData);
                              });
                            },
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                  
                  // Add reminder button
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.accentBlue,
                                surface: AppColors.elevatedSurface,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() {
                          reminderTimes.add(ReminderTimeData(time: time));
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentBlue, width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.accentBlue),
                          SizedBox(width: 8),
                          Text(
                            'Add Reminder',
                            style: TextStyle(color: AppColors.accentBlue, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _MinimalButton(
                        label: habit == null ? 'Create' : 'Update',
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;

                          // Prepare custom days string
                          String? customDaysStr;
                          if (interval == 'custom' && selectedDays.isNotEmpty) {
                            final daysList = selectedDays.toList()..sort();
                            customDaysStr = daysList.join(',');
                          }

                          int habitId;
                          if (habit == null) {
                            // Create new habit
                            habitId = await database.insertHabit(
                              HabitsCompanion.insert(
                                name: nameController.text.trim(),
                                description: drift.Value(descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim()),
                                color: selectedColor,
                                interval: interval,
                                customDays: drift.Value(customDaysStr),
                                intervalDays: drift.Value(interval == 'interval' ? intervalDaysValue : null),
                                goalType: goalType,
                                goalValue: drift.Value(goalType == 'unit' ? goalValue : null),
                                goalUnit: drift.Value(goalType == 'unit' ? goalUnit : null),
                              ),
                            );
                          } else {
                            // Update existing habit
                            habitId = habit.id;
                            await database.updateHabit(
                              habit.copyWith(
                                name: nameController.text.trim(),
                                description: drift.Value(descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim()),
                                color: selectedColor,
                                interval: interval,
                                customDays: drift.Value(customDaysStr),
                                intervalDays: drift.Value(interval == 'interval' ? intervalDaysValue : null),
                                goalType: goalType,
                                goalValue: drift.Value(goalType == 'unit' ? goalValue : null),
                                goalUnit: drift.Value(goalType == 'unit' ? goalUnit : null),
                              ),
                            );
                            
                            // Delete old reminders that were removed
                            final reminderService = ref.read(reminderServiceProvider);
                            final existingReminders = await reminderService.getHabitReminders(habitId);
                            for (final existingReminder in existingReminders) {
                              final stillExists = reminderTimes.any((r) => r.id == existingReminder.id);
                              if (!stillExists) {
                                await reminderService.removeReminder(existingReminder.id);
                              }
                            }
                          }

                          // Save reminders
                          final reminderService = ref.read(reminderServiceProvider);
                          final now = DateTime.now();
                          
                          for (final reminderData in reminderTimes) {
                            var reminderTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              reminderData.time.hour,
                              reminderData.time.minute,
                            );
                            
                            // If time has passed today, schedule for tomorrow
                            if (reminderTime.isBefore(now)) {
                              reminderTime = reminderTime.add(const Duration(days: 1));
                            }
                            
                            if (reminderData.id != null) {
                              // Update existing reminder
                              final existingReminder = (await reminderService.getHabitReminders(habitId))
                                  .firstWhere((r) => r.id == reminderData.id);
                              await database.updateReminder(
                                existingReminder.copyWith(remindAt: reminderTime),
                              );
                              // Reschedule notification
                              final updatedHabit = await database.getHabitById(habitId);
                              if (updatedHabit != null) {
                                final notificationService = ref.read(notificationServiceProvider);
                                final notificationId = (habitId * 100000 + reminderData.id!).hashCode.abs();
                                await notificationService.scheduleHabitReminder(updatedHabit, reminderTime, notificationId);
                              }
                            } else {
                              // Create new reminder
                              await reminderService.addHabitReminder(
                                habitId,
                                reminderTime,
                                recurring: true,
                              );
                            }
                          }
                          
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHabitDetail(BuildContext context, Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailPage(habit: habit),
      ),
    );
  }

  void _deleteHabit(BuildContext context, AppDatabase database, Habit habit) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete Habit',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete "${habit.name}"?\nAll logs will be removed.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: 'Delete',
                    onPressed: () async {
                      await database.deleteHabit(habit.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Habit Card Widget
class _HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final AppDatabase database;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.selectedDate,
    required this.database,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<_HabitCard> {
  // Optimistic state - stores the current state for this specific habit
  HabitLog? _localLog;
  bool _isInitialized = false;
  HabitLog? _lastLog;
  bool _isPendingOptimisticUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadLastLog();
  }

  @override
  void didUpdateWidget(_HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset initialization if the selected date changes
    if (oldWidget.selectedDate != widget.selectedDate) {
      _isInitialized = false;
      _localLog = null;
      _isPendingOptimisticUpdate = false;
    }
    // Reload last log if habit changes
    if (oldWidget.habit.id != widget.habit.id) {
      _loadLastLog();
    }
  }

  Future<void> _loadLastLog() async {
    try {
      final lastLog = await widget.database.getLastHabitLog(widget.habit.id);
      if (mounted) {
        setState(() {
          _lastLog = lastLog;
        });
      }
    } catch (e) {
      // Silently fail - _lastLog will remain null
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(int.parse('FF${widget.habit.color}', radix: 16));

    return StreamBuilder<HabitLog?>(
      stream: widget.database.watchHabitLogForDate(widget.habit.id, widget.selectedDate),
      builder: (context, currentLogSnapshot) {
        // Initialize local state from stream only once
        if (!_isInitialized) {
          if (currentLogSnapshot.hasData) {
            _localLog = currentLogSnapshot.data;
            _isInitialized = true;
          } else if (currentLogSnapshot.connectionState != ConnectionState.waiting) {
            _isInitialized = true;
          }
        } else if (!_isPendingOptimisticUpdate && currentLogSnapshot.connectionState == ConnectionState.active) {
          // Only update from stream if we don't have a pending optimistic update
          final streamLog = currentLogSnapshot.data;
          _localLog = streamLog;
        }
        
        // Clear pending flag after stream has stabilized
        if (_isPendingOptimisticUpdate && currentLogSnapshot.connectionState == ConnectionState.active) {
          // Wait one more frame to ensure DB operation completed
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _isPendingOptimisticUpdate = false;
              });
            }
          });
        }
        
        // Always use local state for display
        final log = _localLog;
        final isCompleted = log != null;
        final currentProgress = log?.amount ?? 0.0;

        return Container(
          decoration: BoxDecoration(
            color: habitColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: habitColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: habitColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title, Description, Completion & Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color indicator
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: habitColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Habit info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.habit.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (widget.habit.description != null && widget.habit.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.habit.description!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Completion indicator
                        if (widget.habit.goalType == 'boolean')
                          GestureDetector(
                            onTap: () => _toggleHabit(isCompleted, log),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCompleted ? habitColor : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: habitColor,
                                  width: 2.5,
                                ),
                                boxShadow: isCompleted ? [
                                  BoxShadow(
                                    color: habitColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => _showUnitInput(context, log, currentProgress),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCompleted 
                                    ? habitColor.withOpacity(0.2) 
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: habitColor.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                isCompleted 
                                    ? '${currentProgress.toStringAsFixed(0)}/${widget.habit.goalValue?.toStringAsFixed(0)}' 
                                    : '0/${widget.habit.goalValue?.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: habitColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // More menu
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: habitColor.withOpacity(0.7), size: 20),
                          color: AppColors.elevatedSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          offset: const Offset(-12, 0),
                          onSelected: (value) {
                            if (value == 'edit') {
                              widget.onEdit();
                            } else if (value == 'delete') {
                              widget.onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                                  const SizedBox(width: 12),
                                  Text('Edit', style: TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  const SizedBox(width: 12),
                                  Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Row 2: Contribution Grid (Full Width)
                    const SizedBox(height: 16),
                    _CompactContributionGrid(
                      habit: widget.habit,
                      database: widget.database,
                      habitColor: habitColor,
                      currentDateLog: _localLog,
                      selectedDate: widget.selectedDate,
                    ),
                    
                    // Row 3: Stats row
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Goal info on the left
                        if (widget.habit.goalType == 'unit' && widget.habit.goalUnit != null)
                          Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Goal: ${widget.habit.goalValue?.toStringAsFixed(0)} ${widget.habit.goalUnit}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        const Spacer(),
                        // Last completion time on the right
                        if (_lastLog != null)
                          Row(
                            children: [
                              Icon(Icons.history, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Last: ${DateFormat('MMM d').format(_lastLog!.date)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleHabit(bool isCompleted, HabitLog? log) async {
    // Optimistic update - update local state immediately
    setState(() {
      _isPendingOptimisticUpdate = true;
      if (isCompleted && log != null) {
        // Remove the log
        _localLog = null;
      } else {
        // Add a log
        _localLog = HabitLog(
          id: log?.id ?? -1, // Use existing ID if updating, temp ID if new
          habitId: widget.habit.id,
          date: widget.selectedDate,
          amount: 1,
        );
      }
    });

    // Perform database operation in background (fire and forget with error handling)
    try {
      if (isCompleted && log != null) {
        await widget.database.deleteHabitLogById(log.id);
      } else {
        await widget.database.upsertHabitLog(widget.habit.id, widget.selectedDate, 1);
      }
      // Database operation succeeded, stream will update naturally
    } catch (e) {
      // On error, revert the optimistic update
      if (mounted) {
        setState(() {
          _localLog = log; // Revert to previous state
          _isPendingOptimisticUpdate = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update habit: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showUnitInput(BuildContext context, HabitLog? log, double currentProgress) {
    final controller = TextEditingController(
      text: currentProgress > 0 ? currentProgress.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.habit.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${widget.habit.goalValue?.toStringAsFixed(0)} ${widget.habit.goalUnit}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: widget.habit.goalUnit,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (log != null)
                    TextButton(
                      onPressed: () async {
                        // Close dialog and update local state immediately
                        Navigator.pop(context);
                        
                        final previousLog = _localLog;
                        setState(() {
                          _isPendingOptimisticUpdate = true;
                          _localLog = null;
                        });
                        
                        try {
                          await widget.database.deleteHabitLogById(log.id);
                        } catch (e) {
                          // Revert on error
                          if (mounted) {
                            setState(() {
                              _localLog = previousLog;
                              _isPendingOptimisticUpdate = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to clear habit: $e'),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: 'Save',
                    onPressed: () async {
                      final amount = double.tryParse(controller.text);
                      if (amount == null || amount <= 0) return;

                      // Close dialog immediately
                      Navigator.pop(context);
                      
                      // Store previous state for rollback
                      final previousLog = _localLog;
                      
                      // Update local state immediately
                      setState(() {
                        _isPendingOptimisticUpdate = true;
                        _localLog = HabitLog(
                          id: log?.id ?? -1,
                          habitId: widget.habit.id,
                          date: widget.selectedDate,
                          amount: amount,
                        );
                      });

                      // Perform database operation in background
                      try {
                        await widget.database.upsertHabitLog(widget.habit.id, widget.selectedDate, amount);
                      } catch (e) {
                        // Revert on error
                        if (mounted) {
                          setState(() {
                            _localLog = previousLog;
                            _isPendingOptimisticUpdate = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save habit: $e'),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact Contribution Grid for Habit Card
class _CompactContributionGrid extends StatefulWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final HabitLog? currentDateLog;
  final DateTime selectedDate;

  const _CompactContributionGrid({
    super.key,
    required this.habit,
    required this.database,
    required this.habitColor,
    required this.currentDateLog,
    required this.selectedDate,
  });

  @override
  State<_CompactContributionGrid> createState() => _CompactContributionGridState();
}

class _CompactContributionGridState extends State<_CompactContributionGrid> {
  Map<String, HabitLog> _logMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void didUpdateWidget(_CompactContributionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if habit changes
    if (oldWidget.habit.id != widget.habit.id) {
      _loadLogs();
    } else if (oldWidget.currentDateLog != widget.currentDateLog) {
      // Optimistically update the current date log in the map
      _updateCurrentDateLog();
    }
  }

  void _updateCurrentDateLog() {
    setState(() {
      final key = _dateKey(widget.selectedDate);
      if (widget.currentDateLog != null) {
        _logMap[key] = widget.currentDateLog!;
      } else {
        _logMap.remove(key);
      }
    });
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await widget.database.getHabitLogs(widget.habit.id);
      if (!mounted) return;
      
      final logMap = <String, HabitLog>{};
      for (final log in logs) {
        final key = _dateKey(log.date);
        logMap[key] = log;
      }

      // Apply current date log optimistically
      final currentKey = _dateKey(widget.selectedDate);
      if (widget.currentDateLog != null) {
        logMap[currentKey] = widget.currentDateLog!;
      } else {
        logMap.remove(currentKey);
      }

      setState(() {
        _logMap = logMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logMap = {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 60);
    }

    return _buildFullWidthGrid(_logMap);
  }

  Widget _buildFullWidthGrid(Map<String, HabitLog> logMap) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    
    // Calculate 6 months back (approximately 26 weeks)
    final startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate square size to fit width
        final availableWidth = constraints.maxWidth;
        final spacing = 3.0;
        final totalSpacing = (weeks - 1) * spacing;
        final squareSize = ((availableWidth - totalSpacing) / weeks).floorToDouble();
        final actualSquareSize = ((squareSize - (6 * spacing)) / 7).floorToDouble();
        
        // Make squares bigger (minimum 10px)
        final finalSquareSize = actualSquareSize < 10 ? 10.0 : actualSquareSize;
        
        // Create scroll controller to start at the end (most recent)
        final scrollController = ScrollController(
          initialScrollOffset: double.maxFinite,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels
            SizedBox(
              height: 18,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildMonthLabels(startDate, weeks, finalSquareSize, spacing),
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            // Grid
            SizedBox(
              height: (finalSquareSize * 7) + (6 * spacing),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // Start from the end (most recent)
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weeks, (weekIndex) {
                    return Padding(
                      padding: EdgeInsets.only(right: weekIndex < weeks - 1 ? spacing : 0),
                      child: Column(
                        children: List.generate(7, (dayIndex) {
                          final dayOffset = (weekIndex * 7) + dayIndex;
                          final date = startDate.add(Duration(days: dayOffset));
                          
                          if (date.isAfter(endDate)) {
                            return SizedBox(
                              width: finalSquareSize,
                              height: finalSquareSize,
                            );
                          }

                          final key = _dateKey(date);
                          final log = logMap[key];
                          final completionPercent = _getCompletionPercent(log);

                          return Padding(
                            padding: EdgeInsets.only(bottom: dayIndex < 6 ? spacing : 0),
                            child: Container(
                              width: finalSquareSize,
                              height: finalSquareSize,
                              decoration: BoxDecoration(
                                color: _getIntensityColor(completionPercent, widget.habitColor),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMonthLabels(DateTime startDate, int weeks, double squareSize, double spacing) {
    final labels = <Widget>[];
    final monthWidths = <String, double>{};
    
    // Calculate which month each week belongs to
    for (int i = 0; i < weeks; i++) {
      final date = startDate.add(Duration(days: i * 7));
      final monthKey = '${date.year}-${date.month}';
      
      if (!monthWidths.containsKey(monthKey)) {
        monthWidths[monthKey] = 0;
      }
      monthWidths[monthKey] = monthWidths[monthKey]! + squareSize + spacing;
    }
    
    // Build month label widgets
    monthWidths.forEach((key, width) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final monthName = DateFormat('MMM').format(date);
      
      labels.add(
        SizedBox(
          width: width - spacing,
          child: Text(
            monthName,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
    
    return labels;
  }

  double _getCompletionPercent(HabitLog? log) {
    if (log == null) return 0;
    
    if (widget.habit.goalType == 'boolean') {
      return 100;
    } else if (widget.habit.goalValue != null && widget.habit.goalValue! > 0) {
      final percent = (log.amount / widget.habit.goalValue!) * 100;
      return percent.clamp(0, 100);
    }
    
    return 0;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Habit Detail Page
class HabitDetailPage extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailPage({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends ConsumerState<HabitDetailPage> {
  final GlobalKey<_HabitRemindersListState> _remindersListKey = GlobalKey();
  String _selectedPeriod = '30'; // Default to 30 days

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final habitColor = Color(int.parse('FF${widget.habit.color}', radix: 16));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: habitColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.habit.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Statistics Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        _PeriodSelector(
                          selected: _selectedPeriod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatisticsCards(
                      habit: widget.habit,
                      database: database,
                      habitColor: habitColor,
                      days: int.parse(_selectedPeriod),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Progress Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Chart',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressChart(
                      habit: widget.habit,
                      database: database,
                      habitColor: habitColor,
                      days: int.parse(_selectedPeriod),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Weekly Trend Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Trend',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WeeklyTrendChart(
                      habit: widget.habit,
                      database: database,
                      habitColor: habitColor,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Contribution Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ContributionGrid(
                      habit: widget.habit,
                      database: database,
                      habitColor: habitColor,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 0.5,
                color: AppColors.border,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Reminders
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Reminders',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        final saved = await _showAddHabitReminderDialog(context, ref);
                        if (saved) {
                          _remindersListKey.currentState?._loadReminders();
                        }
                      },
                      icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _HabitRemindersList(
                  key: _remindersListKey,
                  habitId: widget.habit.id,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Container(
                height: 0.5,
                color: AppColors.border,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // History
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'History',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            StreamBuilder<List<HabitLog>>(
              stream: database.watchHabitLogs(widget.habit.id),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No logs yet',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = logs[index];
                      final completionPercent = widget.habit.goalType == 'unit' && widget.habit.goalValue != null
                          ? (log.amount / widget.habit.goalValue!) * 100
                          : 100.0;
                      
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border, width: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getIntensityColor(completionPercent, habitColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEE, MMM d').format(log.date),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (widget.habit.goalType == 'unit')
                              Row(
                                children: [
                                  Text(
                                    '${log.amount.toStringAsFixed(0)} ${widget.habit.goalUnit}',
                                    style: TextStyle(
                                      color: habitColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${completionPercent.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Icon(Icons.check_circle, color: habitColor, size: 20),
                          ],
                        ),
                      );
                    },
                    childCount: logs.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showAddHabitReminderDialog(BuildContext context, WidgetRef ref) async {
    final reminderService = ref.read(reminderServiceProvider);
    
    // Load existing reminders
    final existingReminders = await reminderService.getHabitReminders(widget.habit.id);
    final List<ReminderTimeData> reminderTimes = existingReminders.map((r) {
      return ReminderTimeData(
        id: r.id,
        time: TimeOfDay.fromDateTime(r.remindAt),
      );
    }).toList();
    
    TimeOfDay newTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Habit Reminders',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add or edit reminders for this habit',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                // List of reminder times
                if (reminderTimes.isNotEmpty) ...[
                  ...reminderTimes.map((reminderData) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: AppColors.accentBlue),
                        const SizedBox(width: 12),
                        Text(
                          reminderData.time.format(context),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        ),
                        const Spacer(),
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentBlue),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: reminderData.time,
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.accentBlue,
                                      surface: AppColors.elevatedSurface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setState(() {
                                reminderData.time = time;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              reminderTimes.remove(reminderData);
                            });
                          },
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                
                // Add time button
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: newTime,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accentBlue,
                              surface: AppColors.elevatedSurface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() {
                        reminderTimes.add(ReminderTimeData(time: time));
                        newTime = time;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentBlue, width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 18, color: AppColors.accentBlue),
                        SizedBox(width: 8),
                        Text(
                          'Add Reminder Time',
                          style: TextStyle(color: AppColors.accentBlue, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Save',
                      onPressed: () async {
                        final now = DateTime.now();
                        
                        // Delete removed reminders
                        for (final existingReminder in existingReminders) {
                          final stillExists = reminderTimes.any((r) => r.id == existingReminder.id);
                          if (!stillExists) {
                            await reminderService.removeReminder(existingReminder.id);
                          }
                        }
                        
                        // Update or create reminders
                        for (final reminderData in reminderTimes) {
                          var reminderTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            reminderData.time.hour,
                            reminderData.time.minute,
                          );
                          
                          // If time has passed today, schedule for tomorrow
                          if (reminderTime.isBefore(now)) {
                            reminderTime = reminderTime.add(const Duration(days: 1));
                          }
                          
                          if (reminderData.id != null) {
                            // Update existing reminder
                            final existingReminder = existingReminders.firstWhere((r) => r.id == reminderData.id);
                            final database = ref.read(databaseProvider);
                            await database.updateReminder(
                              existingReminder.copyWith(remindAt: reminderTime),
                            );
                            // Reschedule notification
                            final habit = await database.getHabitById(widget.habit.id);
                            if (habit != null) {
                              final notificationService = ref.read(notificationServiceProvider);
                              final notificationId = (widget.habit.id * 100000 + reminderData.id!).hashCode.abs();
                              await notificationService.scheduleHabitReminder(habit, reminderTime, notificationId);
                            }
                          } else {
                            // Create new reminder
                            await reminderService.addHabitReminder(
                              widget.habit.id,
                              reminderTime,
                              recurring: true,
                            );
                          }
                        }
                        
                        if (context.mounted) Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    return result ?? false;
  }
}

// Helper class to track reminder data
class ReminderTimeData {
  final int? id; // null for new reminders
  TimeOfDay time;
  
  ReminderTimeData({this.id, required this.time});
}

// Habit Reminders List Widget
class _HabitRemindersList extends ConsumerStatefulWidget {
  final int habitId;

  const _HabitRemindersList({super.key, required this.habitId});

  @override
  ConsumerState<_HabitRemindersList> createState() => _HabitRemindersListState();
}

class _HabitRemindersListState extends ConsumerState<_HabitRemindersList> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminderService = ref.read(reminderServiceProvider);
    final reminders = await reminderService.getHabitReminders(widget.habitId);
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
          ),
        ),
      );
    }

    if (_reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _reminders.map((reminder) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 18, color: AppColors.accentBlue),
              const SizedBox(width: 12),
              Text(
                DateFormat('hh:mm a').format(reminder.remindAt),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              const SizedBox(width: 8),
              if (reminder.recurring)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Daily',
                    style: TextStyle(color: AppColors.accentBlue, fontSize: 11),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final reminderService = ref.read(reminderServiceProvider);
                  await reminderService.removeReminder(reminder.id);
                  await _loadReminders(); // Refresh the list
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Contribution Grid Widget (GitHub-style)
class _ContributionGrid extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;

  const _ContributionGrid({
    required this.habit,
    required this.database,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HabitLog>>(
      future: _getLast90DaysLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final logs = snapshot.data ?? [];
        final logMap = <String, HabitLog>{};
        for (final log in logs) {
          final key = _dateKey(log.date);
          logMap[key] = log;
        }

        return _buildGrid(logMap);
      },
    );
  }

  Future<List<HabitLog>> _getLast90DaysLogs() async {
    return database.getHabitLogs(habit.id);
  }

  Widget _buildGrid(Map<String, HabitLog> logMap) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 90));

    // Calculate weeks
    final totalDays = 91; // ~13 weeks
    final weeks = (totalDays / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels
          SizedBox(
            width: weeks * 16.0,
            height: 20,
            child: Row(
              children: _buildMonthLabels(startDate, weeks),
            ),
          ),
          const SizedBox(height: 4),
          // Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final dayOffset = (weekIndex * 7) + dayIndex;
                    final date = startDate.add(Duration(days: dayOffset));
                    
                    if (date.isAfter(endDate)) {
                      return const SizedBox(width: 12, height: 12);
                    }

                    final key = _dateKey(date);
                    final log = logMap[key];
                    final completionPercent = _getCompletionPercent(log);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Tooltip(
                        message: _getTooltip(date, log),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getIntensityColor(completionPercent, habitColor),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(width: 6),
              _buildLegendBox(0),
              const SizedBox(width: 3),
              _buildLegendBox(25),
              const SizedBox(width: 3),
              _buildLegendBox(50),
              const SizedBox(width: 3),
              _buildLegendBox(75),
              const SizedBox(width: 3),
              _buildLegendBox(100),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(double percent) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getIntensityColor(percent, habitColor),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(DateTime startDate, int weeks) {
    final labels = <Widget>[];
    String? lastMonth;
    
    for (int i = 0; i < weeks; i++) {
      final date = startDate.add(Duration(days: i * 7));
      final monthName = DateFormat('MMM').format(date);
      
      if (monthName != lastMonth) {
        labels.add(
          Expanded(
            child: Text(
              monthName,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        lastMonth = monthName;
      }
    }
    
    return labels;
  }

  double _getCompletionPercent(HabitLog? log) {
    if (log == null) return 0;
    
    if (habit.goalType == 'boolean') {
      return 100;
    } else if (habit.goalValue != null && habit.goalValue! > 0) {
      final percent = (log.amount / habit.goalValue!) * 100;
      return percent.clamp(0, 100);
    }
    
    return 0;
  }

  String _getTooltip(DateTime date, HabitLog? log) {
    final dateStr = DateFormat('MMM d, yyyy').format(date);
    
    if (log == null) {
      return '$dateStr\nNo activity';
    }
    
    if (habit.goalType == 'boolean') {
      return '$dateStr\nCompleted';
    } else {
      final percent = _getCompletionPercent(log);
      return '$dateStr\n${log.amount.toStringAsFixed(0)} ${habit.goalUnit} (${percent.toStringAsFixed(0)}%)';
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

Color _getIntensityColor(double completionPercent, Color baseColor) {
  if (completionPercent == 0) {
    return AppColors.surface;
  } else if (completionPercent < 25) {
    return baseColor.withOpacity(0.3);
  } else if (completionPercent < 50) {
    return baseColor.withOpacity(0.5);
  } else if (completionPercent < 75) {
    return baseColor.withOpacity(0.7);
  } else if (completionPercent < 100) {
    return baseColor.withOpacity(0.85);
  } else {
    return baseColor;
  }
}

// Minimal UI Components
class _MinimalTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final int maxLines;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _MinimalTextField({
    this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _MinimalButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _MinimalButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDestructive 
            ? AppColors.error.withOpacity(0.15) 
            : AppColors.accentBlue.withOpacity(0.15),
        foregroundColor: isDestructive ? AppColors.error : AppColors.accentBlue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        final index = options.indexOf(option);
        final isFirst = index == 0;
        final isLast = index == options.length - 1;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.accentBlue.withOpacity(0.15) 
                    : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.accentBlue : AppColors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(6) : Radius.zero,
                  right: isLast ? const Radius.circular(6) : Radius.zero,
                ),
              ),
              child: Text(
                option.substring(0, 1).toUpperCase() + option.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Day Selector Widget
class _DaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onDaysChanged;

  const _DaySelector({
    required this.selectedDays,
    required this.onDaysChanged,
  });

  static const List<String> dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            final newDays = Set<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(index);
            } else {
              newDays.add(index);
            }
            onDaysChanged(newDays);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.accentBlue.withOpacity(0.2) 
                  : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accentBlue : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                dayNames[index],
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}


// Period Selector Widget
class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['7', '30', '90'].map((period) {
          final isSelected = period == selected;
          return GestureDetector(
            onTap: () => onChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$period days',
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Statistics Cards Widget
class _StatisticsCards extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final int days;

  const _StatisticsCards({
    required this.habit,
    required this.database,
    required this.habitColor,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: database.getHabitStats(habit.id, days: days),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final stats = snapshot.data!;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Completion',
                    value: '${stats['completionRate'].toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: habitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Total Logs',
                    value: '${stats['totalLogs']}',
                    icon: Icons.calendar_month,
                    color: habitColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Current Streak',
                    value: '${stats['currentStreak']} days',
                    icon: Icons.local_fire_department,
                    color: habitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Longest Streak',
                    value: '${stats['longestStreak']} days',
                    icon: Icons.emoji_events,
                    color: habitColor,
                  ),
                ),
              ],
            ),
            if (habit.goalType == 'unit') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Average',
                      value: '${stats['averageAmount'].toStringAsFixed(1)} ${habit.goalUnit}',
                      icon: Icons.analytics,
                      color: habitColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total',
                      value: '${stats['totalAmount'].toStringAsFixed(0)} ${habit.goalUnit}',
                      icon: Icons.functions,
                      color: habitColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// Individual Stat Card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Progress Chart Widget
class _ProgressChart extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final int days;

  const _ProgressChart({
    required this.habit,
    required this.database,
    required this.habitColor,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<DateTime, double>>(
      future: database.getDailyHabitLogs(habit.id, days: days),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final dailyLogs = snapshot.data!;
        if (dailyLogs.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'No data to display',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: days - 1));
        final List<FlSpot> spots = [];
        
        for (var i = 0; i < days; i++) {
          final date = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
          final value = dailyLogs[date] ?? 0.0;
          spots.add(FlSpot(i.toDouble(), value));
        }

        final maxY = spots.isEmpty ? 10.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        final adjustedMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: adjustedMaxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: days > 30 ? (days / 6).floorToDouble() : 7,
                    getTitlesWidget: (value, meta) {
                      final date = startDate.add(Duration(days: value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('M/d').format(date),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (days - 1).toDouble(),
              minY: 0,
              maxY: adjustedMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: habitColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: days <= 30,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: habitColor,
                        strokeWidth: 1,
                        strokeColor: AppColors.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: habitColor.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => AppColors.elevatedSurface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = startDate.add(Duration(days: spot.x.toInt()));
                      return LineTooltipItem(
                        '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(1)} ${habit.goalUnit ?? ''}',
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Weekly Trend Chart Widget
class _WeeklyTrendChart extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;

  const _WeeklyTrendChart({
    required this.habit,
    required this.database,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.getWeeklyHabitStats(habit.id, weeks: 12),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final weeklyStats = snapshot.data!;
        if (weeklyStats.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'No data to display',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }

        final maxCount = weeklyStats.isEmpty ? 10.0 : weeklyStats.map((s) => s['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
        final adjustedMaxY = maxCount == 0 ? 10.0 : maxCount * 1.2;

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: adjustedMaxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: adjustedMaxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= weeklyStats.length) return const Text('');
                      final weekStart = weeklyStats[value.toInt()]['weekStart'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('M/d').format(weekStart),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: weeklyStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (stat['count'] as int).toDouble(),
                      color: habitColor,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.elevatedSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = weeklyStats[groupIndex];
                    final weekStart = stat['weekStart'] as DateTime;
                    final count = stat['count'] as int;
                    return BarTooltipItem(
                      'Week of ${DateFormat('MMM d').format(weekStart)}\n$count logs',
                      const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


