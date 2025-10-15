import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crud.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
