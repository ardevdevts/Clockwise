import 'package:flutter_riverpod/flutter_riverpod.dart';

// Selected folder (null = all notes, 'pinned' = pinned, 'favorites' = favorites)
final selectedFolderProvider = StateProvider<String?>((ref) => null);

// Selected tag filter
final selectedTagProvider = StateProvider<String?>((ref) => null);
