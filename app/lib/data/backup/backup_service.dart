import 'dart:convert';

import 'package:cryptography/cryptography.dart' show Sha256;
import 'package:drift/drift.dart';

import '../database.dart';

/// What a restore brought back.
class RestoreSummary {
  const RestoreSummary({required this.rows, required this.exportedAt});
  final int rows;
  final DateTime? exportedAt;
}

/// All data, ready to back up.
class BackupSnapshot {
  const BackupSnapshot({required this.json, required this.rows, required this.fingerprint});
  final String json;
  final int rows;

  /// SHA-256 of the data (not of when it was exported), as hex.
  final String fingerprint;
}

/// Thrown when a file is not a PowerHub backup (or is from a newer app).
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Full backup and restore of the phone's data as one JSON file.
///
/// Rows are stored as the database holds them (column → value), table by
/// table, so the format follows the schema without a hand-written mapping:
/// a backup from an older app version restores into a newer one (columns it
/// doesn't have get their defaults; columns this version doesn't know are
/// ignored). A backup from a newer schema is refused.
class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  static const format = 'powerhub-backup';

  /// Parents before children, so inserting in this order satisfies the
  /// foreign keys (and deleting in reverse order does too).
  /// Drafts are left out: they are this phone's work in progress, not saved projects.
  List<TableInfo> get _tables => [_db.projects, _db.settings];

  /// Everything, as a JSON string.
  Future<String> exportJson() async => (await snapshot()).json;

  /// Everything, as a JSON string, with a [BackupSnapshot.fingerprint] of the data: the same data always gives
  /// the same fingerprint, so automatic backup can skip uploading when nothing changed. This phone's own
  /// settings ([SettingKeys.deviceOnly]) are left out: they are not the user's data.
  Future<BackupSnapshot> snapshot() async {
    final deviceOnly = SettingKeys.deviceOnly.toList();
    final tables = <String, List<Map<String, Object?>>>{};
    var rowCount = 0;
    for (final table in _tables) {
      final name = table.actualTableName;
      final rows = table == _db.settings
          ? await _db
                .customSelect(
                  'SELECT * FROM settings WHERE key NOT IN (${List.filled(deviceOnly.length, '?').join(', ')}) '
                  'ORDER BY rowid',
                  variables: [for (final k in deviceOnly) Variable<String>(k)],
                  readsFrom: {table},
                )
                .get()
          : await _db.customSelect('SELECT * FROM $name ORDER BY rowid', readsFrom: {table}).get();
      tables[name] = [for (final r in rows) r.data];
      rowCount += rows.length;
    }
    final digest = await Sha256().hash(utf8.encode(jsonEncode({'schemaVersion': _db.schemaVersion, 'tables': tables})));
    final json = const JsonEncoder.withIndent(' ').convert({
      'format': format,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    });
    return BackupSnapshot(
      json: json,
      rows: rowCount,
      fingerprint: digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  /// Number of rows in a backup, without restoring it (for the confirmation).
  static int countRows(String json) {
    final tables = _decode(json, 1 << 30)['tables'] as Map<String, dynamic>;
    return tables.values.fold(0, (sum, rows) => sum + (rows as List).length);
  }

  /// Replaces ALL data with the backup's, in one transaction: if anything
  /// fails, nothing changes. This phone's own settings ([SettingKeys.deviceOnly]:
  /// who is signed in, Google Drive) stay as they are.
  Future<RestoreSummary> restore(String json) async {
    final data = _decode(json, _db.schemaVersion);
    final tables = data['tables'] as Map<String, dynamic>;
    final keep = SettingKeys.deviceOnly.toList();
    final keepList = List.filled(keep.length, '?').join(', ');
    var count = 0;
    await _db.transaction(() async {
      for (final table in _tables.reversed) {
        if (table == _db.settings) {
          await _db.customStatement('DELETE FROM settings WHERE key NOT IN ($keepList)', keep);
        } else {
          await _db.customStatement('DELETE FROM ${table.actualTableName}');
        }
      }
      for (final table in _tables) {
        final known = {for (final c in table.$columns) c.name};
        for (final raw in (tables[table.actualTableName] as List?) ?? const []) {
          final row = {
            for (final e in (raw as Map<String, dynamic>).entries)
              if (known.contains(e.key)) e.key: e.value,
          };
          if (row.isEmpty) continue;
          if (table == _db.settings && SettingKeys.deviceOnly.contains(row['key'])) continue;
          final columns = row.keys.toList();
          await _db.customInsert(
            'INSERT INTO ${table.actualTableName} (${columns.join(', ')}) '
            'VALUES (${List.filled(columns.length, '?').join(', ')})',
            variables: [for (final c in columns) _variable(row[c])],
            updates: {table},
          );
          count++;
        }
      }
    });
    return RestoreSummary(rows: count, exportedAt: DateTime.tryParse(data['exportedAt'] as String? ?? ''));
  }

  static Map<String, dynamic> _decode(String json, int maxSchema) {
    final Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException {
      throw const BackupFormatException('This file is not a PowerHub backup.');
    }
    if (data is! Map<String, dynamic> || data['format'] != format || data['tables'] is! Map) {
      throw const BackupFormatException('This file is not a PowerHub backup.');
    }
    final version = data['schemaVersion'];
    if (version is! int || version > maxSchema) {
      throw const BackupFormatException('This backup is from a newer PowerHub. Update the app first.');
    }
    return data;
  }

  static Variable _variable(Object? value) => switch (value) {
    null => const Variable(null),
    final int v => Variable<int>(v),
    final double v => Variable<double>(v),
    final bool v => Variable<bool>(v),
    final String v => Variable<String>(v),
    _ => Variable<String>(value.toString()),
  };
}
