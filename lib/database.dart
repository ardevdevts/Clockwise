import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';



@DataClassName('Project')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Todo')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get priority => intEnum<Priority>()();
  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DataClassName('Habit')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get interval =>
      text().withLength(min: 1, max: 20)(); // daily, weekly, etc.
  TextColumn get goalType => text().withLength(min: 1, max: 20)(); // 'unit' | 'boolean'
  RealColumn get goalValue => real().nullable()(); // numeric goal for unit type
  TextColumn get goalUnit => text().nullable()(); // e.g., liters, kg, reps
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get archived =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('HabitLog')
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date =>
      dateTime().withDefault(currentDateAndTime)();
  RealColumn get amount => real().withDefault(const Constant(1))();
}

@DataClassName('Reminder')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().nullable().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get todoId =>
      integer().nullable().references(Todos, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get remindAt => dateTime()();
  BoolColumn get recurring => boolean().withDefault(const Constant(false))();
}

enum Priority { low, medium, high, urgent }
enum GoalType { unit, boolean }

@DriftDatabase(tables: [Projects, Todos, Habits, HabitLogs, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());
  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
}
}

