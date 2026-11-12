// Synthetic fixture for signed APK upgrade checks. Run explicitly with GYMMANE_QA_OUTPUT.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/program_templates.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/backup_zip.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/progress_reminder.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('generate synthetic records and an eight-hour unfinished workout', () async {
    final output = Platform.environment['GYMMANE_QA_OUTPUT'];
    if (output == null) throw StateError('Set GYMMANE_QA_OUTPUT to an artifacts directory.');
    final dir = Directory(output)..createSync(recursive: true);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    ProgressReminder.instance.enabled = false;
    fit.resetAllData();
    fit.onboarded = true;
    fit.setLanguage('zh');
    fit.profile.name = 'QA · 修复验收合成记录';
    fit.setThemeLight();
    fit.setBlur(false);
    fit.setCalmMotion(true);
    fit.gamification = false;
    fit.applyTemplate(kProgramTemplates.firstWhere((p) => p.id == 'ppl'));
    fit.savePlanAs('QA 合成周计划');
    final bench = fit.matchExerciseByName('Barbell Bench Press')!;
    fit.sessions.add(LoggedSession(DateTime(2026, 11, 7, 18), 1800, [
      LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(8, 60), LoggedSet(6, 65)]),
    ], routineId: fit.routines.first.id));
    await File('${dir.path}/synthetic-backup.zip').writeAsBytes(await buildBackupZip());
    fit.startRoutine(fit.routines.first);
    fit.endCountdown();
    fit.setSessionReps(0, 0, 8);
    fit.setSessionWeight(0, 0, 72.5);
    fit.toggleSet(0, 0);
    fit.persistNow();
    final data = Store.finite(fit.toJson()) as Map<String, dynamic>;
    data['liveStart'] = DateTime.now().subtract(const Duration(hours: 8)).toIso8601String();
    data['liveElapsed'] = 125;
    data['livePaused'] = false;
    final text = jsonEncode(data);
    await File('${dir.path}/expected-state.json').writeAsString(text);
    final escaped = text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    await File('${dir.path}/synthetic-preferences.xml').writeAsString(
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map><string name="flutter.gymmane_v1">$escaped</string></map>\n',
    );
    fit.discardSession();
  });
}
