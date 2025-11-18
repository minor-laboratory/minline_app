import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart' as router;
import '../utils/logger.dart';
import 'analytics_service.dart';
import 'device_info_service.dart';
import 'local_notification_service.dart';

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
      // FCM 토큰 가져오기 (iOS는 자동으로 APNS 처리)
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
  ///
  /// 서버에서 사용자 언어로 번역된 메시지를 받아 표시
  /// (백그라운드/종료 상태에서도 동일한 메시지 사용 - iOS 호환)
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
    String? notificationType;
    if (message.data.containsKey('draft_id')) {
      payload = 'draft:${message.data['draft_id']}';
      notificationType = 'draft_created';
    }

    // Analytics 로그
    if (notificationType != null) {
      await AnalyticsService.logNotificationReceived(
        notificationType: notificationType,
      );
    }

    // 즉시 표시 (서버에서 방해금지 시간 이미 체크됨)
    LocalNotificationService().showFcmNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// 백그라운드/종료 상태에서 알림 탭 처리
  void _handleBackgroundMessageTap(RemoteMessage message) {
    logger.i('[FCM] User tapped notification');
    logger.d('[FCM] Data: ${message.data}');

    // Draft 생성 완료 알림 → Draft 상세 화면으로 이동
    final draftId = message.data['draft_id'];
    if (draftId != null) {
      logger.i('[FCM] Navigate to draft detail: $draftId');

      // Analytics 로그
      AnalyticsService.logNotificationOpened(
        notificationType: 'draft_created',
      );

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
