import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synchronized/synchronized.dart';

import '../../database/database_service.dart';
import '../../../models/draft.dart';
import '../../../models/fragment.dart';
import '../../../models/post.dart';
import '../../utils/logger.dart';
import 'sync_metadata_service.dart';

/// Supabase Database Stream 기반 실시간 동기화 서비스
///
/// Why: Database Stream 방식 (북랩 검증)
/// - 초기 데이터 + 실시간 업데이트 통합
/// - 서버 사이드 타임스탬프 필터링 (증분 업데이트)
/// - 비용 효율적 (Realtime Channel 대비 50% 절감)
///
/// Lifecycle: @Riverpod(keepAlive: true) Provider로 관리
class SupabaseStreamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _fragmentStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _draftStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _postStreamSubscription;

  /// 순차 처리를 위한 Mutex
  final Lock _updateLock = Lock();

  /// 서비스 활성화 상태
  bool _isListening = false;

  SupabaseStreamService();

  /// 현재 상태
  bool get isListening => _isListening;

  /// 실시간 동기화 시작
  Future<void> startListening() async {
    if (_isListening) {
      logger.i('SupabaseStreamService is already listening');
      return;
    }

    // 로그인 상태 확인
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      logger.i('User not authenticated, skipping SupabaseStreamService start');
      return;
    }

    _isListening = true;
    logger.i('Starting SupabaseStreamService with Database Stream');

    // 마지막 동기화 시간 로드
    final fragmentLastSync =
        await SyncMetadataService.getLastSyncTime('fragments') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    final draftLastSync =
        await SyncMetadataService.getLastSyncTime('drafts') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    final postLastSync = await SyncMetadataService.getLastSyncTime('posts') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    // Fragment stream 구독
    _fragmentStreamSubscription = _supabase
        .from('fragments')
        .stream(primaryKey: ['id'])
        .gt('updated_at', fragmentLastSync.toIso8601String())
        .listen(
          (data) => _handleFragmentUpdate(data),
          onError: (error, stack) =>
              logger.e('Fragment stream error', error, stack),
        );

    // Draft stream 구독
    _draftStreamSubscription = _supabase
        .from('drafts')
        .stream(primaryKey: ['id'])
        .gt('updated_at', draftLastSync.toIso8601String())
        .listen(
          (data) => _handleDraftUpdate(data),
          onError: (error, stack) => logger.e('Draft stream error', error, stack),
        );

    // Post stream 구독
    _postStreamSubscription = _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .gt('updated_at', postLastSync.toIso8601String())
        .listen(
          (data) => _handlePostUpdate(data),
          onError: (error, stack) => logger.e('Post stream error', error, stack),
        );

    logger.i('Started all stream subscriptions with server-side filtering');
  }

  /// 실시간 동기화 중지
  Future<void> stopListening() async {
    if (!_isListening) {
      logger.i('SupabaseStreamService is already stopped');
      return;
    }

    _isListening = false;
    logger.i('Stopping SupabaseStreamService');

    await _fragmentStreamSubscription?.cancel();
    await _draftStreamSubscription?.cancel();
    await _postStreamSubscription?.cancel();

    _fragmentStreamSubscription = null;
    _draftStreamSubscription = null;
    _postStreamSubscription = null;

    logger.i('Stopped all stream subscriptions');
  }

  /// Fragment 업데이트 처리
  Future<void> _handleFragmentUpdate(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;

    await _updateLock.synchronized(() async {
      logger.d('Processing ${data.length} fragment updates from server');

      final isar = DatabaseService.instance.isar;
      DateTime? maxUpdatedAt;

      await isar.writeTxn(() async {
        for (final item in data) {
          final fragment = Fragment.fromJson(item);
          fragment.synced = true; // 서버에서 받은 데이터는 synced = true
          await isar.fragments.put(fragment);

          // 최대 updated_at 추적
          final updatedAt = DateTime.parse(item['updated_at'] as String);
          if (maxUpdatedAt == null || maxUpdatedAt!.isBefore(updatedAt)) {
            maxUpdatedAt = updatedAt;
          }
        }
      });

      // 동기화 시간 저장
      if (maxUpdatedAt != null) {
        await SyncMetadataService.setLastSyncTime('fragments', maxUpdatedAt!);
      }

      logger.i('Successfully processed ${data.length} fragments');
    });
  }

  /// Draft 업데이트 처리
  Future<void> _handleDraftUpdate(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;

    await _updateLock.synchronized(() async {
      logger.d('Processing ${data.length} draft updates from server');

      final isar = DatabaseService.instance.isar;
      DateTime? maxUpdatedAt;

      await isar.writeTxn(() async {
        for (final item in data) {
          final draft = Draft.fromJson(item);
          draft.synced = true; // 서버에서 받은 데이터는 synced = true
          await isar.drafts.put(draft);

          // 최대 updated_at 추적
          final updatedAt = DateTime.parse(item['updated_at'] as String);
          if (maxUpdatedAt == null || maxUpdatedAt!.isBefore(updatedAt)) {
            maxUpdatedAt = updatedAt;
          }
        }
      });

      // 동기화 시간 저장
      if (maxUpdatedAt != null) {
        await SyncMetadataService.setLastSyncTime('drafts', maxUpdatedAt!);
      }

      logger.i('Successfully processed ${data.length} drafts');
    });
  }

  /// Post 업데이트 처리
  Future<void> _handlePostUpdate(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;

    await _updateLock.synchronized(() async {
      logger.d('Processing ${data.length} post updates from server');

      final isar = DatabaseService.instance.isar;
      DateTime? maxUpdatedAt;

      await isar.writeTxn(() async {
        for (final item in data) {
          final post = Post.fromJson(item);
          post.synced = true; // 서버에서 받은 데이터는 synced = true
          await isar.posts.put(post);

          // 최대 updated_at 추적
          final updatedAt = DateTime.parse(item['updated_at'] as String);
          if (maxUpdatedAt == null || maxUpdatedAt!.isBefore(updatedAt)) {
            maxUpdatedAt = updatedAt;
          }
        }
      });

      // 동기화 시간 저장
      if (maxUpdatedAt != null) {
        await SyncMetadataService.setLastSyncTime('posts', maxUpdatedAt!);
      }

      logger.i('Successfully processed ${data.length} posts');
    });
  }

  /// 서비스 정리
  void dispose() {
    stopListening();
    logger.i('SupabaseStreamService disposed');
  }
}
