import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../features/settings/providers/draft_notification_settings_provider.dart';
import '../../../features/settings/providers/post_notification_settings_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../constants/notification_type.dart';
import '../../utils/logger.dart';
import 'isar_watch_sync_service_provider.dart';
import 'supabase_stream_service_provider.dart';

/// 앱 생명주기 및 네트워크 상태에 따른 동기화 서비스 관리
///
/// 역할:
/// 1. 앱 생명주기 이벤트 처리 (foreground/background)
/// 2. 네트워크 상태 변경 감지 및 처리
/// 3. 인증 상태 변경 처리
/// 4. 동기화 서비스들의 시작/중지 제어
///
/// Lifecycle: @Riverpod(keepAlive: true) Provider로 관리
class LifecycleService with WidgetsBindingObserver {
  final Ref _ref;

  LifecycleService(this._ref);

  // 서비스 상태
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isInForeground = true;
  bool _hasNetwork = true;
  bool _isServicesRunning = false; // 중복 시작 방지 플래그

  // 네트워크 연결 감지
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Auth 상태 감지
  StreamSubscription<AuthState>? _authSubscription;

  /// 동기화 가능 조건
  bool get _canSync => _isLoggedIn && _isInForeground && _hasNetwork;

  /// 초기화 (main.dart에서 호출)
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('[LifecycleService] Already initialized');
      return;
    }

    logger.i('[LifecycleService] Initializing...');

    // WidgetsBinding 옵저버 등록
    WidgetsBinding.instance.addObserver(this);

    // 네트워크 상태 감지 시작
    _startNetworkMonitoring();

    // Auth 상태 감지 시작
    _startAuthMonitoring();

    _isInitialized = true;
    logger.i('[LifecycleService] Initialized successfully');
  }

  /// 네트워크 상태 모니터링 시작
  void _startNetworkMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.isNotEmpty &&
            !results.contains(ConnectivityResult.none);

        if (hasConnection != _hasNetwork) {
          logger.i('[LifecycleService] Network state changed: $hasConnection');
          _hasNetwork = hasConnection;
          _updateSyncServices();
        }
      },
    );

    // 초기 네트워크 상태 확인
    _connectivity.checkConnectivity().then((results) {
      _hasNetwork =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      logger.d('[LifecycleService] Initial network state: $_hasNetwork');
    });
  }

  /// Auth 상태 모니터링 시작
  void _startAuthMonitoring() {
    final supabase = Supabase.instance.client;

    // 초기 인증 상태 확인
    final user = supabase.auth.currentUser;
    _isLoggedIn = user != null && !user.isAnonymous;
    logger.d(
        '[LifecycleService] Initial auth state: ${_isLoggedIn ? 'logged in' : 'logged out'}');

    // 이미 로그인되어 있으면 초기화
    if (_isLoggedIn) {
      _onUserLoggedIn();
    }

    // Auth 상태 변경 감지
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        logger.i('[LifecycleService] User signed in');
        _onUserLoggedIn();
      } else if (event == AuthChangeEvent.signedOut) {
        logger.i('[LifecycleService] User signed out');
        _onUserLoggedOut();
      }
    });
  }

  /// 사용자 로그인 시
  void _onUserLoggedIn() {
    logger.i('[LifecycleService] User logged in - preparing sync services');
    _isLoggedIn = true;

    // 알림 설정 초기화 (없으면 생성)
    _initializeNotificationSettings();

    // keepAlive Provider로 관리되므로 인스턴스 저장 불필요
    logger.d('[LifecycleService] Sync services will be accessed via Provider');

    _updateSyncServices();
  }

  /// 알림 설정 초기화
  ///
  /// 서버에서 데이터를 가져와 SharedPreferences 캐시에 저장
  /// 이후 Provider가 캐시에서 바로 읽을 수 있도록 함
  ///
  /// Race Condition 방지:
  /// - 이 메서드에서 한 번에 INSERT (Provider는 INSERT 안함)
  /// - Provider는 캐시에서만 읽음
  Future<void> _initializeNotificationSettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      // 서버에서 알림 설정 조회
      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('app_name', 'miniline');

      final prefs = await _ref.read(sharedPreferencesProvider.future);

      // 설정 값 준비
      Map<String, dynamic>? draftSettings;
      Map<String, dynamic>? postSettings;

      if (response.isNotEmpty) {
        // 서버에서 데이터 가져오기
        logger.d('[LifecycleService] Notification settings exist - loading from server');

        final draftList = response.where(
          (item) => item['notification_type'] == NotificationType.draftCompletion.value,
        ).toList();
        if (draftList.isNotEmpty) {
          draftSettings = draftList.first;
        }

        final postList = response.where(
          (item) => item['notification_type'] == NotificationType.postCreation.value,
        ).toList();
        if (postList.isNotEmpty) {
          postSettings = postList.first;
        }
      } else {
        // 데이터 없으면 INSERT 후 기본값 사용
        logger.d('[LifecycleService] No settings found - inserting default settings');

        final timezone = tz.local.name; // IANA 형식 (예: "Asia/Seoul")

        // QuietHours 기본값(23:00-08:00)의 역전 = Allowed Time (08:00-23:00)
        // Draft와 Post 모두 동일한 allowed time 사용
        const defaultAllowedStart = '08:00';
        const defaultAllowedEnd = '23:00';

        // INSERT용 데이터 준비 (캐시 저장에도 재사용)
        draftSettings = {
          'user_id': userId,
          'app_name': 'miniline',
          'notification_type': NotificationType.draftCompletion.value,
          'enabled': true,
          'settings': {
            'allowed_start': defaultAllowedStart,
            'allowed_end': defaultAllowedEnd,
            'timezone': timezone,
          },
        };

        postSettings = {
          'user_id': userId,
          'app_name': 'miniline',
          'notification_type': NotificationType.postCreation.value,
          'enabled': true,
          'settings': {
            'allowed_start': defaultAllowedStart,
            'allowed_end': defaultAllowedEnd,
            'timezone': timezone,
          },
        };

        // 서버에 INSERT (객체 재사용)
        await supabase.from('user_notification_settings').insert([
          draftSettings,
          postSettings,
        ]);

        logger.i('[LifecycleService] Notification settings initialized (timezone: $timezone)');
      }

      // 캐시에 한 번에 저장 (서버 또는 기본값)
      await Future.wait([
        if (draftSettings != null) ...[
          prefs.setBool('draft_notification_enabled', draftSettings['enabled'] as bool),
          prefs.setString('draft_notification_start', draftSettings['settings']['allowed_start'] as String),
          prefs.setString('draft_notification_end', draftSettings['settings']['allowed_end'] as String),
          prefs.setString('draft_notification_timezone', draftSettings['settings']['timezone'] as String),
        ],
        if (postSettings != null) ...[
          prefs.setBool('post_notification_enabled', postSettings['enabled'] as bool),
          prefs.setString('post_notification_start', postSettings['settings']['allowed_start'] as String),
          prefs.setString('post_notification_end', postSettings['settings']['allowed_end'] as String),
          prefs.setString('post_notification_timezone', postSettings['settings']['timezone'] as String),
        ],
      ]);

      logger.d('[LifecycleService] Settings saved to cache');

      // Provider refresh → 캐시에서 읽음 (INSERT 안함)
      logger.d('[LifecycleService] Invalidating providers to load from cache');
      _ref.invalidate(draftNotificationSettingsProvider);
      _ref.invalidate(postNotificationSettingsProvider);
    } catch (e, stack) {
      logger.e('[LifecycleService] Failed to initialize notification settings', e, stack);
    }
  }

  /// 사용자 로그아웃 시
  void _onUserLoggedOut() {
    logger.i('[LifecycleService] User logged out - stopping sync services');
    _isLoggedIn = false;

    // 모든 동기화 서비스 중지
    _stopAllServices();

    // keepAlive Provider로 관리되므로 인스턴스 정리 불필요
    logger.d('[LifecycleService] Sync services stopped');
  }

  /// 앱 생명주기 상태 변경 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d('[LifecycleService] App lifecycle changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        logger.i('[LifecycleService] App resumed - restarting services');
        _updateSyncServices();
        break;

      case AppLifecycleState.paused:
        _isInForeground = false;
        logger.i('[LifecycleService] App paused - pausing services');
        _updateSyncServices();
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 다른 상태는 무시
        break;
    }
  }

  /// 동기화 서비스 상태 업데이트
  void _updateSyncServices() {
    logger.d('[LifecycleService] Checking sync conditions - '
        'logged in: $_isLoggedIn, foreground: $_isInForeground, network: $_hasNetwork, running: $_isServicesRunning');

    if (_canSync && !_isServicesRunning) {
      logger.i('[LifecycleService] All conditions met - starting services');
      _startAllServices();
    } else if (!_canSync && _isServicesRunning) {
      final reasons = <String>[];
      if (!_isLoggedIn) reasons.add('not logged in');
      if (!_isInForeground) reasons.add('in background');
      if (!_hasNetwork) reasons.add('no network');

      logger.i(
          '[LifecycleService] Conditions not met - stopping services (${reasons.join(', ')})');
      _stopAllServices();
    } else {
      logger.d('[LifecycleService] No state change needed');
    }
  }

  /// 모든 동기화 서비스 시작
  void _startAllServices() {
    // 중복 시작 방지
    if (_isServicesRunning) {
      logger.d('[LifecycleService] Services already running - skipping start');
      return;
    }

    _isServicesRunning = true; // 플래그 먼저 설정
    logger.i('[LifecycleService] Starting all sync services');

    // IsarWatchSyncService 시작 (로컬 → 서버) - keepAlive Provider로 접근
    _ref.read(isarWatchSyncServiceProvider).start().then((_) {
      logger.d('[LifecycleService] IsarWatchSyncService started');
    }).catchError((e, stack) {
      logger.e('[LifecycleService] Failed to start IsarWatchSyncService', e,
          stack);
    });

    // SupabaseStreamService 시작 (서버 → 로컬) - keepAlive Provider로 접근
    _ref.read(supabaseStreamServiceProvider).startListening().then((_) {
      logger.d('[LifecycleService] SupabaseStreamService started');
    }).catchError((e, stack) {
      logger.e(
          '[LifecycleService] Failed to start SupabaseStreamService', e, stack);
    });
  }

  /// 모든 동기화 서비스 중지
  void _stopAllServices() {
    // 중복 중지 방지
    if (!_isServicesRunning) {
      logger.d('[LifecycleService] Services not running - skipping stop');
      return;
    }

    _isServicesRunning = false; // 플래그 먼저 설정
    logger.i('[LifecycleService] Stopping all sync services');

    // IsarWatchSyncService 중지 - keepAlive Provider로 접근
    _ref.read(isarWatchSyncServiceProvider).stop();
    logger.d('[LifecycleService] IsarWatchSyncService stopped');

    // SupabaseStreamService 중지 - keepAlive Provider로 접근
    _ref.read(supabaseStreamServiceProvider).stopListening();
    logger.d('[LifecycleService] SupabaseStreamService stopped');
  }

  /// 수동 동기화 트리거
  Future<void> triggerManualSync() async {
    logger.i('[LifecycleService] Manual sync triggered');

    if (!_canSync) {
      final reasons = <String>[];
      if (!_isLoggedIn) reasons.add('not logged in');
      if (!_isInForeground) reasons.add('in background');
      if (!_hasNetwork) reasons.add('no network');

      logger.w(
          '[LifecycleService] Cannot sync - conditions not met: ${reasons.join(', ')}');
      return;
    }

    // 서비스 재시작으로 동기화 트리거
    _stopAllServices();
    await Future.delayed(const Duration(milliseconds: 100));
    _startAllServices();
  }

  /// 정리
  void dispose() {
    logger.i('[LifecycleService] Disposing...');

    // WidgetsBinding 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);

    // 구독 해제
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();

    // 서비스 중지 (Provider가 lifecycle 관리)
    _stopAllServices();

    _isInitialized = false;
    logger.i('[LifecycleService] Disposed');
  }
}
