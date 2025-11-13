import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'logger.dart';

/// 네트워크 관련 에러 처리 유틸리티
class NetworkErrorHandler {
  static const String _tag = 'NetworkErrorHandler';

  /// Supabase 관련 에러를 분석하고 사용자 친화적인 메시지 반환
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error occurred';

    final errorString = error.toString();

    // AuthRetryableFetchException 처리
    if (error is AuthRetryableFetchException ||
        errorString.contains('AuthRetryableFetchException')) {
      if (errorString.contains('SocketException') ||
          errorString.contains('Failed host lookup')) {
        return 'Network connection failed. Please check your internet connection.';
      }
      if (errorString.contains('TimeoutException')) {
        return 'Connection timeout. Please try again.';
      }
      return 'Authentication service temporarily unavailable. Please try again.';
    }

    // PostgrestException 처리
    if (error is PostgrestException) {
      if (error.code == 'PGRST301') {
        return 'Server temporarily unavailable. Please try again.';
      }
      if (error.code?.startsWith('PGRST') == true) {
        return 'Database service error. Please try again.';
      }
    }

    // SocketException 처리
    if (error is SocketException || errorString.contains('SocketException')) {
      if (errorString.contains('Failed host lookup')) {
        return 'Cannot reach server. Please check your internet connection.';
      }
      if (errorString.contains('Network is unreachable')) {
        return 'Network is unreachable. Please check your connection.';
      }
      return 'Network connection error. Please try again.';
    }

    // StorageException 처리
    if (error is StorageException) {
      if (error.statusCode == '404') {
        return 'File not found.';
      }
      if (error.statusCode == '413') {
        return 'File too large.';
      }
      return 'File storage error. Please try again.';
    }

    // 일반적인 HTTP 에러 처리
    if (errorString.contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    }

    if (errorString.contains('HandshakeException')) {
      return 'Secure connection failed. Please check your connection.';
    }

    // 기본 메시지
    return 'Service temporarily unavailable. Please try again.';
  }

  /// 에러 타입 분류
  static NetworkErrorType getErrorType(dynamic error) {
    if (error == null) return NetworkErrorType.unknown;

    final errorString = error.toString();

    if (error is SocketException ||
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('Network is unreachable')) {
      return NetworkErrorType.noConnection;
    }

    if (error is AuthRetryableFetchException ||
        errorString.contains('AuthRetryableFetchException')) {
      return NetworkErrorType.authError;
    }

    if (errorString.contains('TimeoutException')) {
      return NetworkErrorType.timeout;
    }

    if (error is PostgrestException || error is StorageException) {
      return NetworkErrorType.serverError;
    }

    return NetworkErrorType.unknown;
  }

  /// 재시도 가능 여부 판단
  static bool isRetryable(dynamic error) {
    final errorType = getErrorType(error);
    switch (errorType) {
      case NetworkErrorType.noConnection:
      case NetworkErrorType.timeout:
      case NetworkErrorType.serverError:
        return true;
      case NetworkErrorType.authError:
        return false; // 인증 에러는 일반적으로 재시도하지 않음
      case NetworkErrorType.unknown:
        return false;
    }
  }

  /// 에러 로깅
  static void logError(dynamic error, String operation, [StackTrace? stackTrace]) {
    final errorType = getErrorType(error);
    final message = getErrorMessage(error);

    logger.e('[$_tag] $operation failed - Type: $errorType, Message: $message',
        error, stackTrace);
  }

  /// 간단한 연결 상태 확인
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// 네트워크 에러 타입
enum NetworkErrorType {
  noConnection,  // 네트워크 연결 없음
  timeout,       // 타임아웃
  authError,     // 인증 에러
  serverError,   // 서버 에러
  unknown,       // 알 수 없는 에러
}
