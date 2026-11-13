import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/screens/session_screen.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/workout_import.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/ruler_picker.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
  });

  group('tabla de RPE', () {
    test('coincide con la tabla de RTS', () {
      expect(rpePercent(1, 10), 1.0);
      expect(rpePercent(5, 8), closeTo(0.811, 1e-9));
      expect(rpePercent(3, 9.5), closeTo(0.907, 1e-9));
      expect(rpePercent(12, 6), closeTo(0.574, 1e-9));
    });

    test('fuera de la tabla no se inventa nada', () {
      expect(rpePercent(5, null), isNull);
      expect(rpePercent(5, 5), isNull);
      expect(rpePercent(13, 8), isNull);
      expect(rpePercent(0, 8), isNull);
    });

    test('el 1RM usa la tabla cuando la serie lleva RPE', () {
      expect(LoggedSet(5, 100, rpe: 8).oneRm, closeTo(100 / 0.811, 1e-6));
      expect(LoggedSet(5, 100).oneRm, closeTo(100 * (1 + 5 / 30), 1e-6));
      expect(LoggedSet(15, 50, rpe: 8).oneRm, closeTo(50 * (1 + 15 / 30), 1e-6));
    });
  });

  group('RPE o RIR', () {
    test('apagado por defecto y se elige la escala', () {
      expect(fit.effortMode, '');
      fit.setEffortMode('rir');
      expect(fit.logRpe, isTrue);
      expect(fit.usesRir, isTrue);
      expect(fit.effortLabel(8), 'RIR 2');
      expect(fit.effortTag(8.5), 'R1.5');
      fit.setEffortMode('rpe');
      expect(fit.effortLabel(8), 'RPE 8');
      expect(fit.effortTag(8), '@8');
      fit.setEffortMode('');
      expect(fit.logRpe, isFalse);
      expect(fit.effortScale, 'rpe');
    });

    test('la escala se guarda en la copia', () {
      fit.setEffortMode('rir');
      final data = fit.toJson();
      fit.resetAllData();
      expect(fit.effortMode, '');
      fit.applyBackup(data);
      expect(fit.effortMode, 'rir');
    });
  });

  testWidgets('set effort takes reps left and follows the last logged set of that exercise', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    setAppLanguage('en');
    fit.setEffortMode('rpe');
    fit.setDemoSize('off');
    fit.toggleStartCountdown();
    fit.setRestSeconds(0);
    final bench = fit.exerciseById('EIeI8Vf')!;
    final raise = fit.exerciseById('v1qBec9')!;
    final routine = Routine('effort-qa', 'Effort', [bench.id, raise.id], sets: {bench.id: 5});
    fit.startRoutine(routine);
    final sets = fit.session!.exercises.first.sets;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: AnimatedBuilder(animation: fit, builder: (_, _) => SessionScreen(key: ObjectKey(fit.session))),
      ),
    ));
    await tester.pumpAndSettle();

    Future<RulerPicker> open(int exercise, int index) async {
      final cell = find.byKey(ValueKey(('session-effort', exercise, index)));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      return tester.widget<RulerPicker>(find.byType(RulerPicker));
    }

    Future<void> save() async {
      await tester.tap(find.text(titleCase(t.save)));
      await tester.pumpAndSettle();
    }

    final first = await open(0, 0);
    expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('RPE')), findsOneWidget);
    expect(find.text(t.remainingRepsTitle), findsOneWidget);
    expect(find.text('RPE 8'), findsOneWidget);
    expect(first.value, 2);
    expect(sets[0].rpe, isNull);
    await save();
    expect(sets[0].rpe, 8);
    final firstCell = tester.widget<Semantics>(find.byKey(const ValueKey(('session-effort', 0, 0))));
    expect(firstCell.properties.value, '8');

    fit.toggleSet(0, 0);
    await tester.pumpAndSettle();
    expect((await open(0, 1)).value, 2);
    await save();
    fit.toggleSet(0, 1);
    await tester.pumpAndSettle();

    (await open(0, 2)).onChanged(0);
    await tester.pumpAndSettle();
    expect(find.text('RPE 10'), findsOneWidget);
    await save();
    expect(sets[2].rpe, 10);

    expect((await open(0, 3)).value, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(sets[3].rpe, isNull);
    fit.toggleSet(0, 3);
    await tester.pumpAndSettle();
    expect((await open(0, 4)).value, 0, reason: 'skip the unrated fourth set');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    fit.goToExercise(1);
    await tester.pumpAndSettle();
    expect((await open(1, 0)).value, 2);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    fit.goToExercise(0);
    await tester.pumpAndSettle();
    expect((await open(0, 0)).value, 2, reason: 'editing a set starts at its own saved value');
    await tester.tap(find.text(t.none));
    await tester.pumpAndSettle();
    expect(sets[0].rpe, isNull);
    fit.saveAndExit();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('finishing the last set waits for effort confirmation before writing history', (tester) async {
    fit.setEffortMode('rpe');
    fit.toggleStartCountdown();
    fit.setRestSeconds(0);
    fit.startRoutine(Routine('effort-qa', 'Effort', ['EIeI8Vf'], sets: {'EIeI8Vf': 1}));
    fit.toggleSet(0, 0);
    final edit = fit.editSessionEffort(0, 0, (_, _) async {
      await Future<void>.delayed(const Duration(seconds: 5));
      return (rpe: 10.0);
    });
    await tester.pump(WorkoutState.effortDelay);
    expect(fit.session!.complete, isFalse);
    expect(fit.sessions, isEmpty);

    await tester.pump(const Duration(seconds: 2));
    await edit;
    await tester.pump(WorkoutState.finishDelay);
    expect(fit.sessions.single.exercises.single.sets.single.rpe, 10);
    fit.saveAndExit();
  });

  group('CSV', () {
    test('la exportación lleva el RPE y se vuelve a leer', () {
      final csv = Store.instance.exportCsv([
        LoggedSession(DateTime(2026, 9, 19), 1800, [
          LoggedExercise('EIeI8Vf', 'Barbell Bench Press', 'chest', [
            LoggedSet(5, 100, rpe: 8.5),
            LoggedSet(5, 100),
          ]),
        ]),
      ]);
      final rows = csv.trim().split('\n');
      expect(rows.first, endsWith(',set_type,rpe,rir,note'));
      expect(rows[1], endsWith(',normal,8.5,1.5,'));
      expect(rows[2], endsWith(',normal,,,'));

      final back = parseImport(csv);
      final sets = back.sessions.single.exercises.single.sets;
      expect(sets.first.rpe, 8.5);
      expect(sets.last.rpe, isNull);
    });

    test('la nota de la serie sale en el CSV y vuelve al importarlo', () {
      final csv = Store.instance.exportCsv([
        LoggedSession(DateTime(2026, 11, 2, 18), 3000, [
          LoggedExercise('bench', 'Bench Press', 'chest', [
            LoggedSet(5, 100, note: 'agarre, más cerrado'),
            LoggedSet(5, 100),
          ]),
        ]),
      ]);
      final sets = parseImport(csv).sessions.single.exercises.single.sets;
      expect(sets.first.note, 'agarre, más cerrado');
      expect(sets.last.note, isEmpty);
    });

    test('Hevy trae su RPE y una columna RIR se convierte', () {
      const hevy = '"title","start_time","end_time","description","exercise_title","superset_id",'
          '"exercise_notes","set_index","set_type","weight_kg","reps","distance_km","duration_seconds","rpe"\n'
          '"Push","19 Sep 2026, 10:00","19 Sep 2026, 11:00","","Bench Press (Barbell)","","",0,"normal",100,5,,,8\n';
      final hevySets = parseImport(hevy).sessions.single.exercises.single.sets;
      expect(hevySets.single.rpe, 8);

      const generic = 'date,exercise,reps,weight,rir\n2026-09-19,Squat,5,120,2\n';
      final genericSets = parseImport(generic).sessions.single.exercises.single.sets;
      expect(genericSets.single.rpe, 8);
    });
  });
}
