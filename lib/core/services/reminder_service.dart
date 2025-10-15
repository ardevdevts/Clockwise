import '../../database/crud.dart';
import 'package:drift/drift.dart' as drift;
import 'notification_service.dart';

class ReminderService {
  final AppDatabase _database;
  final NotificationService _notificationService;

  ReminderService(this._database, this._notificationService);

  // Add a task reminder
  Future<void> addTaskReminder(int todoId, DateTime remindAt) async {
    // Save to database
    await _database.insertReminder(
      RemindersCompanion.insert(
        todoId: drift.Value(todoId),
        remindAt: remindAt,
        recurring: drift.Value(false),
      ),
    );

    // Schedule notification
    final todo = await _database.getTodoById(todoId);
    if (todo != null) {
      await _notificationService.scheduleTaskReminder(todo, remindAt);
    }
  }

  // Add a habit reminder (can be recurring)
  Future<void> addHabitReminder(int habitId, DateTime remindAt, {bool recurring = true}) async {
    // Save to database
    final reminderId = await _database.insertReminder(
      RemindersCompanion.insert(
        habitId: drift.Value(habitId),
        remindAt: remindAt,
        recurring: drift.Value(recurring),
      ),
    );

    // Schedule notification
    final habit = await _database.getHabitById(habitId);
    if (habit != null) {
      // Use reminder ID + habitId to create unique notification ID
      final notificationId = _generateNotificationId(habitId, reminderId);
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
  Future<List<Reminder>> getTaskReminders(int todoId) async {
    final allReminders = await _database.allReminders;
    return allReminders.where((r) => r.todoId == todoId).toList();
  }

  // Get all reminders for a habit
  Future<List<Reminder>> getHabitReminders(int habitId) async {
    final allReminders = await _database.allReminders;
    return allReminders.where((r) => r.habitId == habitId).toList();
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
    if (reminder.todoId != null) {
      final todo = await _database.getTodoById(reminder.todoId!);
      if (todo != null) {
        await _notificationService.scheduleTaskReminder(todo, reminder.remindAt);
      }
    } else if (reminder.habitId != null) {
      final habit = await _database.getHabitById(reminder.habitId!);
      if (habit != null) {
        final notificationId = _generateNotificationId(reminder.habitId!, reminder.id);
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
  Future<void> deleteTaskReminders(int todoId) async {
    final reminders = await getTaskReminders(todoId);
    for (final reminder in reminders) {
      await removeReminder(reminder.id);
    }
  }

  // Delete all reminders for a habit
  Future<void> deleteHabitReminders(int habitId) async {
    final reminders = await getHabitReminders(habitId);
    for (final reminder in reminders) {
      await removeReminder(reminder.id);
    }
  }
}

