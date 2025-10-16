import 'package:financialtracker/database.dart';
import 'package:financialtracker/database/crud.dart' show Habit, HabitLog;

class HabitWithDetails {
  final Habit habit;
  final List<HabitLog> logs;

  HabitWithDetails({
    required this.habit,
    required this.logs,
  });
}
