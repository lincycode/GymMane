import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const updateRepository = 'lincycode/GymMane';
const updateAppId = 'com.echolin.gymmane';
const updateManifestName = 'enogym-update.json';

class UpdateFailure implements Exception {
  const UpdateFailure(this.code);
  final String code;
}

class InstalledUpdateApp {
  InstalledUpdateApp.fromJson(Map<Object?, Object?> json)
    : packageName = json['packageName'] as String,
      versionCode = json['versionCode'] as int,
      sdk = json['sdk'] as int,
      abis = List<String>.from(json['abis'] as List),
      cachePath = json['cachePath'] as String;

  final String packageName;
  final int versionCode;
  final int sdk;
  final List<String> abis;
  final String cachePath;
}

class AppUpdate {
  const AppUpdate({
    required this.versionName,
    required this.versionCode,
    required this.size,
    required this.sha256,
    required this.apkUrl,
    required this.notes,
  });

  final String versionName;
  final int versionCode;
  final int size;
  final String sha256;
  final Uri apkUrl;
  final String notes;
  String get fileName => '$sha256.apk';

  static Uri assetUrl(Map<String, dynamic> release, String name) {
    final tag = release['tag_name'];
    if (tag is! String || release['draft'] != false || release['prerelease'] != false) {
      throw const UpdateFailure('metadata');
    }
    final assets = (release['assets'] as List).whereType<Map<String, dynamic>>();
    final matches = assets.where((a) => a['name'] == name && a['state'] == 'uploaded').toList();
    if (matches.length != 1) throw const UpdateFailure('metadata');
    final uri = Uri.parse(matches.single['browser_download_url'] as String);
    final expected = Uri.https('github.com', '/$updateRepository/releases/download/$tag/$name');
    if (uri != expected) throw const UpdateFailure('metadata');
    final id = matches.single['id'];
    final apiUrl = matches.single['url'];
    if (id is! int || id <= 0 || apiUrl is! String) throw const UpdateFailure('metadata');
    final apiUri = Uri.parse(apiUrl);
    if (apiUri != Uri.https('api.github.com', '/repos/$updateRepository/releases/assets/$id')) {
      throw const UpdateFailure('metadata');
    }
    return apiUri;
  }

  factory AppUpdate.fromRelease(
    Map<String, dynamic> release,
    Map<String, dynamic> manifest,
    InstalledUpdateApp installed,
  ) {
    final version = manifest['versionName'];
    final code = manifest['versionCode'];
    final size = manifest['size'];
    final hash = manifest['sha256'];
    final minSdk = manifest['minSdk'];
    final abi = manifest['abi'];
    final name = manifest['apkName'];
    if (manifest['schemaVersion'] != 1 ||
        manifest['applicationId'] != updateAppId ||
        installed.packageName != updateAppId ||
        version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+-own\.\d+$').hasMatch(version) ||
        release['tag_name'] != 'enogym-v$version' ||
        code is! int ||
        code <= 0 ||
        size is! int ||
        size <= 0 ||
        size > 1024 * 1024 * 1024 ||
        hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
        minSdk is! int ||
        minSdk < 24 ||
        abi != 'arm64-v8a' ||
        name != 'EnoGym-$version-Ace6T-arm64-v8a-release.apk') {
      throw const UpdateFailure('metadata');
    }
    if (installed.sdk < minSdk || !installed.abis.contains(abi)) {
      throw const UpdateFailure('incompatible');
    }
    final url = assetUrl(release, name as String);
    final asset = (release['assets'] as List).cast<Map<String, dynamic>>().singleWhere(
      (a) => a['name'] == name,
    );
    if (asset['size'] != size) throw const UpdateFailure('metadata');
    final body = release['body'];
    return AppUpdate(
      versionName: version,
      versionCode: code,
      size: size,
      sha256: hash,
      apkUrl: url,
      notes: body is String ? body.substring(0, body.length.clamp(0, 12000)) : '',
    );
  }
}

class AppUpdateService {
  static const channel = MethodChannel('enogym/updates');
  HttpClient? _client;
  bool _cancelled = false;
  InstalledUpdateApp? installed;

  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }

  HttpClient _start() {
    _cancelled = false;
    return _client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  }

  void _ensureActive() {
    if (_cancelled) throw const UpdateFailure('cancelled');
  }

  static bool allowedDownloadUri(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      (uri.host == 'api.github.com' ||
          uri.host == 'github.com' ||
          uri.host == 'release-assets.githubusercontent.com' ||
          uri.host == 'objects.githubusercontent.com');

  Future<HttpClientResponse> _get(HttpClient client, Uri uri) async {
    final asset =
        uri.host == 'api.github.com' && uri.path.startsWith('/repos/$updateRepository/releases/assets/');
    for (var redirects = 0; redirects <= 5; redirects++) {
      _ensureActive();
      if (!allowedDownloadUri(uri)) throw const UpdateFailure('metadata');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 25));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, 'EnoGym-Updater');
      request.headers.set(
        HttpHeaders.acceptHeader,
        asset ? 'application/octet-stream' : 'application/vnd.github+json',
      );
      request.headers.set('X-GitHub-Api-Version', '2022-11-28');
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final response = await request.close().timeout(const Duration(seconds: 25));
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) throw const UpdateFailure('network');
        await response.drain<void>().timeout(const Duration(seconds: 25));
        uri = uri.resolve(location);
        continue;
      }
      return response;
    }
    throw const UpdateFailure('network');
  }

  Future<Map<String, dynamic>?> _json(HttpClient client, Uri uri, {bool allowMissing = false}) async {
    final response = await _get(client, uri);
    if (allowMissing && response.statusCode == 404) return null;
    if (response.statusCode == 403 || response.statusCode == 429) throw const UpdateFailure('rateLimit');
    if (response.statusCode != 200) throw const UpdateFailure('network');
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 25))) {
      _ensureActive();
      if (bytes.length + chunk.length > 1024 * 1024) throw const UpdateFailure('metadata');
      bytes.addAll(chunk);
    }
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Future<AppUpdate?> check() async {
    final client = _start();
    try {
      installed = InstalledUpdateApp.fromJson((await channel.invokeMapMethod<Object?, Object?>('info'))!);
      if (installed!.packageName != updateAppId) throw const UpdateFailure('unsupported');
      final release = await _json(
        client,
        Uri.https('api.github.com', '/repos/$updateRepository/releases/latest'),
        allowMissing: true,
      );
      if (release == null) throw const UpdateFailure('noRelease');
      final manifest = await _json(client, AppUpdate.assetUrl(release, updateManifestName));
      final update = AppUpdate.fromRelease(release, manifest!, installed!);
      if (update.versionCode <= installed!.versionCode) {
        await _clearCache();
        return null;
      }
      return update;
    } on FormatException {
      throw const UpdateFailure('metadata');
    } on TypeError {
      throw const UpdateFailure('metadata');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _clearCache({String? keep}) async {
    final directory = Directory(installed!.cachePath);
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is File && entity.uri.pathSegments.last != keep) {
        await entity.delete();
      }
    }
  }

  Map<String, Object> _arguments(AppUpdate update) => {
    'fileName': update.fileName,
    'sha256': update.sha256,
    'versionCode': update.versionCode,
    'versionName': update.versionName,
    'size': update.size,
  };

  Future<void> download(AppUpdate update, void Function(int received, int total) progress) async {
    final client = _start();
    final directory = Directory(installed!.cachePath);
    final file = File('${directory.path}/${update.fileName}');
    final partial = File('${file.path}.part');
    try {
      await directory.create(recursive: true);
      await _clearCache(keep: update.fileName);
      if (await file.exists()) {
        try {
          await channel.invokeMethod<void>('verify', _arguments(update));
          return;
        } on PlatformException {
          if (await file.exists()) await file.delete();
        }
      }
      final response = await _get(client, update.apkUrl);
      if (response.statusCode != 200) throw const UpdateFailure('network');
      if (response.contentLength != -1 && response.contentLength != update.size) {
        throw const UpdateFailure('integrity');
      }
      var received = 0;
      final sink = await partial.open(mode: FileMode.write);
      try {
        await for (final chunk in response.timeout(const Duration(seconds: 30))) {
          _ensureActive();
          received += chunk.length;
          if (received > update.size) throw const UpdateFailure('integrity');
          await sink.writeFrom(chunk);
          progress(received, update.size);
        }
      } finally {
        await sink.close();
      }
      _ensureActive();
      if (received != update.size) throw const UpdateFailure('integrity');
      await partial.rename(file.path);
      await channel.invokeMethod<void>('verify', _arguments(update));
    } finally {
      client.close(force: true);
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<String> install(AppUpdate update) async =>
      (await channel.invokeMethod<String>('install', _arguments(update)))!;
}
