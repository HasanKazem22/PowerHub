import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import 'database_location.dart';

part 'database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// A saved calculation: the user's name for it, which calculator made it, and
/// its inputs as JSON. Results are never stored; they are always worked out
/// again from the inputs, so a newer app version recalculates old projects
/// with its improved formulas.
@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// The calculator's id (see `CalcModule.id`: 'load', 'substation', …).
  TextColumn get module => text()();

  /// The calculator's inputs, JSON-encoded.
  TextColumn get inputs => text()();

  /// The headline result when it was saved ("2 × 630 kVA"), shown in History without recalculating.
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// The work in progress of each calculator, so nothing typed is lost when the
/// app closes. One row per calculator. Stays on this phone: not backed up.
@DataClassName('Draft')
class Drafts extends Table {
  TextColumn get module => text()();
  TextColumn get inputs => text()();

  /// The saved project this draft is editing, if any.
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {module};
}

/// Simple key → value preferences.
@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Keys used in [Settings].
abstract final class SettingKeys {
  /// The user's name for the Home greeting and reports (part of the backup, so it comes back on a new phone).
  static const userName = 'user_name';

  /// Company or firm printed on reports (optional).
  static const company = 'company';

  /// Set once the welcome slides have been seen or skipped.
  static const onboardingDone = 'onboarding_done';

  /// When the last backup file was saved (ISO-8601), shown on Backup & restore.
  static const lastBackupAt = 'last_backup_at';

  // Google Drive backup (data/backup/drive_backup_service.dart).
  /// Google account (email) the backups go to; empty when backup is off.
  static const driveAccount = 'drive_account';

  /// '0' when automatic backup is turned off; on otherwise.
  static const driveAuto = 'drive_auto';

  /// When the last Google Drive backup was made (ISO-8601, UTC).
  static const driveLastBackupAt = 'drive_last_backup_at';

  /// Fingerprint of the data in the last backup: automatic backup runs only when the data has changed since.
  static const driveFingerprint = 'drive_fingerprint';

  /// '1' when the backups are locked with a backup password.
  static const drivePassword = 'drive_password';

  /// A BackupErrorCode name when automatic backup can't continue without the user; empty when all is well.
  static const driveProblem = 'drive_problem';

  /// Ids of the Home tips closed with ×, comma-separated.
  static const tipsDismissed = 'tips_dismissed';

  /// Settings about this phone, not about the user's data: they are not put in backups, and a restore keeps this
  /// phone's values (restoring never turns Google backup off or changes where it goes).
  static const deviceOnly = {
    onboardingDone,
    tipsDismissed,
    lastBackupAt,
    driveAccount,
    driveAuto,
    driveLastBackupAt,
    driveFingerprint,
    drivePassword,
    driveProblem,
  };
}

@DriftDatabase(tables: [Projects, Drafts, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: AppConstants.databaseName,
              native: const DriftNativeOptions(databasePath: databasePath),
              // Only used when run in a browser (development preview). Needs
              // web/sqlite3.wasm and web/drift_worker.js; see app/README.md.
              web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
            ),
      );

  /// 1: projects, drafts, settings.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll());

  // ── Settings ─────────────────────────────────────────────

  Stream<String?> watchSetting(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).watchSingleOrNull().map((s) => s?.value);

  Future<String?> getSetting(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).map((s) => s.value).getSingleOrNull();

  /// Several settings at once, as key → value (missing keys are absent).
  Stream<Map<String, String>> watchSettings(List<String> keys) =>
      (select(settings)..where((s) => s.key.isIn(keys))).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Future<Map<String, String>> getSettings(List<String> keys) async {
    final rows = await (select(settings)..where((s) => s.key.isIn(keys))).get();
    return {for (final r in rows) r.key: r.value};
  }

  /// Saves several settings in one transaction (empty values are removed).
  Future<void> setSettings(Map<String, String> values) => transaction(() async {
    for (final e in values.entries) {
      await setSetting(e.key, e.value);
    }
  });

  /// Saves [value]; an empty value removes the setting.
  Future<void> setSetting(String key, String value) async {
    if (value.trim().isEmpty) {
      await (delete(settings)..where((s) => s.key.equals(key))).go();
    } else {
      await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value.trim()));
    }
  }

  // ── Projects (History) ───────────────────────────────────

  /// Newest change first.
  Stream<List<Project>> watchProjects() =>
      (select(projects)..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();

  Future<Project?> getProject(String id) => (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Saves a new project (no [id]) or updates one; returns its id.
  Future<String> saveProject({
    String? id,
    required String name,
    required String module,
    required Map<String, Object?> inputs,
    required String summary,
  }) async {
    final now = DateTime.now();
    final projectId = id ?? newId();
    await into(projects).insertOnConflictUpdate(
      ProjectsCompanion(
        id: Value(projectId),
        name: Value(name.trim()),
        module: Value(module),
        inputs: Value(jsonEncode(inputs)),
        summary: Value(summary),
        updatedAt: Value(now),
        // Absent on an update, so the conflict update leaves the original date alone.
        createdAt: id == null ? Value(now) : const Value.absent(),
      ),
    );
    return projectId;
  }

  Future<void> renameProject(String id, String name) =>
      (update(projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(name: Value(name.trim()), updatedAt: Value(DateTime.now())),
      );

  /// A copy named "[name] (copy)"; returns the new id.
  Future<String> duplicateProject(Project p) => saveProject(
    name: _copyName(p.name),
    module: p.module,
    inputs: decodeInputs(p.inputs),
    summary: p.summary,
  );

  Future<void> deleteProject(String id) => transaction(() async {
    await (delete(projects)..where((p) => p.id.equals(id))).go();
    // A draft that was editing it becomes a fresh, unsaved calculation.
    await (update(drafts)..where((d) => d.projectId.equals(id))).write(const DraftsCompanion(projectId: Value(null)));
  });

  static String _copyName(String name) {
    final copy = '$name (copy)';
    return copy.length <= 80 ? copy : '${name.substring(0, 80 - 7)} (copy)';
  }

  /// Inputs JSON → map; damaged JSON gives an empty map (the calculator then uses its defaults).
  static Map<String, Object?> decodeInputs(String json) {
    try {
      final v = jsonDecode(json);
      return v is Map<String, dynamic> ? v : const {};
    } on FormatException {
      return const {};
    }
  }

  // ── Drafts ───────────────────────────────────────────────

  Future<Draft?> getDraft(String module) => (select(drafts)..where((d) => d.module.equals(module))).getSingleOrNull();

  Future<void> saveDraft(String module, Map<String, Object?> inputs, {String? projectId}) =>
      into(drafts).insertOnConflictUpdate(
        DraftsCompanion.insert(
          module: module,
          inputs: jsonEncode(inputs),
          projectId: Value(projectId),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> clearDraft(String module) => (delete(drafts)..where((d) => d.module.equals(module))).go();
}
