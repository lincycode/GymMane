import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/program_templates.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/backup_zip.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export explicitly synthetic data for the isolated Android emulator', () async {
    final output = Platform.environment['GYMMANE_QA_OUTPUT'];
    if (output == null) throw StateError('Set GYMMANE_QA_OUTPUT to an artifacts directory.');
    final directory = Directory(output)..createSync(recursive: true);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.onboarded = true;
    fit.setLanguage('zh');
    fit.profile.name = 'QA · 合成数据';
    fit.setThemeLight();
    fit.calmMotion = true;
    fit.gamification = false;
    String xml(String value) =>
        value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    Future<void> preferences(String name) => File('${directory.path}/$name.xml').writeAsString(
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map><string name="flutter.gymmane_v1">${xml(jsonEncode(fit.toJson()))}</string></map>\n',
    );
    await preferences('empty-preferences');
    fit.applyTemplate(kProgramTemplates.firstWhere((p) => p.id == 'ppl'));
    fit.savePlanAs('QA 周计划');
    final bench = fit.matchExerciseByName('Barbell Bench Press')!;
    fit.sessions.add(
      LoggedSession(DateTime(2026, 11, 7, 18), 1800, [
        LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(8, 60), LoggedSet(6, 65)]),
      ], routineId: fit.routines.first.id),
    );
    final data = fit.toJson();
    final json = jsonEncode(data);
    await preferences('preferences');
    await File('${directory.path}/synthetic-backup.json').writeAsString(json);
    await File('${directory.path}/synthetic-backup.zip').writeAsBytes(await buildBackupZip());
    expect(fit.sessions, hasLength(1));
    expect(fit.routines, hasLength(3));
    expect(fit.sessions.single.exercises.single.sets, hasLength(2));
  });
}
