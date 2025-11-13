import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/logger.dart';

/// 테이블별 동기화 메타데이터를 관리하는 서비스
///
/// Why: 서버와 동기화 시 마지막 업데이트 시간을 저장하여
/// 증분 업데이트만 수신 (전체 데이터 재전송 방지)
class SyncMetadataService {
  static const _storage = FlutterSecureStorage();

  // 각 테이블별 마지막 동기화 시간 키
  static const String _fragmentsLastSyncKey = 'fragments_last_sync_time';
  static const String _draftsLastSyncKey = 'drafts_last_sync_time';
  static const String _postsLastSyncKey = 'posts_last_sync_time';

  // 각 테이블별 동기화 버전 (스키마 변경 시 전체 리셋용)
  static const String _fragmentsVersionKey = 'fragments_sync_version';
  static const String _draftsVersionKey = 'drafts_sync_version';
  static const String _postsVersionKey = 'posts_sync_version';

  // 현재 동기화 버전 (스키마 변경 시 증가)
  static const int _currentSyncVersion = 1;

  // 전체 동기화 마지막 시간 키
  static const String _lastFullSyncKey = 'last_full_sync_time';

  /// 테이블별 마지막 동기화 시간 조회
  static Future<DateTime?> getLastSyncTime(String tableName) async {
    try {
      final key = _getLastSyncKey(tableName);
      final timeString = await _storage.read(key: key);

      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      logger.e('Failed to get last sync time for $tableName: $e');
      return null;
    }
  }

  /// 테이블별 마지막 동기화 시간 저장
  static Future<void> setLastSyncTime(
      String tableName, DateTime syncTime) async {
    try {
      final key = _getLastSyncKey(tableName);
      await _storage.write(key: key, value: syncTime.toIso8601String());
      logger.d(
          'Updated last sync time for $tableName: ${syncTime.toIso8601String()}');
    } catch (e) {
      logger.e('Failed to set last sync time for $tableName: $e');
    }
  }

  /// 테이블의 동기화 버전이 현재 버전과 일치하는지 확인
  static Future<bool> isSyncVersionCurrent(String tableName) async {
    try {
      final key = _getVersionKey(tableName);
      final versionString = await _storage.read(key: key);

      if (versionString != null) {
        final version = int.tryParse(versionString) ?? 0;
        return version == _currentSyncVersion;
      }
      return false;
    } catch (e) {
      logger.e('Failed to check sync version for $tableName: $e');
      return false;
    }
  }

  /// 테이블의 동기화 버전을 현재 버전으로 업데이트
  static Future<void> updateSyncVersion(String tableName) async {
    try {
      final key = _getVersionKey(tableName);
      await _storage.write(key: key, value: _currentSyncVersion.toString());
      logger.d('Updated sync version for $tableName to $_currentSyncVersion');
    } catch (e) {
      logger.e('Failed to update sync version for $tableName: $e');
    }
  }

  /// 테이블의 동기화 메타데이터 초기화 (전체 리셋 시)
  static Future<void> resetSyncMetadata(String tableName) async {
    try {
      final lastSyncKey = _getLastSyncKey(tableName);
      final versionKey = _getVersionKey(tableName);

      await Future.wait([
        _storage.delete(key: lastSyncKey),
        _storage.delete(key: versionKey),
      ]);

      logger.i('Reset sync metadata for $tableName');
    } catch (e) {
      logger.e('Failed to reset sync metadata for $tableName: $e');
    }
  }

  /// 모든 테이블의 동기화 메타데이터 초기화
  static Future<void> resetAllSyncMetadata() async {
    try {
      await Future.wait([
        resetSyncMetadata('fragments'),
        resetSyncMetadata('drafts'),
        resetSyncMetadata('posts'),
      ]);

      logger.i('Reset all sync metadata');
    } catch (e) {
      logger.e('Failed to reset all sync metadata: $e');
    }
  }

  /// 모든 동기화 시간 초기화 (강제 동기화용 별칭)
  static Future<void> clearAllSyncTimes() async {
    await resetAllSyncMetadata();
  }

  /// 전체 동기화 마지막 시간 조회
  static Future<DateTime?> getLastFullSyncTime() async {
    try {
      final timeString = await _storage.read(key: _lastFullSyncKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      logger.e('Failed to get last full sync time: $e');
      return null;
    }
  }

  /// 전체 동기화 마지막 시간 저장
  static Future<void> setLastFullSyncTime(DateTime syncTime) async {
    try {
      await _storage.write(
          key: _lastFullSyncKey, value: syncTime.toIso8601String());
      logger.d('Updated last full sync time: ${syncTime.toIso8601String()}');
    } catch (e) {
      logger.e('Failed to set last full sync time: $e');
    }
  }

  /// 동기화 통계 정보 조회
  static Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final stats = <String, dynamic>{};

      for (final table in ['fragments', 'drafts', 'posts']) {
        final lastSync = await getLastSyncTime(table);
        final isVersionCurrent = await isSyncVersionCurrent(table);

        stats[table] = {
          'lastSyncTime': lastSync?.toIso8601String(),
          'isVersionCurrent': isVersionCurrent,
          'needsFullSync': lastSync == null || !isVersionCurrent,
        };
      }

      return stats;
    } catch (e) {
      logger.e('Failed to get sync stats: $e');
      return {};
    }
  }

  // Private helper methods
  static String _getLastSyncKey(String tableName) {
    switch (tableName.toLowerCase()) {
      case 'fragments':
        return _fragmentsLastSyncKey;
      case 'drafts':
        return _draftsLastSyncKey;
      case 'posts':
        return _postsLastSyncKey;
      default:
        return '${tableName.toLowerCase()}_last_sync_time';
    }
  }

  static String _getVersionKey(String tableName) {
    switch (tableName.toLowerCase()) {
      case 'fragments':
        return _fragmentsVersionKey;
      case 'drafts':
        return _draftsVersionKey;
      case 'posts':
        return _postsVersionKey;
      default:
        return '${tableName.toLowerCase()}_sync_version';
    }
  }
}
