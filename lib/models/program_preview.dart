import '../catalog/program_templates.dart';
import 'exercise.dart';

class ProgramPreviewDay {
  const ProgramPreviewDay(this.name, this.exercises, this.weekday);

  final String name;
  final List<(Exercise, int)> exercises;
  final int? weekday;

  String get identity => '$name|${exercises.map((e) => '${e.$1.id}:${e.$2}').join(',')}';
}

class ProgramPreview {
  const ProgramPreview(this.template, this.days, this.missing);

  final ProgramTemplate template;
  final List<ProgramPreviewDay> days;
  final List<String> missing;

  bool get canApply => missing.isEmpty && days.isNotEmpty && days.every((d) => d.exercises.isNotEmpty);
  int get routineCount => days.map((d) => d.identity).toSet().length;
}

ProgramPreview resolveProgramTemplate(ProgramTemplate template, Exercise? Function(String) match) {
  final missing = <String>{};
  final days = <ProgramPreviewDay>[];
  for (final day in template.days) {
    final exercises = <String, (Exercise, int)>{};
    for (final (name, sets) in day.exercises) {
      final exercise = match(name);
      if (exercise == null) {
        missing.add(name);
      } else {
        exercises.putIfAbsent(exercise.id, () => (exercise, sets));
      }
    }
    days.add(ProgramPreviewDay(day.name, List.unmodifiable(exercises.values), day.weekday));
  }
  return ProgramPreview(template, List.unmodifiable(days), List.unmodifiable(missing));
}
