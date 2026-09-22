import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/roulette.dart';

/// 룰렛 목록·테마 잠금 해제·언어 설정을 기기에 저장한다.
class Storage {
  static const _kRoulettes = 'roulettes';
  static const _kLocale = 'locale';
  static const _kTheme = 'theme';
  static const _kUnlocked = 'unlocked_themes';
  static const _kSeeded = 'seeded';

  final SharedPreferences _prefs;
  Storage(this._prefs);

  static Future<Storage> create() async => Storage(await SharedPreferences.getInstance());

  /// 사용자가 고른 언어 코드 (null = 시스템 언어).
  String? get localeCode => _prefs.getString(_kLocale);
  Future<void> setLocaleCode(String? code) =>
      code == null ? _prefs.remove(_kLocale) : _prefs.setString(_kLocale, code);

  /// 첫 실행 시 기본 룰렛을 넣었는지.
  bool get seeded => _prefs.getBool(_kSeeded) ?? false;
  Future<void> markSeeded() => _prefs.setBool(_kSeeded, true);

  List<Roulette> loadRoulettes() {
    final s = _prefs.getString(_kRoulettes);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List).map((e) => Roulette.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoulettes(List<Roulette> list) =>
      _prefs.setString(_kRoulettes, jsonEncode(list.map((r) => r.toJson()).toList()));

  String? get themeId => _prefs.getString(_kTheme);
  Future<void> setThemeId(String id) => _prefs.setString(_kTheme, id);

  Set<String> get unlockedThemes => (_prefs.getStringList(_kUnlocked) ?? const []).toSet();
  Future<void> unlockTheme(String id) => _prefs.setStringList(_kUnlocked, {...unlockedThemes, id}.toList());
}
