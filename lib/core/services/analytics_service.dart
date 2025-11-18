import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Google Analytics 이벤트 관리 서비스
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  // 사용자 속성 설정
  static Future<void> setUserId(String? userId) async {
    if (!kDebugMode) {
      await _analytics.setUserId(id: userId);
      if (userId != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
    }
  }

  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!kDebugMode) {
      await _analytics.setUserProperty(name: name, value: value);
    }
  }

  // 화면 추적
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // 범용 이벤트 로깅
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // 인증 이벤트
  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  // Fragment 관련 이벤트
  static Future<void> logFragmentAdded({
    required String fragmentId,
    bool hasImage = false,
    int? contentLength,
  }) async {
    await _analytics.logEvent(
      name: 'fragment_added',
      parameters: {
        'fragment_id': fragmentId,
        'has_image': hasImage.toString(),
        if (contentLength != null) 'content_length': contentLength,
      },
    );
  }

  static Future<void> logFragmentDeleted(String fragmentId) async {
    await _analytics.logEvent(
      name: 'fragment_deleted',
      parameters: {'fragment_id': fragmentId},
    );
  }

  static Future<void> logFragmentEdited({
    required String fragmentId,
    int? contentLength,
  }) async {
    await _analytics.logEvent(
      name: 'fragment_edited',
      parameters: {
        'fragment_id': fragmentId,
        if (contentLength != null) 'content_length': contentLength,
      },
    );
  }

  // Draft 관련 이벤트
  static Future<void> logDraftGenerated({
    required String draftId,
    required int fragmentCount,
    int? contentLength,
  }) async {
    await _analytics.logEvent(
      name: 'draft_generated',
      parameters: {
        'draft_id': draftId,
        'fragment_count': fragmentCount,
        if (contentLength != null) 'content_length': contentLength,
      },
    );
  }

  static Future<void> logDraftDeleted(String draftId) async {
    await _analytics.logEvent(
      name: 'draft_deleted',
      parameters: {'draft_id': draftId},
    );
  }

  static Future<void> logDraftEdited({
    required String draftId,
    int? contentLength,
  }) async {
    await _analytics.logEvent(
      name: 'draft_edited',
      parameters: {
        'draft_id': draftId,
        if (contentLength != null) 'content_length': contentLength,
      },
    );
  }

  // Post 관련 이벤트
  static Future<void> logPostPublished({
    required String postId,
    int? contentLength,
  }) async {
    await _analytics.logEvent(
      name: 'post_published',
      parameters: {
        'post_id': postId,
        if (contentLength != null) 'content_length': contentLength,
      },
    );
  }

  static Future<void> logPostDeleted(String postId) async {
    await _analytics.logEvent(
      name: 'post_deleted',
      parameters: {'post_id': postId},
    );
  }

  static Future<void> logPostEdited({
    required String postId,
    int? contentLength,
  }) async {
    await _analytics.logEvent(
      name: 'post_edited',
      parameters: {
        'post_id': postId,
        if (contentLength != null) 'content_length': contentLength,
      },
    );
  }

  // 공유 이벤트
  static Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }

  static Future<void> logShareReceived({
    required String contentType,
    bool hasImage = false,
  }) async {
    await _analytics.logEvent(
      name: 'share_received',
      parameters: {
        'content_type': contentType,
        'has_image': hasImage.toString(),
      },
    );
  }

  // 검색 이벤트
  static Future<void> logSearch({
    required String searchTerm,
    required String searchType,
    int? resultCount,
  }) async {
    if (!kDebugMode) {
      try {
        await _analytics.logSearch(
          searchTerm: searchTerm,
          parameters: {
            'search_type': searchType,
            if (resultCount != null) 'result_count': resultCount,
          },
        );
      } catch (e) {
        if (kDebugMode) {
          print('Analytics logSearch failed (test mode): $e');
        }
      }
    }
  }

  // 설정 관련 이벤트
  static Future<void> logThemeChanged(String theme) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme': theme},
    );
  }

  static Future<void> logLanguageChanged(String language) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': language},
    );
  }

  // 동기화 이벤트
  static Future<void> logSyncStarted() async {
    await _analytics.logEvent(name: 'sync_started');
  }

  static Future<void> logSyncCompleted({
    required int itemsSynced,
    required int duration,
  }) async {
    await _analytics.logEvent(
      name: 'sync_completed',
      parameters: {
        'items_synced': itemsSynced,
        'duration_ms': duration,
      },
    );
  }

  static Future<void> logSyncFailed(String error) async {
    await _analytics.logEvent(
      name: 'sync_failed',
      parameters: {'error': error},
    );
  }

  // AI 관련 이벤트
  static Future<void> logAIProcessing({
    required String processType,
    required int fragmentCount,
    int? duration,
  }) async {
    await _analytics.logEvent(
      name: 'ai_processing',
      parameters: {
        'process_type': processType,
        'fragment_count': fragmentCount,
        if (duration != null) 'duration_ms': duration,
      },
    );
  }

  // 알림 이벤트
  static Future<void> logNotificationReceived({
    required String notificationType,
  }) async {
    await _analytics.logEvent(
      name: 'notification_received',
      parameters: {'notification_type': notificationType},
    );
  }

  static Future<void> logNotificationOpened({
    required String notificationType,
  }) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {'notification_type': notificationType},
    );
  }

  // 커스텀 이벤트
  static Future<void> logCustomEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    final Map<String, Object>? convertedParams = parameters?.map(
      (key, value) => MapEntry(key, value ?? 'null'),
    );

    await _analytics.logEvent(
      name: name,
      parameters: convertedParams,
    );
  }

  // 에러 추적
  static void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    }
  }

  // 커스텀 로그 메시지
  static void log(String message) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  // 커스텀 키
  static Future<void> setCustomKey(String key, Object value) async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }
}
