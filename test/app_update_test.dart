import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/screens/app_update_dialog.dart';
import 'package:gymmane/services/app_update.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apk = 'EnoGym-2.1.0-own.7-Ace6T-arm64-v8a-release.apk';
final _hash = List.filled(64, 'a').join();
Map<String, dynamic> _manifest() => {
  'schemaVersion': 1,
  'applicationId': updateAppId,
  'versionName': '2.1.0-own.7',
  'versionCode': 72,
  'minSdk': 24,
  'abi': 'arm64-v8a',
  'apkName': _apk,
  'size': 4,
  'sha256': _hash,
};
Map<String, dynamic> _release() => {
  'tag_name': 'enogym-v2.1.0-own.7',
  'draft': false,
  'prerelease': false,
  'body': 'Test release notes',
  'assets': [
    for (final name in [_apk, updateManifestName])
      {
        'name': name,
        'state': 'uploaded',
        'size': 4,
        'browser_download_url':
            'https://github.com/$updateRepository/releases/download/enogym-v2.1.0-own.7/$name',
      },
  ],
};
Map<String, Object> _installed(String path, {int code = 62}) => {
  'packageName': updateAppId,
  'versionCode': code,
  'sdk': 37,
  'abis': ['arm64-v8a'],
  'cachePath': path,
};

class _Headers extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes, {this.statusCode = 200, int? length}) : contentLength = length ?? bytes.length;
  final List<int> bytes;
  @override
  final int statusCode;
  @override
  final int contentLength;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.response);
  final _Response response;
  @override
  final headers = _Headers();
  @override
  set followRedirects(bool value) {}
  @override
  Future<HttpClientResponse> close() async => response;
}

class _Client extends Fake implements HttpClient {
  _Client(this.responses);
  final List<_Response> responses;
  @override
  set connectionTimeout(Duration? value) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(responses.removeAt(0));
  @override
  void close({bool force = false}) {}
}

class _Updates extends AppUpdateService {
  AppUpdate? update;
  Object? failure;
  int installs = 0;
  bool cancelled = false;
  String result = 'opened';
  @override
  Future<AppUpdate?> check() async {
    if (failure != null) throw failure!;
    return update;
  }

  @override
  Future<void> download(AppUpdate update, void Function(int, int) progress) async => progress(4, 4);
  @override
  Future<String> install(AppUpdate update) async {
    installs++;
    return result;
  }

  @override
  void cancel() {
    cancelled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final methods = <String>[];
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('enogym-update-test-');
    methods.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      AppUpdateService.channel,
      (call) async {
        methods.add(call.method);
        if (call.method == 'info') return _installed(directory.path);
        if (call.method == 'verify') {
          expect(call.arguments['fileName'], '$_hash.apk');
          expect(call.arguments['versionCode'], 72);
          return null;
        }
        return 'opened';
      },
    );
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    setAppLanguage('en');
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      AppUpdateService.channel,
      null,
    );
    await directory.delete(recursive: true);
    if (fit.session != null) fit.saveAndExit();
    setAppLanguage('en');
  });

  AppUpdate parse([Map<String, dynamic>? manifest, Map<String, dynamic>? release]) => AppUpdate.fromRelease(
    release ?? _release(),
    manifest ?? _manifest(),
    InstalledUpdateApp.fromJson(_installed(directory.path)),
  );

  test('personal versions use the installed Android version code including ABI', () {
    final update = parse();
    expect(update.versionCode, 72);
    expect(update.versionName, '2.1.0-own.7');
    expect(update.apkUrl.host, 'github.com');
  });

  test('rejects wrong identity, unsupported ABI, hashes, size and inconsistent tags', () {
    for (final entry in {
      'schemaVersion': 2,
      'applicationId': 'com.gymmane.app',
      'abi': 'x86_64',
      'sha256': 'bad',
      'size': 0,
      'versionCode': '72',
      'versionName': '2.1.0',
      'apkName': '../other.apk',
    }.entries) {
      expect(
        () => parse({..._manifest(), entry.key: entry.value}),
        throwsA(isA<UpdateFailure>()),
        reason: entry.key,
      );
    }
    expect(() => parse({..._manifest(), 'minSdk': 99}), throwsA(isA<UpdateFailure>()));
    expect(() => parse(null, {..._release(), 'prerelease': true}), throwsA(isA<UpdateFailure>()));
    expect(() => parse(null, {..._release(), 'draft': true}), throwsA(isA<UpdateFailure>()));
  });

  test('rejects foreign URLs, duplicate assets, missing checksums and mismatched sizes', () {
    final release = _release();
    final assets = release['assets'] as List;
    assets[0]['browser_download_url'] =
        'https://github.com/InlitX/GymMane/releases/download/v2.1.0/GymMane.apk';
    expect(() => parse(null, release), throwsA(isA<UpdateFailure>()));
    assets[0]['browser_download_url'] = (_release()['assets'] as List)[0]['browser_download_url'];
    assets.add(assets[0]);
    expect(() => parse(null, release), throwsA(isA<UpdateFailure>()));
    expect(() => parse({..._manifest(), 'size': 8}), throwsA(isA<UpdateFailure>()));
    expect(() => parse({..._manifest()}..remove('sha256')), throwsA(isA<UpdateFailure>()));
    expect(AppUpdateService.allowedDownloadUri(Uri.parse('http://github.com/a')), isFalse);
    expect(AppUpdateService.allowedDownloadUri(Uri.parse('https://github.com.evil.test/a')), isFalse);
    expect(AppUpdateService.allowedDownloadUri(Uri.parse('https://user@github.com/a')), isFalse);
  });

  test('check and streamed download verify before installation and reuse verified cache', () async {
    final client = _Client([
      _Response(utf8.encode(jsonEncode(_release()))),
      _Response(utf8.encode(jsonEncode(_manifest()))),
      _Response([1, 2, 3, 4]),
    ]);
    await HttpOverrides.runZoned(() async {
      final service = AppUpdateService();
      final update = (await service.check())!;
      await service.download(update, (_, total) => expect(total, 4));
      expect(methods, ['info', 'verify']);
      expect(await File('${directory.path}/${update.fileName}').readAsBytes(), [1, 2, 3, 4]);
      await service.download(update, (_, _) => fail('Cached APK must not be downloaded again'));
      expect(methods, ['info', 'verify', 'verify']);
      await service.install(update);
      expect(methods.last, 'install');
    }, createHttpClient: (_) => client);
  });

  test('truncated downloads are deleted and never sent to installer', () async {
    final client = _Client([
      _Response([1, 2], length: -1),
    ]);
    await HttpOverrides.runZoned(() async {
      final service = AppUpdateService()..installed = InstalledUpdateApp.fromJson(_installed(directory.path));
      await expectLater(service.download(parse(), (_, _) {}), throwsA(isA<UpdateFailure>()));
      expect(directory.listSync(), isEmpty);
      expect(methods, isEmpty);
    }, createHttpClient: (_) => client);
  });

  test('no release and rate limiting are distinct from already up to date', () async {
    for (final status in [404, 403, 429]) {
      await HttpOverrides.runZoned(() async {
        await expectLater(
          AppUpdateService().check(),
          throwsA(
            isA<UpdateFailure>().having((e) => e.code, 'code', status == 404 ? 'noRelease' : 'rateLimit'),
          ),
        );
      }, createHttpClient: (_) => _Client([_Response([], statusCode: status)]));
    }
  });

  test('already installed version clears only the updater cache', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      AppUpdateService.channel,
      (call) async => _installed(directory.path, code: 72),
    );
    await File('${directory.path}/old.apk').writeAsBytes([1]);
    final client = _Client([
      _Response(utf8.encode(jsonEncode(_release()))),
      _Response(utf8.encode(jsonEncode(_manifest()))),
    ]);
    final before = jsonEncode(fit.toJson());
    await HttpOverrides.runZoned(() async {
      expect(await AppUpdateService().check(), isNull);
      expect(directory.listSync(), isEmpty);
      expect(jsonEncode(fit.toJson()), before);
    }, createHttpClient: (_) => client);
  });

  test('cancelled download never verifies or leaves a partial APK', () async {
    await HttpOverrides.runZoned(
      () async {
        final service = AppUpdateService()
          ..installed = InstalledUpdateApp.fromJson(_installed(directory.path));
        await expectLater(
          service.download(parse(), (_, _) => service.cancel()),
          throwsA(isA<UpdateFailure>().having((e) => e.code, 'code', 'cancelled')),
        );
        expect(methods, isEmpty);
        expect(directory.listSync(), isEmpty);
      },
      createHttpClient: (_) => _Client([
        _Response([1, 2, 3, 4]),
      ]),
    );
  });

  Future<void> dialog(WidgetTester tester, _Updates service) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AppUpdateDialog(service: service),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('download requires explicit install and explains the permission return path', (tester) async {
    final service = _Updates()
      ..update = parse()
      ..result = 'permission';
    await dialog(tester, service);
    await tester.tap(find.byKey(const ValueKey('download-update')));
    await tester.pumpAndSettle();
    expect(service.installs, 0);
    await tester.tap(find.byKey(const ValueKey('install-update')));
    await tester.pumpAndSettle();
    expect(service.installs, 1);
    expect(find.text(t.ownUpdatePermission), findsOneWidget);
    await tester.tap(find.text(t.done));
    await tester.pumpAndSettle();
    expect(service.cancelled, isTrue);
  });

  testWidgets('small screen with large Chinese text remains usable on network failure', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    setAppLanguage('zh');
    await dialog(tester, _Updates()..failure = const UpdateFailure('network'));
    expect(find.text(t.ownUpdateNetworkError), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an active workout blocks installation without changing workout records', (tester) async {
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    expect(fit.session, isNotNull);
    final session = fit.session;
    final service = _Updates()..update = parse();
    await dialog(tester, service);
    await tester.tap(find.byKey(const ValueKey('download-update')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('install-update')));
    await tester.pumpAndSettle();
    expect(service.installs, 0);
    expect(fit.session, same(session));
    expect(find.text(t.ownUpdateTraining), findsOneWidget);
    fit.saveAndExit();
    await tester.pumpAndSettle();
  });
}
