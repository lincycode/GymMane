import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('theme palettes and contrast', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.onboarded = true;
      setAppLanguage('en');
    });

    double lin(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    double lum(Color c) => 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    double contrast(Color a, Color b) {
      final la = lum(a), lb = lum(b);
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    test('original warm palette remains available and invalid choices use sage', () {
      expect(GymColors.lightFor('original'), same(GymColors.lightOriginal));
      expect(GymColors.lightOriginal.bg, const Color(0xFFF7F4F0));
      expect(GymColors.lightOriginal.ember, const Color(0xFF1A1713));
      expect(GymColors.lightOriginal.accent, const Color(0xFF9E4E27));
      expect(GymColors.lightFor('sage'), same(GymColors.light));
      expect(GymColors.lightFor('unknown'), same(GymColors.light));
    });

    test('light neutrals use a restrained sage tint', () {
      for (final c in [GymColors.light.bg, GymColors.light.bgRaised2, GymColors.light.border]) {
        final hsl = HSLColor.fromColor(c);
        expect(hsl.hue, inInclusiveRange(100, 150));
        expect(hsl.saturation, lessThan(0.25));
        expect(hsl.lightness, greaterThan(0.85));
      }
    });

    test('every text colour on light is actually readable', () {
      final gc = GymColors.light;
      for (final bg in [gc.bg, gc.bgRaised, gc.bgRaised2, gc.accentSoft]) {
        expect(contrast(bg, gc.text), greaterThan(7), reason: 'primary on $bg');
        expect(contrast(bg, gc.textSecondary), greaterThan(4.5), reason: 'secondary on $bg');
        expect(contrast(bg, gc.textTertiary), greaterThan(3), reason: 'tertiary on $bg');
      }
    });

    test('the light accent reads on page, card and selected surfaces', () {
      final gc = GymColors.light;
      for (final bg in [gc.bg, gc.bgRaised, gc.accentSoft]) {
        expect(contrast(bg, gc.accent), greaterThanOrEqualTo(4.5));
      }
    });

    test('dark text stays readable too', () {
      final bg = GymColors.dark.bg;
      expect(contrast(bg, GymColors.dark.text), greaterThan(7));
      expect(contrast(bg, GymColors.dark.textSecondary), greaterThan(4.5));
    });

    test('action colour flips with the theme but keeps its contrast', () {
      expect(contrast(GymColors.dark.ember, GymColors.dark.onEmber), greaterThan(7));
      expect(contrast(GymColors.light.ember, GymColors.light.onEmber), greaterThan(7));
    });
  });
}
