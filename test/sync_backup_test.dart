import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/models/note.dart';
import 'package:gymmane/services/backup_zip.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/media_store.dart';
import 'package:gymmane/services/progress_reminder.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    tmp = await Directory.systemTemp.createTemp('enogym-sync-');
    MediaStore.directory = tmp.path;
    ProgressReminder.instance.enabled = false;
    fit.resetAllData();
  });
  tearDown(() async {
    fit.persistNow();
    MediaStore.directory = null;
    await tmp.delete(recursive: true);
  });
  Uint8List noteZip() {
    fit.saveNote(
      exerciseId: kExercises.first.id,
      date: DateTime(2026, 11, 12),
      kind: NoteKind.note,
      text: 'synthetic remote note',
      media: ['remote-note.png'],
    );
    final data = jsonDecode(jsonEncode(Store.finite(fit.toJson()))) as Map<String, dynamic>;
    data['noteMedia'] = {'remote-note.png': 'media/notes/note.png'};
    final archive = Archive()
      ..addFile(ArchiveFile.string('gymmane.json', jsonEncode(data)))
      ..addFile(ArchiveFile.noCompress('media/notes/note.png', 4, [1, 2, 3, 4]));
    fit.resetAllData();
    return ZipEncoder().encodeBytes(archive);
  }

  test('newer snapshot must be able to turn background blur back on', () async {
    fit.setBlur(true);
    final remote = await buildBackupZip();
    fit.setBlur(false);
    final result = await mergeBackupZip(remote, incomingNewer: true);
    expect(result, isTrue);
    expect(fit.blurOn, true);
  });
  test('newer snapshot must be able to turn reduced motion back off', () async {
    fit.setCalmMotion(false);
    final remote = await buildBackupZip();
    fit.setCalmMotion(true);
    await mergeBackupZip(remote, incomingNewer: true);
    expect(fit.calmMotion, false);
  });
  test('failed media write must reject snapshot so it can be retried', () async {
    final zip = noteZip();
    final blocker = File('${tmp.path}/not-a-directory')..writeAsStringSync('synthetic');
    MediaStore.directory = blocker.path;
    final result = await mergeBackupZip(zip, incomingNewer: true);
    expect(result, isNull);
    expect(fit.notes, isEmpty);
  });
  test('same note photo in successive snapshots must reuse the local media', () async {
    final zip = noteZip();
    await mergeBackupZip(zip, incomingNewer: true);
    final first = fit.notes.single.media.single;
    final original = ZipDecoder().decodeBytes(zip);
    final data =
        jsonDecode(utf8.decode(original.findFile('gymmane.json')!.readBytes()!)) as Map<String, dynamic>;
    (data['profile'] as Map)['name'] = 'Remote newer snapshot';
    final newer = Archive()..addFile(ArchiveFile.string('gymmane.json', jsonEncode(data)));
    for (final file in original.files) {
      if (file.name != 'gymmane.json') newer.addFile(file);
    }
    await mergeBackupZip(ZipEncoder().encodeBytes(newer), incomingNewer: true);
    final second = fit.notes.single.media.single;
    expect(second, first);
    expect(MediaStore.names(), hasLength(1));
  });
  test('a local edit during media copy must survive', () async {
    final zip = noteZip();
    final merging = mergeBackupZip(zip, incomingNewer: true);
    scheduleMicrotask(() => fit.updateProfile(name: 'Local edit during import'));
    final result = await merging;
    expect(result, isNull);
    expect(fit.profile.name, 'Local edit during import');
    expect(fit.notes, isEmpty);
    expect(MediaStore.names(), isEmpty);
  });
  test('missing archive media rejects the whole snapshot and rolls back new files', () async {
    final zip = noteZip();
    final original = ZipDecoder().decodeBytes(zip);
    final data =
        jsonDecode(utf8.decode(original.findFile('gymmane.json')!.readBytes()!)) as Map<String, dynamic>;
    data['media'] = {'new-exercise': 'exercise.png'};
    final broken = Archive()
      ..addFile(ArchiveFile.string('gymmane.json', jsonEncode(data)))
      ..addFile(ArchiveFile.noCompress('exercise.png', 3, [5, 6, 7]));
    expect(await mergeBackupZip(ZipEncoder().encodeBytes(broken), incomingNewer: true), isNull);
    expect(fit.notes, isEmpty);
    expect(fit.exerciseMedia, isEmpty);
    expect(MediaStore.names(), isEmpty);
    expect(await mergeBackupZip(zip, incomingNewer: true), isTrue);
    expect(await MediaStore.readBytes(fit.notes.single.media.single), [1, 2, 3, 4]);
  });

  test('a remote filename cannot replace an unrelated local photo', () async {
    final zip = noteZip();
    await File('${tmp.path}/remote-note.png').writeAsBytes([9, 8, 7]);
    fit.saveNote(
      exerciseId: kExercises.first.id,
      date: DateTime(2026, 11, 11),
      kind: NoteKind.note,
      text: 'Local note',
      media: ['remote-note.png'],
    );
    expect(await mergeBackupZip(zip, incomingNewer: true), isTrue);
    final local = fit.notes.firstWhere((n) => n.text == 'Local note');
    final remote = fit.notes.firstWhere((n) => n.text == 'synthetic remote note');
    expect(local.media.single, 'remote-note.png');
    expect(await MediaStore.readBytes(local.media.single), [9, 8, 7]);
    expect(await MediaStore.readBytes(remote.media.single), [1, 2, 3, 4]);
  });
}
