import 'package:drift/drift.dart';
import '../database.dart'; // your tables
import 'package:drift_flutter/drift_flutter.dart';
import 'package:financialtracker/features/habits/habit_with_details.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

part 'crud.g.dart'; // will be generated

@DriftDatabase(
  tables: [
    Projects,
    Todos,
    Habits,
    HabitLogs,
    Reminders,
    TodoLinks,
    TodoImages,
    NoteFolders,
    Notes,
    Tags,
    NoteTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  // Migration strategy
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 9) {
        // Schema changed to use UUIDs for foreign keys.
        // This is a destructive migration that will delete all existing data.
        await migrator.drop(projects);
        await migrator.drop(todos);
        await migrator.drop(habits);
        await migrator.drop(habitLogs);
        await migrator.drop(reminders);
        await migrator.drop(todoLinks);
        await migrator.drop(todoImages);
        await migrator.drop(noteFolders);
        await migrator.drop(notes);
        await migrator.drop(tags);
        await migrator.drop(noteTags);
        await migrator.createAll();
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

  Future<int> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  Future<int> insertHabit(HabitsCompanion habit) => into(habits).insert(habit);

  Future<int> insertHabitLog(HabitLogsCompanion habitLog) =>
      into(habitLogs).insert(habitLog);

  Future<int> insertReminder(RemindersCompanion reminder) =>
      into(reminders).insert(reminder);

  Future<int> insertTodoLink(TodoLinksCompanion link) =>
      into(todoLinks).insert(link);

  Future<int> insertTodoImage(TodoImagesCompanion image) =>
      into(todoImages).insert(image);

  // UPDATE

  Future<bool> updateTodo(Todo todo) => update(todos).replace(todo);

  Future<bool> updateProject(Project project) =>
      update(projects).replace(project);

  Future<bool> updateHabit(Habit habit) => update(habits).replace(habit);

  Future<bool> updateHabitLog(HabitLog habitLog) =>
      update(habitLogs).replace(habitLog);

  Future<bool> updateReminder(Reminder reminder) =>
      update(reminders).replace(reminder);

  Future<bool> updateTodoLink(TodoLink link) => update(todoLinks).replace(link);

  Future<bool> updateTodoImage(TodoImage image) =>
      update(todoImages).replace(image);

  // DELETE

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteProject(int id) =>
      (delete(projects)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteHabit(int id) =>
      (delete(habits)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteHabitLog(int id) =>
      (delete(habitLogs)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteReminder(int id) =>
      (delete(reminders)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteTodoLink(int id) =>
      (delete(todoLinks)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteTodoImage(int id) =>
      (delete(todoImages)..where((tbl) => tbl.id.equals(id))).go();

  // TASK-SPECIFIC QUERIES

  // Get tasks for a specific project
  Future<List<Todo>> getTasksByProject(String projectUuid) {
    return (select(
      todos,
    )..where((tbl) => tbl.projectUuid.equals(projectUuid))).get();
  }

  // Get root tasks (no parent) for a project
  Future<List<Todo>> getRootTasksByProject(String projectUuid) {
    return (select(todos)..where(
          (tbl) =>
              tbl.projectUuid.equals(projectUuid) & tbl.parentUuid.isNull(),
        ))
        .get();
  }

  // Get subtasks for a specific task
  Future<List<Todo>> getSubtasks(String parentUuid) {
    return (select(
      todos,
    )..where((tbl) => tbl.parentUuid.equals(parentUuid))).get();
  }

  // Get a single task by ID
  Future<Todo?> getTodoById(int id) {
    return (select(todos)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Todo?> getTodoByUuid(String uuid) {
    return (select(
      todos,
    )..where((tbl) => tbl.uuid.equals(uuid))).getSingleOrNull();
  }

  // Get a single project by ID
  Future<Project?> getProjectById(int id) {
    return (select(
      projects,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Project?> getProjectByUuid(String uuid) {
    return (select(
      projects,
    )..where((tbl) => tbl.uuid.equals(uuid))).getSingleOrNull();
  }

  // Watch projects (stream for real-time updates)
  Stream<List<Project>> watchProjects() => select(projects).watch();

  // Watch tasks by project (stream)
  Stream<List<Todo>> watchTasksByProject(String projectUuid) {
    return (select(
      todos,
    )..where((tbl) => tbl.projectUuid.equals(projectUuid))).watch();
  }

  // Watch root tasks by project (stream)
  Stream<List<Todo>> watchRootTasksByProject(String projectUuid) {
    return (select(todos)..where(
          (tbl) =>
              tbl.projectUuid.equals(projectUuid) & tbl.parentUuid.isNull(),
        ))
        .watch();
  }

  // Watch subtasks (stream)
  Stream<List<Todo>> watchSubtasks(String parentUuid) {
    return (select(
      todos,
    )..where((tbl) => tbl.parentUuid.equals(parentUuid))).watch();
  }

  // Watch a single todo by ID (stream)
  Stream<Todo?> watchTodoById(int id) {
    return (select(
      todos,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  Stream<Todo?> watchTodoByUuid(String uuid) {
    return (select(
      todos,
    )..where((tbl) => tbl.uuid.equals(uuid))).watchSingleOrNull();
  }

  // Get links for a specific todo
  Future<List<TodoLink>> getTodoLinks(String todoUuid) {
    return (select(
      todoLinks,
    )..where((tbl) => tbl.todoUuid.equals(todoUuid))).get();
  }

  // Watch links for a specific todo (stream)
  Stream<List<TodoLink>> watchTodoLinks(String todoUuid) {
    return (select(
      todoLinks,
    )..where((tbl) => tbl.todoUuid.equals(todoUuid))).watch();
  }

  // Get images for a specific todo
  Future<List<TodoImage>> getTodoImages(String todoUuid) {
    return (select(
      todoImages,
    )..where((tbl) => tbl.todoUuid.equals(todoUuid))).get();
  }

  // Watch images for a specific todo (stream)
  Stream<List<TodoImage>> watchTodoImages(String todoUuid) {
    return (select(
      todoImages,
    )..where((tbl) => tbl.todoUuid.equals(todoUuid))).watch();
  }

  // Get project task statistics
  Future<Map<String, int>> getProjectStats(String projectUuid) async {
    final tasks = await getTasksByProject(projectUuid);
    final completedTasks = tasks.where((task) => task.completed).length;
    return {'total': tasks.length, 'completed': completedTasks};
  }

  // Watch project task statistics (stream)
  Stream<Map<String, int>> watchProjectStats(String projectUuid) {
    return watchTasksByProject(projectUuid).map((tasks) {
      final completedTasks = tasks.where((task) => task.completed).length;
      return {'total': tasks.length, 'completed': completedTasks};
    });
  }

  Future<List<Habit>> getActiveHabits() {
    return (select(habits)..where((tbl) => tbl.archived.equals(false))).get();
  }

  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)..where((tbl) => tbl.archived.equals(false))).watch();
  }

  Future<Habit?> getHabitById(int id) {
    return (select(
      habits,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Habit?> getHabitByUuid(String uuid) {
    return (select(
      habits,
    )..where((tbl) => tbl.uuid.equals(uuid))).getSingleOrNull();
  }

  // Get habit logs for a specific habit
  Future<List<HabitLog>> getHabitLogs(String habitUuid) {
    return (select(
      habitLogs,
    )..where((tbl) => tbl.habitUuid.equals(habitUuid))).get();
  }

  // Get habit logs for a specific date
  Future<List<HabitLog>> getHabitLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(habitLogs)..where(
          (tbl) =>
              tbl.date.isBiggerOrEqualValue(startOfDay) &
              tbl.date.isSmallerOrEqualValue(endOfDay),
        ))
        .get();
  }

  // Get habit log for specific habit and date
  Future<HabitLog?> getHabitLogForDate(String habitUuid, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(habitLogs)..where(
          (tbl) =>
              tbl.habitUuid.equals(habitUuid) &
              tbl.date.isBiggerOrEqualValue(startOfDay) &
              tbl.date.isSmallerOrEqualValue(endOfDay),
        ))
        .getSingleOrNull();
  }

  // Watch habit log for specific habit and date (stream)
  Stream<HabitLog?> watchHabitLogForDate(String habitUuid, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(habitLogs)..where(
          (tbl) =>
              tbl.habitUuid.equals(habitUuid) &
              tbl.date.isBiggerOrEqualValue(startOfDay) &
              tbl.date.isSmallerOrEqualValue(endOfDay),
        ))
        .watchSingleOrNull();
  }

  // Watch habit logs for a habit (stream)
  Stream<List<HabitLog>> watchHabitLogs(String habitUuid) {
    return (select(habitLogs)
          ..where((tbl) => tbl.habitUuid.equals(habitUuid))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Stream<List<Reminder>> watchHabitReminders(String habitUuid) {
    return (select(
      reminders,
    )..where((tbl) => tbl.habitUuid.equals(habitUuid))).watch();
  }

  Stream<HabitWithDetails> watchHabitWithDetails(String habitUuid) {
    final habitStream = (select(
      habits,
    )..where((tbl) => tbl.uuid.equals(habitUuid))).watchSingle();
    final logsStream = watchHabitLogs(habitUuid);

    return Rx.combineLatest2(habitStream, logsStream, (habit, logs) {
      return HabitWithDetails(habit: habit, logs: logs);
    });
  }

  // Get last habit log for a habit
  Future<HabitLog?> getLastHabitLog(String habitUuid) {
    return (select(habitLogs)
          ..where((tbl) => tbl.habitUuid.equals(habitUuid))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Upsert habit log (update if exists for the date, insert if not)
  Future<void> upsertHabitLog(
    String habitUuid,
    DateTime date,
    double amount,
  ) async {
    final existingLog = await getHabitLogForDate(habitUuid, date);

    if (existingLog != null) {
      // Update existing log
      await updateHabitLog(existingLog.copyWith(amount: amount));
    } else {
      // Insert new log
      await into(habitLogs).insert(
        HabitLogsCompanion.insert(
          habitUuid: habitUuid,
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
  Future<List<HabitLog>> getHabitLogsInRange(
    String habitUuid,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(habitLogs)
          ..where(
            (tbl) =>
                tbl.habitUuid.equals(habitUuid) &
                tbl.date.isBiggerOrEqualValue(startDate) &
                tbl.date.isSmallerOrEqualValue(endDate),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  // Get habit statistics for a specific period
  Future<Map<String, dynamic>> getHabitStats(
    String habitUuid, {
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final logs = await getHabitLogsInRange(habitUuid, startDate, endDate);

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
      final logDate = DateTime(
        sortedLogs[i].date.year,
        sortedLogs[i].date.month,
        sortedLogs[i].date.day,
      );

      if (lastDate == null) {
        tempStreak = 1;
        if (i == 0) {
          final today = DateTime(endDate.year, endDate.month, endDate.day);
          final yesterday = today.subtract(const Duration(days: 1));
          if (logDate.isAtSameMomentAs(today) ||
              logDate.isAtSameMomentAs(yesterday)) {
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
    if (currentStreak > 0 && currentStreak < tempStreak)
      currentStreak = tempStreak;

    // Calculate completion rate (logs vs expected days)
    final habit = await getHabitByUuid(habitUuid);
    int expectedDays = days;
    if (habit != null &&
        habit.interval == 'custom' &&
        habit.customDays != null) {
      // Calculate expected days based on custom schedule
      final customDays = habit.customDays!.split(',').map(int.parse).toSet();
      expectedDays = 0;
      for (var i = 0; i < days; i++) {
        final date = endDate.subtract(Duration(days: i));
        if (customDays.contains(date.weekday % 7)) {
          expectedDays++;
        }
      }
    } else if (habit != null &&
        habit.interval == 'interval' &&
        habit.intervalDays != null) {
      expectedDays = days ~/ habit.intervalDays!;
    }

    final completionRate = expectedDays > 0
        ? (totalLogs / expectedDays * 100).clamp(0, 100)
        : 0.0;

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
  Future<Map<DateTime, double>> getDailyHabitLogs(
    String habitUuid, {
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    final logs = await getHabitLogsInRange(habitUuid, startDate, endDate);

    final Map<DateTime, double> dailyData = {};
    for (var log in logs) {
      final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
      dailyData[dateKey] = log.amount;
    }

    return dailyData;
  }

  // Get weekly aggregated data
  Future<List<Map<String, dynamic>>> getWeeklyHabitStats(
    String habitUuid, {
    int weeks = 12,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: weeks * 7));
    final logs = await getHabitLogsInRange(habitUuid, startDate, endDate);

    final Map<int, List<HabitLog>> weeklyLogs = {};

    for (var log in logs) {
      final weekNumber = _getWeekNumber(log.date);
      weeklyLogs.putIfAbsent(weekNumber, () => []).add(log);
    }

    final List<Map<String, dynamic>> weeklyStats = [];
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = endDate.subtract(
        Duration(days: i * 7 + endDate.weekday - 1),
      );
      final weekNumber = _getWeekNumber(weekStart);
      final logsForWeek = weeklyLogs[weekNumber] ?? [];

      weeklyStats.add({
        'weekStart': weekStart,
        'count': logsForWeek.length,
        'total': logsForWeek.fold<double>(0, (sum, log) => sum + log.amount),
        'average': logsForWeek.isEmpty
            ? 0.0
            : logsForWeek.fold<double>(0, (sum, log) => sum + log.amount) /
                  logsForWeek.length,
      });
    }

    return weeklyStats;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }

  // ============= NOTES CRUD =============

  // Folders
  Future<List<NoteFolder>> get allNoteFolders => select(noteFolders).get();

  Stream<List<NoteFolder>> watchNoteFolders() => select(noteFolders).watch();

  Future<NoteFolder?> getNoteFolderById(int id) => (select(
    noteFolders,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<NoteFolder?> getNoteFolderByUuid(String uuid) => (select(
    noteFolders,
  )..where((tbl) => tbl.uuid.equals(uuid))).getSingleOrNull();

  Future<int> insertNoteFolder(NoteFoldersCompanion folder) =>
      into(noteFolders).insert(folder);

  Future<bool> updateNoteFolder(NoteFolder folder) =>
      update(noteFolders).replace(folder);

  Future<int> deleteNoteFolder(int id) =>
      (delete(noteFolders)..where((tbl) => tbl.id.equals(id))).go();

  // Notes
  Future<List<Note>> get allNotes => select(notes).get();

  Stream<List<Note>> watchNotes() => select(notes).watch();

  Stream<List<Note>> watchNotesByFolder(String? folderUuid) {
    if (folderUuid == null) {
      return (select(notes)..where((tbl) => tbl.folderUuid.isNull())).watch();
    }
    return (select(
      notes,
    )..where((tbl) => tbl.folderUuid.equals(folderUuid))).watch();
  }

  Future<Note?> getNoteById(int id) =>
      (select(notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<Note?> getNoteByUuid(String uuid) =>
      (select(notes)..where((tbl) => tbl.uuid.equals(uuid))).getSingleOrNull();

  Future<List<Note>> getNotesByFolder(String? folderUuid) {
    if (folderUuid == null) {
      return (select(notes)..where((tbl) => tbl.folderUuid.isNull())).get();
    }
    return (select(
      notes,
    )..where((tbl) => tbl.folderUuid.equals(folderUuid))).get();
  }

  Future<List<Note>> getPinnedNotes() =>
      (select(notes)..where((tbl) => tbl.isPinned.equals(true))).get();

  Future<List<Note>> getFavoriteNotes() =>
      (select(notes)..where((tbl) => tbl.isFavorite.equals(true))).get();

  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);

  Future<bool> updateNote(Note note) => update(notes).replace(note);

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<Note>> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(notes)..where(
          (tbl) =>
              tbl.title.lower().like('%$lowerQuery%') |
              tbl.content.lower().like('%$lowerQuery%'),
        ))
        .get();
  }

  // Get count of todos linked to a note
  Future<int> getLinkedTodosCount(String noteUuid) async {
    final query = selectOnly(todos)
      ..addColumns([todos.id.count()])
      ..where(todos.noteUuid.equals(noteUuid));

    final result = await query.getSingle();
    return result.read(todos.id.count()) ?? 0;
  }

  // Tags
  Future<List<Tag>> get allTags => select(tags).get();

  Stream<List<Tag>> watchTags() => select(tags).watch();

  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<Tag?> getTagByName(String name) =>
      (select(tags)..where((tbl) => tbl.name.equals(name))).getSingleOrNull();

  Future<int> insertTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<bool> updateTag(Tag tag) => update(tags).replace(tag);

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((tbl) => tbl.id.equals(id))).go();

  // Note-Tag relationships
  Future<List<Tag>> getTagsForNote(String noteUuid) async {
    final query = select(noteTags).join([
      innerJoin(tags, tags.uuid.equalsExp(noteTags.tagUuid)),
    ])..where(noteTags.noteUuid.equals(noteUuid));

    final results = await query.get();
    return results.map((row) => row.readTable(tags)).toList();
  }

  Future<List<Note>> getNotesByTag(String tagUuid) async {
    final query = select(noteTags).join([
      innerJoin(notes, notes.uuid.equalsExp(noteTags.noteUuid)),
    ])..where(noteTags.tagUuid.equals(tagUuid));

    final results = await query.get();
    return results.map((row) => row.readTable(notes)).toList();
  }

  Future<int> addTagToNote(String noteUuid, String tagUuid) => into(
    noteTags,
  ).insert(NoteTagsCompanion.insert(noteUuid: noteUuid, tagUuid: tagUuid));

  Future<int> removeTagFromNote(String noteUuid, String tagUuid) =>
      (delete(noteTags)..where(
            (tbl) =>
                tbl.noteUuid.equals(noteUuid) & tbl.tagUuid.equals(tagUuid),
          ))
          .go();

  Future<void> setNoteTags(String noteUuid, List<String> tagUuids) async {
    // Remove all existing tags
    await (delete(
      noteTags,
    )..where((tbl) => tbl.noteUuid.equals(noteUuid))).go();

    // Add new tags
    for (final tagUuid in tagUuids) {
      await addTagToNote(noteUuid, tagUuid);
    }
  }

  Stream<List<HabitWithDetails>> watchActiveHabitsWithDetails() {
    return watchActiveHabits().asyncMap((habits) async {
      final habitsWithDetails = <HabitWithDetails>[];
      for (final habit in habits) {
        final today = DateTime.now();

        final endDate = DateTime(today.year, today.month, today.day);
        // The grid in habits_page.dart shows 180 days.
        final startDate = endDate.subtract(const Duration(days: 180));
        final recentLogsList = await getHabitLogsInRange(
          habit.uuid,
          startDate,
          endDate,
        );

        final recentLogs = <String, HabitLog>{};
        for (final log in recentLogsList) {
          final key =
              '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';
          recentLogs[key] = log;
        }

        habitsWithDetails.add(
          HabitWithDetails(habit: habit, logs: recentLogs.values.toList()),
        );
      }
      return habitsWithDetails;
    });
  }

  // ============= SYNC METHODS =============

  // Get records changed since a specific date
  Future<List<Project>> getProjectsChangedSince(DateTime since) {
    return (select(
      projects,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<Todo>> getTodosChangedSince(DateTime since) {
    return (select(
      todos,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<Habit>> getHabitsChangedSince(DateTime since) {
    return (select(
      habits,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<HabitLog>> getHabitLogsChangedSince(DateTime since) {
    return (select(
      habitLogs,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<Reminder>> getRemindersChangedSince(DateTime since) {
    return (select(
      reminders,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<NoteFolder>> getNoteFoldersChangedSince(DateTime since) {
    return (select(
      noteFolders,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<Note>> getNotesChangedSince(DateTime since) {
    return (select(
      notes,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<Tag>> getTagsChangedSince(DateTime since) {
    return (select(
      tags,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<TodoLink>> getTodoLinksChangedSince(DateTime since) {
    return (select(
      todoLinks,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<TodoImage>> getTodoImagesChangedSince(DateTime since) {
    return (select(
      todoImages,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<NoteTag>> getNoteTagsChangedSince(DateTime since) {
    return (select(
      noteTags,
    )..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(since))).get();
  }

  // Upsert methods for syncing from server
  Future<void> upsertProjectFromSync(Map<String, dynamic> data) async {
    final existing = await getProjectByUuid(data['uuid']);
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    if (existing == null) {
      // Insert new
      await into(projects).insert(
        ProjectsCompanion.insert(
          uuid: Value(data['uuid']),
          name: data['name'],
          description: Value(data['description']),
          color: Value(data['color'] ?? '00ADEF'),
          icon: Value(data['icon']),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      // Update if server version is newer
      await update(projects).replace(
        existing.copyWith(
          name: data['name'],
          description: data['description'],
          color: data['color'] ?? '00ADEF',
          icon: data['icon'],
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertTodoFromSync(Map<String, dynamic> data) async {
    final existing = await getTodoByUuid(data['uuid']);
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    if (existing == null) {
      await into(todos).insert(
        TodosCompanion.insert(
          uuid: Value(data['uuid']),
          projectUuid: data['projectId'],
          parentUuid: Value(data['parentId']),
          title: data['title'],
          description: Value(data['description']),
          notes: Value(data['notes']),
          noteUuid: Value(data['noteId']),
          priority: Priority.values[data['priority'] ?? 0],
          completed: Value(data['completed'] ?? false),
          dueAt: Value(
            data['dueAt'] != null ? DateTime.parse(data['dueAt']) : null,
          ),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(todos).replace(
        existing.copyWith(
          projectUuid: data['projectId'],
          parentUuid: data['parentId'],
          title: data['title'],
          description: data['description'],
          notes: data['notes'],
          noteUuid: data['noteId'],
          priority: Priority.values[data['priority'] ?? 0],
          completed: data['completed'] ?? false,
          dueAt: Value(
            data['dueAt'] != null ? DateTime.parse(data['dueAt']) : null,
          ),
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertHabitFromSync(Map<String, dynamic> data) async {
    final existing = await getHabitByUuid(data['uuid']);
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    if (existing == null) {
      await into(habits).insert(
        HabitsCompanion.insert(
          uuid: Value(data['uuid']),
          name: data['name'],
          description: Value(data['description']),
          color: data['color'],
          interval: data['interval'],
          customDays: Value(data['customDays']),
          intervalDays: Value(data['intervalDays']),
          goalType: data['goalType'],
          goalValue: Value(data['goalValue']),
          goalUnit: Value(data['goalUnit']),
          startDate: Value(DateTime.parse(data['startDate'])),
          archived: Value(data['archived'] ?? false),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(habits).replace(
        existing.copyWith(
          name: data['name'],
          description: data['description'],
          color: data['color'],
          interval: data['interval'],
          customDays: data['customDays'],
          intervalDays: data['intervalDays'],
          goalType: data['goalType'],
          goalValue: data['goalValue'],
          goalUnit: data['goalUnit'],
          startDate: DateTime.parse(data['startDate']),
          archived: data['archived'] ?? false,
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertHabitLogFromSync(Map<String, dynamic> data) async {
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    // Check if habit log exists by uuid
    final existing = await (select(
      habitLogs,
    )..where((tbl) => tbl.uuid.equals(data['uuid']))).getSingleOrNull();

    if (existing == null) {
      await into(habitLogs).insert(
        HabitLogsCompanion.insert(
          uuid: Value(data['uuid']),
          habitUuid: data['habitId'],
          date: Value(DateTime.parse(data['date'])),
          amount: Value(data['amount'] ?? 1.0),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(habitLogs).replace(
        existing.copyWith(
          habitUuid: data['habitId'],
          date: DateTime.parse(data['date']),
          amount: data['amount'] ?? 1.0,
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertReminderFromSync(Map<String, dynamic> data) async {
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    final existing = await (select(
      reminders,
    )..where((tbl) => tbl.uuid.equals(data['uuid']))).getSingleOrNull();

    if (existing == null) {
      await into(reminders).insert(
        RemindersCompanion.insert(
          uuid: Value(data['uuid']),
          habitUuid: Value(data['habitId']),
          todoUuid: Value(data['todoId']),
          remindAt: DateTime.parse(data['remindAt']),
          recurring: Value(data['recurring'] ?? false),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(reminders).replace(
        existing.copyWith(
          habitUuid: data['habitId'],
          todoUuid: data['todoId'],
          remindAt: DateTime.parse(data['remindAt']),
          recurring: data['recurring'] ?? false,
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertTodoLinkFromSync(Map<String, dynamic> data) async {
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    final existing = await (select(
      todoLinks,
    )..where((tbl) => tbl.uuid.equals(data['uuid']))).getSingleOrNull();

    if (existing == null) {
      await into(todoLinks).insert(
        TodoLinksCompanion.insert(
          uuid: Value(data['uuid']),
          todoUuid: data['todoId'],
          url: data['url'],
          title: Value(data['title']),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(todoLinks).replace(
        existing.copyWith(
          todoUuid: data['todoId'],
          url: data['url'],
          title: data['title'],
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertTodoImageFromSync(Map<String, dynamic> data) async {
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    final existing = await (select(
      todoImages,
    )..where((tbl) => tbl.uuid.equals(data['uuid']))).getSingleOrNull();

    if (existing == null) {
      await into(todoImages).insert(
        TodoImagesCompanion.insert(
          uuid: Value(data['uuid']),
          todoUuid: data['todoId'],
          imagePath: data['imagePath'],
          caption: Value(data['caption']),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(todoImages).replace(
        existing.copyWith(
          todoUuid: data['todoId'],
          imagePath: data['imagePath'],
          caption: data['caption'],
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertNoteFolderFromSync(Map<String, dynamic> data) async {
    final existing = await getNoteFolderByUuid(data['uuid']);
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    if (existing == null) {
      await into(noteFolders).insert(
        NoteFoldersCompanion.insert(
          uuid: Value(data['uuid']),
          name: data['name'],
          color: Value(data['color'] ?? '00ADEF'),
          parentUuid: Value(data['parentId']),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(noteFolders).replace(
        existing.copyWith(
          name: data['name'],
          color: data['color'] ?? '00ADEF',
          parentUuid: data['parentId'],
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertNoteFromSync(Map<String, dynamic> data) async {
    final existing = await getNoteByUuid(data['uuid']);
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    if (existing == null) {
      await into(notes).insert(
        NotesCompanion.insert(
          uuid: Value(data['uuid']),
          folderUuid: Value(data['folderId']),
          title: data['title'],
          content: data['content'],
          isPinned: Value(data['isPinned'] ?? false),
          isFavorite: Value(data['isFavorite'] ?? false),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(notes).replace(
        existing.copyWith(
          folderUuid: data['folderId'],
          title: data['title'],
          content: data['content'],
          isPinned: data['isPinned'] ?? false,
          isFavorite: data['isFavorite'] ?? false,
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertTagFromSync(Map<String, dynamic> data) async {
    final existing = await (select(
      tags,
    )..where((tbl) => tbl.uuid.equals(data['uuid']))).getSingleOrNull();
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    if (existing == null) {
      await into(tags).insert(
        TagsCompanion.insert(
          uuid: Value(data['uuid']),
          name: data['name'],
          color: Value(data['color'] ?? '00ADEF'),
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(tags).replace(
        existing.copyWith(
          name: data['name'],
          color: data['color'] ?? '00ADEF',
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }

  Future<void> upsertNoteTagFromSync(Map<String, dynamic> data) async {
    final serverUpdatedAt = DateTime.parse(data['updatedAt']);

    final existing = await (select(
      noteTags,
    )..where((tbl) => tbl.uuid.equals(data['uuid']))).getSingleOrNull();

    if (existing == null) {
      await into(noteTags).insert(
        NoteTagsCompanion.insert(
          uuid: Value(data['uuid']),
          noteUuid: data['noteId'],
          tagUuid: data['tagId'],
          createdAt: Value(DateTime.parse(data['createdAt'])),
          updatedAt: Value(serverUpdatedAt),
          isDeleted: Value(data['isDeleted'] ?? false),
        ),
      );
    } else if (serverUpdatedAt.isAfter(existing.updatedAt)) {
      await update(noteTags).replace(
        existing.copyWith(
          noteUuid: data['noteId'],
          tagUuid: data['tagId'],
          updatedAt: serverUpdatedAt,
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'app_database');
}
