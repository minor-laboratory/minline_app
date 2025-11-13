import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/logger.dart';
import 'isar_watch_sync_service.dart';
import 'supabase_stream_service.dart';

part 'lifecycle_service.g.dart';

/// 앱 생명주기 및 네트워크 상태에 따른 동기화 서비스 관리
///
/// 역할:
/// 1. 앱 생명주기 이벤트 처리 (foreground/background)
/// 2. 네트워크 상태 변경 감지 및 처리
/// 3. 인증 상태 변경 처리
/// 4. 동기화 서비스들의 시작/중지 제어
@riverpod
LifecycleService lifecycleService(Ref ref) {
  return LifecycleService(ref);
}

class LifecycleService with WidgetsBindingObserver {
  final Ref _ref;

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

  LifecycleService(this._ref);

  /// 동기화 가능 조건
  bool get _canSync => _isLoggedIn && _isInForeground && _hasNetwork;

  /// 초기화
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
    _updateSyncServices();
  }

  /// 사용자 로그아웃 시
  void _onUserLoggedOut() {
    logger.i('[LifecycleService] User logged out - stopping sync services');
    _isLoggedIn = false;
    _stopAllServices();
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

    // IsarWatchSyncService 시작 (로컬 → 서버)
    final isarWatchService = _ref.read(isarWatchSyncServiceProvider);
    isarWatchService.start().then((_) {
      logger.d('[LifecycleService] IsarWatchSyncService started');
    }).catchError((e, stack) {
      logger.e('[LifecycleService] Failed to start IsarWatchSyncService', e,
          stack);
    });

    // SupabaseStreamService 시작 (서버 → 로컬)
    final supabaseStreamService = _ref.read(supabaseStreamServiceProvider);
    supabaseStreamService.startListening().then((_) {
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

    // IsarWatchSyncService 중지
    final isarWatchService = _ref.read(isarWatchSyncServiceProvider);
    isarWatchService.stop().then((_) {
      logger.d('[LifecycleService] IsarWatchSyncService stopped');
    }).catchError((e, stack) {
      logger.e(
          '[LifecycleService] Failed to stop IsarWatchSyncService', e, stack);
    });

    // SupabaseStreamService 중지
    final supabaseStreamService = _ref.read(supabaseStreamServiceProvider);
    supabaseStreamService.stopListening().then((_) {
      logger.d('[LifecycleService] SupabaseStreamService stopped');
    }).catchError((e, stack) {
      logger.e(
          '[LifecycleService] Failed to stop SupabaseStreamService', e, stack);
    });
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

    // 서비스 중지
    _stopAllServices();

    _isInitialized = false;
    logger.i('[LifecycleService] Disposed');
  }
}
