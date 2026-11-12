import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gymmane_server/src/state_store.dart';
import 'package:gymmane_server/src/media_store.dart';
import 'package:gymmane_server/src/phone_sync.dart';
import 'package:sync/sync.dart';
import 'package:test/test.dart';

class _GateMedia extends MediaFiles {
  _GateMedia(super.dir);
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> write(String name, List<int> bytes) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return super.write(name, bytes);
  }
}

void main() {
  late Directory tmp;
  late StateStore store;
  late MediaFiles media;
  late PhoneSync sync;
  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('enogym-sync-safety-');
    store = StateStore('${tmp.path}/data');
    await store.open();
    media = MediaFiles('${store.dir}/media');
    await media.open();
    Directory('${tmp.path}/sync').createSync();
    sync = PhoneSync(
      syncDir: '${tmp.path}/sync',
      dataDir: store.dir,
      store: store,
      media: media,
    );
  });
  tearDown(() async {
    sync.stop();
    await tmp.delete(recursive: true);
  });

  Uint8List zip(Map<String, dynamic> data, {bool photo = false}) {
    final archive = Archive()
      ..addFile(ArchiveFile.string('gymmane.json', jsonEncode(data)));
    if (photo) {
      archive.addFile(ArchiveFile.noCompress('image.png', 3, [1, 2, 3]));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  test(
    'simultaneous writes compare revisions after the preceding commit',
    () async {
      await store.write('{"value":"initial"}');
      final results = await Future.wait([
        store.write('{"value":"A"}', baseRev: 1),
        store.write('{"value":"B"}', baseRev: 1),
      ]);
      expect(results.map((r) => r.conflict), [false, true]);
      expect(store.current.rev, 2);
      final disk = StateStore(store.dir);
      await disk.open();
      expect(disk.current.text, store.current.text);
      expect(disk.current.rev, store.current.rev);
      expect(jsonDecode(disk.current.text!)['value'], 'A');
    },
  );

  test('a failed write does not poison the queue', () async {
    final blocker = Directory('${store.dir}/state.json.tmp')..createSync();
    await expectLater(
      store.write('{"value":1}'),
      throwsA(isA<FileSystemException>()),
    );
    await blocker.delete();
    expect((await store.write('{"value":2}', baseRev: 0)).conflict, isFalse);
    expect(store.current.rev, 1);
  });

  test(
    'a browser edit during phone media import survives and new media is rolled back',
    () async {
      await store.write('{"notes":[{"id":"old"}]}');
      final gate = _GateMedia(media.dir);
      sync = PhoneSync(
        syncDir: sync.syncDir,
        dataDir: store.dir,
        store: store,
        media: gate,
      );
      final incoming = zip({
        'notes': [
          {'id': 'phone'},
        ],
        'media': {'ex': 'image.png'},
      }, photo: true);
      final merging = sync.mergeZip(incoming, incomingNewer: true);
      await gate.entered.future;
      await store.write(
        '{"notes":[{"id":"old"},{"id":"new-web"}]}',
        baseRev: 1,
      );
      gate.release.complete();
      expect(await merging, isNull);
      expect(store.current.text, contains('new-web'));
      expect(Directory(media.dir).listSync(), isEmpty);
      expect(await sync.mergeZip(incoming, incomingNewer: false), isTrue);
      expect(store.current.text, contains('new-web'));
      expect(store.current.text, contains('phone'));
    },
  );

  test('a repaired snapshot with the same filename is retried', () async {
    final file = File('${sync.syncDir}/${syncName('phone', DateTime.now())}');
    await file.writeAsBytes([1, 2, 3]);
    expect(await sync.scan(), isFalse);
    await file.writeAsBytes(
      zip({
        'notes': [
          {'id': 'repaired'},
        ],
      }),
    );
    expect(await sync.scan(), isTrue);
    expect(store.current.text, contains('repaired'));
    expect(await sync.scan(), isFalse);
  });

  test(
    'missing media fails atomically and the next attempt can reuse the snapshot',
    () async {
      final data = {
        'notes': [
          {
            'id': 'phone',
            'm': ['remote.png'],
          },
        ],
        'noteMedia': {'remote.png': 'image.png'},
      };
      expect(await sync.mergeZip(zip(data), incomingNewer: true), isNull);
      expect(store.current.text, isNull);
      expect(Directory(media.dir).listSync(), isEmpty);
      expect(
        await sync.mergeZip(zip(data, photo: true), incomingNewer: true),
        isTrue,
      );
      expect(
        await sync.mergeZip(zip(data, photo: true), incomingNewer: true),
        isFalse,
      );
      expect(Directory(media.dir).listSync(), hasLength(1));
    },
  );

  test(
    'an older phone snapshot cannot replace a newer unexported browser edit',
    () async {
      await store.write('{"profile":{"name":"New web edit"}}');
      final file = File(
        '${sync.syncDir}/${syncName('phone', DateTime.now().subtract(const Duration(hours: 1)))}',
      );
      await file.writeAsBytes(
        zip({
          'profile': {'name': 'Old phone'},
          'notes': [
            {'id': 'phone'},
          ],
        }),
      );
      expect(await sync.scan(), isTrue);
      final state = jsonDecode(store.current.text!) as Map;
      expect((state['profile'] as Map)['name'], 'New web edit');
      expect(state['notes'], hasLength(1));
    },
  );
}
