import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_roulette/l10n/strings.dart';
import 'package:random_roulette/model/roulette.dart';

void main() {
  test('every locale has presets within item limits', () {
    for (final l in S.supported) {
      final s = S(l);
      expect(s.presets.length, greaterThanOrEqualTo(3));
      for (final (title, items) in s.presets) {
        expect(title, isNotEmpty);
        expect(items.length, inInclusiveRange(Roulette.minItems, Roulette.maxItems), reason: '$l $title');
        expect(items.every((e) => e.trim().isNotEmpty), isTrue, reason: '$l $title');
      }
    }
  });

  test('resolve falls back to English', () {
    expect(S.resolve(const Locale('fr')).languageCode, 'en');
    expect(S.resolve(const Locale('ko', 'KR')).languageCode, 'ko');
    expect(S.resolve(null).languageCode, 'en');
  });

  test('LocaleController.fromCode ignores unsupported codes', () {
    expect(LocaleController.fromCode('xx'), isNull);
    expect(LocaleController.fromCode('ja')?.languageCode, 'ja');
    expect(LocaleController.fromCode(null), isNull);
  });

  test('theme names exist for all themes', () {
    for (final l in S.supported) {
      final s = S(l);
      for (final id in ['classic', 'pastel', 'neon', 'sunset', 'forest', 'ocean']) {
        expect(s.themeName(id), isNot(id));
      }
    }
  });
}
