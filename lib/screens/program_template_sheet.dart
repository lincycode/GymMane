import 'package:flutter/material.dart';

import '../catalog/program_templates.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/ui_kit.dart';

Future<int?> showProgramTemplatePreview(BuildContext context, ProgramTemplate template) => showAppSheet<int>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => ProgramTemplateSheet(template: template),
);

class ProgramTemplateSheet extends StatefulWidget {
  const ProgramTemplateSheet({super.key, required this.template});

  final ProgramTemplate template;

  @override
  State<ProgramTemplateSheet> createState() => _ProgramTemplateSheetState();
}

class _ProgramTemplateSheetState extends State<ProgramTemplateSheet> {
  late bool _schedule = fit.canScheduleTemplate;
  bool _applied = false;
  bool _failed = false;

  void _apply() {
    if (_applied) return;
    setState(() => _applied = true);
    final made = fit.applyTemplate(widget.template, schedule: _schedule);
    if (made == 0) {
      setState(() {
        _applied = false;
        _failed = true;
      });
      return;
    }
    Navigator.pop(context, made);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: fit,
    builder: (context, _) {
      final gc = context.gc;
      final preview = fit.previewTemplate(widget.template);
      final canSchedule = fit.canScheduleTemplate;
      return Container(
        key: const ValueKey('program-template-preview'),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        padding: sheetPad(context),
        decoration: sheetDecoration(gc),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.templateTitle(widget.template.id, widget.template.name),
                      style: AppTheme.f(22, weight: FontWeight.w800, color: gc.text, height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.ownTemplateCreates(preview.routineCount),
                      style: AppTheme.f(14, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    if (preview.missing.isNotEmpty) ...[
                      Text(
                        t.ownTemplateMissing,
                        style: AppTheme.f(14, weight: FontWeight.w700, color: gc.warn, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preview.missing.join('\n'),
                        style: AppTheme.f(14, weight: FontWeight.w500, color: gc.text, height: 1.4),
                      ),
                    ] else if (canSchedule)
                      CheckboxListTile(
                        key: const ValueKey('template-schedule-week'),
                        value: _schedule,
                        onChanged: _applied ? null : (value) => setState(() => _schedule = value ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          t.ownTemplateSchedule,
                          style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text, height: 1.4),
                        ),
                      )
                    else
                      Text(
                        fit.rotation ? t.ownTemplateKeepRotation : t.ownTemplateKeepWeek,
                        style: AppTheme.f(14, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
                      ),
                    for (final day in preview.days) ...[
                      const SizedBox(height: 24),
                      Text(
                        day.weekday == null
                            ? t.templateDayName(day.name)
                            : '${t.weekday(day.weekday!)} · ${t.templateDayName(day.name)}',
                        style: AppTheme.f(16, weight: FontWeight.w700, color: gc.text, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      for (final (exercise, sets) in day.exercises)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  exerciseName(exercise),
                                  style: AppTheme.f(14, weight: FontWeight.w500, color: gc.text, height: 1.4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                t.setCount(sets),
                                style: AppTheme.f(
                                  14,
                                  weight: FontWeight.w600,
                                  color: gc.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (_failed) ...[
                      const SizedBox(height: 8),
                      Text(
                        t.ownTemplateMissing,
                        style: AppTheme.f(14, weight: FontWeight.w600, color: gc.warn, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('template-confirm-add'),
              onPressed: preview.canApply && !_applied ? _apply : null,
              style: FilledButton.styleFrom(
                backgroundColor: gc.ember,
                foregroundColor: gc.onEmber,
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                textStyle: AppTheme.f(15, weight: FontWeight.w700, height: 1.3),
              ),
              child: Text(t.ownTemplateAdd, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    },
  );
}
