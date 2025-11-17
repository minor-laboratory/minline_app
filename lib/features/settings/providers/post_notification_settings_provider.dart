import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import 'settings_provider.dart';

part 'post_notification_settings_provider.g.dart';

/// Post 알림 설정 데이터
class PostNotificationData {
  final bool enabled;
  final String allowedStart; // "HH:MM" (수신 가능 시작 시간)
  final String allowedEnd; // "HH:MM" (수신 가능 종료 시간)

  PostNotificationData({
    required this.enabled,
    required this.allowedStart,
    required this.allowedEnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostNotificationData &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          allowedStart == other.allowedStart &&
          allowedEnd == other.allowedEnd;

  @override
  int get hashCode =>
      enabled.hashCode ^ allowedStart.hashCode ^ allowedEnd.hashCode;
}

/// Post 알림 설정 Provider (PolicyLatestPage 패턴)
@riverpod
class PostNotificationSettings extends _$PostNotificationSettings {
  static const String _keyEnabled = 'post_notification_enabled';
  static const String _keyStart = 'post_notification_start';
  static const String _keyEnd = 'post_notification_end';

  @override
  Future<PostNotificationData> build() async {
    return await loadWithCache();
  }

  /// 캐시 우선 로드
  Future<PostNotificationData> loadWithCache() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);

      final cachedEnabled = prefs.getBool(_keyEnabled);
      final cachedStart = prefs.getString(_keyStart);
      final cachedEnd = prefs.getString(_keyEnd);

      if (cachedEnabled != null && cachedStart != null && cachedEnd != null) {
        final cached = PostNotificationData(
          enabled: cachedEnabled,
          allowedStart: cachedStart,
          allowedEnd: cachedEnd,
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
        final defaultSettings = PostNotificationData(
          enabled: true,
          allowedStart: '08:00',
          allowedEnd: '23:00',
        );
        await _saveToCache(defaultSettings);
        return defaultSettings;
      }

      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('app_name', 'miniline')
          .eq('notification_type', 'post_notification')
          .maybeSingle();

      if (response == null) {
        final defaultSettings = PostNotificationData(
          enabled: true,
          allowedStart: '08:00',
          allowedEnd: '23:00',
        );
        await _saveToCache(defaultSettings);
        return defaultSettings;
      }

      final settings = PostNotificationData(
        enabled: response['enabled'] as bool,
        allowedStart: response['settings']['allowed_start'] as String,
        allowedEnd: response['settings']['allowed_end'] as String,
      );

      await _saveToCache(settings);
      return settings;
    } catch (e) {
      logger.e('Failed to fetch post notification from server', e);
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
        current.allowedEnd != server.allowedEnd;
  }

  /// 캐시 저장
  Future<void> _saveToCache(PostNotificationData settings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setString(_keyStart, settings.allowedStart);
    await prefs.setString(_keyEnd, settings.allowedEnd);
  }

  /// 설정 업데이트 (사용자 액션)
  Future<void> updateSettings(PostNotificationData settings) async {
    state = AsyncValue.data(settings);
    await _saveToCache(settings);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase.from('user_notification_settings').upsert({
        'user_id': userId,
        'app_name': 'miniline',
        'notification_type': 'post_notification',
        'enabled': settings.enabled,
        'settings': {
          'allowed_start': settings.allowedStart,
          'allowed_end': settings.allowedEnd,
        },
      });
    } catch (e) {
      logger.e('Failed to save post notification to server', e);
    }
  }

  /// 수신 가능 시간대 업데이트 (QuietHours 변경 시 호출)
  Future<void> updateAllowedTime(String allowedStart, String allowedEnd) async {
    final current = state.value;
    if (current == null) return;

    final updated = PostNotificationData(
      enabled: current.enabled,
      allowedStart: allowedStart,
      allowedEnd: allowedEnd,
    );

    await updateSettings(updated);
  }
}
