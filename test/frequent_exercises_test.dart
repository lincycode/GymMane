import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Exercise _exercise(String name) => kExercises.firstWhere((e) => e.name == name);

LoggedExercise _logged(Exercise exercise, [List<LoggedSet>? sets]) =>
    LoggedExercise(exercise.id, exercise.name, exercise.primary, sets ?? [LoggedSet(8, 20)]);

LoggedSession _session(DateTime day, List<LoggedExercise> exercises, {int duration = 0}) =>
    LoggedSession(day, duration, exercises);

List<String> _visibleIds() => fit.exercisesFiltered.map((e) => e.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bench = _exercise('Barbell Bench Press');
  final dumbbellBench = _exercise('Dumbbell Bench Press');
  final row = _exercise('Barbell Bent Over Row');
  final plank = _exercise('Plank');
  final run = _exercise('Outdoor Run');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.clearExFilters();
    fit.onboarded = true;
    setAppLanguage('en');
  });

  tearDown(() {
    fit.clearExFilters();
    setAppLanguage('en');
  });

  test('counts workouts by start day and counts valid exercises once per workout', () {
    final today = DateTime(2026, 11, 11);
    fit.sessions.addAll([
      _session(shiftDays(today, -700), [_logged(bench)]),
      _session(shiftDays(today, -90), [_logged(bench)]),
      _session(shiftDays(today, -89), [_logged(bench)]),
      _session(today, [_logged(bench)], duration: 3600),
      _session(today.add(const Duration(hours: 8)), [
        _logged(bench, [LoggedSet(8, 20), LoggedSet(8, 20)]),
        _logged(bench),
        _logged(row, [LoggedSet(8, 20, kind: SetKind.warmup), LoggedSet(0, 20)]),
        _logged(dumbbellBench, [LoggedSet(0, 10, left: 8, right: 0)]),
        _logged(plank, [LoggedSet(0, 0, sec: 30)]),
        _logged(run, [LoggedSet(0, 0, km: 1.5)]),
      ]),
      _session(today.add(const Duration(hours: 19)), [_logged(bench)]),
      _session(shiftDays(today, 1), [_logged(bench)]),
    ]);

    final usage = fit.exerciseTrainingUsage(now: today);
    expect(usage[bench.id], (recent: 4, total: 6, lastTrained: today.add(const Duration(hours: 19))));
    expect(usage[row.id], isNull);
    expect(usage[dumbbellBench.id]?.recent, 1);
    expect(usage[plank.id]?.recent, 1);
    expect(usage[run.id]?.recent, 1);
    final tomorrow = fit.exerciseTrainingUsage(now: shiftDays(today, 1))[bench.id]!;
    expect(tomorrow.recent, 4);
    expect(tomorrow.total, 7);
  });

  test('sorts frequent results by count, then recency, and combines library filters', () {
    final today = DateTime.now();
    fit.sessions.addAll([
      _session(shiftDays(today, -4), [_logged(bench), _logged(dumbbellBench), _logged(row)]),
      _session(shiftDays(today, -3), [_logged(bench), _logged(row), _logged(plank)]),
      _session(shiftDays(today, -2), [_logged(dumbbellBench), _logged(row)]),
    ]);
    final original = _visibleIds();
    fit.toggleFrequentExercisesFilter();
    expect(_visibleIds(), [row.id, dumbbellBench.id, bench.id]);

    fit.setExSearch('bench press');
    fit.setZoneFilter('Chest');
    fit.setEquipmentFilter('Barbell');
    expect(_visibleIds(), [bench.id]);
    fit.toggleFavouritesFilter();
    expect(_visibleIds(), isEmpty);
    fit.toggleFavorite(bench.id);
    expect(_visibleIds(), [bench.id]);

    fit.clearExFilters();
    expect(fit.exFrequentOnly, isFalse);
    expect(_visibleIds(), original);
  });

  test('refreshes cached usage when restoring, editing, deleting and saving a workout', () {
    final today = DateTime.now();
    fit.toggleFrequentExercisesFilter();
    expect(_visibleIds(), isEmpty);

    fit.applyBackup({
      'sessions': [
        _session(shiftDays(today, -3), [_logged(bench)]).toJson(),
        _session(shiftDays(today, -2), [_logged(bench)]).toJson(),
      ],
    });
    expect(_visibleIds(), [bench.id]);

    final last = fit.sessions.last;
    fit.setLoggedReps(last.exercises.single, 0, 0);
    expect(_visibleIds(), isEmpty);
    fit.setLoggedReps(last.exercises.single, 0, 6);
    expect(_visibleIds(), [bench.id]);
    fit.deleteSession(last);
    expect(_visibleIds(), isEmpty);

    fit.startPicking();
    fit.togglePick(bench.id);
    fit.startSession();
    final set = fit.session!.exercises.single.sets.firstWhere((s) => s.counts);
    set.done = true;
    expect(_visibleIds(), isEmpty);
    fit.finishSession();
    expect(_visibleIds(), [bench.id]);
  });

  testWidgets('shows counts on narrow screens and exits the empty filter without clearing the search', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final today = DateTime.now();
    fit.sessions.addAll([
      _session(shiftDays(today, -100), [_logged(bench)]),
      _session(shiftDays(today, -2), [_logged(bench)]),
      _session(shiftDays(today, -1), [_logged(bench)]),
    ]);
    fit.setLanguage('zh');
    fit.setTextSize('large');
    fit.persistNow();
    fit.goExercises();
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    final usage = find.text('近 90 天 2 次 · 累计 3 次');
    expect(usage, findsNothing);
    await tester.tap(find.text('常练'));
    await tester.pumpAndSettle();
    expect(usage, findsOneWidget);
    expect(find.text('清除筛选'), findsNothing);

    await tester.enterText(find.byType(EditableText), 'dumbbell bench press');
    await tester.pumpAndSettle();
    expect(find.text('没有符合条件的常练动作'), findsOneWidget);
    expect(find.bySemanticsLabel('退出常练'), findsOneWidget);
    await tester.tap(find.text('退出常练'));
    await tester.pumpAndSettle();
    expect(find.text('哑铃平板卧推'), findsOneWidget);
    expect(fit.exSearch, 'dumbbell bench press');
    expect(fit.exFrequentOnly, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keeps the clear button visible while narrow filter chips scroll', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final today = DateTime.now();
    fit.sessions.addAll([
      _session(shiftDays(today, -2), [_logged(bench)]),
      _session(shiftDays(today, -1), [_logged(bench)]),
    ]);
    fit.setLanguage('zh');
    fit.setTextSize('large');
    fit.setExSearch('bench press');
    fit.setZoneFilter('Chest');
    fit.setEquipmentFilter('Barbell');
    fit.setDifficultyFilter('Intermediate');
    fit.toggleFavorite(bench.id);
    fit.toggleFavouritesFilter();
    fit.toggleFrequentExercisesFilter();
    fit.persistNow();
    fit.goExercises();
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    final reset = find.bySemanticsLabel('清除筛选');
    final strip = find.ancestor(of: find.text('常练'), matching: find.byType(SingleChildScrollView));
    expect(reset, findsOneWidget);
    expect(find.text('清除筛选'), findsNothing);
    final resetRect = tester.getRect(reset);
    expect(resetRect.right, 300);
    expect(resetRect.size, const Size(44, 44));
    final chipX = tester.getTopLeft(find.text('常练')).dx;

    await tester.drag(strip, const Offset(-170, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('常练')).dx, lessThan(chipX));
    expect(tester.getRect(reset), resetRect);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(reset, findsNothing);
    expect(fit.exSearch, isEmpty);
    expect(fit.exZoneFilter, isNull);
    expect(fit.exEquipmentFilter, isNull);
    expect(fit.exDifficultyFilter, isNull);
    expect(fit.exFavouritesOnly, isFalse);
    expect(fit.exFrequentOnly, isFalse);
    expect(fit.favorites[bench.id], isTrue);
    expect(_visibleIds().length, fit.allExercises.length);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
