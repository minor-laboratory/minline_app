import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';
import 'local_notification_service.dart';

/// 방해금지 시간대에 도착한 알림을 보관하고 나중에 전달하는 서비스
class PendingNotificationsService {
  static const String _keyPendingNotifications = 'pending_notifications';

  Timer? _checkTimer;

  /// 알림 추가 (방해금지 시간대에 도착한 알림)
  Future<void> addPendingNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = await _loadPendingNotifications();

      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendingList.add(notification);

      await prefs.setString(
        _keyPendingNotifications,
        jsonEncode(pendingList),
      );

      logger.d('[PendingNotifications] Added notification: $title');
    } catch (e, stack) {
      logger.e('[PendingNotifications] Failed to add notification', e, stack);
    }
  }

  /// 대기 중인 알림 목록 로드
  Future<List<Map<String, dynamic>>> _loadPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPendingNotifications);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      logger.e('[PendingNotifications] Failed to load notifications', e, stack);
      return [];
    }
  }

  /// 방해금지 시간이 끝났을 때 대기 중인 알림 전달
  Future<void> deliverPendingNotifications() async {
    try {
      final pendingList = await _loadPendingNotifications();

      if (pendingList.isEmpty) {
        logger.d('[PendingNotifications] No pending notifications');
        return;
      }

      logger.d('[PendingNotifications] Delivering ${pendingList.length} notifications');

      // 알림 전달
      for (final notification in pendingList) {
        final title = notification['title'] as String;
        final body = notification['body'] as String;
        final payload = notification['payload'] as Map<String, dynamic>?;

        await LocalNotificationService().showFcmNotification(
          title: title,
          body: body,
          payload: payload != null ? jsonEncode(payload) : null,
        );
      }

      // 전달 완료 후 목록 초기화
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingNotifications);

      logger.d('[PendingNotifications] Delivered all pending notifications');
    } catch (e, stack) {
      logger.e('[PendingNotifications] Failed to deliver notifications', e, stack);
    }
  }

  /// 주기적으로 방해금지 시간 종료 체크 시작
  void startPeriodicCheck(
    Future<bool> Function() isQuietHoursActive,
  ) {
    // 기존 타이머 취소
    _checkTimer?.cancel();

    // 1분마다 체크
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final isActive = await isQuietHoursActive();

      if (!isActive) {
        // 방해금지 시간이 아니면 대기 중인 알림 전달
        await deliverPendingNotifications();
      }
    });

    logger.d('[PendingNotifications] Started periodic check');
  }

  /// 주기적 체크 중지
  void stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    logger.d('[PendingNotifications] Stopped periodic check');
  }

  /// 서비스 종료
  void dispose() {
    stopPeriodicCheck();
  }
}
