import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

// Predefined habit colors
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
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Habits',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
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

            // Date Selector
            _DateSelector(
              selectedDate: selectedDate,
              onDateChanged: (date) => setState(() => selectedDate = date),
            ),

            const SizedBox(height: 16),

            // Habits List
            Expanded(
              child: StreamBuilder<List<Habit>>(
                stream: database.watchActiveHabits(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    );
                  }

                  final habits = snapshot.data ?? [];

                  if (habits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.track_changes_outlined,
                            size: 48,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HabitCard(
                        habit: habits[index],
                        selectedDate: selectedDate,
                        database: database,
                        onTap: () => _showHabitDetail(context, habits[index]),
                        onEdit: () => _showHabitDialog(context, database, habit: habits[index]),
                        onDelete: () => _deleteHabit(context, database, habits[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHabitDialog(BuildContext context, AppDatabase database, {Habit? habit}) {
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

                          if (habit == null) {
                            await database.insertHabit(
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
class _HabitCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final habitColor = Color(int.parse('FF${habit.color}', radix: 16));

    return FutureBuilder<HabitLog?>(
      future: database.getHabitLogForDate(habit.id, selectedDate),
      builder: (context, snapshot) {
        final log = snapshot.data;
        final isCompleted = log != null;
        final currentProgress = log?.amount ?? 0.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                habitColor.withOpacity(0.15),
                habitColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: habitColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
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
                                habit.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (habit.description != null && habit.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  habit.description!,
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
                        if (habit.goalType == 'boolean')
                          GestureDetector(
                            onTap: () => _toggleHabit(isCompleted, log),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted ? habitColor : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: habitColor,
                                  width: 2,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
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
                                    ? '${currentProgress.toStringAsFixed(0)}/${habit.goalValue?.toStringAsFixed(0)}' 
                                    : '0/${habit.goalValue?.toStringAsFixed(0)}',
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
                              onEdit();
                            } else if (value == 'delete') {
                              onDelete();
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
                      habit: habit,
                      database: database,
                      habitColor: habitColor,
                    ),
                    
                    // Row 3: Goal info
                    if (habit.goalType == 'unit' && habit.goalUnit != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 14, color: habitColor.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text(
                            'Goal: ${habit.goalValue?.toStringAsFixed(0)} ${habit.goalUnit}',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    if (isCompleted && log != null) {
      await database.deleteHabitLogById(log.id);
    } else {
      await database.insertHabitLog(
        HabitLogsCompanion.insert(
          habitId: habit.id,
          date: drift.Value(selectedDate),
          amount: const drift.Value(1),
        ),
      );
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
                habit.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${habit.goalValue?.toStringAsFixed(0)} ${habit.goalUnit}',
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
                  suffixText: habit.goalUnit,
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
                        await database.deleteHabitLogById(log.id);
                        if (context.mounted) Navigator.pop(context);
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

                      if (log != null) {
                        await database.updateHabitLog(
                          log.copyWith(amount: amount),
                        );
                      } else {
                        await database.insertHabitLog(
                          HabitLogsCompanion.insert(
                            habitId: habit.id,
                            date: drift.Value(selectedDate),
                            amount: drift.Value(amount),
                          ),
                        );
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
    );
  }
}

// Compact Contribution Grid for Habit Card
class _CompactContributionGrid extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;

  const _CompactContributionGrid({
    required this.habit,
    required this.database,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HabitLog>>(
      future: _getLast6MonthsLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 60);
        }

        final logs = snapshot.data ?? [];
        final logMap = <String, HabitLog>{};
        for (final log in logs) {
          final key = _dateKey(log.date);
          logMap[key] = log;
        }

        return _buildFullWidthGrid(logMap);
      },
    );
  }

  Future<List<HabitLog>> _getLast6MonthsLogs() async {
    return database.getHabitLogs(habit.id);
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
                                color: _getIntensityColor(completionPercent, habitColor),
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
      final monthName = DateFormat('MMM yyyy').format(date);
      
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
    
    if (habit.goalType == 'boolean') {
      return 100;
    } else if (habit.goalValue != null && habit.goalValue! > 0) {
      final percent = (log.amount / habit.goalValue!) * 100;
      return percent.clamp(0, 100);
    }
    
    return 0;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Date Selector
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - index));
    });

    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          return GestureDetector(
            onTap: () => onDateChanged(date),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.accentBlue.withOpacity(0.15) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.accentBlue 
                      : AppColors.border,
                  width: isSelected ? 2 : 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).substring(0, 1),
                    style: TextStyle(
                      color: isSelected 
                          ? AppColors.accentBlue 
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.accentBlue 
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Habit Detail Page
class HabitDetailPage extends ConsumerWidget {
  final Habit habit;

  const HabitDetailPage({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final habitColor = Color(int.parse('FF${habit.color}', radix: 16));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
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
                      habit.name,
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

            // Contribution Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                    habit: habit,
                    database: database,
                    habitColor: habitColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              height: 0.5,
              color: AppColors.border,
            ),
            const SizedBox(height: 16),

            // History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'History',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<List<HabitLog>>(
                stream: database.watchHabitLogs(habit.id),
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? [];

                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs yet',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final completionPercent = habit.goalType == 'unit' && habit.goalValue != null
                          ? (log.amount / habit.goalValue!) * 100
                          : 100.0;
                      
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border, width: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                            if (habit.goalType == 'unit')
                              Row(
                                children: [
                                  Text(
                                    '${log.amount.toStringAsFixed(0)} ${habit.goalUnit}',
                                    style: TextStyle(
                                      color: habitColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${completionPercent.toStringAsFixed(0)}%',
                                    style: TextStyle(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90));
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
  static const List<String> fullDayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

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
