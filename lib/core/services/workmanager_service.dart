import 'package:workmanager/workmanager.dart';
import '../../database/crud.dart';
import 'notification_service.dart';
import 'reminder_service.dart';

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final database = AppDatabase();
      final notificationService = NotificationService();
      final reminderService = ReminderService(database, notificationService);

      await notificationService.initialize();

      switch (task) {
        case 'rescheduleReminders':
          await reminderService.rescheduleAllReminders();
          break;
        case 'checkDueReminders':
          await _checkAndSendDueReminders(database, notificationService);
          break;
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

// Check for due reminders and send notifications
Future<void> _checkAndSendDueReminders(
  AppDatabase database,
  NotificationService notificationService,
) async {
  final allReminders = await database.allReminders;
  final now = DateTime.now();

  for (final reminder in allReminders) {
    // Check if reminder is due (within next 5 minutes)
    final diff = reminder.remindAt.difference(now).inMinutes;
    
    if (diff >= 0 && diff <= 5) {
      // Send notification
      if (reminder.todoUuid != null) {
        final todo = await database.getTodoByUuid(reminder.todoUuid!);
        if (todo != null && !todo.completed) {
          await notificationService.scheduleTaskReminder(todo, reminder.remindAt);
        }
      } else if (reminder.habitUuid != null) {
        final habit = await database.getHabitByUuid(reminder.habitUuid!);
        if (habit != null && !habit.archived) {
          final notificationId = (habit.id * 100000 + reminder.id).hashCode.abs();
          await notificationService.scheduleHabitReminder(
            habit,
            reminder.remindAt,
            notificationId,
          );
        }
      }

      // If not recurring, delete after scheduling
      if (!reminder.recurring) {
        await database.deleteReminder(reminder.id);
      }
    }
  }
}

class WorkManagerService {
  static final WorkManagerService _instance = WorkManagerService._internal();
  factory WorkManagerService() => _instance;
  WorkManagerService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic task to check reminders every 15 minutes
    await Workmanager().registerPeriodicTask(
      'checkDueReminders',
      'checkDueReminders',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  // Trigger one-time reminder rescheduling
  Future<void> rescheduleReminders() async {
    await Workmanager().registerOneOffTask(
      'rescheduleReminders-${DateTime.now().millisecondsSinceEpoch}',
      'rescheduleReminders',
    );
  }

  // Cancel all background tasks
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
