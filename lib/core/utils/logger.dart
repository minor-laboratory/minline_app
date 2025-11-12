import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전역 로거 인스턴스
final logger = AppLogger();

/// 커스텀 로거 클래스
class AppLogger {
  late final Logger _logger;

  AppLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
      filter: DevelopmentFilter(),
    );
  }

  /// Debug 레벨 로그
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, time: DateTime.now(), error: error, stackTrace: stackTrace);
  }

  /// Info 레벨 로그
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, time: DateTime.now(), error: error, stackTrace: stackTrace);
  }

  /// Warning 레벨 로그
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, time: DateTime.now(), error: error, stackTrace: stackTrace);
  }

  /// Error 레벨 로그
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, time: DateTime.now(), error: error, stackTrace: stackTrace);

    // Crashlytics에 에러 기록
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: message?.toString(),
        fatal: false,
      );
    }
  }

  /// Fatal 레벨 로그
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, time: DateTime.now(), error: error, stackTrace: stackTrace);

    // Crashlytics에 Fatal 에러 기록
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: message?.toString(),
        fatal: true,
      );
    }
  }

  /// Verbose 레벨 로그
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, time: DateTime.now(), error: error, stackTrace: stackTrace);
  }
}

/// 인증 관련 로거
class AuthLogger {
  static void logSignIn(String method, String? email) {
    logger.i('Sign in attempt', {'method': method, 'email': email});
  }

  static void logSignInSuccess(String userId) {
    logger.i('Sign in successful', {'userId': userId});
  }

  static void logSignInError(dynamic error, [StackTrace? stackTrace]) {
    logger.e('Sign in failed', error, stackTrace);
  }

  static void logSignOut() {
    logger.i('User signed out');
  }
}

/// 데이터베이스 관련 로거
class DatabaseLogger {
  static void logQuery(String table, String operation) {
    logger.d('Database query', {'table': table, 'operation': operation});
  }

  static void logError(String table, dynamic error, [StackTrace? stackTrace]) {
    logger.e('Database error: $table', error, stackTrace);
  }
}

/// 동기화 관련 로거
class SyncLogger {
  static void logSyncStart(String table) {
    logger.i('🔄 Sync started: $table');
  }

  static void logSyncComplete(String table, int count) {
    logger.i('✅ Sync completed: $table ($count items)');
  }

  static void logSyncError(String table, dynamic error, [StackTrace? stackTrace]) {
    logger.e('❌ Sync failed: $table', error, stackTrace);
  }
}

/// 성능 모니터링 로거
class PerformanceLogger {
  static void logLoadTime(String component, int milliseconds) {
    final level = milliseconds > 1000 ? 'w' : 'i';
    final emoji = milliseconds > 1000 ? '🐌' : '⚡';

    if (level == 'w') {
      logger.w('$emoji [$component] Slow load time: ${milliseconds}ms');
    } else {
      logger.i('$emoji [$component] Load time: ${milliseconds}ms');
    }
  }

  static void logApiCall(String endpoint, int milliseconds, {bool success = true}) {
    final emoji = success ? '🌐' : '❌';
    final message = '$emoji [API] $endpoint completed in ${milliseconds}ms';

    if (success) {
      logger.i(message);
    } else {
      logger.w(message);
    }
  }

  static void logMemoryUsage(String component, double memoryMB) {
    if (memoryMB > 100) {
      logger.w('🧠 [$component] High memory usage: ${memoryMB.toStringAsFixed(1)}MB');
    } else {
      logger.d('🧠 [$component] Memory usage: ${memoryMB.toStringAsFixed(1)}MB');
    }
  }
}

/// UI 관련 로거
class UILogger {
  static void logNavigation(String from, String to) {
    logger.i('🧭 Navigation: $from → $to');
  }

  static void logUserAction(String action, [Map<String, dynamic>? context]) {
    logger.i('👆 User action: $action', context);
  }

  static void logError(String component, dynamic error, [StackTrace? stackTrace]) {
    logger.e('🎨 UI Error [$component]', error, stackTrace);
  }
}

/// 알림 관련 로거
class NotificationLogger {
  static void logSchedule(DateTime scheduledTime) {
    logger.i('🔔 Notification scheduled: $scheduledTime');
  }

  static void logReceived(String title) {
    logger.i('📬 Notification received: $title');
  }

  static void logError(dynamic error, [StackTrace? stackTrace]) {
    logger.e('🔕 Notification error', error, stackTrace);
  }
}
