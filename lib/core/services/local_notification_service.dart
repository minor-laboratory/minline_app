import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../router/app_router.dart' as router;
import '../utils/logger.dart';

/// 로컬 알림 서비스
///
/// 역할:
/// 1. 로컬 알림 초기화 및 권한 요청
/// 2. 일일 입력 리마인더 스케줄링
/// 3. FCM 포그라운드 메시지 → 로컬 알림 표시
/// 4. 알림 탭 처리 (라우팅)
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // 알림 ID
  static const int _dailyReminderId = 1;
  static const int _draftCreatedId = 2;

  // 알림 채널 ID
  static const String _reminderChannelId = 'daily_reminder';
  static const String _draftChannelId = 'draft_created';

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('[LocalNotification] Already initialized');
      return;
    }

    try {
      logger.i('[LocalNotification] Initializing...');

      // Android 설정
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정
      const iOSSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      // 알림 탭 핸들러 설정
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android 채널 생성
      await _createNotificationChannels();

      // 권한 요청
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
        await _requestIOSPermissions();
      } else if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
        await _requestAndroidPermissions();
      }

      _isInitialized = true;
      logger.i('[LocalNotification] Initialized successfully');
    } catch (e, stackTrace) {
      logger.e('[LocalNotification] Failed to initialize', e, stackTrace);
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createNotificationChannels() async {
    // 일일 리마인더 채널
    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Daily Reminder',
      description: 'Daily reminder to write your thoughts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Draft 생성 완료 채널
    const draftChannel = AndroidNotificationChannel(
      _draftChannelId,
      'Draft Created',
      description: 'Notifications for AI-generated drafts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(reminderChannel);
    await androidImplementation?.createNotificationChannel(draftChannel);
  }

  /// iOS 권한 요청
  Future<void> _requestIOSPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Android 권한 요청
  Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      logger.i('[LocalNotification] Android permission granted: $granted');
    }
  }

  /// 알림 탭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    logger.i('[LocalNotification] Notification tapped');
    logger.d('[LocalNotification] Payload: ${response.payload}');

    // Draft 알림 탭 → Drafts 페이지로 이동
    if (response.payload != null && response.payload!.startsWith('draft:')) {
      final draftId = response.payload!.replaceFirst('draft:', '');
      logger.i('[LocalNotification] Navigate to draft: $draftId');

      // GoRouter 사용하여 네비게이션
      // navigatorKey를 import해서 사용
      final navigatorKey = _getNavigatorKey();
      final context = navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        // Drafts 페이지로 이동 (나중에 Draft 상세 라우트 추가 시 변경)
        context.go('/drafts');
      }
    }
  }

  /// Navigator Key 가져오기 (app_router에서)
  GlobalKey<NavigatorState>? _getNavigatorKey() {
    return router.navigatorKey;
  }

  /// 일일 리마인더 스케줄링
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      logger.i('[LocalNotification] Scheduling daily reminder at $hour:$minute');

      await _plugin.zonedSchedule(
        _dailyReminderId,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannelId,
            'Daily Reminder',
            channelDescription: 'Daily reminder to write your thoughts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      logger.i('[LocalNotification] Daily reminder scheduled successfully');
    } catch (e, stackTrace) {
      logger.e('[LocalNotification] Failed to schedule daily reminder', e, stackTrace);
    }
  }

  /// 일일 리마인더 취소
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(_dailyReminderId);
      logger.i('[LocalNotification] Daily reminder cancelled');
    } catch (e, stackTrace) {
      logger.e('[LocalNotification] Failed to cancel daily reminder', e, stackTrace);
    }
  }

  /// Draft 생성 완료 알림 표시
  Future<void> showDraftCreatedNotification({
    required String draftId,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      logger.i('[LocalNotification] Showing draft created notification');

      await _plugin.show(
        _draftCreatedId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _draftChannelId,
            'Draft Created',
            channelDescription: 'Notifications for AI-generated drafts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'draft:$draftId',
      );

      logger.i('[LocalNotification] Draft notification shown');
    } catch (e, stackTrace) {
      logger.e('[LocalNotification] Failed to show draft notification', e, stackTrace);
    }
  }

  /// FCM 포그라운드 메시지 → 로컬 알림 표시
  Future<void> showFcmNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      logger.i('[LocalNotification] Showing FCM notification');

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _draftChannelId,
            'Draft Created',
            channelDescription: 'Notifications for AI-generated drafts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      logger.i('[LocalNotification] FCM notification shown');
    } catch (e, stackTrace) {
      logger.e('[LocalNotification] Failed to show FCM notification', e, stackTrace);
    }
  }

  /// 다음 지정 시간 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 알림 권한 상태 확인
  Future<bool> hasPermission() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
    }

    return true; // iOS는 시스템 설정에서만 확인 가능
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    }

    return true;
  }

  /// 서비스 정리
  void dispose() {
    logger.i('[LocalNotification] Disposing');
    _isInitialized = false;
  }
}
