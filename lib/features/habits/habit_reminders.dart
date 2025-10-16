import 'package:financialtracker/database/crud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../core/theme/colors.dart';
import 'package:intl/intl.dart';
import '../../core/services/service_providers.dart';

// Helper class to track reminder data
class ReminderTimeData {
  final int? id; // null for new reminders
  TimeOfDay time;

  ReminderTimeData({this.id, required this.time});
}

// Habit Reminders List Widget
class HabitRemindersList extends ConsumerStatefulWidget {
  final int habitId;

  const HabitRemindersList({super.key, required this.habitId});

  @override
  ConsumerState<HabitRemindersList> createState() => HabitRemindersListState();
}

class HabitRemindersListState extends ConsumerState<HabitRemindersList> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
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
                  await loadReminders(); // Refresh the list
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
