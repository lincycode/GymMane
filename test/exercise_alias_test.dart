import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_aliases.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/services/exercise_match.dart';

const _hevyNames = {
  'Bench Press (Barbell)': 'Barbell Bench Press',
  'Squat (Barbell)': 'Barbell Full Squat',
  'Deadlift (Barbell)': 'Barbell Deadlift',
  'Lat Pulldown (Cable)': 'Cable Pulldown',
  'Seated Row (Cable)': 'Cable Seated Row',
  'Overhead Press (Barbell)': 'Barbell Standing Wide Military Press',
  'Shoulder Press (Dumbbell)': 'Dumbbell Standing Overhead Press',
  'Lateral Raise (Dumbbell)': 'Dumbbell Lateral Raise',
  'Bicep Curl (Dumbbell)': 'Dumbbell Biceps Curl',
  'Hammer Curl (Dumbbell)': 'Dumbbell Hammer Curl',
  'Triceps Pushdown (Cable)': 'Cable Pushdown',
  'Skullcrusher (Barbell)': 'Barbell Lying Triceps Extension',
  'Romanian Deadlift (Barbell)': 'Barbell Romanian Deadlift',
  'Bulgarian Split Squat (Dumbbell)': 'Dumbbell Single Leg Split Squat',
  'Chest Fly (Machine)': 'Pec Deck',
  'Chest Press (Machine)': 'Machine Chest Press',
  'T Bar Row': 'T-Bar Row',
  'Hip Abduction (Machine)': 'Hip Abduction Machine',
  'Leg Curl (Machine)': 'Seated Leg Curl',
  'Farmers Walk': 'Kettlebell Farmer Carry',
};

List<Exercise> _search(String query) => kExercises.where(exerciseSearch(query)).toList();

void main() {
  final byName = {for (final e in kExercises) e.name: e};

  test('every alias belongs to an exercise in the catalog', () {
    final orphans = kExerciseAliases.keys.where((name) => !byName.containsKey(name));
    expect(orphans, isEmpty);
  });

  test('no two exercises claim the same alias', () {
    final owners = <String, String>{};
    final clashes = <String>[];
    for (final entry in kExerciseAliases.entries) {
      for (final alias in entry.value) {
        final owner = owners.putIfAbsent(searchKey(alias), () => entry.key);
        if (owner != entry.key) clashes.add('$alias: $owner / ${entry.key}');
      }
    }
    expect(clashes, isEmpty);
  });

  test('searching a name from another app finds the exercise', () {
    for (final entry in _hevyNames.entries) {
      expect(_search(entry.key).map((e) => e.name), contains(entry.value),
          reason: 'searching "${entry.key}" should find ${entry.value}');
    }
  });

  test('importing a name from another app maps to the same exercise', () {
    for (final entry in _hevyNames.entries) {
      expect(matchExercise(entry.key, kExercises)?.name, entry.value);
    }
  });

  test('a half-typed name still narrows down to the exercise', () {
    expect(_search('lat pulld').map((e) => e.name), contains('Cable Pulldown'));
    expect(_search('db bench').map((e) => e.name), contains('Dumbbell Bench Press'));
    expect(_search('bulgarian split').map((e) => e.name), contains('Dumbbell Single Leg Split Squat'));
  });

  test('Chinese search names resolve to the corresponding exercise variants', () {
    const queries = {
      '平板杠铃推胸': ['EIeI8Vf'],
      '坐姿器械推胸-上斜': ['incline-chest-press-machine'],
      '引体向上-反手': ['T2mxWqc'],
      '反手高位下拉': ['reverse-grip-lat-pulldown'],
      '坐姿划船': ['fUBheHs', '7I6LNUG'],
      'T杠划船': ['aaXr7ld'],
      'T型杠划船': ['aaXr7ld'],
      '坐姿器械内收': ['hip-adduction-machine'],
      '器械压腿': ['7zdxRTl'],
      '单侧绳索下拉': ['single-arm-cable-pushdown'],
    };
    for (final entry in queries.entries) {
      expect(_search(entry.key).map((e) => e.id), unorderedEquals(entry.value));
    }
    final ids = kExercises.map((e) => e.id).toSet();
    for (final entry in kChineseExerciseSearchAliases.entries) {
      expect(ids, contains(entry.key));
      for (final alias in entry.value) {
        expect(_search(alias).map((e) => e.id), contains(entry.key), reason: alias);
      }
    }
    expect(matchExercise('坐姿划船', kExercises), isNull);
  });

  test('the plain catalog name still wins on its own', () {
    expect(_search('Barbell Bench Press').map((e) => e.name), contains('Barbell Bench Press'));
    expect(_search('pec deck').single.name, 'Pec Deck');
  });

  test('the names an AI writes land on a real exercise', () {
    const written = [
      'Bench Press', 'Squat', 'Deadlift', 'Overhead Press', 'Barbell Row',
      'Lat Pulldown', 'Bicep Curl', 'Tricep Pushdown', 'Leg Press',
      'Romanian Deadlift', 'Plank', 'Face Pull', 'Pull-ups', 'Push-ups',
      'Dumbbell Shoulder Press', 'Incline Bench Press', 'Leg Curl',
      'Calf Raises', 'Lateral Raises', 'Hip Thrust', 'Cable Fly',
      'Seated Row', 'Hammer Curls', 'Skull Crushers', 'Bulgarian Split Squat',
      'Goblet Squat', 'Russian Twist', 'Mountain Climbers',
    ];
    final missed = [for (final n in written) if (matchExercise(n, kExercises) == null) n];
    expect(missed, isEmpty, reason: 'sin emparejar: ${missed.join(", ")}');
  });

  test('the order of the words does not matter for an alias', () {
    expect(matchExercise('Dumbbell Shoulder Press', kExercises)?.name,
        'Dumbbell Standing Overhead Press');
    expect(matchExercise('Shoulder Press (Dumbbell)', kExercises)?.name,
        'Dumbbell Standing Overhead Press');
  });

  test('an empty search keeps the whole catalog', () {
    expect(_search('   ').length, kExercises.length);
  });
}
