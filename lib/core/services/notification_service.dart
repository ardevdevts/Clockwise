import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../database/crud.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTap,
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Handle notification tap when app is in foreground or background
  void _handleNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.length < 2) return;

    final type = parts[0]; // 'task' or 'habit'
    final id = int.tryParse(parts[1]);
    if (id == null) return;

    final database = AppDatabase();

    if (type == 'task' && response.actionId == 'mark_complete') {
      // Mark task as complete
      final todo = await database.getTodoById(id);
      if (todo != null) {
        await database.updateTodo(todo.copyWith(completed: true));
      }
    } else if (type == 'habit' && response.actionId == 'log_habit') {
      // Log habit for today
      final habit = await database.getHabitById(id);
      if (habit != null) {
        final now = DateTime.now();
        final goalValue = habit.goalType == 'boolean' ? 1.0 : (habit.goalValue ?? 1.0);
        await database.upsertHabitLog(id, now, goalValue);
      }
    }
  }

  // Handle notification tap when app is terminated
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse response) {
    // Background handling is done through workmanager
    _instance._handleNotificationTap(response);
  }

  // Schedule a task reminder
  Future<void> scheduleTaskReminder(Todo task, DateTime scheduledTime) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_complete',
          'Mark Complete',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'task_category',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      task.id,
      task.title,
      task.description ?? 'Task reminder',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task|${task.id}',
    );
  }

  // Schedule a habit reminder
  Future<void> scheduleHabitReminder(
    Habit habit,
    DateTime scheduledTime,
    int notificationId,
  ) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'log_habit',
          'Log Now',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'habit_category',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      habit.name,
      habit.description ?? 'Time to log your habit!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'habit|${habit.id}',
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

