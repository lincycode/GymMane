import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  test('keeps workouts from both sides and the newer settings', () {
    final phone = {
      'units': 'kg',
      'sessions': [
        {'d': '2026-11-01T10:00:00.000', 'dur': 60},
        {'d': '2026-11-03T10:00:00.000', 'dur': 50},
      ],
      'routines': [
        {'id': 'a', 'n': 'Push'},
      ],
      'live': {'ex': 1},
    };
    final web = {
      'units': 'lb',
      'sessions': [
        {'d': '2026-11-01T10:00:00.000', 'dur': 61},
        {'d': '2026-11-02T10:00:00.000', 'dur': 40},
      ],
      'routines': [
        {'id': 'a', 'n': 'Push day'},
        {'id': 'b', 'n': 'Pull'},
      ],
      'live': {'ex': 9},
      'noteMedia': {'x.jpg': 'notes/x.jpg'},
    };
    final m = mergeStates(phone, web, incomingNewer: true);
    expect(m['units'], 'lb');
    expect([for (final s in m['sessions'] as List) (s as Map)['d']],
        ['2026-11-01T10:00:00.000', '2026-11-02T10:00:00.000', '2026-11-03T10:00:00.000']);
    expect(((m['sessions'] as List).first as Map)['dur'], 61);
    expect([for (final r in m['routines'] as List) (r as Map)['n']], ['Push day', 'Pull']);
    expect(m['live'], {'ex': 1});
    expect(m.containsKey('noteMedia'), isFalse);
  });

  test('merging twice changes nothing', () {
    final a = {
      'notes': [
        {'id': '1', 't': 'a'},
      ],
      'checkins': ['x'],
    };
    final b = {
      'notes': [
        {'id': '2', 't': 'b'},
      ],
      'checkins': ['y'],
    };
    final once = mergeStates(a, b, incomingNewer: false);
    final twice = mergeStates(once, b, incomingNewer: false);
    expect(sameState(once, twice), isTrue);
    expect(once['checkins'], ['x', 'y']);
  });

  test('reads sync file names and skips its own', () {
    final at = DateTime.utc(2026, 11, 11, 9, 5, 7);
    final name = syncName('server', at);
    expect(name, 'gymmane-auto-server-2026-11-11-090507.zip');
    expect(SyncFile.parse(name)!.at, at);
    expect(SyncFile.parse('gymmane-auto-2026-11-11-090507.zip'), isNull);
    final newest = newestByDevice([
      syncName('phone', at),
      syncName('phone', at.add(const Duration(hours: 1))),
      syncName('server', at),
    ], self: 'server');
    expect(newest.keys, ['phone']);
    expect(newest['phone']!.at, at.add(const Duration(hours: 1)));
  });

  test('renames media references', () {
    final out = renameStrings(
      {
        'notes': [
          {
            'm': ['old.jpg'],
          },
        ],
      },
      {'old.jpg': 'new.jpg'},
    );
    expect(stringsIn(out), contains('new.jpg'));
  });
  test(
    'preferred defaults clear omitted preferences without dropping any records',
    () {
      final local = {
        'blur': false,
        'calm': true,
        'trainAt': 600,
        'nutrition': {
          'betaOff': true,
          'rest': {'kcal': 1000},
          'water': [
            {'id': 'local'},
          ],
        },
        'sessions': [
          {'id': 'local'},
        ],
      };
      final remote = {
        'trainAt': null,
        'nutrition': {
          'water': [
            {'id': 'remote'},
          ],
        },
        'sessions': [
          {'id': 'remote'},
        ],
      };
      final merged = mergeStates(local, remote, incomingNewer: true);
      expect(merged.containsKey('blur'), isFalse);
      expect(merged.containsKey('calm'), isFalse);
      expect(merged['trainAt'], isNull);
      expect((merged['nutrition'] as Map).containsKey('betaOff'), isFalse);
      expect((merged['nutrition'] as Map).containsKey('rest'), isFalse);
      expect((merged['nutrition'] as Map)['water'], hasLength(2));
      expect(merged['sessions'], hasLength(2));
      final reversed = mergeStates(remote, local, incomingNewer: false);
      expect(sameState(merged, reversed), isTrue);
    },
  );

  test(
    'media fingerprints are idempotent and byte collisions do not overwrite',
    () async {
      final files = <String, List<int>>{};
      Future<String?> save(List<int> bytes) => saveSyncMedia(
        bytes: bytes,
        fingerprint: 123,
        extension: 'png',
        read: (name) async => files[name],
        write: (name, data) async {
          files[name] = data;
          return true;
        },
      );
      final first = await save([1, 2]);
      expect(await save([1, 2]), first);
      final second = await save([3, 4]);
      expect(second, isNot(first));
      expect(files[first], [1, 2]);
      expect(files[second], [3, 4]);
      expect(files, hasLength(2));
    },
  );
}
