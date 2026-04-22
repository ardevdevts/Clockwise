import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'android_saf_channel.dart';
import 'file_notes_models.dart';

class FileNotesRepository {
  FileNotesRepository({AndroidSafChannel? safChannel})
    : _saf = safChannel ?? AndroidSafChannel();

  static const _workspaceRegistryFile = 'notes_workspaces.json';
  static const _todoNoteLinksFile = 'todo_note_links.json';

  final AndroidSafChannel _saf;
  final _workspaceController = StreamController<List<NoteWorkspace>>.broadcast();
  final _uuid = const Uuid();

  List<NoteWorkspace> _workspaces = const [];

  Stream<List<NoteWorkspace>> watchWorkspaces() => _workspaceController.stream;

  Future<void> initialize() async {
    _workspaces = await _readWorkspaceRegistry();
    _workspaceController.add(_workspaces);
  }

  Future<List<NoteWorkspace>> getWorkspaces() async {
    if (_workspaces.isEmpty) {
      _workspaces = await _readWorkspaceRegistry();
      _workspaceController.add(_workspaces);
    }
    return _workspaces;
  }

  Future<NoteWorkspace?> addWorkspaceFromPicker() async {
    final picked = await _saf.pickWorkspaceDirectory();
    if (picked == null) return null;

    final existing = _workspaces.where((w) => w.treeUri == picked.treeUri).firstOrNull;
    if (existing != null) {
      return existing;
    }

    final workspace = NoteWorkspace(
      id: _uuid.v4(),
      name: picked.name,
      treeUri: picked.treeUri,
      addedAt: DateTime.now(),
    );

    _workspaces = [..._workspaces, workspace];
    await _writeWorkspaceRegistry(_workspaces);
    _workspaceController.add(_workspaces);

    await ensureMetadataFolder(workspace);
    return workspace;
  }

  Future<void> removeWorkspace(String workspaceId) async {
    _workspaces = _workspaces.where((w) => w.id != workspaceId).toList();
    await _writeWorkspaceRegistry(_workspaces);
    _workspaceController.add(_workspaces);
  }

  Future<List<NoteFileNode>> listChildren(
    NoteWorkspace workspace, {
    String? directoryUri,
    bool markdownOnly = true,
  }) async {
    final nodes = await _saf.listChildren(
      treeUri: workspace.treeUri,
      directoryUri: directoryUri,
    );

    final filtered = nodes.where((node) {
      if (node.name.startsWith('.clockwise')) return false;
      if (node.isDirectory) return true;
      if (!markdownOnly) return true;
      return node.isMarkdownFile;
    }).toList();

    filtered.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  Future<String> getRootUri(NoteWorkspace workspace) {
    return _rootDirectoryUri(workspace);
  }

  Future<String?> createFolder({
    required NoteWorkspace workspace,
    required String parentUri,
    required String name,
  }) {
    return _saf.createDirectory(
      treeUri: workspace.treeUri,
      parentUri: parentUri,
      name: name,
    );
  }

  Future<String?> createMarkdownNote({
    required NoteWorkspace workspace,
    required String parentUri,
    required String title,
  }) async {
    final normalized = _normalizeFilename(title);
    final filename = normalized.endsWith('.md') ? normalized : '$normalized.md';

    final fileUri = await _saf.createFile(
      treeUri: workspace.treeUri,
      parentUri: parentUri,
      name: filename,
      mimeType: 'text/markdown',
    );
    if (fileUri == null) return null;

    await _saf.writeText(uri: fileUri, content: '# ${filename.replaceAll('.md', '')}\n');
    return fileUri;
  }

  Future<void> deleteNode(String uri) => _saf.deleteDocument(uri: uri);

  Future<String?> renameNode({required String uri, required String newName}) {
    return _saf.renameDocument(uri: uri, newName: newName);
  }

  Future<String> readNote(NoteWorkspace workspace, NoteFileNode node) {
    return _saf.readText(uri: node.uri);
  }

  Future<void> saveNote(
    NoteWorkspace workspace,
    NoteFileNode node,
    String markdown,
  ) {
    return _saf.writeText(uri: node.uri, content: markdown);
  }

  Future<NoteMetadata> readMetadata(
    NoteWorkspace workspace,
    NoteFileNode node,
  ) async {
    final metaFileUri = await _findMetadataFileUri(workspace, node.relativePath);
    if (metaFileUri == null) return NoteMetadata.defaults();

    try {
      final raw = await _saf.readText(uri: metaFileUri);
      if (raw.trim().isEmpty) return NoteMetadata.defaults();
      return NoteMetadata.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return NoteMetadata.defaults();
    }
  }

  Future<void> writeMetadata(
    NoteWorkspace workspace,
    NoteFileNode node,
    NoteMetadata metadata,
  ) async {
    final metaDirUri = await ensureMetadataFolder(workspace);
    final key = '${encodePathKey(node.relativePath)}.json';
    var metaFileUri = await _findMetadataFileUri(workspace, node.relativePath);

    metaFileUri ??= await _saf.createFile(
      treeUri: workspace.treeUri,
      parentUri: metaDirUri,
      name: key,
      mimeType: 'application/json',
    );

    if (metaFileUri == null) return;
    await _saf.writeText(uri: metaFileUri, content: jsonEncode(metadata.toJson()));
  }

  Future<String> ensureMetadataFolder(NoteWorkspace workspace) async {
    final root = await _rootDirectoryUri(workspace);
    final clockwise = await _saf.ensureDirectory(
      treeUri: workspace.treeUri,
      parentUri: root,
      name: '.clockwise',
    );
    if (clockwise == null) {
      throw StateError('Unable to create .clockwise folder');
    }

    final meta = await _saf.ensureDirectory(
      treeUri: workspace.treeUri,
      parentUri: clockwise,
      name: 'meta',
    );

    if (meta == null) {
      throw StateError('Unable to create meta folder');
    }

    return meta;
  }

  Future<void> setTodoNoteLink(TodoNoteLink link) async {
    final links = await _readTodoLinks();
    final updated = [
      ...links.where((e) => e.todoUuid != link.todoUuid),
      link,
    ];
    await _writeTodoLinks(updated);
  }

  Future<TodoNoteLink?> getTodoNoteLink(String todoUuid) async {
    final links = await _readTodoLinks();
    return links.where((link) => link.todoUuid == todoUuid).firstOrNull;
  }

  Future<void> clearTodoNoteLink(String todoUuid) async {
    final links = await _readTodoLinks();
    final updated = links.where((e) => e.todoUuid != todoUuid).toList();
    await _writeTodoLinks(updated);
  }

  Future<NoteFileNode?> findNodeByRelativePath({
    required NoteWorkspace workspace,
    required String relativePath,
  }) async {
    final queue = <String?>[null];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final children = await listChildren(workspace, directoryUri: current);
      for (final child in children) {
        if (child.relativePath == relativePath) {
          return child;
        }
        if (child.isDirectory) {
          queue.add(child.uri);
        }
      }
    }

    return null;
  }

  Future<String> _rootDirectoryUri(NoteWorkspace workspace) async {
    final root = await _saf.getDocumentInfo(treeUri: workspace.treeUri, uri: workspace.treeUri);
    final uri = root?['uri'] as String?;
    if (uri == null || uri.isEmpty) {
      throw StateError('Unable to resolve workspace root uri.');
    }
    return uri;
  }

  Future<String?> _findMetadataFileUri(NoteWorkspace workspace, String relativePath) async {
    final key = '${encodePathKey(relativePath)}.json';
    final metaDirUri = await ensureMetadataFolder(workspace);
    return _saf.findChild(treeUri: workspace.treeUri, parentUri: metaDirUri, name: key);
  }

  String _normalizeFilename(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'untitled';
    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
  }

  Future<File> _workspaceRegistryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _workspaceRegistryFile));
  }

  Future<File> _todoLinksPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _todoNoteLinksFile));
  }

  Future<List<NoteWorkspace>> _readWorkspaceRegistry() async {
    final file = await _workspaceRegistryPath();
    if (!await file.exists()) return const [];

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NoteWorkspace.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeWorkspaceRegistry(List<NoteWorkspace> workspaces) async {
    final file = await _workspaceRegistryPath();
    await file.writeAsString(jsonEncode(workspaces.map((w) => w.toJson()).toList()));
  }

  Future<List<TodoNoteLink>> _readTodoLinks() async {
    final file = await _todoLinksPath();
    if (!await file.exists()) return const [];

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TodoNoteLink.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeTodoLinks(List<TodoNoteLink> links) async {
    final file = await _todoLinksPath();
    await file.writeAsString(jsonEncode(links.map((l) => l.toJson()).toList()));
  }

  Future<void> dispose() async {
    await _workspaceController.close();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
