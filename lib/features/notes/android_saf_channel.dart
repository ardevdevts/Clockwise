import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_notes_models.dart';

class AndroidSafChannel {
  static const MethodChannel _channel = MethodChannel('clockwise/saf');

  Future<NoteWorkspace?> pickWorkspaceDirectory() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'pickWorkspaceDirectory',
    );
    if (result == null) return null;
    return NoteWorkspace(
      id: result['id'] as String,
      name: result['name'] as String,
      treeUri: result['treeUri'] as String,
      addedAt: DateTime.now(),
    );
  }

  Future<List<NoteFileNode>> listChildren({
    required String treeUri,
    String? directoryUri,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('listChildren', {
      'treeUri': treeUri,
      'directoryUri': directoryUri,
    });

    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(NoteFileNode.fromMap)
        .toList();
  }

  Future<String> readText({required String uri}) async {
    final result = await _channel.invokeMethod<String>('readText', {'uri': uri});
    return result ?? '';
  }

  Future<void> writeText({required String uri, required String content}) async {
    await _channel.invokeMethod<void>('writeText', {
      'uri': uri,
      'content': content,
    });
  }

  Future<String?> createFile({
    required String treeUri,
    required String parentUri,
    required String name,
    String mimeType = 'text/markdown',
  }) {
    return _channel.invokeMethod<String>('createFile', {
      'treeUri': treeUri,
      'parentUri': parentUri,
      'name': name,
      'mimeType': mimeType,
    });
  }

  Future<String?> createDirectory({
    required String treeUri,
    required String parentUri,
    required String name,
  }) {
    return _channel.invokeMethod<String>('createDirectory', {
      'treeUri': treeUri,
      'parentUri': parentUri,
      'name': name,
    });
  }

  Future<String?> ensureDirectory({
    required String treeUri,
    required String parentUri,
    required String name,
  }) {
    return _channel.invokeMethod<String>('ensureDirectory', {
      'treeUri': treeUri,
      'parentUri': parentUri,
      'name': name,
    });
  }

  Future<String?> findChild({
    required String treeUri,
    required String parentUri,
    required String name,
  }) {
    return _channel.invokeMethod<String>('findChild', {
      'treeUri': treeUri,
      'parentUri': parentUri,
      'name': name,
    });
  }

  Future<void> deleteDocument({required String uri}) {
    return _channel.invokeMethod<void>('deleteDocument', {'uri': uri});
  }

  Future<String?> renameDocument({
    required String uri,
    required String newName,
  }) {
    return _channel.invokeMethod<String>('renameDocument', {
      'uri': uri,
      'newName': newName,
    });
  }

  Future<Map<Object?, Object?>?> getDocumentInfo({
    required String treeUri,
    required String uri,
  }) {
    return _channel.invokeMethod<Map<Object?, Object?>>('getDocumentInfo', {
      'treeUri': treeUri,
      'uri': uri,
    });
  }

  void logError(Object error, StackTrace stackTrace) {
    debugPrint('SAF error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
