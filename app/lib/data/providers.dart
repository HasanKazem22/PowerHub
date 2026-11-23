import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Every saved project, newest change first (History, Home's recent list).
final projectsProvider = StreamProvider<List<Project>>((ref) => ref.watch(databaseProvider).watchProjects());

/// The user's name for the greeting and reports; empty when not set.
final userNameProvider = StreamProvider<String>(
  (ref) => ref.watch(databaseProvider).watchSetting(SettingKeys.userName).map((v) => v?.trim() ?? ''),
);

/// Company printed on reports; empty when not set.
final companyProvider = StreamProvider<String>(
  (ref) => ref.watch(databaseProvider).watchSetting(SettingKeys.company).map((v) => v?.trim() ?? ''),
);
