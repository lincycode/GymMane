import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/note.dart';
import 'package:gymmane/services/auto_backup.dart';
import 'package:gymmane/services/backup_zip.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/media_store.dart';
import 'package:gymmane/services/progress_reminder.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late AutoBackup backup;
  late Map<String, Uint8List> files;
  late int reads;
  const channel = MethodChannel('gymmane/backup');
  const paths = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('enogym-auto-sync-');
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    MediaStore.directory = temp.path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(paths,
        (call) async => temp.path);
    ProgressReminder.instance.enabled = false;
    fit.resetAllData();
    backup = AutoBackup.forTesting()..folderUri = 'content://synthetic-sync';
    backup.setSyncEnabled(true);
    files = {};
    reads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      final args = call.arguments as Map;
      switch (call.method) {
        case 'write':
          files[args['name'] as String] = await File(args['path'] as String).readAsBytes();
          return true;
        case 'list':
          return files.keys.toList();
        case 'read':
          reads++;
          await File(args['path'] as String).writeAsBytes(files[args['name']]!);
          return true;
        default:
          throw StateError('Unexpected method ${call.method}');
      }
    });
  });

  tearDown(() async {
    fit.persistNow();
    backup.dispose();
    MediaStore.directory = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(paths, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });

  test('pull preserves unbacked local edits while adding new remote records', () async {
    fit.updateProfile(name: 'Remote');
    fit.saveNote(
      exerciseId: '',
      date: DateTime(2026, 11, 12),
      kind: NoteKind.note,
      text: 'New remote record',
    );
    final zip = await buildBackupZip();
    fit.resetAllData();
    expect(await backup.run(), isTrue);
    backup.lastAt = DateTime.now().subtract(const Duration(hours: 2));
    files[syncName('server', DateTime.now().subtract(const Duration(hours: 1)))] = zip;
    fit.updateProfile(name: 'New local edit');
    expect(await backup.pull(), 1);
    expect(fit.profile.name, 'New local edit');
    expect(fit.notes.single.text, 'New remote record');
  });

  test('a newer snapshot can update a clean local state and is not pulled twice', () async {
    fit.updateProfile(name: 'Remote');
    final zip = await buildBackupZip();
    fit.updateProfile(name: 'Backed up local');
    expect(await backup.run(), isTrue);
    backup.lastAt = DateTime.now().subtract(const Duration(hours: 2));
    files[syncName('server', DateTime.now().subtract(const Duration(hours: 1)))] = zip;
    expect(await backup.pull(), 1);
    expect(fit.profile.name, 'Remote');
    expect(await backup.pull(), 0);
    expect(reads, 1);
  });

  test('a failed snapshot remains retryable under the same filename', () async {
    fit.saveNote(exerciseId: '', date: DateTime(2026, 11, 12), kind: NoteKind.note, text: 'Recovered');
    final zip = await buildBackupZip();
    fit.resetAllData();
    final name = syncName('server', DateTime.now());
    files[name] = Uint8List.fromList([1, 2, 3]);
    expect(await backup.pull(), 0);
    files[name] = zip;
    expect(await backup.pull(), 1);
    expect(reads, 2);
    expect(fit.notes.single.text, 'Recovered');
  });

  test('a skipped unchanged backup does not advance the snapshot timestamp', () async {
    expect(await backup.run(), isTrue);
    final before = DateTime.now().subtract(const Duration(hours: 1));
    backup.lastAt = before;
    expect(await backup.run(), isTrue);
    expect(backup.lastAt, before);
  });
}
