import 'dart:convert';

import 'package:flutter/services.dart';

class ReleaseNote {
  const ReleaseNote(this.version, this.highlights, {this.date});

  final String version;
  final List<String> highlights;
  final DateTime? date;
}

class Changelog {
  const Changelog({
    required this.personal,
    required this.upstream,
    required this.upstreamVersion,
    required this.upstreamCommit,
  });

  final List<ReleaseNote> personal;
  final List<ReleaseNote> upstream;
  final String upstreamVersion;
  final String upstreamCommit;

  static const _directory = 'docs/releases/';
  static final _version = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-own\.(\d+))?$');

  static Future<Changelog> load(
    AssetBundle bundle, {
    required String installedVersion,
    required bool chinese,
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final versions = <String>[];
    final installed = _versionKey(installedVersion);
    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith(_directory) || !asset.endsWith('.md')) continue;
      final version = asset.substring(_directory.length, asset.length - '.md'.length);
      final key = _versionKey(version);
      if (key != null && (installed == null || _compare(key, installed) <= 0)) {
        versions.add(version);
      }
    }
    versions.sort((a, b) => _compare(_versionKey(b)!, _versionKey(a)!));
    final personal = await Future.wait([
      for (final version in versions)
        bundle.loadString('$_directory$version.md').then((body) => ReleaseNote(version, _highlights(body))),
    ]);

    final upstreamJson = jsonDecode(await bundle.loadString('docs/upstream-releases.json')) as List;
    final properties = await bundle.loadString('own.properties');
    return Changelog(
      personal: personal,
      upstream: [
        for (final entry in upstreamJson.cast<Map<String, dynamic>>())
          ReleaseNote(
            entry['version'] as String,
            List<String>.from(entry[chinese ? 'zh' : 'en'] as List),
            date: DateTime.parse(entry['date'] as String),
          ),
      ],
      upstreamVersion: _property(properties, 'upstreamVersion'),
      upstreamCommit: _property(properties, 'upstreamCommit'),
    );
  }

  static List<int>? _versionKey(String version) {
    final match = _version.firstMatch(version);
    if (match == null) return null;
    final legacy = match[4];
    // EnoGym switched from 2.1.0-own.N to its own 1.x release series.
    return [
      legacy == null ? 1 : 0,
      for (var i = 1; i <= 3; i++) int.parse(match[i]!),
      if (legacy != null) int.parse(legacy),
    ];
  }

  static int _compare(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      final result = a[i].compareTo(b[i]);
      if (result != 0) return result;
    }
    return 0;
  }

  static String _property(String body, String key) =>
      RegExp('^$key=(.+)', multiLine: true).firstMatch(body)?.group(1)?.trim() ?? '';

  static List<String> _highlights(String body) {
    final blocks = body.trim().split(RegExp(r'\r?\n\s*\r?\n'));
    final bullets = RegExp(r'^- +', multiLine: true);
    for (final block in blocks) {
      if (!block.startsWith(bullets)) continue;
      return block.split(bullets).skip(1).map(_plainText).toList();
    }
    for (final block in blocks) {
      if (block.isNotEmpty && !block.startsWith('#')) return [_plainText(block)];
    }
    return const [];
  }

  static String _plainText(String text) => text
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (link) => link[1]!)
      .replaceAll(RegExp(r'\*\*|`'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
