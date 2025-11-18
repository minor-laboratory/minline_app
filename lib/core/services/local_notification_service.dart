import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/main/presentation/pages/main_page.dart';
import '../../features/timeline/presentation/widgets/fragment_input_bar.dart';
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

  // 알림 ID (요일별: 101~107)
  static const int _baseReminderId = 100;
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

      // Timezone 초기화 (scheduled notifications용)
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // 디버깅: Timezone 확인
      final now = tz.TZDateTime.now(tz.local);
      final systemNow = DateTime.now();
      logger.i('[LocalNotification] Timezone: ${tz.local.name}');
      logger.i('[LocalNotification] TZ Now: $now');
      logger.i('[LocalNotification] System Now: $systemNow');

      // Android 설정
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

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

      // 앱 종료 상태에서 notification 탭으로 시작되었는지 확인
      await _checkAppLaunchFromNotification();

      // 디버깅: 예약된 알림 목록 확인
      await _logPendingNotifications();
    } catch (e, stackTrace) {
      logger.e('[LocalNotification] Failed to initialize', e, stackTrace);
    }
  }

  /// 앱이 notification 탭으로 시작되었는지 확인
  Future<void> _checkAppLaunchFromNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();

      if (details != null && details.didNotificationLaunchApp) {
        logger.i('[LocalNotification] App launched from notification');
        final payload = details.notificationResponse?.payload;

        if (payload != null) {
          logger.d('[LocalNotification] Launch payload: $payload');

          // 화면이 준비될 때까지 대기 후 navigation
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleNotificationPayload(payload);
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e(
        '[LocalNotification] Failed to check app launch details',
        e,
        stackTrace,
      );
    }
  }

  /// Notification payload 처리
  void _handleNotificationPayload(String payload) {
    // 일일 리마인더: 입력창 표시
    if (payload.isEmpty || payload.startsWith('reminder:')) {
      logger.i('[LocalNotification] Show input from notification');
      _showInputFromNotification();
      return;
    }

    // Draft 알림: Drafts 페이지로 이동
    if (payload.startsWith('draft:')) {
      final draftId = payload.replaceFirst('draft:', '');
      logger.i('[LocalNotification] Navigate to draft from launch: $draftId');
      _navigateToDraft(draftId);
      return;
    }
  }

  /// 예약된 알림 목록 확인 (디버깅용)
  Future<void> _logPendingNotifications() async {
    try {
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      logger.i(
        '[LocalNotification] 📋 Pending notifications: ${pendingNotifications.length}',
      );

      if (pendingNotifications.isEmpty) {
        logger.w('[LocalNotification] ⚠️ No pending notifications found!');
      } else {
        for (final notification in pendingNotifications) {
          logger.i(
            '[LocalNotification] - ID: ${notification.id}, Title: ${notification.title}',
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e(
        '[LocalNotification] Failed to get pending notifications',
        e,
        stackTrace,
      );
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
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(reminderChannel);
    await androidImplementation?.createNotificationChannel(draftChannel);
  }

  /// iOS 권한 요청
  Future<void> _requestIOSPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Android 권한 요청
  Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      logger.i('[LocalNotification] Android permission granted: $granted');
    }
  }

  /// 알림 탭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    logger.i('[LocalNotification] Notification tapped');
    logger.d('[LocalNotification] Payload: ${response.payload}');

    final payload = response.payload ?? '';

    // 일일 리마인더: 입력창 표시 (타임라인이면 포커스, 아니면 모달)
    if (payload.isEmpty || payload.startsWith('reminder:')) {
      logger.i('[LocalNotification] Show input from notification');
      _showInputFromNotification();
      return;
    }

    // Draft 알림 탭 → Drafts 페이지로 이동
    if (payload.startsWith('draft:')) {
      final draftId = payload.replaceFirst('draft:', '');
      logger.i('[LocalNotification] Navigate to draft: $draftId');
      _navigateToDraft(draftId);
      return;
    }
  }

  /// Navigator Key 가져오기 (app_router에서)
  GlobalKey<NavigatorState>? _getNavigatorKey() {
    return router.navigatorKey;
  }

  /// Notification 탭 시 입력창 표시
  /// 1. 현재 홈화면 타임라인인 경우: 입력창 포커스
  /// 2. 그 외 모든 경우: 공유 입력 모달 표시
  void _showInputFromNotification() {
    final navigatorKey = _getNavigatorKey();
    final context = navigatorKey?.currentContext;

    if (context == null || !context.mounted) {
      logger.w('[LocalNotification] Context not available');
      return;
    }

    // 1. MainPage가 활성화되어 있고, callback이 있으면 사용
    //    (타임라인이면 focus, 다른 탭이면 modal)
    if (MainPage.onTabChangeRequested != null) {
      logger.i('[LocalNotification] Requesting input via MainPage');
      MainPage.onTabChangeRequested!(0);
    } else {
      // 2. MainPage가 아닌 다른 화면 (설정, post 상세 등)
      //    → Fragment 입력 모달 표시
      logger.i(
        '[LocalNotification] Showing fragment input modal (not on MainPage)',
      );
      showFragmentInputModal(context);
    }
  }

  /// Drafts 페이지로 이동
  void _navigateToDraft(String draftId) {
    final navigatorKey = _getNavigatorKey();
    final context = navigatorKey?.currentContext;

    if (context != null && context.mounted) {
      // Drafts 페이지로 이동 (나중에 Draft 상세 라우트 추가 시 변경)
      context.go('/?tab=1');
    } else {
      logger.w('[LocalNotification] Context not available for navigation');
    }
  }

  /// 일일 리마인더 스케줄링 (요일별)
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    Set<int> weekdays = const {1, 2, 3, 4, 5, 6, 7}, // 기본: 매일
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      logger.i(
        '[LocalNotification] Scheduling reminders for weekdays: $weekdays at $hour:$minute',
      );

      // 기존 알림 모두 취소
      await cancelDailyReminder();

      // 모든 요일 선택 시: 매일 반복 (더 안정적)
      if (weekdays.length == 7) {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // 오늘 시간이 지났으면 내일
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        logger.d(
          '[LocalNotification] - Daily (ID: $_baseReminderId) → ${scheduledDate.toString()}',
        );

        await _plugin.zonedSchedule(
          _baseReminderId,
          title,
          body,
          scheduledDate,
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
          matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
        );
      } else {
        // 특정 요일만 선택: 요일별 스케줄링
        for (final weekday in weekdays) {
          final notificationId = _baseReminderId + weekday;
          final scheduledDate = _nextInstanceOfDayAndTime(
            weekday,
            hour,
            minute,
          );

          logger.d(
            '[LocalNotification] - Weekday $weekday (ID: $notificationId) → ${scheduledDate.toString()}',
          );

          await _plugin.zonedSchedule(
            notificationId,
            title,
            body,
            scheduledDate,
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
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }

      logger.i('[LocalNotification] Daily reminders scheduled successfully');

      // 디버깅: 예약된 알림 목록 확인
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      logger.i(
        '[LocalNotification] Pending notifications count: ${pendingNotifications.length}',
      );
      for (final notification in pendingNotifications) {
        logger.d(
          '[LocalNotification] - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}',
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        '[LocalNotification] Failed to schedule daily reminder',
        e,
        stackTrace,
      );
    }
  }

  /// 일일 리마인더 취소
  Future<void> cancelDailyReminder() async {
    try {
      // 모든 요일 알림 취소 (101~107)
      for (int weekday = 1; weekday <= 7; weekday++) {
        await _plugin.cancel(_baseReminderId + weekday);
      }
      logger.i('[LocalNotification] Daily reminders cancelled');
    } catch (e, stackTrace) {
      logger.e(
        '[LocalNotification] Failed to cancel daily reminder',
        e,
        stackTrace,
      );
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
      logger.e(
        '[LocalNotification] Failed to show draft notification',
        e,
        stackTrace,
      );
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
      logger.e(
        '[LocalNotification] Failed to show FCM notification',
        e,
        stackTrace,
      );
    }
  }

  /// 다음 지정 요일 및 시간 계산
  tz.TZDateTime _nextInstanceOfDayAndTime(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 현재 요일과 목표 요일 차이 계산
    int daysToAdd = (weekday - now.weekday) % 7;

    // 오늘이 목표 요일이지만 시간이 지났으면 다음 주
    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      daysToAdd = 7;
    }

    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));
    return scheduledDate;
  }

  /// 알림 권한 상태 확인
  Future<bool> hasPermission() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

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
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        return granted ?? false;
      }
    }

    return true;
  }

  /// Exact alarm 권한 확인 (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final canSchedule = await androidImplementation
            .canScheduleExactNotifications();
        return canSchedule ?? false;
      }
    }
    return true; // iOS는 exact alarm 권한 불필요
  }

  /// Exact alarm 권한 요청 (Android 12+)
  /// Settings 화면으로 이동하여 사용자가 직접 권한 부여
  Future<void> requestExactAlarmPermission() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  /// 테스트 알림 표시 (디버깅용)
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      logger.i('[LocalNotification] Showing test notification');

      await _plugin.show(
        999,
        '스냅 작성 시간이에요',
        '오늘 하루를 기록해보세요',
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
        payload: 'reminder:test',
      );

      logger.i('[LocalNotification] Test notification shown');
    } catch (e, stackTrace) {
      logger.e(
        '[LocalNotification] Failed to show test notification',
        e,
        stackTrace,
      );
    }
  }

  /// 서비스 정리
  void dispose() {
    logger.i('[LocalNotification] Disposing');
    _isInitialized = false;
  }
}
