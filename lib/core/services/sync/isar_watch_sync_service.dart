import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synchronized/synchronized.dart';

import '../../database/database_service.dart';
import '../../../models/draft.dart';
import '../../../models/fragment.dart';
import '../../../models/post.dart';
import '../../utils/logger.dart';

/// Isar watch를 활용하여 로컬 변경사항을 자동 감지하고
/// Mutex를 통해 순차적으로 서버에 동기화하는 서비스
///
/// Why: synced = false인 항목이 생기면 자동으로 서버에 업로드 (1초 디바운스)
class IsarWatchSyncService {
  static IsarWatchSyncService? _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// 순차 처리를 위한 Mutex
  final Lock _syncLock = Lock();

  /// Isar watch 구독들
  StreamSubscription<List<Fragment>>? _fragmentWatchSubscription;
  StreamSubscription<List<Draft>>? _draftWatchSubscription;
  StreamSubscription<List<Post>>? _postWatchSubscription;

  /// 디바운스 타이머들 (1초 대기)
  Timer? _fragmentDebounce;
  Timer? _draftDebounce;
  Timer? _postDebounce;

  /// 서비스 활성화 상태
  bool _isActive = false;

  IsarWatchSyncService._();

  factory IsarWatchSyncService() {
    _instance ??= IsarWatchSyncService._();
    return _instance!;
  }

  /// 동기화 서비스 시작
  Future<void> start() async {
    if (_isActive) {
      logger.i('IsarWatchSyncService is already active');
      return;
    }

    // 로그인 상태 확인
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      logger.i(
          'User not authenticated, skipping IsarWatchSyncService start');
      return;
    }

    _isActive = true;
    logger.i('Starting IsarWatchSyncService');

    await _startWatchingChanges();
  }

  /// 동기화 서비스 중지
  Future<void> stop() async {
    if (!_isActive) {
      logger.i('IsarWatchSyncService is already inactive');
      return;
    }

    _isActive = false;
    logger.i('Stopping IsarWatchSyncService');

    await _stopWatchingChanges();

    // 디바운스 타이머 정리
    _fragmentDebounce?.cancel();
    _draftDebounce?.cancel();
    _postDebounce?.cancel();
  }

  /// Isar watch 구독 시작
  Future<void> _startWatchingChanges() async {
    final isar = DatabaseService.instance.isar;

    // Fragment 변경사항 감지 (synced = false인 항목)
    _fragmentWatchSubscription = isar.fragments
        .filter()
        .syncedEqualTo(false)
        .build()
        .watch(fireImmediately: true)
        .listen(
          (fragments) => _debouncedSync('fragments', fragments.length),
          onError: (error, stack) =>
              logger.e('Fragment watch error', error, stack),
        );

    // Draft 변경사항 감지 (synced = false인 항목)
    _draftWatchSubscription = isar.drafts
        .filter()
        .syncedEqualTo(false)
        .build()
        .watch(fireImmediately: true)
        .listen(
          (drafts) => _debouncedSync('drafts', drafts.length),
          onError: (error, stack) => logger.e('Draft watch error', error, stack),
        );

    // Post 변경사항 감지 (synced = false인 항목)
    _postWatchSubscription = isar.posts
        .filter()
        .syncedEqualTo(false)
        .build()
        .watch(fireImmediately: true)
        .listen(
          (posts) => _debouncedSync('posts', posts.length),
          onError: (error, stack) => logger.e('Post watch error', error, stack),
        );

    logger.i('Started watching Isar changes');
  }

  /// Isar watch 구독 중지
  Future<void> _stopWatchingChanges() async {
    await _fragmentWatchSubscription?.cancel();
    await _draftWatchSubscription?.cancel();
    await _postWatchSubscription?.cancel();

    _fragmentWatchSubscription = null;
    _draftWatchSubscription = null;
    _postWatchSubscription = null;

    logger.i('Stopped watching Isar changes');
  }

  /// 디바운스 동기화 (1초 후 실행, 연속 호출 시 타이머 리셋)
  void _debouncedSync(String tableName, int count) {
    if (count == 0) return;

    logger.d('Detected $count unsynced $tableName, scheduling sync in 1s');

    switch (tableName) {
      case 'fragments':
        _fragmentDebounce?.cancel();
        _fragmentDebounce =
            Timer(const Duration(seconds: 1), () => _syncFragments());
        break;
      case 'drafts':
        _draftDebounce?.cancel();
        _draftDebounce =
            Timer(const Duration(seconds: 1), () => _syncDrafts());
        break;
      case 'posts':
        _postDebounce?.cancel();
        _postDebounce =
            Timer(const Duration(seconds: 1), () => _syncPosts());
        break;
    }
  }

  /// Fragment 동기화
  Future<void> _syncFragments() async {
    if (!_isActive) return;

    await _syncLock.synchronized(() async {
      final isar = DatabaseService.instance.isar;
      final unsyncedFragments =
          await isar.fragments.filter().syncedEqualTo(false).findAll();

      if (unsyncedFragments.isEmpty) return;

      logger.i('Processing ${unsyncedFragments.length} unsynced fragments');

      for (final fragment in unsyncedFragments) {
        try {
          await _syncFragmentToServer(fragment);
        } catch (error, stack) {
          logger.e(
              'Failed to sync fragment ${fragment.remoteID}', error, stack);
          // 개별 실패는 로그만 남기고 계속 진행
        }
      }
    });
  }

  /// Draft 동기화
  Future<void> _syncDrafts() async {
    if (!_isActive) return;

    await _syncLock.synchronized(() async {
      final isar = DatabaseService.instance.isar;
      final unsyncedDrafts =
          await isar.drafts.filter().syncedEqualTo(false).findAll();

      if (unsyncedDrafts.isEmpty) return;

      logger.i('Processing ${unsyncedDrafts.length} unsynced drafts');

      for (final draft in unsyncedDrafts) {
        try {
          await _syncDraftToServer(draft);
        } catch (error, stack) {
          logger.e('Failed to sync draft ${draft.remoteID}', error, stack);
        }
      }
    });
  }

  /// Post 동기화
  Future<void> _syncPosts() async {
    if (!_isActive) return;

    await _syncLock.synchronized(() async {
      final isar = DatabaseService.instance.isar;
      final unsyncedPosts =
          await isar.posts.filter().syncedEqualTo(false).findAll();

      if (unsyncedPosts.isEmpty) return;

      logger.i('Processing ${unsyncedPosts.length} unsynced posts');

      for (final post in unsyncedPosts) {
        try {
          await _syncPostToServer(post);
        } catch (error, stack) {
          logger.e('Failed to sync post ${post.remoteID}', error, stack);
        }
      }
    });
  }

  /// Fragment를 서버에 동기화
  Future<void> _syncFragmentToServer(Fragment fragment) async {
    logger.d('Syncing fragment ${fragment.remoteID} to server');

    final user = _supabase.auth.currentUser;
    if (user == null) {
      logger.w('Cannot sync: user not authenticated');
      return;
    }

    // Supabase에 upsert
    // created_at, updated_at은 서버에서 자동 관리 (클라이언트에서 보내지 않음)
    // 최신 supabase_flutter: 에러 시 예외 throw, 성공 시 데이터 반환
    await _supabase.from('fragments').upsert({
      'id': fragment.remoteID,
      'user_id': user.id,
      'content': fragment.content,
      'media_urls': fragment.mediaUrls,
      'timestamp': fragment.timestamp.toIso8601String(),
      'event_time': fragment.eventTime.toIso8601String(),
      'event_time_source': fragment.eventTimeSource,
      'tags': fragment.tags,
      'user_tags': fragment.userTags,
      'deleted': fragment.deleted,
    });

    // 성공 시 synced = true로 업데이트
    final isar = DatabaseService.instance.isar;
    await isar.writeTxn(() async {
      fragment.synced = true;
      await isar.fragments.put(fragment);
    });

    logger.i('Successfully synced fragment ${fragment.remoteID}');
  }

  /// Draft를 서버에 동기화
  Future<void> _syncDraftToServer(Draft draft) async {
    logger.d('Syncing draft ${draft.remoteID} to server');

    final user = _supabase.auth.currentUser;
    if (user == null) {
      logger.w('Cannot sync: user not authenticated');
      return;
    }

    // created_at, updated_at은 서버에서 자동 관리
    // 최신 supabase_flutter: 에러 시 예외 throw, 성공 시 데이터 반환
    await _supabase.from('drafts').upsert({
      'id': draft.remoteID,
      'user_id': user.id,
      'title': draft.title,
      'fragment_ids': draft.fragmentIds,
      'status': draft.status,
      'viewed': draft.viewed,
      'deleted': draft.deleted,
    });

    // 성공 시 synced = true로 업데이트
    final isar = DatabaseService.instance.isar;
    await isar.writeTxn(() async {
      draft.synced = true;
      await isar.drafts.put(draft);
    });

    logger.i('Successfully synced draft ${draft.remoteID}');
  }

  /// Post를 서버에 동기화
  Future<void> _syncPostToServer(Post post) async {
    logger.d('Syncing post ${post.remoteID} to server');

    final user = _supabase.auth.currentUser;
    if (user == null) {
      logger.w('Cannot sync: user not authenticated');
      return;
    }

    // created_at, updated_at은 서버에서 자동 관리
    // 최신 supabase_flutter: 에러 시 예외 throw, 성공 시 데이터 반환
    await _supabase.from('posts').upsert({
      'id': post.remoteID,
      'user_id': user.id,
      'draft_id': post.draftId,
      'title': post.title,
      'content': post.content,
      'fragment_ids': post.fragmentIds,
      'template': post.template,
      'version': post.version,
      'previous_version_id': post.previousVersionId,
      'viewed': post.viewed,
      'deleted': post.deleted,
    });

    // 성공 시 synced = true로 업데이트
    final isar = DatabaseService.instance.isar;
    await isar.writeTxn(() async {
      post.synced = true;
      await isar.posts.put(post);
    });

    logger.i('Successfully synced post ${post.remoteID}');
  }
}
