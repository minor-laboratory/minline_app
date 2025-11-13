import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/logger.dart';

/// 디바이스 정보 수집 및 서버 동기화 서비스
///
/// 역할:
/// 1. 앱 설치당 하나의 고유 디바이스 ID 생성
/// 2. 플랫폼별 디바이스 정보 수집 (OS, 기기명, 앱 버전 등)
/// 3. Supabase devices 테이블 UPSERT
/// 4. 익명/로그인 사용자 모두 지원
/// 5. 앱 시작/포그라운드 진입 시 자동 갱신
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Uuid _uuid = Uuid();

  // 사용자별 디바이스 ID 저장 키
  static const String _deviceIdPrefix = 'device_id_';

  bool _isInitialized = false;
  String? _cachedDeviceId;
  Map<String, dynamic>? _cachedDeviceInfo;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('[DeviceInfo] Already initialized');
      return;
    }

    logger.i('[DeviceInfo] Initializing device info service...');

    try {
      // 사용자별 디바이스 ID 로드/생성
      await _loadOrCreateDeviceId();

      // 플랫폼별 디바이스 정보 수집
      await _loadDeviceInfo();

      _isInitialized = true;
      logger.i('[DeviceInfo] Device info service initialized successfully');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to initialize device info service', e, stackTrace);
      rethrow;
    }
  }

  /// 사용자별 디바이스 ID 로드 또는 생성
  Future<void> _loadOrCreateDeviceId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        logger.w('[DeviceInfo] No user available - device ID will be generated on server update');
        return;
      }

      final userId = user.id;
      final deviceIdKey = '$_deviceIdPrefix$userId';

      // 이미 캐시된 경우
      if (_cachedDeviceId != null) return;

      // 사용자별 저장된 UUID 확인
      String? existingId = await _secureStorage.read(key: deviceIdKey);

      if (existingId != null && existingId.isNotEmpty) {
        _cachedDeviceId = existingId;
        logger.d('[DeviceInfo] Loaded existing device ID: ${existingId.substring(0, 8)}...');
      } else {
        // 새로운 UUID 생성 (사용자별)
        final newId = _uuid.v4();
        await _secureStorage.write(key: deviceIdKey, value: newId);
        _cachedDeviceId = newId;
        logger.i('[DeviceInfo] Generated new device ID: ${newId.substring(0, 8)}...');
      }
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to load or create device ID', e, stackTrace);
      rethrow;
    }
  }

  /// 디바이스 정보 로드 및 캐싱
  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platformDeviceInfo = await _collectPlatformDeviceInfo();

      _cachedDeviceInfo = {
        ...platformDeviceInfo,
        'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
        'package_name': packageInfo.packageName,
      };

      logger.d('[DeviceInfo] Device info cached');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to load device info', e, stackTrace);
      rethrow;
    }
  }

  /// 플랫폼별 디바이스 정보 수집
  Future<Map<String, dynamic>> _collectPlatformDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidInfo();
      } else if (Platform.isIOS) {
        return await _getIOSInfo();
      } else if (kIsWeb) {
        return _getWebInfo();
      } else {
        return _getUnknownInfo();
      }
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to collect platform device info', e, stackTrace);
      return _getUnknownInfo();
    }
  }

  /// Android 디바이스 정보 수집
  Future<Map<String, dynamic>> _getAndroidInfo() async {
    final androidInfo = await _deviceInfo.androidInfo;

    return {
      'device_type': 'android',
      'device_name': '${androidInfo.brand} ${androidInfo.model}',
      'os_version': 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})',
      'model': androidInfo.model,
      'brand': androidInfo.brand,
      'manufacturer': androidInfo.manufacturer,
    };
  }

  /// iOS 디바이스 정보 수집
  Future<Map<String, dynamic>> _getIOSInfo() async {
    final iosInfo = await _deviceInfo.iosInfo;

    return {
      'device_type': 'ios',
      'device_name': '${iosInfo.name} (${iosInfo.model})',
      'os_version': 'iOS ${iosInfo.systemVersion}',
      'model': iosInfo.model,
    };
  }

  /// Web 디바이스 정보 수집
  Map<String, dynamic> _getWebInfo() {
    return {
      'device_type': 'web',
      'device_name': 'Web Browser',
      'os_version': 'Web',
    };
  }

  /// 알 수 없는 플랫폼 정보
  Map<String, dynamic> _getUnknownInfo() {
    return {
      'device_type': 'unknown',
      'device_name': 'Unknown Device',
      'os_version': 'Unknown',
    };
  }

  /// 서버에 디바이스 정보 UPSERT
  Future<void> updateDeviceInfoToServer() async {
    if (!_isInitialized) {
      logger.w('[DeviceInfo] Service not initialized - initializing now');
      await initialize();
    }

    if (_cachedDeviceInfo == null) {
      logger.w('[DeviceInfo] No cached device info - reloading');
      await _loadDeviceInfo();
    }

    if (_cachedDeviceId == null) {
      logger.w('[DeviceInfo] No cached device ID - generating new one');
      await _loadOrCreateDeviceId();
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        logger.w('[DeviceInfo] No user available - cannot update device info');
        return;
      }

      final userId = user.id;
      final isAnonymous = user.isAnonymous;

      logger.i('[DeviceInfo] Updating device info for ${isAnonymous ? 'anonymous' : 'logged-in'} user');

      // info 필드에 저장할 JSON 데이터
      final infoData = {
        'device_name': isAnonymous
            ? '${_cachedDeviceInfo!['device_name']} (Guest)'
            : _cachedDeviceInfo!['device_name'],
        'os_version': _cachedDeviceInfo!['os_version'],
        'package_name': _cachedDeviceInfo!['package_name'],
        'is_active': true,
      };

      final deviceData = {
        'id': _cachedDeviceId!,
        'user_id': userId,
        'platform': _cachedDeviceInfo!['device_type'],
        'app_version': _cachedDeviceInfo!['app_version'],
        'info': infoData,
      };

      // UPSERT 수행
      await _supabase.from('devices').upsert(deviceData);

      logger.i('[DeviceInfo] Device info updated successfully');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to update device info to server', e, stackTrace);
    }
  }

  /// 앱 시작 시 디바이스 정보 갱신
  Future<void> refreshOnAppStart() async {
    logger.i('[DeviceInfo] Refreshing device info on app start');

    try {
      await _loadDeviceInfo();
      await updateDeviceInfoToServer();

      logger.i('[DeviceInfo] Device info refreshed on app start');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to refresh device info on app start', e, stackTrace);
    }
  }

  /// 포그라운드 진입 시 디바이스 정보 갱신
  Future<void> refreshOnForeground() async {
    logger.i('[DeviceInfo] Refreshing device info on foreground');

    try {
      await updateDeviceInfoToServer();

      logger.i('[DeviceInfo] Device info refreshed on foreground');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to refresh device info on foreground', e, stackTrace);
    }
  }

  /// 로그아웃 시 처리
  Future<void> markDeviceInactiveOnLogout() async {
    logger.i('[DeviceInfo] Processing device info after logout');

    try {
      _cachedDeviceId = null;
      await _loadOrCreateDeviceId();
      await updateDeviceInfoToServer();

      logger.i('[DeviceInfo] Device info updated after logout with new device ID');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to update device info after logout', e, stackTrace);
    }
  }

  /// 로그인 시 처리
  Future<void> linkAnonymousDeviceToUser() async {
    logger.i('[DeviceInfo] Processing device info after login');

    try {
      _cachedDeviceId = null;
      await _loadOrCreateDeviceId();
      await updateDeviceInfoToServer();

      logger.i('[DeviceInfo] Device info updated after login with new device ID');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to update device info after login', e, stackTrace);
    }
  }

  /// 현재 사용자별 디바이스 ID 반환
  String? get deviceId => _cachedDeviceId;

  /// 현재 디바이스 정보 반환
  Map<String, dynamic>? get deviceInfo => _cachedDeviceInfo;

  /// FCM 토큰 업데이트
  Future<void> updateFcmToken(String fcmToken) async {
    if (_cachedDeviceId == null) {
      logger.w('[DeviceInfo] Cannot update FCM token - device ID not available');
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        logger.w('[DeviceInfo] No user available - cannot update FCM token');
        return;
      }

      logger.i('[DeviceInfo] Updating FCM token');

      await _supabase
          .from('devices')
          .update({'notification_id': fcmToken})
          .eq('id', _cachedDeviceId!);

      logger.i('[DeviceInfo] FCM token updated successfully');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to update FCM token', e, stackTrace);
    }
  }

  /// APNS 토큰 업데이트 (iOS용)
  Future<void> updateApnsToken(String apnsToken) async {
    if (_cachedDeviceId == null) {
      logger.w('[DeviceInfo] Cannot update APNS token - device ID not available');
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        logger.w('[DeviceInfo] No user available - cannot update APNS token');
        return;
      }

      logger.i('[DeviceInfo] Updating APNS token');

      await _supabase
          .from('devices')
          .update({'notification_id': apnsToken})
          .eq('id', _cachedDeviceId!);

      logger.i('[DeviceInfo] APNS token updated successfully');
    } catch (e, stackTrace) {
      logger.e('[DeviceInfo] Failed to update APNS token', e, stackTrace);
    }
  }

  /// 서비스 정리
  void dispose() {
    logger.i('[DeviceInfo] Disposing device info service');
    _isInitialized = false;
    _cachedDeviceId = null;
    _cachedDeviceInfo = null;
  }
}
