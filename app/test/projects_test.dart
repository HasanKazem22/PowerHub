import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/data/backup/backup_service.dart';
import 'package:powerhub/data/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('save, update keeps the creation date, newest change first', () async {
    final a = await db.saveProject(name: 'Rahman Tower', module: 'load', inputs: {'mdbDiv': 2}, summary: '250 A');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final b = await db.saveProject(name: 'Mill substation', module: 'substation', inputs: {}, summary: '1 × 630 kVA');
    expect((await db.watchProjects().first).map((p) => p.id), [b, a]);

    final created = (await db.getProject(a))!.createdAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.saveProject(id: a, name: 'Rahman Tower', module: 'load', inputs: {'mdbDiv': 3}, summary: '200 A');
    final updated = (await db.getProject(a))!;
    expect(updated.createdAt, created);
    expect(AppDatabase.decodeInputs(updated.inputs), {'mdbDiv': 3});
    expect(updated.summary, '200 A');
    expect((await db.watchProjects().first).first.id, a);
  });

  test('rename, duplicate, delete', () async {
    final id = await db.saveProject(name: 'Site A', module: 'pf', inputs: {'kw': 300}, summary: '96 kVAR');
    await db.renameProject(id, '  Site B  ');
    expect((await db.getProject(id))!.name, 'Site B');

    final copy = await db.duplicateProject((await db.getProject(id))!);
    final c = (await db.getProject(copy))!;
    expect(c.name, 'Site B (copy)');
    expect(AppDatabase.decodeInputs(c.inputs), {'kw': 300});

    await db.deleteProject(id);
    expect(await db.getProject(id), isNull);
    expect((await db.watchProjects().first).length, 1);
  });

  test('a long name still fits when copied', () async {
    final id = await db.saveProject(name: 'x' * 80, module: 'pf', inputs: {}, summary: '');
    final copy = (await db.getProject(await db.duplicateProject((await db.getProject(id))!)))!;
    expect(copy.name.length, lessThanOrEqualTo(80));
    expect(copy.name, endsWith('(copy)'));
  });

  test('damaged inputs JSON opens with defaults instead of failing', () {
    expect(AppDatabase.decodeInputs('{not json'), isEmpty);
    expect(AppDatabase.decodeInputs('[1,2]'), isEmpty);
  });

  test('drafts: one per calculator, and deleting its project unlinks it', () async {
    final id = await db.saveProject(name: 'P', module: 'motor', inputs: {}, summary: '');
    await db.saveDraft('motor', {'p': 15}, projectId: id);
    await db.saveDraft('motor', {'p': 22}, projectId: id);
    expect(AppDatabase.decodeInputs((await db.getDraft('motor'))!.inputs), {'p': 22});

    await db.deleteProject(id);
    final draft = (await db.getDraft('motor'))!;
    expect(draft.projectId, isNull);
    expect(AppDatabase.decodeInputs(draft.inputs), {'p': 22}, reason: 'the work in progress is kept');

    await db.clearDraft('motor');
    expect(await db.getDraft('motor'), isNull);
  });

  test('backup carries projects and the name, not drafts or this phone\'s settings', () async {
    await db.saveProject(name: 'Keep me', module: 'solar', inputs: {'E': 30}, summary: '8 kWp');
    await db.saveDraft('solar', {'E': 99});
    await db.setSettings({SettingKeys.userName: 'Hasan', SettingKeys.onboardingDone: '1'});
    final snap = await BackupService(db).snapshot();
    expect(snap.json, contains('Keep me'));
    expect(snap.json, contains('Hasan'));
    expect(snap.json, isNot(contains('"E": 99')));
    expect(snap.json, isNot(contains(SettingKeys.onboardingDone)));

    // Same data, same fingerprint: a new draft alone doesn't trigger an upload.
    await db.saveDraft('motor', {'p': 1});
    expect((await BackupService(db).snapshot()).fingerprint, snap.fingerprint);

    // Restore into another phone.
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await other.setSetting(SettingKeys.onboardingDone, '1');
    await BackupService(other).restore(snap.json);
    final projects = await other.watchProjects().first;
    expect(projects.single.name, 'Keep me');
    expect(await other.getSetting(SettingKeys.userName), 'Hasan');
    expect(await other.getSetting(SettingKeys.onboardingDone), '1', reason: 'this phone\'s own setting is kept');
  });

  test('a BearTrack backup is refused, not restored into PowerHub', () async {
    const bearTrack = '{"format":"beartrack-backup","schemaVersion":4,"tables":{"accounts":[]}}';
    expect(() => BackupService.countRows(bearTrack), throwsA(isA<BackupFormatException>()));
  });
}
