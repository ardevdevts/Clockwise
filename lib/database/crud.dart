import 'package:drift/drift.dart';
import '../database.dart'; // your tables
import 'package:drift_flutter/drift_flutter.dart';

part 'crud.g.dart'; // will be generated

@DriftDatabase(
  tables: [Projects, Todos, Habits, HabitLogs, Reminders],
)
class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 3;

  // Migration strategy
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Add color column to habits table
        await migrator.addColumn(habits, habits.color);
      }
      if (from < 3) {
        // Add custom interval columns
        await migrator.addColumn(habits, habits.customDays);
        await migrator.addColumn(habits, habits.intervalDays);
      }
    },
  );

  Future<List<Todo>> get allTodoItems => select(todos).get();

  Future<List<Project>> get allProjects => select(projects).get();

  Future<List<Habit>> get allHabits => select(habits).get();

  Future<List<HabitLog>> get allHabitLogs => select(habitLogs).get();

  Future<List<Reminder>> get allReminders => select(reminders).get();

  // CREATE

  Future<int> insertTodo(TodosCompanion todo) => into(todos).insert(todo);

  Future<int> insertProject(ProjectsCompanion project) => into(projects).insert(project);

  Future<int> insertHabit(HabitsCompanion habit) => into(habits).insert(habit);

  Future<int> insertHabitLog(HabitLogsCompanion habitLog) => into(habitLogs).insert(habitLog);

  Future<int> insertReminder(RemindersCompanion reminder) => into(reminders).insert(reminder);

  // UPDATE

  Future<bool> updateTodo(Todo todo) => update(todos).replace(todo);

  Future<bool> updateProject(Project project) => update(projects).replace(project);

  Future<bool> updateHabit(Habit habit) => update(habits).replace(habit);

  Future<bool> updateHabitLog(HabitLog habitLog) => update(habitLogs).replace(habitLog);

  Future<bool> updateReminder(Reminder reminder) => update(reminders).replace(reminder);

  // DELETE 

  Future<int> deleteTodo(int id) => (delete(todos)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteProject(int id) => (delete(projects)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteHabit(int id) => (delete(habits)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteHabitLog(int id) => (delete(habitLogs)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteReminder(int id) => (delete(reminders)..where((tbl) => tbl.id.equals(id))).go();

  // TASK-SPECIFIC QUERIES

  // Get tasks for a specific project
  Future<List<Todo>> getTasksByProject(int projectId) {
    return (select(todos)..where((tbl) => tbl.projectId.equals(projectId))).get();
  }

  // Get root tasks (no parent) for a project
  Future<List<Todo>> getRootTasksByProject(int projectId) {
    return (select(todos)
          ..where((tbl) => tbl.projectId.equals(projectId) & tbl.parentId.isNull()))
        .get();
  }

  // Get subtasks for a specific task
  Future<List<Todo>> getSubtasks(int parentId) {
    return (select(todos)..where((tbl) => tbl.parentId.equals(parentId))).get();
  }

  // Get a single task by ID
  Future<Todo?> getTodoById(int id) {
    return (select(todos)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Get a single project by ID
  Future<Project?> getProjectById(int id) {
    return (select(projects)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Watch projects (stream for real-time updates)
  Stream<List<Project>> watchProjects() => select(projects).watch();

  // Watch tasks by project (stream)
  Stream<List<Todo>> watchTasksByProject(int projectId) {
    return (select(todos)..where((tbl) => tbl.projectId.equals(projectId))).watch();
  }

  // Watch root tasks by project (stream)
  Stream<List<Todo>> watchRootTasksByProject(int projectId) {
    return (select(todos)
          ..where((tbl) => tbl.projectId.equals(projectId) & tbl.parentId.isNull()))
        .watch();
  }

  // Watch subtasks (stream)
  Stream<List<Todo>> watchSubtasks(int parentId) {
    return (select(todos)..where((tbl) => tbl.parentId.equals(parentId))).watch();
  }

  // HABIT-SPECIFIC QUERIES

  // Get active (non-archived) habits
  Future<List<Habit>> getActiveHabits() {
    return (select(habits)..where((tbl) => tbl.archived.equals(false))).get();
  }

  // Watch active habits (stream)
  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)..where((tbl) => tbl.archived.equals(false))).watch();
  }

  // Get a single habit by ID
  Future<Habit?> getHabitById(int id) {
    return (select(habits)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Get habit logs for a specific habit
  Future<List<HabitLog>> getHabitLogs(int habitId) {
    return (select(habitLogs)..where((tbl) => tbl.habitId.equals(habitId))).get();
  }

  // Get habit logs for a specific date
  Future<List<HabitLog>> getHabitLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(habitLogs)
          ..where((tbl) => 
              tbl.date.isBiggerOrEqualValue(startOfDay) & 
              tbl.date.isSmallerOrEqualValue(endOfDay)))
        .get();
  }

  // Get habit log for specific habit and date
  Future<HabitLog?> getHabitLogForDate(int habitId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(habitLogs)
          ..where((tbl) => 
              tbl.habitId.equals(habitId) &
              tbl.date.isBiggerOrEqualValue(startOfDay) & 
              tbl.date.isSmallerOrEqualValue(endOfDay)))
        .getSingleOrNull();
  }

  // Watch habit log for specific habit and date (stream)
  Stream<HabitLog?> watchHabitLogForDate(int habitId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(habitLogs)
          ..where((tbl) => 
              tbl.habitId.equals(habitId) &
              tbl.date.isBiggerOrEqualValue(startOfDay) & 
              tbl.date.isSmallerOrEqualValue(endOfDay)))
        .watchSingleOrNull();
  }

  // Watch habit logs for a habit (stream)
  Stream<List<HabitLog>> watchHabitLogs(int habitId) {
    return (select(habitLogs)
          ..where((tbl) => tbl.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // Get last habit log for a habit
  Future<HabitLog?> getLastHabitLog(int habitId) {
    return (select(habitLogs)
          ..where((tbl) => tbl.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Upsert habit log (update if exists for the date, insert if not)
  Future<void> upsertHabitLog(int habitId, DateTime date, double amount) async {
    final existingLog = await getHabitLogForDate(habitId, date);
    
    if (existingLog != null) {
      // Update existing log
      await updateHabitLog(existingLog.copyWith(amount: amount));
    } else {
      // Insert new log
      await insertHabitLog(
        HabitLogsCompanion.insert(
          habitId: habitId,
          date: Value(date),
          amount: Value(amount),
        ),
      );
    }
  }

  // Delete habit log
  Future<int> deleteHabitLogById(int id) => 
      (delete(habitLogs)..where((tbl) => tbl.id.equals(id))).go();
  
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'app_database');
}

