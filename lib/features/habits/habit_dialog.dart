import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/services/service_providers.dart';
import 'habit_constants.dart';

class ReminderTimeData {
  final int? id; 
  TimeOfDay time;

  ReminderTimeData({this.id, required this.time});
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

class HabitDialog extends ConsumerStatefulWidget {
  final Habit? habit;
  final AppDatabase database;

  const HabitDialog({
    super.key,
    this.habit,
    required this.database,
  });

  @override
  ConsumerState<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends ConsumerState<HabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _selectedColor = '';
  String _goalType = 'boolean';
  double _goalValue = 1;
  String _goalUnit = '';
  String _interval = 'daily';

  // Parse custom days (0=Sunday, 1=Monday, etc.)
  Set<int> _selectedDays = {};

  int _intervalDaysValue = 2;

  // List of reminder times
  final List<ReminderTimeData> _reminderTimes = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadExistingReminders();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');
    _selectedColor = widget.habit?.color ?? habitColors[0].value.toRadixString(16).substring(2);
    _goalType = widget.habit?.goalType ?? 'boolean';
    _goalValue = widget.habit?.goalValue ?? 1;
    _goalUnit = widget.habit?.goalUnit ?? '';
    _interval = widget.habit?.interval ?? 'daily';

    // Parse custom days (0=Sunday, 1=Monday, etc.)
    if (widget.habit?.customDays != null && widget.habit!.customDays!.isNotEmpty) {
      _selectedDays = widget.habit!.customDays!.split(',').map((e) => int.parse(e)).toSet();
    }

    _intervalDaysValue = widget.habit?.intervalDays ?? 2;
  }

  Future<void> _loadExistingReminders() async {
    if (widget.habit != null) {
      final reminderService = ref.read(reminderServiceProvider);
      final existingReminders = await reminderService.getHabitReminders(widget.habit!.id);
      setState(() {
        _reminderTimes.addAll(existingReminders.map((r) => ReminderTimeData(
          id: r.id,
          time: TimeOfDay.fromDateTime(r.remindAt),
        )));
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                widget.habit == null ? 'New Habit' : 'Edit Habit',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              _MinimalTextField(
                controller: _nameController,
                hint: 'Habit name',
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Description
              _MinimalTextField(
                controller: _descriptionController,
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
                  final isSelected = _selectedColor == colorHex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorHex),
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
                selected: _interval,
                onChanged: (value) => setState(() => _interval = value),
              ),
              const SizedBox(height: 16),

              // Custom days selector
              if (_interval == 'custom') ...[
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
                  selectedDays: _selectedDays,
                  onDaysChanged: (days) => setState(() => _selectedDays = days),
                ),
                const SizedBox(height: 16),
              ],

              // Interval days selector
              if (_interval == 'interval') ...[
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
                        controller: TextEditingController(text: _intervalDaysValue.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _intervalDaysValue.toString().length),
                          ),
                        hint: 'Days',
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            _intervalDaysValue = parsed;
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
                selected: _goalType,
                onChanged: (value) => setState(() => _goalType = value),
              ),

              if (_goalType == 'unit') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _MinimalTextField(
                        controller: TextEditingController(
                          text: _goalValue.toString(),
                        )..selection = TextSelection.fromPosition(
                            TextPosition(offset: _goalValue.toString().length),
                          ),
                        hint: 'Goal value',
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) _goalValue = parsed;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _MinimalTextField(
                        controller: TextEditingController(text: _goalUnit),
                        hint: 'Unit (e.g., km, reps)',
                        onChanged: (val) => _goalUnit = val,
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
              if (_reminderTimes.isNotEmpty) ...[
                ..._reminderTimes.map((reminderData) => Container(
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
                            _reminderTimes.remove(reminderData);
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
                      _reminderTimes.add(ReminderTimeData(time: time));
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
                    label: widget.habit == null ? 'Create' : 'Update',
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) return;

                      // Prepare custom days string
                      String? customDaysStr;
                      if (_interval == 'custom' && _selectedDays.isNotEmpty) {
                        final daysList = _selectedDays.toList()..sort();
                        customDaysStr = daysList.join(',');
                      }

                      int habitId;
                      if (widget.habit == null) {
                        // Create new habit
                        habitId = await widget.database.insertHabit(
                          HabitsCompanion.insert(
                            name: _nameController.text.trim(),
                            description: drift.Value(_descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim()),
                            color: _selectedColor,
                            interval: _interval,
                            customDays: drift.Value(customDaysStr),
                            intervalDays: drift.Value(_interval == 'interval' ? _intervalDaysValue : null),
                            goalType: _goalType,
                            goalValue: drift.Value(_goalType == 'unit' ? _goalValue : null),
                            goalUnit: drift.Value(_goalType == 'unit' ? _goalUnit : null),
                          ),
                        );
                      } else {
                        // Update existing habit
                        habitId = widget.habit!.id;
                        await widget.database.updateHabit(
                          widget.habit!.copyWith(
                            name: _nameController.text.trim(),
                            description: drift.Value(_descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim()),
                            color: _selectedColor,
                            interval: _interval,
                            customDays: drift.Value(customDaysStr),
                            intervalDays: drift.Value(_interval == 'interval' ? _intervalDaysValue : null),
                            goalType: _goalType,
                            goalValue: drift.Value(_goalType == 'unit' ? _goalValue : null),
                            goalUnit: drift.Value(_goalType == 'unit' ? _goalUnit : null),
                          ),
                        );

                        // Delete old reminders that were removed
                        final reminderService = ref.read(reminderServiceProvider);
                        final existingReminders = await reminderService.getHabitReminders(habitId);
                        for (final existingReminder in existingReminders) {
                          final stillExists = _reminderTimes.any((r) => r.id == existingReminder.id);
                          if (!stillExists) {
                            await reminderService.removeReminder(existingReminder.id);
                          }
                        }
                      }

                      // Save reminders
                      final reminderService = ref.read(reminderServiceProvider);
                      final now = DateTime.now();

                      for (final reminderData in _reminderTimes) {
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
                          await widget.database.updateReminder(
                            existingReminder.copyWith(remindAt: reminderTime),
                          );
                          // Reschedule notification
                          final updatedHabit = await widget.database.getHabitById(habitId);
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
    );
  }
}
