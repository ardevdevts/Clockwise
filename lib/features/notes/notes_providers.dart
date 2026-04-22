import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_notes_models.dart';
import 'file_notes_repository.dart';

final fileNotesRepositoryProvider = Provider<FileNotesRepository>((ref) {
  final repository = FileNotesRepository();
  repository.initialize();
  ref.onDispose(repository.dispose);
  return repository;
});

final workspacesProvider = StreamProvider<List<NoteWorkspace>>((ref) {
  final repository = ref.watch(fileNotesRepositoryProvider);
  return repository.watchWorkspaces();
});

final selectedWorkspaceIdProvider = StateProvider<String?>((ref) => null);
final selectedFileNodeProvider = StateProvider<NoteFileNode?>((ref) => null);
