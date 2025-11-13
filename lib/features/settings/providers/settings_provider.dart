import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// SharedPreferences Provider
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// 테마 모드 Provider
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const String _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final String? modeString = prefs.getString(_key);

    if (modeString != null) {
      return ThemeMode.values.firstWhere(
        (mode) => mode.toString() == modeString,
        orElse: () => ThemeMode.system,
      );
    }

    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, mode.toString());
  }
}

/// 컬러 테마 Provider (12가지 Shadcn UI 컬러)
@riverpod
class ColorThemeNotifier extends _$ColorThemeNotifier {
  static const String _key = 'color_theme';

  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString(_key) ?? 'zinc';
  }

  Future<void> setColorTheme(String colorId) async {
    state = AsyncValue.data(colorId);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, colorId);
  }
}

/// 언어 설정 Provider
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const String _key = 'locale';

  @override
  Future<Locale?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final String? localeCode = prefs.getString(_key);

    if (localeCode != null) {
      return Locale(localeCode);
    }

    return null; // null = 시스템 언어
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncValue.data(locale);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (locale != null) {
      await prefs.setString(_key, locale.languageCode);
    } else {
      await prefs.remove(_key);
    }
  }
}
