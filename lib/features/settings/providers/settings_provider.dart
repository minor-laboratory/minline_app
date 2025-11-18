import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../../../core/services/analytics_service.dart';

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

    // Analytics 로그
    await AnalyticsService.logThemeChanged(mode.toString().split('.').last);
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

    // Analytics 로그
    await AnalyticsService.logLanguageChanged(locale?.languageCode ?? 'system');
  }
}

/// 배경색 옵션 Provider
@riverpod
class BackgroundColorNotifier extends _$BackgroundColorNotifier {
  static const String _key = 'background_color_option';

  @override
  Future<common.BackgroundColorOption> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final String? optionString = prefs.getString(_key);

    if (optionString != null) {
      return common.BackgroundColorOption.values.firstWhere(
        (option) => option.toString() == optionString,
        orElse: () => common.BackgroundColorOption.defaultColor,
      );
    }

    return common.BackgroundColorOption.defaultColor;
  }

  Future<void> setBackgroundOption(common.BackgroundColorOption option) async {
    state = AsyncValue.data(option);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, option.toString());
  }
}

/// 앱 시작시 입력 활성화 Provider
@riverpod
class AutoFocusInputNotifier extends _$AutoFocusInputNotifier {
  static const String _key = 'auto_focus_input';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false; // 기본값: false
  }

  Future<void> setAutoFocusInput(bool enabled) async {
    state = AsyncValue.data(enabled);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, enabled);

    // Analytics 로그
    await AnalyticsService.logEvent(
      name: 'auto_focus_input_changed',
      parameters: {'enabled': enabled.toString()},
    );
  }
}

/// 마지막 탭 인덱스 Provider (홈 화면 탭 위치 저장)
@riverpod
class LastTabIndexNotifier extends _$LastTabIndexNotifier {
  static const String _key = 'last_tab_index';

  @override
  Future<int> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getInt(_key) ?? 0; // 기본값: 0 (타임라인)
  }

  Future<void> setLastTabIndex(int index) async {
    // 범위 검증 (0: Timeline, 1: Drafts, 2: Posts)
    if (index < 0 || index > 2) {
      return;
    }

    state = AsyncValue.data(index);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_key, index);
  }
}

/// Fragment 입력 방식 Provider
@riverpod
class FragmentInputModeNotifier extends _$FragmentInputModeNotifier {
  static const String _key = 'fragment_input_mode';

  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString(_key) ?? 'inline'; // 기본값: inline (하단 고정 입력창)
  }

  Future<void> setInputMode(String mode) async {
    // 'inline' 또는 'fab'만 허용
    if (mode != 'inline' && mode != 'fab') {
      return;
    }

    state = AsyncValue.data(mode);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, mode);

    // Analytics 로그
    await AnalyticsService.logEvent(
      name: 'fragment_input_mode_changed',
      parameters: {'mode': mode},
    );
  }
}
