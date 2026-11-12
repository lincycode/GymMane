import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/own_build.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/screens/about_screen.dart';
import 'package:gymmane/services/changelog.dart';
import 'package:gymmane/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses packaged notes and puts independent releases ahead of the old numbering', () async {
    final log = await Changelog.load(rootBundle, installedVersion: '1.0.0', chinese: true);

    expect(log.personal.map((note) => note.version), [
      '1.0.0',
      '2.1.0-own.10',
      '2.1.0-own.9',
      '2.1.0-own.8',
      '2.1.0-own.7',
    ]);
    expect(log.personal.first.highlights.single, contains('独立的版本号'));
    expect(log.personal[1].highlights.single, isNot(contains('`')));
    expect(log.personal.last.highlights.first, contains('手动检查 GitHub Releases'));
    expect(log.upstream.first.highlights, isNotEmpty);
    expect(log.upstreamVersion, isNotEmpty);
    expect(log.upstreamCommit, matches(r'^[0-9a-f]{7,40}$'));
  });

  testWidgets('About opens both histories and Android back returns to About', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: const Scaffold(body: AboutScreen()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-changelog')));
    final log = await tester.runAsync(() async {
      await tester.pump();
      // The route loads the real assets through the engine's platform channel.
      return Changelog.load(rootBundle, installedVersion: ownAppVersion, chinese: false);
    });
    await tester.pumpAndSettle();
    expect(find.text('v${log!.personal.first.version}'), findsOneWidget);

    await tester.tap(find.text('GymMane'));
    await tester.pumpAndSettle();
    expect(find.text(t.ownChangelogMerged), findsOneWidget);
    expect(find.text(t.ownChangelogGitHub), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-changelog')), findsOneWidget);
  });
}
