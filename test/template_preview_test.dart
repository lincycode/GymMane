import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/program_templates.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/screens/program_template_sheet.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.onboarded = true;
    fit.setLanguage('en');
    fit.calmMotion = true;
    fit.route = 'routines';
  });

  tearDown(() {
    if (fit.session != null) fit.saveAndExit();
    setAppLanguage('en');
  });

  ProgramTemplate template(String id) => kProgramTemplates.firstWhere((p) => p.id == id);

  test('all ten templates resolve completely without changing stored data', () {
    final before = jsonEncode(fit.toJson());
    expect(kProgramTemplates, hasLength(10));
    for (final source in kProgramTemplates) {
      final preview = fit.previewTemplate(source);
      expect(preview.canApply, isTrue, reason: source.name);
      expect(preview.missing, isEmpty, reason: source.name);
      expect(preview.days.length, source.days.length);
      expect(preview.routineCount, greaterThan(0));
    }
    expect(jsonEncode(fit.toJson()), before);
  });

  test('unmatched exercises prevent the entire template from being added', () {
    const broken = ProgramTemplate('broken', 'Missing', [
      ProgramDay('A', [('Barbell Bench Press', 3)], weekday: 1),
      ProgramDay('B', [('Missing exercise 123', 3)], weekday: 3),
    ]);
    final before = jsonEncode(fit.toJson());
    expect(fit.previewTemplate(broken).missing, ['Missing exercise 123']);
    expect(fit.applyTemplate(broken, schedule: true), 0);
    expect(jsonEncode(fit.toJson()), before);
  });

  test('empty templates do not write data', () {
    const empty = ProgramTemplate('empty', 'Empty', []);
    final before = jsonEncode(fit.toJson());
    expect(fit.applyTemplate(empty), 0);
    expect(jsonEncode(fit.toJson()), before);
  });

  test('the explicit add-only option leaves an empty week empty', () {
    final preview = fit.previewTemplate(template('rr'));
    expect(fit.applyTemplate(template('rr'), schedule: false), preview.routineCount);
    expect(fit.routines, hasLength(1));
    expect(fit.weeklyPlan, isEmpty);
    expect(fit.sessions, isEmpty);
  });

  test('a confirmed empty fixed week follows the template and survives restore', () {
    final preview = fit.previewTemplate(template('rr'));
    fit.savePlanAs('Personal week', empty: true);
    expect(fit.applyTemplate(template('rr'), schedule: true), preview.routineCount);
    final routine = fit.routines.single;
    expect(fit.weeklyPlan, {1: routine.id, 3: routine.id, 5: routine.id});
    expect(routine.exerciseIds, preview.days.first.exercises.map((e) => e.$1.id));
    for (final (exercise, sets) in preview.days.first.exercises) {
      expect(fit.routineSets(routine, exercise.id), sets);
    }
    final backup = fit.toJson();
    fit.resetAllData();
    fit.applyBackup(backup);
    expect(fit.routines, hasLength(1));
    expect(fit.weeklyPlan.values.toSet(), {routine.id});
    expect(fit.savedPlansLive.single.week, fit.weeklyPlan);
    expect(fit.sessions, isEmpty);
  });

  test('explicit scheduling cannot overwrite an existing week or date override', () {
    final id = fit.createRoutine('Existing');
    fit.assignRoutineToDay(2, id);
    fit.planMoves['2026-11-20'] = [id];
    fit.savePlanAs('Existing week');
    final week = Map.of(fit.weeklyPlan);
    final moves = jsonEncode(fit.planMoves);
    expect(fit.canScheduleTemplate, isFalse);
    fit.applyTemplate(template('ppl'), schedule: true);
    expect(fit.weeklyPlan, week);
    expect(jsonEncode(fit.planMoves), moves);
    expect(fit.savedPlansLive.single.week, week);
  });

  test('rotation and its current step survive even if scheduling is requested', () {
    final id = fit.createRoutine('Next');
    fit.rotation = true;
    fit.rotationIds.add(id);
    fit.rotationNextId = id;
    expect(fit.canScheduleTemplate, isFalse);
    fit.applyTemplate(template('ppl'), schedule: true);
    expect(fit.rotation, isTrue);
    expect(fit.rotationIds, [id]);
    expect(fit.rotationNextId, id);
    expect(fit.weeklyPlan, isEmpty);
  });

  Future<void> openPreview(WidgetTester tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-create-from-template')));
    await tester.pumpAndSettle();
    final templateCard = find.byKey(const ValueKey('plan-template-fullbody'));
    await tester.ensureVisible(templateCard);
    await tester.tap(templateCard);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('program-template-preview')), findsOneWidget);
  }

  testWidgets('opening and canceling a template never creates routines', (tester) async {
    await openPreview(tester);
    expect(fit.routines, isEmpty);
    expect(fit.weeklyPlan, isEmpty);
    final context = tester.element(find.byType(ProgramTemplateSheet));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(fit.routines, isEmpty);
    expect(fit.sessions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated confirmation adds the template once', (tester) async {
    await openPreview(tester);
    final confirm = find.byKey(const ValueKey('template-confirm-add'));
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 700));
    expect(fit.routines.length, fit.previewTemplate(template('fullbody')).routineCount);
    expect(fit.weeklyPlan.length, 3);
    expect(fit.sessions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home exposes plan management with no saved routines', (tester) async {
    fit.route = 'home';
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('home-manage-plan'));
    expect(action, findsOneWidget);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(fit.route, 'routines');
    expect(find.byKey(const ValueKey('plan-create-from-template')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('Chinese template preview fits a narrow screen with large text, dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      fit.setLanguage('zh');
      fit.setTextSize('large');
      dark ? fit.setThemeDark() : fit.setThemeLight();
      await openPreview(tester);
      final confirm = find.byKey(const ValueKey('template-confirm-add'));
      expect(confirm.hitTestable(), findsOneWidget);
      final scope = find.byKey(const ValueKey('template-schedule-week'));
      await tester.ensureVisible(scope);
      await tester.tap(scope);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(fit.routines, hasLength(1));
      expect(fit.weeklyPlan, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an incomplete preview identifies the missing exercise and disables adding', (tester) async {
    const broken = ProgramTemplate('broken', 'Missing', [
      ProgramDay('A', [('Missing exercise 123', 3)]),
    ]);
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(const ValueKey('plan-create-from-template')));
    showProgramTemplatePreview(context, broken);
    await tester.pumpAndSettle();
    expect(find.text('Missing exercise 123'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(find.byKey(const ValueKey('template-confirm-add')));
    expect(confirm.onPressed, isNull);
    expect(fit.routines, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
