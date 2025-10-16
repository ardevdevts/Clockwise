import 'package:drift/drift.dart';

@DataClassName('Project')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withLength(min: 6, max: 9).withDefault(const Constant('00ADEF'))(); // Hex color code
  TextColumn get icon => text().nullable()(); // Emoji icon
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Todo')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get parentId => integer().nullable().customConstraint("NULL REFERENCES todos(id)")();
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
  TextColumn get color => text().withLength(min: 6, max: 9)(); // Hex color code
  TextColumn get interval =>
      text().withLength(min: 1, max: 20)(); // daily, weekly, custom, interval
  TextColumn get customDays => text().nullable()(); // Comma-separated days: 0=Sun, 1=Mon, etc.
  IntColumn get intervalDays => integer().nullable()(); // For "every N days"
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

@DataClassName('TodoLink')
class TodoLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get todoId =>
      integer().references(Todos, #id, onDelete: KeyAction.cascade)();
  TextColumn get url => text().withLength(min: 1, max: 500)();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TodoImage')
class TodoImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get todoId =>
      integer().references(Todos, #id, onDelete: KeyAction.cascade)();
  TextColumn get imagePath => text().withLength(min: 1, max: 500)();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

enum Priority { low, medium, high, urgent }
enum GoalType { unit, boolean }
