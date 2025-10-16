import 'package:flutter_riverpod/flutter_riverpod.dart';

// Selected folder (null = all notes, -1 = pinned, -2 = favorites)
final selectedFolderProvider = StateProvider<int?>((ref) => null);

// Selected tag filter
final selectedTagProvider = StateProvider<int?>((ref) => null);
