import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/notification_type.dart';
import '../../../core/utils/logger.dart';
import 'settings_provider.dart';

part 'post_notification_settings_provider.g.dart';

/// Post 알림 설정 데이터
class PostNotificationData {
  final bool enabled;
  final String allowedStart; // "HH:MM" (수신 가능 시작 시간)
  final String allowedEnd; // "HH:MM" (수신 가능 종료 시간)
  final String timezone; // IANA Timezone (예: "Asia/Seoul")

  PostNotificationData({
    required this.enabled,
    required this.allowedStart,
    required this.allowedEnd,
    required this.timezone,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostNotificationData &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          allowedStart == other.allowedStart &&
          allowedEnd == other.allowedEnd &&
          timezone == other.timezone;

  @override
  int get hashCode =>
      enabled.hashCode ^
      allowedStart.hashCode ^
      allowedEnd.hashCode ^
      timezone.hashCode;
}

/// Post 알림 설정 Provider (PolicyLatestPage 패턴)
@riverpod
class PostNotificationSettings extends _$PostNotificationSettings {
  static const String _keyEnabled = 'post_notification_enabled';
  static const String _keyStart = 'post_notification_start';
  static const String _keyEnd = 'post_notification_end';
  static const String _keyTimezone = 'post_notification_timezone';

  @override
  Future<PostNotificationData> build() async {
    return await loadWithCache();
  }

  /// 현재 디바이스의 timezone 가져오기 (IANA 형식)
  ///
  /// 예: "Asia/Seoul", "America/New_York", "Europe/London"
  /// (Not "KST", "EST" - 서버의 Intl.DateTimeFormat과 호환되지 않음)
  String _getCurrentTimezone() {
    try {
      // tz.local.name은 IANA timezone 반환 (예: "Asia/Seoul")
      final timezone = tz.local.name;
      logger.d('[Notification] Current timezone: $timezone');
      return timezone;
    } catch (e) {
      logger.w('Failed to get timezone, using UTC', e);
      return 'UTC';
    }
  }

  /// 캐시 우선 로드
  Future<PostNotificationData> loadWithCache() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);

      final cachedEnabled = prefs.getBool(_keyEnabled);
      final cachedStart = prefs.getString(_keyStart);
      final cachedEnd = prefs.getString(_keyEnd);
      final cachedTimezone = prefs.getString(_keyTimezone);

      if (cachedEnabled != null && cachedStart != null && cachedEnd != null) {
        final cached = PostNotificationData(
          enabled: cachedEnabled,
          allowedStart: cachedStart,
          allowedEnd: cachedEnd,
          timezone: cachedTimezone ?? _getCurrentTimezone(), // Fallback
        );

        _checkForUpdates();
        return cached;
      }

      return await _fetchFromServer();
    } catch (e) {
      logger.e('Failed to load post notification from cache', e);
      return await _fetchFromServer();
    }
  }

  /// 서버에서 데이터 가져오기
  Future<PostNotificationData> _fetchFromServer() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        // 로그인 안됨 → 기본값 + 캐시 저장
        // QuietHours 기본값(23:00-08:00)의 역전 = Allowed Time (08:00-23:00)
        final defaultSettings = PostNotificationData(
          enabled: true,
          allowedStart: '08:00',
          allowedEnd: '23:00',
          timezone: _getCurrentTimezone(),
        );
        await _saveToCache(defaultSettings);
        return defaultSettings;
      }

      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('app_name', 'miniline')
          .eq('notification_type', NotificationType.postCreation.value)
          .maybeSingle();

      if (response == null) {
        // 서버에 데이터 없음 → 기본값 생성 + 서버에 저장
        // QuietHours 기본값(23:00-08:00)의 역전 = Allowed Time (08:00-23:00)
        final defaultSettings = PostNotificationData(
          enabled: true,
          allowedStart: '08:00',
          allowedEnd: '23:00',
          timezone: _getCurrentTimezone(),
        );

        // 캐시 저장
        await _saveToCache(defaultSettings);

        // 서버에 저장 (중요!)
        await _saveToServer(userId, defaultSettings);

        return defaultSettings;
      }

      final settings = PostNotificationData(
        enabled: response['enabled'] as bool,
        allowedStart: response['settings']['allowed_start'] as String,
        allowedEnd: response['settings']['allowed_end'] as String,
        timezone: response['settings']['timezone'] as String? ?? _getCurrentTimezone(),
      );

      await _saveToCache(settings);
      return settings;
    } catch (e) {
      logger.e('Failed to fetch post notification from server', e);
      rethrow;
    }
  }

  /// 서버에 저장
  Future<void> _saveToServer(String userId, PostNotificationData settings) async {
    try {
      final supabase = Supabase.instance.client;

      logger.d('[Notification] Saving Post settings: enabled=${settings.enabled}, allowed=${settings.allowedStart}-${settings.allowedEnd}, tz=${settings.timezone}');

      await supabase.from('user_notification_settings').upsert(
        {
          'user_id': userId,
          'app_name': 'miniline',
          'notification_type': NotificationType.postCreation.value,
          'enabled': settings.enabled,
          'settings': {
            'allowed_start': settings.allowedStart,
            'allowed_end': settings.allowedEnd,
            'timezone': settings.timezone,
          },
        },
        onConflict: 'user_id,app_name,notification_type',
      );

      logger.i('[Notification] Post settings saved to server');
    } catch (e) {
      logger.e('[Notification] Failed to save post settings to server', e);
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
  bool _hasDataChanged(
      PostNotificationData current, PostNotificationData server) {
    return current.enabled != server.enabled ||
        current.allowedStart != server.allowedStart ||
        current.allowedEnd != server.allowedEnd ||
        current.timezone != server.timezone;
  }

  /// 캐시 저장
  Future<void> _saveToCache(PostNotificationData settings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setString(_keyStart, settings.allowedStart);
    await prefs.setString(_keyEnd, settings.allowedEnd);
    await prefs.setString(_keyTimezone, settings.timezone);
  }

  /// 설정 업데이트 (사용자 액션)
  Future<void> updateSettings(PostNotificationData settings) async {
    // 1. 즉시 UI 업데이트
    state = AsyncValue.data(settings);

    // 2. 로컬 캐시 저장
    await _saveToCache(settings);

    // 3. 서버로 전송
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await _saveToServer(userId, settings);
    } catch (e) {
      logger.e('Failed to save post notification to server', e);
      // 서버 저장 실패해도 캐시는 이미 저장됨 (다음 동기화에서 재시도)
    }
  }

  /// 수신 가능 시간대 업데이트 (QuietHours 변경 시 호출)
  Future<void> updateAllowedTime(String allowedStart, String allowedEnd) async {
    final current = state.value ?? await future;

    final updated = PostNotificationData(
      enabled: current.enabled,
      allowedStart: allowedStart,
      allowedEnd: allowedEnd,
      timezone: current.timezone, // 기존 timezone 유지
    );

    await updateSettings(updated);
  }
}
