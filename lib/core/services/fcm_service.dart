import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/app_router.dart' as router;
import '../utils/logger.dart';
import 'device_info_service.dart';
import 'local_notification_service.dart';
import 'pending_notifications_service.dart';

/// Firebase Cloud Messaging 서비스
///
/// 역할:
/// 1. FCM 토큰 생성 및 관리
/// 2. 푸시 알림 수신 처리
/// 3. DeviceInfoService와 연동하여 토큰 업데이트
/// 4. 알림 탭 시 라우팅 처리
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  bool _isInitialized = false;
  String? _fcmToken;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('[FCM] Already initialized');
      return;
    }

    logger.i('[FCM] Initializing FCM service...');

    try {
      // 알림 권한 요청
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      logger.i('[FCM] Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // FCM 토큰 가져오기
        await _getFcmToken();

        // 토큰 갱신 리스너 설정
        _messaging.onTokenRefresh.listen((token) {
          logger.i('[FCM] Token refreshed');
          _fcmToken = token;
          _updateTokenToServer(token);
        });

        // 포그라운드 알림 리스너 설정
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 백그라운드 알림 탭 리스너 설정
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

        // 앱이 종료된 상태에서 알림 탭으로 실행된 경우
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessageTap(initialMessage);
        }

        _isInitialized = true;
        logger.i('[FCM] FCM service initialized successfully');
      } else {
        logger.w('[FCM] Notification permission denied');
      }
    } catch (e, stackTrace) {
      logger.e('[FCM] Failed to initialize FCM service', e, stackTrace);
      rethrow;
    }
  }

  /// FCM 토큰 가져오기
  Future<void> _getFcmToken() async {
    try {
      if (Platform.isIOS) {
        // iOS APNS 토큰 가져오기
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          logger.d('[FCM] APNS token: ${apnsToken.substring(0, 10)}...');
          await _deviceInfoService.updateApnsToken(apnsToken);
        }
      }

      // FCM 토큰 가져오기
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        logger.i('[FCM] FCM token: ${_fcmToken!.substring(0, 20)}...');
        await _updateTokenToServer(_fcmToken!);
      } else {
        logger.w('[FCM] Failed to get FCM token');
      }
    } catch (e, stackTrace) {
      logger.e('[FCM] Failed to get FCM token', e, stackTrace);
    }
  }

  /// 서버에 FCM 토큰 업데이트
  Future<void> _updateTokenToServer(String token) async {
    try {
      await _deviceInfoService.updateFcmToken(token);
      logger.i('[FCM] Token updated to server');
    } catch (e, stackTrace) {
      logger.e('[FCM] Failed to update token to server', e, stackTrace);
    }
  }

  /// 포그라운드 알림 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logger.i('[FCM] Received foreground message');
    logger.d('[FCM] Title: ${message.notification?.title}');
    logger.d('[FCM] Body: ${message.notification?.body}');
    logger.d('[FCM] Data: ${message.data}');

    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';

    // payload로 data 전달 (draft_id 등)
    String? payload;
    if (message.data.containsKey('draft_id')) {
      payload = 'draft:${message.data['draft_id']}';
    }

    // 알림 타입 확인
    final notificationType = message.data['notification_type'] as String?;

    // 방해금지 시간 체크
    final shouldDelay = await _shouldDelayNotification(notificationType);

    if (shouldDelay) {
      // 방해금지 시간대 → 대기 목록에 추가
      logger.i('[FCM] Adding notification to pending queue (quiet hours)');
      await PendingNotificationsService().addPendingNotification(
        title: title,
        body: body,
        payload: message.data,
      );
    } else {
      // 즉시 표시
      LocalNotificationService().showFcmNotification(
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  /// 알림을 지연시켜야 하는지 확인 (방해금지 시간대 체크)
  Future<bool> _shouldDelayNotification(String? notificationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = TimeOfDay.now();
      final currentMinutes = now.hour * 60 + now.minute;

      String? allowedStart;
      String? allowedEnd;

      // 알림 타입에 따라 설정 로드
      if (notificationType == 'draft_completion') {
        allowedStart = prefs.getString('draft_notification_start');
        allowedEnd = prefs.getString('draft_notification_end');
      } else if (notificationType == 'post_notification') {
        allowedStart = prefs.getString('post_notification_start');
        allowedEnd = prefs.getString('post_notification_end');
      }

      // 설정이 없으면 즉시 표시
      if (allowedStart == null || allowedEnd == null) {
        return false;
      }

      // 허용 시간대 파싱
      final startParts = allowedStart.split(':');
      final endParts = allowedEnd.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      // 자정을 넘어가는 경우 (예: 08:00 ~ 23:00의 역 = 23:00 ~ 08:00 방해금지)
      if (startMinutes > endMinutes) {
        // 현재 시간이 허용 범위 밖이면 지연
        return currentMinutes < startMinutes && currentMinutes >= endMinutes;
      } else {
        // 현재 시간이 허용 범위 안이면 즉시 표시
        return currentMinutes < startMinutes || currentMinutes >= endMinutes;
      }
    } catch (e, stack) {
      logger.e('[FCM] Failed to check quiet hours', e, stack);
      // 에러 발생 시 즉시 표시 (안전한 기본값)
      return false;
    }
  }

  /// 백그라운드/종료 상태에서 알림 탭 처리
  void _handleBackgroundMessageTap(RemoteMessage message) {
    logger.i('[FCM] User tapped notification');
    logger.d('[FCM] Data: ${message.data}');

    // Draft 생성 완료 알림 → Draft 상세 화면으로 이동
    final draftId = message.data['draft_id'];
    if (draftId != null) {
      logger.i('[FCM] Navigate to draft detail: $draftId');

      // GoRouter를 사용하여 네비게이션
      final context = router.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Drafts 페이지로 이동 (나중에 Draft 상세 라우트 추가 시 변경)
        GoRouter.of(context).go('/?tab=1');
      }
    }
  }

  /// 현재 FCM 토큰 반환
  String? get fcmToken => _fcmToken;

  /// 알림 권한 상태 확인
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// 서비스 정리
  void dispose() {
    logger.i('[FCM] Disposing FCM service');
    _isInitialized = false;
    _fcmToken = null;
  }
}

/// 백그라운드 메시지 핸들러 (top-level 함수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i('[FCM] Background message received');
  logger.d('[FCM] Title: ${message.notification?.title}');
  logger.d('[FCM] Body: ${message.notification?.body}');
  logger.d('[FCM] Data: ${message.data}');

  // 백그라운드에서 알림을 표시하려면 로컬 알림 서비스 사용
}
