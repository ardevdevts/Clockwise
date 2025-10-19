import '../../database/crud.dart';
import 'package:drift/drift.dart' as drift;
import 'notification_service.dart';

class ReminderService {
  final AppDatabase _database;
  final NotificationService _notificationService;

  ReminderService(this._database, this._notificationService);

  // Add a task reminder
  Future<void> addTaskReminder(String todoUuid, DateTime remindAt) async {
    // Save to database
    await _database.insertReminder(
      RemindersCompanion.insert(
        todoUuid: drift.Value(todoUuid),
        remindAt: remindAt,
        recurring: drift.Value(false),
      ),
    );

    // Schedule notification
    final todo = await _database.getTodoByUuid(todoUuid);
    if (todo != null) {
      await _notificationService.scheduleTaskReminder(todo, remindAt);
    }
  }

  // Add a habit reminder (can be recurring)
  Future<void> addHabitReminder(String habitUuid, DateTime remindAt, {bool recurring = true}) async {
    // Save to database
    final reminderId = await _database.insertReminder(
      RemindersCompanion.insert(
        habitUuid: drift.Value(habitUuid),
        remindAt: remindAt,
        recurring: drift.Value(recurring),
      ),
    );

    // Schedule notification
    final habit = await _database.getHabitByUuid(habitUuid);
    if (habit != null) {
      // Use reminder ID + habitId to create unique notification ID
      final notificationId = _generateNotificationId(habit.id, reminderId);
      await _notificationService.scheduleHabitReminder(habit, remindAt, notificationId);
    }
  }

  // Remove a reminder
  Future<void> removeReminder(int reminderId) async {
    await _database.deleteReminder(reminderId);
    // Cancel the notification
    await _notificationService.cancelNotification(reminderId);
  }

  // Get all reminders for a task
  Future<List<Reminder>> getTaskReminders(String todoUuid) async {
    final allReminders = await _database.allReminders;
    return allReminders.where((r) => r.todoUuid == todoUuid).toList();
  }

  // Get all reminders for a habit
  Future<List<Reminder>> getHabitReminders(String habitUuid) async {
    final allReminders = await _database.allReminders;
    return allReminders.where((r) => r.habitUuid == habitUuid).toList();
  }

  // Reschedule all reminders (useful after app restart)
  Future<void> rescheduleAllReminders() async {
    final allReminders = await _database.allReminders;
    final now = DateTime.now();

    for (final reminder in allReminders) {
      if (reminder.remindAt.isBefore(now)) {
        // Skip past reminders
        if (!reminder.recurring) {
          // Delete non-recurring past reminders
          await _database.deleteReminder(reminder.id);
        } else {
          // Reschedule recurring reminders
          final nextRemindAt = _getNextReminderTime(reminder);
          if (nextRemindAt != null) {
            await _database.updateReminder(
              reminder.copyWith(remindAt: nextRemindAt),
            );
            await _scheduleReminder(reminder.copyWith(remindAt: nextRemindAt));
          }
        }
      } else {
        // Schedule future reminders
        await _scheduleReminder(reminder);
      }
    }
  }

  // Schedule a reminder notification
  Future<void> _scheduleReminder(Reminder reminder) async {
    if (reminder.todoUuid != null) {
      final todo = await _database.getTodoByUuid(reminder.todoUuid!);
      if (todo != null) {
        await _notificationService.scheduleTaskReminder(todo, reminder.remindAt);
      }
    } else if (reminder.habitUuid != null) {
      final habit = await _database.getHabitByUuid(reminder.habitUuid!);
      if (habit != null) {
        final notificationId = _generateNotificationId(habit.id, reminder.id);
        await _notificationService.scheduleHabitReminder(habit, reminder.remindAt, notificationId);
      }
    }
  }

  // Get next reminder time for recurring reminders
  DateTime? _getNextReminderTime(Reminder reminder) {
    if (!reminder.recurring) return null;

    final now = DateTime.now();
    final remindTime = reminder.remindAt;
    
    // Calculate next day with same time
    var nextReminder = DateTime(
      now.year,
      now.month,
      now.day,
      remindTime.hour,
      remindTime.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (nextReminder.isBefore(now)) {
      nextReminder = nextReminder.add(const Duration(days: 1));
    }

    return nextReminder;
  }

  // Generate unique notification ID
  int _generateNotificationId(int habitId, int reminderId) {
    // Combine habit ID and reminder ID to create unique notification ID
    // Using hash to keep it within int range
    return (habitId * 100000 + reminderId).hashCode.abs();
  }

  // Delete all reminders for a task
  Future<void> deleteTaskReminders(String todoUuid) async {
    final reminders = await getTaskReminders(todoUuid);
    for (final reminder in reminders) {
      await removeReminder(reminder.id);
    }
  }

  // Delete all reminders for a habit
  Future<void> deleteHabitReminders(String habitUuid) async {
    final reminders = await getHabitReminders(habitUuid);
    for (final reminder in reminders) {
      await removeReminder(reminder.id);
    }
  }
}

