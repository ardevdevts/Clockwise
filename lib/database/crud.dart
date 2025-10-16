import 'package:drift/drift.dart';
import '../database.dart'; // your tables
import 'package:drift_flutter/drift_flutter.dart';

part 'crud.g.dart'; // will be generated

@DriftDatabase(
  tables: [Projects, Todos, Habits, HabitLogs, Reminders, TodoLinks, TodoImages],
)
class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 6;

  // Migration strategy
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
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
      if (from < 4) {
        // Add color and icon columns to projects table
        await migrator.addColumn(projects, projects.color);
        await migrator.addColumn(projects, projects.icon);
      }
      if (from < 5) {
        // Create TodoLinks table
        await migrator.createTable(todoLinks);
      }
      if (from < 6) {
        // Create TodoImages table
        await migrator.createTable(todoImages);
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
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

  Future<int> insertTodoLink(TodoLinksCompanion link) => into(todoLinks).insert(link);

  Future<int> insertTodoImage(TodoImagesCompanion image) => into(todoImages).insert(image);

  // UPDATE

  Future<bool> updateTodo(Todo todo) => update(todos).replace(todo);

  Future<bool> updateProject(Project project) => update(projects).replace(project);

  Future<bool> updateHabit(Habit habit) => update(habits).replace(habit);

  Future<bool> updateHabitLog(HabitLog habitLog) => update(habitLogs).replace(habitLog);

  Future<bool> updateReminder(Reminder reminder) => update(reminders).replace(reminder);

  Future<bool> updateTodoLink(TodoLink link) => update(todoLinks).replace(link);

  Future<bool> updateTodoImage(TodoImage image) => update(todoImages).replace(image);

  // DELETE

  Future<int> deleteTodo(int id) => (delete(todos)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteProject(int id) => (delete(projects)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteHabit(int id) => (delete(habits)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteHabitLog(int id) => (delete(habitLogs)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteReminder(int id) => (delete(reminders)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteTodoLink(int id) => (delete(todoLinks)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteTodoImage(int id) => (delete(todoImages)..where((tbl) => tbl.id.equals(id))).go();

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

  // Watch a single todo by ID (stream)
  Stream<Todo?> watchTodoById(int id) {
    return (select(todos)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  // Get links for a specific todo
  Future<List<TodoLink>> getTodoLinks(int todoId) {
    return (select(todoLinks)..where((tbl) => tbl.todoId.equals(todoId))).get();
  }

  // Watch links for a specific todo (stream)
  Stream<List<TodoLink>> watchTodoLinks(int todoId) {
    return (select(todoLinks)..where((tbl) => tbl.todoId.equals(todoId))).watch();
  }

  // Get images for a specific todo
  Future<List<TodoImage>> getTodoImages(int todoId) {
    return (select(todoImages)..where((tbl) => tbl.todoId.equals(todoId))).get();
  }

  // Watch images for a specific todo (stream)
  Stream<List<TodoImage>> watchTodoImages(int todoId) {
    return (select(todoImages)..where((tbl) => tbl.todoId.equals(todoId))).watch();
  }

  // Get project task statistics
  Future<Map<String, int>> getProjectStats(int projectId) async {
    final tasks = await getTasksByProject(projectId);
    final completedTasks = tasks.where((task) => task.completed).length;
    return {
      'total': tasks.length,
      'completed': completedTasks,
    };
  }

  // Watch project task statistics (stream)
  Stream<Map<String, int>> watchProjectStats(int projectId) {
    return watchTasksByProject(projectId).map((tasks) {
      final completedTasks = tasks.where((task) => task.completed).length;
      return {
        'total': tasks.length,
        'completed': completedTasks,
      };
    });
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

  // Get habit logs within a date range
  Future<List<HabitLog>> getHabitLogsInRange(int habitId, DateTime startDate, DateTime endDate) {
    return (select(habitLogs)
          ..where((tbl) => 
              tbl.habitId.equals(habitId) &
              tbl.date.isBiggerOrEqualValue(startDate) & 
              tbl.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  // Get habit statistics for a specific period
  Future<Map<String, dynamic>> getHabitStats(int habitId, {int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final logs = await getHabitLogsInRange(habitId, startDate, endDate);
    
    if (logs.isEmpty) {
      return {
        'totalLogs': 0,
        'completionRate': 0.0,
        'currentStreak': 0,
        'longestStreak': 0,
        'averageAmount': 0.0,
        'totalAmount': 0.0,
      };
    }

    final totalLogs = logs.length;
    final totalAmount = logs.fold<double>(0, (sum, log) => sum + log.amount);
    final averageAmount = totalAmount / totalLogs;
    
    // Calculate streaks
    final sortedLogs = logs.toList()..sort((a, b) => b.date.compareTo(a.date));
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    
    DateTime? lastDate;
    for (var i = 0; i < sortedLogs.length; i++) {
      final logDate = DateTime(sortedLogs[i].date.year, sortedLogs[i].date.month, sortedLogs[i].date.day);
      
      if (lastDate == null) {
        tempStreak = 1;
        if (i == 0) {
          final today = DateTime(endDate.year, endDate.month, endDate.day);
          final yesterday = today.subtract(const Duration(days: 1));
          if (logDate.isAtSameMomentAs(today) || logDate.isAtSameMomentAs(yesterday)) {
            currentStreak = 1;
          }
        }
      } else {
        final dayDiff = lastDate.difference(logDate).inDays;
        if (dayDiff == 1) {
          tempStreak++;
          if (i == 0) currentStreak = tempStreak;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      lastDate = logDate;
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;
    if (currentStreak > 0 && currentStreak < tempStreak) currentStreak = tempStreak;

    // Calculate completion rate (logs vs expected days)
    final habit = await getHabitById(habitId);
    int expectedDays = days;
    if (habit != null && habit.interval == 'custom' && habit.customDays != null) {
      // Calculate expected days based on custom schedule
      final customDays = habit.customDays!.split(',').map(int.parse).toSet();
      expectedDays = 0;
      for (var i = 0; i < days; i++) {
        final date = endDate.subtract(Duration(days: i));
        if (customDays.contains(date.weekday % 7)) {
          expectedDays++;
        }
      }
    } else if (habit != null && habit.interval == 'interval' && habit.intervalDays != null) {
      expectedDays = days ~/ habit.intervalDays!;
    }
    
    final completionRate = expectedDays > 0 ? (totalLogs / expectedDays * 100).clamp(0, 100) : 0.0;

    return {
      'totalLogs': totalLogs,
      'completionRate': completionRate,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'averageAmount': averageAmount,
      'totalAmount': totalAmount,
    };
  }

  // Get daily logs for chart (last N days)
  Future<Map<DateTime, double>> getDailyHabitLogs(int habitId, {int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    final logs = await getHabitLogsInRange(habitId, startDate, endDate);
    
    final Map<DateTime, double> dailyData = {};
    for (var log in logs) {
      final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
      dailyData[dateKey] = log.amount;
    }
    
    return dailyData;
  }

  // Get weekly aggregated data
  Future<List<Map<String, dynamic>>> getWeeklyHabitStats(int habitId, {int weeks = 12}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: weeks * 7));
    final logs = await getHabitLogsInRange(habitId, startDate, endDate);
    
    final Map<int, List<HabitLog>> weeklyLogs = {};
    
    for (var log in logs) {
      final weekNumber = _getWeekNumber(log.date);
      weeklyLogs.putIfAbsent(weekNumber, () => []).add(log);
    }
    
    final List<Map<String, dynamic>> weeklyStats = [];
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = endDate.subtract(Duration(days: i * 7 + endDate.weekday - 1));
      final weekNumber = _getWeekNumber(weekStart);
      final logsForWeek = weeklyLogs[weekNumber] ?? [];
      
      weeklyStats.add({
        'weekStart': weekStart,
        'count': logsForWeek.length,
        'total': logsForWeek.fold<double>(0, (sum, log) => sum + log.amount),
        'average': logsForWeek.isEmpty ? 0.0 : logsForWeek.fold<double>(0, (sum, log) => sum + log.amount) / logsForWeek.length,
      });
    }
    
    return weeklyStats;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }
  
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'app_database');
}

