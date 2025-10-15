import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'reminder_service.dart';
import 'workmanager_service.dart';
import '../../database/database_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final workManagerServiceProvider = Provider<WorkManagerService>((ref) {
  return WorkManagerService();
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final database = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ReminderService(database, notificationService);
});
