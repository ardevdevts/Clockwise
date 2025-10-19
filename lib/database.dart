import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package

@DataClassName('Project')
class Projects extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withLength(min: 6, max: 9).withDefault(const Constant('00ADEF'))(); // Hex color code
  TextColumn get icon => text().nullable()(); // Emoji icon
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('Todo')
class Todos extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectUuid => text().references(Projects, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get parentUuid => text().nullable().references(Todos, #uuid, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get noteUuid => text().nullable().references(Notes, #uuid, onDelete: KeyAction.setNull)();
  IntColumn get priority => intEnum<Priority>()();
  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('Habit')
class Habits extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('HabitLog')
class HabitLogs extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitUuid => text().references(Habits, #uuid, onDelete: KeyAction.cascade)();
  DateTimeColumn get date =>
      dateTime().withDefault(currentDateAndTime)();
  RealColumn get amount => real().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('Reminder')
class Reminders extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitUuid => text().nullable().references(Habits, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get todoUuid => text().nullable().references(Todos, #uuid, onDelete: KeyAction.cascade)();
  DateTimeColumn get remindAt => dateTime()();
  BoolColumn get recurring => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('TodoLink')
class TodoLinks extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get todoUuid => text().references(Todos, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get url => text().withLength(min: 1, max: 500)();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('TodoImage')
class TodoImages extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get todoUuid => text().references(Todos, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get imagePath => text().withLength(min: 1, max: 500)();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

enum Priority { low, medium, high, urgent }
enum GoalType { unit, boolean }

@DataClassName('NoteFolder')
class NoteFolders extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().withLength(min: 6, max: 9).withDefault(const Constant('00ADEF'))();
  TextColumn get parentUuid => text().nullable().references(NoteFolders, #uuid, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('Note')
class Notes extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get folderUuid => text().nullable().references(NoteFolders, #uuid, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()(); // JSON content from flutter_quill
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('Tag')
class Tags extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withLength(min: 6, max: 9).withDefault(const Constant('00ADEF'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}

@DataClassName('NoteTag')
class NoteTags extends Table {
  TextColumn get uuid =>
      text().clientDefault(() => const Uuid().v4()).unique()(); // globally unique identifier
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noteUuid => text().references(Notes, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get tagUuid => text().references(Tags, #uuid, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)(); // last local/server update
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // soft delete flag
}
