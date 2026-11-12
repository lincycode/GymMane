import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/own_build.dart';
import '../l10n/l10n.dart';
import '../services/changelog.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

const _upstreamUrl = 'https://github.com/InlitX/GymMane';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  late final _notes = Changelog.load(
    rootBundle,
    installedVersion: ownAppVersion,
    chinese: appLanguage == 'zh',
  );
  bool _upstream = false;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Scaffold(
      backgroundColor: gc.bg,
      appBar: AppBar(
        title: Text(
          t.ownChangelog,
          style: AppTheme.f(22, weight: FontWeight.w800, color: gc.text),
        ),
        backgroundColor: gc.bg,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: FutureBuilder<Changelog>(
              future: _notes,
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _ProjectTab(
                              name: ownAppName,
                              version: ownAppVersion,
                              caption: t.ownChangelogInstalled,
                              selected: !_upstream,
                              onTap: () => setState(() => _upstream = false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProjectTab(
                              name: 'GymMane',
                              version: snapshot.data?.upstream.firstOrNull?.version ?? '—',
                              caption: t.ownChangelogBundled,
                              selected: _upstream,
                              onTap: () => setState(() => _upstream = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: _history(snapshot)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _history(AsyncSnapshot<Changelog> snapshot) {
    final gc = context.gc;
    final data = snapshot.data;
    final notes = _upstream ? data?.upstream : data?.personal;
    final repo = _upstream ? _upstreamUrl : ownSourceUrl;
    return ListView(
      key: PageStorageKey(_upstream ? 'upstream-releases' : 'personal-releases'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _open('$repo/releases'),
            icon: const Icon(PhosphorIconsRegular.arrowUpRight, size: 16),
            label: Text(t.ownChangelogGitHub),
            style: TextButton.styleFrom(
              foregroundColor: gc.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 48),
            ),
          ),
        ),
        if (_upstream && data != null && data.upstreamVersion.isNotEmpty) ...[
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            radius: 16,
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t.ownChangelogMerged, style: AppTheme.f(13, color: gc.textSecondary)),
                Ltr(
                  child: Text(
                    [
                      'v${data.upstreamVersion}',
                      if (data.upstreamCommit.isNotEmpty) data.upstreamCommit,
                    ].join(' · '),
                    style: AppTheme.f(14, weight: FontWeight.w800, color: gc.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (snapshot.connectionState != ConnectionState.done)
          const Center(child: CircularProgressIndicator())
        else if (notes == null || notes.isEmpty)
          Text(t.ownChangelogUnavailable, style: AppTheme.s(14, color: gc.textSecondary))
        else
          for (var i = 0; i < notes.length; i++)
            _ReleaseEntry(note: notes[i], first: i == 0, last: i == notes.length - 1),
      ],
    );
  }

  Future<void> _open(String url) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cantOpenLink)));
    }
  }
}

class _ProjectTab extends StatelessWidget {
  const _ProjectTab({
    required this.name,
    required this.version,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String version;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final foreground = selected ? gc.onEmber : gc.text;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? gc.ember : gc.bgRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: 0.12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.f(14, weight: FontWeight.w800, color: foreground),
                ),
                const SizedBox(height: 8),
                Text(
                  version,
                  textDirection: TextDirection.ltr,
                  style: AppTheme.f(24, weight: FontWeight.w800, color: foreground),
                ),
                const SizedBox(height: 5),
                Text(
                  caption,
                  style: AppTheme.f(
                    12,
                    color: selected ? foreground.withValues(alpha: 0.82) : gc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseEntry extends StatelessWidget {
  const _ReleaseEntry({required this.note, required this.first, required this.last});

  final ReleaseNote note;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final date = note.date;
    return Stack(
      children: [
        if (!first || !last)
          PositionedDirectional(
            start: 4,
            top: first ? 13 : 0,
            bottom: last ? null : 0,
            height: last ? 13 : null,
            child: SizedBox(width: 1, child: ColoredBox(color: gc.border)),
          ),
        PositionedDirectional(
          start: 0,
          top: 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: first ? gc.accent : gc.bg,
              shape: BoxShape.circle,
              border: Border.all(color: first ? gc.accent : gc.textSecondary),
            ),
            child: const SizedBox.square(dimension: 9),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 23, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'v${note.version}',
                      textDirection: TextDirection.ltr,
                      style: AppTheme.f(first ? 23 : 18, weight: FontWeight.w800, color: gc.text),
                    ),
                    if (date != null)
                      Text(t.shortDateYear(date), style: AppTheme.f(12, color: gc.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final line in note.highlights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 8, end: 9),
                        child: Icon(PhosphorIconsFill.circle, size: 4, color: gc.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: AppTheme.s(14, weight: FontWeight.w500, color: gc.text, height: 1.55),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
