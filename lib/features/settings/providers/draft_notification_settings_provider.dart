import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/logger.dart';
import 'settings_provider.dart';

part 'draft_notification_settings_provider.g.dart';

/// 알림 설정 상태
enum NotificationSettingsState {
  initial, // 초기 상태
  loading, // 로딩 중 (캐시 없음)
  refreshing, // 백그라운드 새로고침 (캐시 있음)
  loaded, // 로드 완료
  error, // 에러
}

/// Draft 완성 알림 설정 데이터
class NotificationSettingsData {
  final bool enabled;
  final String allowedStart; // "HH:MM"
  final String allowedEnd; // "HH:MM"
  final String timezone; // IANA Timezone (예: "Asia/Seoul")

  NotificationSettingsData({
    required this.enabled,
    required this.allowedStart,
    required this.allowedEnd,
    required this.timezone,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsData &&
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

/// Draft 완성 알림 설정 Provider (PolicyLatestPage 패턴)
@riverpod
class DraftNotificationSettings extends _$DraftNotificationSettings {
  static const String _keyEnabled = 'draft_notification_enabled';
  static const String _keyStart = 'draft_notification_start';
  static const String _keyEnd = 'draft_notification_end';
  static const String _keyTimezone = 'draft_notification_timezone';

  NotificationSettingsState _pageState = NotificationSettingsState.initial;

  NotificationSettingsState get pageState => _pageState;

  @override
  Future<NotificationSettingsData> build() async {
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

  /// 캐시 우선 로드 (PolicyLatestPage 패턴)
  Future<NotificationSettingsData> loadWithCache() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);

      // 1. 캐시 먼저 읽기
      final cachedEnabled = prefs.getBool(_keyEnabled);
      final cachedStart = prefs.getString(_keyStart);
      final cachedEnd = prefs.getString(_keyEnd);
      final cachedTimezone = prefs.getString(_keyTimezone);

      // 캐시가 있으면 즉시 반환
      if (cachedEnabled != null && cachedStart != null && cachedEnd != null) {
        final cached = NotificationSettingsData(
          enabled: cachedEnabled,
          allowedStart: cachedStart,
          allowedEnd: cachedEnd,
          timezone: cachedTimezone ?? _getCurrentTimezone(), // Fallback
        );

        // 상태를 loaded로 설정
        _pageState = NotificationSettingsState.loaded;

        // 2. 백그라운드에서 서버 확인 (Cache-First with Always-Check)
        _checkForUpdates();

        return cached;
      }

      // 캐시 없으면 로딩 표시
      _pageState = NotificationSettingsState.loading;
      return await _fetchFromServer();
    } catch (e) {
      // 캐시 로드 실패시 서버에서 로드
      _pageState = NotificationSettingsState.loading;
      return await _fetchFromServer();
    }
  }

  /// 서버에서 데이터 가져오기
  Future<NotificationSettingsData> _fetchFromServer() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        // 로그인 안됨 → 기본값 + 캐시 저장
        // QuietHours 기본값(23:00-08:00)의 역전 = Allowed Time (08:00-23:00)
        final defaultSettings = NotificationSettingsData(
          enabled: true,
          allowedStart: '08:00',
          allowedEnd: '23:00',
          timezone: _getCurrentTimezone(),
        );
        await _saveToCache(defaultSettings);
        _pageState = NotificationSettingsState.loaded;
        return defaultSettings;
      }

      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('app_name', 'miniline')
          .eq('notification_type', 'draft_completion')
          .maybeSingle();

      if (response == null) {
        // 서버에 데이터 없음 → 기본값 생성 + 서버에 저장
        // QuietHours 기본값(23:00-08:00)의 역전 = Allowed Time (08:00-23:00)
        final defaultSettings = NotificationSettingsData(
          enabled: true,
          allowedStart: '08:00',
          allowedEnd: '23:00',
          timezone: _getCurrentTimezone(),
        );

        // 캐시 저장
        await _saveToCache(defaultSettings);

        // 서버에 저장 (중요!)
        await _saveToServer(userId, defaultSettings);

        _pageState = NotificationSettingsState.loaded;
        return defaultSettings;
      }

      final settings = NotificationSettingsData(
        enabled: response['enabled'] as bool,
        allowedStart: response['settings']['allowed_start'] as String,
        allowedEnd: response['settings']['allowed_end'] as String,
        timezone: response['settings']['timezone'] as String? ?? _getCurrentTimezone(),
      );

      await _saveToCache(settings);
      _pageState = NotificationSettingsState.loaded;
      return settings;
    } catch (e) {
      _pageState = NotificationSettingsState.error;
      logger.e('Failed to fetch notification settings', e);
      rethrow;
    }
  }

  /// 서버에 저장
  Future<void> _saveToServer(String userId, NotificationSettingsData settings) async {
    try {
      final supabase = Supabase.instance.client;

      logger.d('[Notification] Saving Draft settings: enabled=${settings.enabled}, allowed=${settings.allowedStart}-${settings.allowedEnd}, tz=${settings.timezone}');

      await supabase.from('user_notification_settings').upsert(
        {
          'user_id': userId,
          'app_name': 'miniline',
          'notification_type': 'draft_completion',
          'enabled': settings.enabled,
          'settings': {
            'allowed_start': settings.allowedStart,
            'allowed_end': settings.allowedEnd,
            'timezone': settings.timezone,
          },
        },
        onConflict: 'user_id,app_name,notification_type',
      );

      logger.i('[Notification] Draft settings saved to server');
    } catch (e) {
      logger.e('[Notification] Failed to save settings to server', e);
      rethrow;
    }
  }

  /// 백그라운드 업데이트 확인 (PolicyLatestPage 패턴)
  Future<void> _checkForUpdates() async {
    _pageState = NotificationSettingsState.refreshing;

    try {
      final serverData = await _fetchFromServer();

      // 데이터 변경 확인
      final currentData = state.value;
      if (currentData != null && _hasDataChanged(currentData, serverData)) {
        // 변경사항 있으면 업데이트
        state = AsyncValue.data(serverData);
      }

      _pageState = NotificationSettingsState.loaded;
    } catch (e) {
      // 서버 에러는 조용히 실패 (캐시 데이터 유지)
      _pageState = NotificationSettingsState.loaded;
      logger.e('Background sync failed (ignored)', e);
    }
  }

  /// 데이터 변경 여부 확인
  bool _hasDataChanged(
      NotificationSettingsData current, NotificationSettingsData server) {
    return current.enabled != server.enabled ||
        current.allowedStart != server.allowedStart ||
        current.allowedEnd != server.allowedEnd ||
        current.timezone != server.timezone;
  }

  /// 캐시 저장
  Future<void> _saveToCache(NotificationSettingsData settings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setString(_keyStart, settings.allowedStart);
    await prefs.setString(_keyEnd, settings.allowedEnd);
    await prefs.setString(_keyTimezone, settings.timezone);
  }

  /// 설정 업데이트 (사용자 액션)
  Future<void> updateSettings(NotificationSettingsData settings) async {
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
      logger.e('Failed to save notification settings to server', e);
      // 서버 저장 실패해도 캐시는 이미 저장됨 (다음 동기화에서 재시도)
    }
  }

  /// 수신 가능 시간대 업데이트 (QuietHours 변경 시 호출)
  Future<void> updateAllowedTime(String allowedStart, String allowedEnd) async {
    final current = state.value ?? await future;

    final updated = NotificationSettingsData(
      enabled: current.enabled,
      allowedStart: allowedStart,
      allowedEnd: allowedEnd,
      timezone: current.timezone, // 기존 timezone 유지
    );

    await updateSettings(updated);
  }
}
