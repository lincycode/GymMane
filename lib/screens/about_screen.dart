import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/own_build.dart';
import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/ui_kit.dart';
import 'app_update_dialog.dart';
import 'changelog_screen.dart';

const kAppVersion = ownAppVersion;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final content = <Widget>[
      Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              ownBrandIcon,
              width: 64,
              height: 64,
              cacheWidth: (64 * MediaQuery.devicePixelRatioOf(context)).round(),
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ownAppName,
                  style: AppTheme.f(24, weight: FontWeight.w800, color: gc.text),
                ),
                Text(t.version(kAppVersion), style: AppTheme.f(14, color: gc.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const ValueKey('check-app-updates'),
          onPressed: () => showDialog<void>(context: context, builder: (_) => const AppUpdateDialog()),
          icon: const Icon(PhosphorIconsRegular.downloadSimple, size: 20),
          label: Text(t.ownCheckUpdates),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
      const SizedBox(height: 8),
      ListTile(
        key: const ValueKey('open-changelog'),
        contentPadding: EdgeInsets.zero,
        leading: Icon(PhosphorIconsRegular.listBullets, size: 20, color: gc.text),
        title: Text(t.ownChangelog, style: AppTheme.f(14, color: gc.text)),
        trailing: Icon(PhosphorIconsRegular.caretRight, size: 16, color: gc.textSecondary),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ChangelogScreen()),
        ),
      ),
      const SizedBox(height: 24),
      Text(t.ownAttribution, style: AppTheme.f(14, color: gc.textSecondary, height: 1.4)),
      const SizedBox(height: 8),
      for (final (label, url) in [
        (t.ownOriginalAuthor, 'https://github.com/InlitX'),
        (t.ownOriginalSource, 'https://github.com/InlitX/GymMane'),
        (t.ownSourceCode, ownSourceUrl),
      ])
        Semantics(
          link: true,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: AppTheme.f(14, color: gc.text)),
            trailing: Icon(PhosphorIconsRegular.arrowUpRight, size: 16, color: gc.textSecondary),
            onTap: () => _open(context, url),
          ),
        ),
    ];
    if (embedded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content);
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          ScreenHeader(title: t.about, onBack: fit.backFromAbout, titleSize: 18, titleSpacing: 1),
          const SizedBox(height: 24),
          ...content,
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && context.mounted) {
      showNotchToast(
        context,
        t.cantOpenLink,
        icon: PhosphorIconsFill.warningCircle,
        accent: context.gc.danger,
      );
    }
  }
}
