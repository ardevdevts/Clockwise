import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../database.dart'; // your tables
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'crud.g.dart'; // will be generated

@DriftDatabase(
  tables: [Projects, Todos, Habits, HabitLogs, Reminders],
)
class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 1;

  Future<List<Todo>> get allTodoItems => select(todos).get();

  Future<List<Project>> get allProjects => select(projects).get();

  Future<List<Habit>> get allHabits => select(habits).get();

  Future<List<HabitLog>> get allHabitLogs => select(habitLogs).get();

  Future<List<Reminder>> get allReminders => select(reminders).get();

  // CREATE

  Future<int> insertTodo(Todo todo) => into(todos).insert(todo);

  Future<int> insertProject(Project project) => into(projects).insert(project);

  Future<int> insertHabit(Habit habit) => into(habits).insert(habit);

  Future<int> insertHabitLog(HabitLog habitLog) => into(habitLogs).insert(habitLog);

  Future<int> insertReminder(Reminder reminder) => into(reminders).insert(reminder);

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

  
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase(file);
  });
}

