import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// ShareActivity와 통신하는 Method Channel Service
///
/// Android: ShareActivity와 통신
/// iOS: Share Extension과 통신
class ShareActivityService {
  static const _channel = MethodChannel('com.minorlab.miniline/share');

  /// 현재 Activity가 ShareActivity인지 확인
  static Future<bool> isShareActivity() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('isShareActivity');
      return result == true;
    } catch (e) {
      // Method가 없으면 MainActivity (또는 다른 Activity)
      return false;
    }
  }

  /// ShareActivity에서 공유된 데이터 가져오기
  static Future<Map<String, dynamic>?> getSharedData() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getSharedData');
      if (result == null) return null;

      return Map<String, dynamic>.from(result as Map);
    } catch (e, stack) {
      logger.e('[ShareActivityService] Failed to get shared data', e, stack);
      return null;
    }
  }

  /// ShareActivity 종료
  static Future<void> closeShareActivity() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      await _channel.invokeMethod('closeShareActivity');
      logger.i('[ShareActivityService] Share activity closed');
    } catch (e, stack) {
      logger.e('[ShareActivityService] Failed to close share activity', e, stack);
    }
  }
}
