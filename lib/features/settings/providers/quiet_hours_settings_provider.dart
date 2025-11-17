import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import 'draft_notification_settings_provider.dart';
import 'post_notification_settings_provider.dart';
import 'settings_provider.dart';

part 'quiet_hours_settings_provider.g.dart';

/// 방해금지 시간 설정 데이터
class QuietHoursData {
  final bool enabled;
  final String quietStart; // "HH:MM"
  final String quietEnd; // "HH:MM"

  QuietHoursData({
    required this.enabled,
    required this.quietStart,
    required this.quietEnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuietHoursData &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          quietStart == other.quietStart &&
          quietEnd == other.quietEnd;

  @override
  int get hashCode =>
      enabled.hashCode ^ quietStart.hashCode ^ quietEnd.hashCode;
}

/// 방해금지 시간 설정 Provider (PolicyLatestPage 패턴)
@riverpod
class QuietHoursSettings extends _$QuietHoursSettings {
  static const String _keyEnabled = 'quiet_hours_enabled';
  static const String _keyStart = 'quiet_hours_start';
  static const String _keyEnd = 'quiet_hours_end';

  @override
  Future<QuietHoursData> build() async {
    return await loadWithCache();
  }

  /// 캐시 우선 로드 (PolicyLatestPage 패턴)
  Future<QuietHoursData> loadWithCache() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);

      // 1. 캐시 먼저 읽기
      final cachedEnabled = prefs.getBool(_keyEnabled);
      final cachedStart = prefs.getString(_keyStart);
      final cachedEnd = prefs.getString(_keyEnd);

      // 캐시가 있으면 즉시 반환
      if (cachedEnabled != null && cachedStart != null && cachedEnd != null) {
        final cached = QuietHoursData(
          enabled: cachedEnabled,
          quietStart: cachedStart,
          quietEnd: cachedEnd,
        );

        // 2. 백그라운드에서 서버 확인
        _checkForUpdates();

        return cached;
      }

      // 캐시 없으면 서버에서 로드
      return await _fetchFromServer();
    } catch (e) {
      logger.e('Failed to load quiet hours from cache', e);
      return await _fetchFromServer();
    }
  }

  /// 서버에서 데이터 가져오기
  Future<QuietHoursData> _fetchFromServer() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        // 로그인 안됨 → 기본값
        final defaultSettings = QuietHoursData(
          enabled: true,
          quietStart: '23:00',
          quietEnd: '08:00',
        );
        await _saveToCache(defaultSettings);
        return defaultSettings;
      }

      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('app_name', 'miniline')
          .eq('notification_type', 'quiet_hours')
          .maybeSingle();

      if (response == null) {
        // 서버에 데이터 없음 → 기본값
        final defaultSettings = QuietHoursData(
          enabled: true,
          quietStart: '23:00',
          quietEnd: '08:00',
        );
        await _saveToCache(defaultSettings);
        return defaultSettings;
      }

      final settings = QuietHoursData(
        enabled: response['enabled'] as bool,
        quietStart: response['settings']['quiet_start'] as String,
        quietEnd: response['settings']['quiet_end'] as String,
      );

      await _saveToCache(settings);
      return settings;
    } catch (e) {
      logger.e('Failed to fetch quiet hours from server', e);
      rethrow;
    }
  }

  /// 백그라운드 업데이트 확인
  Future<void> _checkForUpdates() async {
    try {
      final serverData = await _fetchFromServer();
      final currentData = state.value;

      if (currentData != null && _hasDataChanged(currentData, serverData)) {
        state = AsyncValue.data(serverData);
      }
    } catch (e) {
      logger.e('Background sync failed (ignored)', e);
    }
  }

  /// 데이터 변경 여부 확인
  bool _hasDataChanged(QuietHoursData current, QuietHoursData server) {
    return current.enabled != server.enabled ||
        current.quietStart != server.quietStart ||
        current.quietEnd != server.quietEnd;
  }

  /// 캐시 저장
  Future<void> _saveToCache(QuietHoursData settings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setString(_keyStart, settings.quietStart);
    await prefs.setString(_keyEnd, settings.quietEnd);
  }

  /// 설정 업데이트 (연쇄 업데이트 포함)
  Future<void> updateSettings(QuietHoursData settings) async {
    // 1. 즉시 UI 업데이트
    state = AsyncValue.data(settings);

    // 2. 로컬 캐시 저장
    await _saveToCache(settings);

    // 3. 수신 가능 시간대 계산
    final allowedStart = settings.quietEnd;
    final allowedEnd = settings.quietStart;

    // 4. Draft/Post 설정 연쇄 업데이트
    await ref
        .read(draftNotificationSettingsProvider.notifier)
        .updateAllowedTime(allowedStart, allowedEnd);

    await ref
        .read(postNotificationSettingsProvider.notifier)
        .updateAllowedTime(allowedStart, allowedEnd);

    // 5. 서버로 전송
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase.from('user_notification_settings').upsert({
        'user_id': userId,
        'app_name': 'miniline',
        'notification_type': 'quiet_hours',
        'enabled': settings.enabled,
        'settings': {
          'quiet_start': settings.quietStart,
          'quiet_end': settings.quietEnd,
        },
      });
    } catch (e) {
      logger.e('Failed to save quiet hours to server', e);
    }
  }
}
