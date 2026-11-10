import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/app_update.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum _UpdateStep { checking, current, available, downloading, ready, installing, failed }

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({super.key, this.service});
  final AppUpdateService? service;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  late final _service = widget.service ?? AppUpdateService();
  _UpdateStep _step = _UpdateStep.checking;
  AppUpdate? _update;
  String? _error;
  int _percent = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _service.cancel();
    super.dispose();
  }

  String _message(String code) => switch (code) {
    'noRelease' => t.ownUpdateNoRelease,
    'rateLimit' => t.ownUpdateRateLimit,
    'metadata' => t.ownUpdateMetadataError,
    'integrity' || 'signature' || 'version' => t.ownUpdateInvalidApk,
    'incompatible' || 'unsupported' => t.ownUpdateUnsupported,
    'foreground' => t.ownUpdateForeground,
    'installer' => t.ownUpdateInstallerError,
    'permission' => t.ownUpdatePermission,
    'training' => t.ownUpdateTraining,
    _ => t.ownUpdateNetworkError,
  };

  String _errorCode(Object e) => switch (e) {
    UpdateFailure() => e.code,
    PlatformException() => e.code,
    MissingPluginException() => 'unsupported',
    _ => 'network',
  };

  Future<void> _check() async {
    setState(() {
      _step = _UpdateStep.checking;
      _error = null;
    });
    try {
      final update = await _service.check();
      if (!mounted) return;
      setState(() {
        _update = update;
        _step = update == null ? _UpdateStep.current : _UpdateStep.available;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _UpdateStep.failed;
          _error = _errorCode(e);
        });
      }
    }
  }

  Future<void> _download() async {
    setState(() {
      _step = _UpdateStep.downloading;
      _error = null;
      _percent = 0;
    });
    try {
      await _service.download(_update!, (received, total) {
        final percent = (received * 100 ~/ total).clamp(0, 100);
        if (mounted && percent != _percent) setState(() => _percent = percent);
      });
      if (mounted) setState(() => _step = _UpdateStep.ready);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _UpdateStep.available;
        _error = _errorCode(e);
      });
    }
  }

  Future<void> _install() async {
    if (fit.session != null && !fit.session!.complete) {
      setState(() => _error = 'training');
      return;
    }
    setState(() {
      _step = _UpdateStep.installing;
      _error = null;
    });
    try {
      fit.persistNow();
      final result = await _service.install(_update!);
      if (mounted) {
        setState(() {
          _step = _UpdateStep.ready;
          _error = result == 'permission' ? 'permission' : null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final code = _errorCode(e);
      setState(() {
        _step = ['integrity', 'signature', 'version'].contains(code)
            ? _UpdateStep.available
            : _UpdateStep.ready;
        _error = code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final busy = [_UpdateStep.checking, _UpdateStep.downloading, _UpdateStep.installing].contains(_step);
    return AlertDialog(
      key: const ValueKey('app-update-dialog'),
      backgroundColor: gc.bgRaised,
      scrollable: true,
      title: Text(
        t.ownCheckUpdates,
        style: AppTheme.f(21, weight: FontWeight.w800, color: gc.text),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == _UpdateStep.checking) Text(t.ownUpdateChecking),
            if (_step == _UpdateStep.current) Text(t.ownUpdateCurrent),
            if (_error != null && _error != 'cancelled') ...[
              Semantics(
                liveRegion: true,
                child: Text(_message(_error!), style: AppTheme.f(14, color: gc.text, height: 1.5)),
              ),
              const SizedBox(height: 16),
            ],
            if (_update != null) ...[
              Text(
                _update!.versionName,
                style: AppTheme.f(18, weight: FontWeight.w700, color: gc.text),
              ),
              const SizedBox(height: 6),
              Text(
                t.ownUpdateSize((_update!.size / (1024 * 1024)).toStringAsFixed(1)),
                style: AppTheme.f(14, color: gc.textSecondary),
              ),
              if (_update!.notes.isNotEmpty && _step == _UpdateStep.available) ...[
                const SizedBox(height: 16),
                Text(_update!.notes, style: AppTheme.f(14, color: gc.text, height: 1.5)),
              ],
            ],
            if (busy) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _step == _UpdateStep.downloading ? _percent / 100 : null),
              const SizedBox(height: 10),
              if (_step == _UpdateStep.downloading)
                Text(_percent == 100 ? t.ownUpdateVerifying : t.ownUpdateProgress(_percent)),
              if (_step == _UpdateStep.installing) Text(t.ownUpdateVerifying),
            ],
            if (_step == _UpdateStep.ready) ...[const SizedBox(height: 12), Text(t.ownUpdateReady)],
            if (!busy) ...[
              const SizedBox(height: 16),
              Text(t.ownUpdatePrivacy, style: AppTheme.f(12, color: gc.textSecondary, height: 1.4)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _step == _UpdateStep.installing ? null : () => Navigator.pop(context),
          child: Text(busy ? t.cancel : t.done),
        ),
        if (_step == _UpdateStep.failed) ...[
          TextButton(
            onPressed: () async {
              try {
                final opened = await launchUrl(
                  Uri.https('github.com', '/$updateRepository/releases'),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && mounted) setState(() => _error = 'network');
              } catch (_) {
                if (mounted) setState(() => _error = 'network');
              }
            },
            child: Text(t.ownUpdateReleases),
          ),
          FilledButton(onPressed: _check, child: Text(t.ownCheckUpdates)),
        ],
        if (_step == _UpdateStep.available)
          FilledButton(
            key: const ValueKey('download-update'),
            onPressed: _download,
            child: Text(t.ownUpdateDownload),
          ),
        if (_step == _UpdateStep.ready)
          FilledButton(
            key: const ValueKey('install-update'),
            onPressed: _install,
            child: Text(t.ownUpdateInstall),
          ),
      ],
    );
  }
}
