import 'package:financialtracker/database/crud.dart';

/// Model for sync request sent to server
class SyncRequest {
  final String? clientId;
  final String? lastSyncAt;
  final SyncChanges changes;

  SyncRequest({this.clientId, this.lastSyncAt, required this.changes});

  Map<String, dynamic> toJson() {
    return {
      if (clientId != null) 'clientId': clientId,
      if (lastSyncAt != null) 'lastSyncAt': lastSyncAt,
      'changes': changes.toJson(),
    };
  }
}

/// All changes to sync
class SyncChanges {
  final List<Map<String, dynamic>>? projects;
  final List<Map<String, dynamic>>? todos;
  final List<Map<String, dynamic>>? habits;
  final List<Map<String, dynamic>>? habitLogs;
  final List<Map<String, dynamic>>? reminders;
  final List<Map<String, dynamic>>? todoLinks;
  final List<Map<String, dynamic>>? todoImages;
  final List<Map<String, dynamic>>? noteFolders;
  final List<Map<String, dynamic>>? notes;
  final List<Map<String, dynamic>>? tags;
  final List<Map<String, dynamic>>? noteTags;

  SyncChanges({
    this.projects,
    this.todos,
    this.habits,
    this.habitLogs,
    this.reminders,
    this.todoLinks,
    this.todoImages,
    this.noteFolders,
    this.notes,
    this.tags,
    this.noteTags,
  });

  factory SyncChanges.fromJson(Map<String, dynamic> json) {
    return SyncChanges(
      projects: _parseList(json['projects']),
      todos: _parseList(json['todos']),
      habits: _parseList(json['habits']),
      habitLogs: _parseList(json['habitLogs']),
      reminders: _parseList(json['reminders']),
      todoLinks: _parseList(json['todoLinks']),
      todoImages: _parseList(json['todoImages']),
      noteFolders: _parseList(json['noteFolders']),
      notes: _parseList(json['notes']),
      tags: _parseList(json['tags']),
      noteTags: _parseList(json['noteTags']),
    );
  }

  static List<Map<String, dynamic>>? _parseList(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (projects != null && projects!.isNotEmpty) 'projects': projects,
      if (todos != null && todos!.isNotEmpty) 'todos': todos,
      if (habits != null && habits!.isNotEmpty) 'habits': habits,
      if (habitLogs != null && habitLogs!.isNotEmpty) 'habitLogs': habitLogs,
      if (reminders != null && reminders!.isNotEmpty) 'reminders': reminders,
      if (todoLinks != null && todoLinks!.isNotEmpty) 'todoLinks': todoLinks,
      if (todoImages != null && todoImages!.isNotEmpty)
        'todoImages': todoImages,
      if (noteFolders != null && noteFolders!.isNotEmpty)
        'noteFolders': noteFolders,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (tags != null && tags!.isNotEmpty) 'tags': tags,
      if (noteTags != null && noteTags!.isNotEmpty) 'noteTags': noteTags,
    };
  }

  bool get isEmpty =>
      (projects?.isEmpty ?? true) &&
      (todos?.isEmpty ?? true) &&
      (habits?.isEmpty ?? true) &&
      (habitLogs?.isEmpty ?? true) &&
      (reminders?.isEmpty ?? true) &&
      (todoLinks?.isEmpty ?? true) &&
      (todoImages?.isEmpty ?? true) &&
      (noteFolders?.isEmpty ?? true) &&
      (notes?.isEmpty ?? true) &&
      (tags?.isEmpty ?? true) &&
      (noteTags?.isEmpty ?? true);
}

/// Model for sync response from server
class SyncResponse {
  final int status;
  final SyncChanges? message;
  final String? error;
  final String? code;
  final dynamic details;

  SyncResponse({
    required this.status,
    this.message,
    this.error,
    this.code,
    this.details,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return SyncResponse(
        status: json['status'] ?? 500,
        error: json['error'],
        code: json['code'],
        details: json['details'],
      );
    }

    return SyncResponse(
      status: json['status'] ?? 200,
      message: json['message'] != null
          ? SyncChanges.fromJson(json['message'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => status == 200 && error == null;
  bool get hasError => error != null;
}

/// Helper extension to convert Drift models to JSON for sync
extension ProjectToSync on Project {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension TodoToSync on Todo {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'projectId': projectUuid,
      'parentId': parentUuid,
      'title': title,
      'description': description,
      'notes': notes,
      'noteId': noteUuid,
      'priority': priority.index,
      'completed': completed,
      'dueAt': dueAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension HabitToSync on Habit {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'color': color,
      'interval': interval,
      'customDays': customDays,
      'intervalDays': intervalDays,
      'goalType': goalType,
      'goalValue': goalValue,
      'goalUnit': goalUnit,
      'startDate': startDate.toIso8601String(),
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension HabitLogToSync on HabitLog {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'habitId': habitUuid,
      'date': date.toIso8601String(),
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension ReminderToSync on Reminder {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'habitId': habitUuid,
      'todoId': todoUuid,
      'remindAt': remindAt.toIso8601String(),
      'recurring': recurring,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension TodoLinkToSync on TodoLink {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'todoId': todoUuid,
      'url': url,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension TodoImageToSync on TodoImage {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'todoId': todoUuid,
      'imagePath': imagePath,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension NoteFolderToSync on NoteFolder {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'name': name,
      'color': color,
      'parentId': parentUuid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension NoteToSync on Note {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'folderId': folderUuid,
      'title': title,
      'content': content,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension TagToSync on Tag {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}

extension NoteTagToSync on NoteTag {
  Map<String, dynamic> toSyncJson() {
    return {
      'uuid': uuid,
      'noteId': noteUuid,
      'tagId': tagUuid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
