import 'dart:convert';

class NoteWorkspace {
  const NoteWorkspace({
    required this.id,
    required this.name,
    required this.treeUri,
    required this.addedAt,
  });

  final String id;
  final String name;
  final String treeUri;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'treeUri': treeUri,
    'addedAt': addedAt.toIso8601String(),
  };

  factory NoteWorkspace.fromJson(Map<String, dynamic> json) => NoteWorkspace(
    id: json['id'] as String,
    name: json['name'] as String,
    treeUri: json['treeUri'] as String,
    addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class NoteFileNode {
  const NoteFileNode({
    required this.uri,
    required this.name,
    required this.isDirectory,
    required this.relativePath,
    required this.lastModified,
    required this.size,
  });

  final String uri;
  final String name;
  final bool isDirectory;
  final String relativePath;
  final DateTime? lastModified;
  final int? size;

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  bool get isMarkdownFile => !isDirectory && extension == 'md';

  factory NoteFileNode.fromMap(Map<Object?, Object?> map) => NoteFileNode(
    uri: map['uri'] as String,
    name: map['name'] as String,
    isDirectory: map['isDirectory'] as bool,
    relativePath: (map['relativePath'] as String?) ?? '',
    lastModified: map['lastModified'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int),
    size: map['size'] as int?,
  );
}

class NoteMetadata {
  const NoteMetadata({
    required this.isPinned,
    required this.isFavorite,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  final bool isPinned;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteMetadata copyWith({
    bool? isPinned,
    bool? isFavorite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteMetadata(
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'isPinned': isPinned,
    'isFavorite': isFavorite,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteMetadata.fromJson(Map<String, dynamic> json) => NoteMetadata(
    isPinned: (json['isPinned'] as bool?) ?? false,
    isFavorite: (json['isFavorite'] as bool?) ?? false,
    tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  factory NoteMetadata.defaults() {
    final now = DateTime.now();
    return NoteMetadata(
      isPinned: false,
      isFavorite: false,
      tags: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
}

class TodoNoteLink {
  const TodoNoteLink({
    required this.todoUuid,
    required this.workspaceId,
    required this.relativePath,
  });

  final String todoUuid;
  final String workspaceId;
  final String relativePath;

  Map<String, dynamic> toJson() => {
    'todoUuid': todoUuid,
    'workspaceId': workspaceId,
    'relativePath': relativePath,
  };

  factory TodoNoteLink.fromJson(Map<String, dynamic> json) => TodoNoteLink(
    todoUuid: json['todoUuid'] as String,
    workspaceId: json['workspaceId'] as String,
    relativePath: json['relativePath'] as String,
  );
}

String encodePathKey(String path) {
  final bytes = utf8.encode(path);
  return base64Url.encode(bytes).replaceAll('=', '');
}
