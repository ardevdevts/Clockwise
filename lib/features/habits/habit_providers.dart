import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/crud.dart';
import '../../database/database_provider.dart';
import 'habit_with_details.dart';

final habitWithDetailsProvider = StreamProvider.autoDispose.family<HabitWithDetails, int>((ref, habitId) {
  final database = ref.watch(databaseProvider);
  return database.watchHabitWithDetails(habitId);
});

final habitStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, (int, int)>((ref, params) {
  final database = ref.watch(databaseProvider);
  return database.getHabitStats(params.$1, days: params.$2);
});

final dailyHabitLogsProvider = FutureProvider.autoDispose.family<Map<DateTime, double>, (int, int)>((ref, params) {
  final database = ref.watch(databaseProvider);
  return database.getDailyHabitLogs(params.$1, days: params.$2);
});

final weeklyHabitStatsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, habitId) {
  final database = ref.watch(databaseProvider);
  return database.getWeeklyHabitStats(habitId, weeks: 12);
});

final habitRemindersProvider = StreamProvider.autoDispose.family<List<Reminder>, int>((ref, habitId) {
  final database = ref.watch(databaseProvider);
  return database.watchHabitReminders(habitId);
});
