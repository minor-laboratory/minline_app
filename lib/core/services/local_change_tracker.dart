import 'package:isar_community/isar.dart';

import '../../models/draft.dart';
import '../../models/fragment.dart';
import '../../models/post.dart';
import '../database/database_service.dart';
import '../utils/logger.dart';

/// 로컬 변경사항을 추적하는 서비스
///
/// Isar 데이터베이스에서 동기화되지 않은 변경사항을 감지합니다.
/// synced 필드가 false인 레코드를 찾습니다.
class LocalChangeTracker {
  static final LocalChangeTracker _instance = LocalChangeTracker._internal();
  factory LocalChangeTracker() => _instance;
  LocalChangeTracker._internal();

  /// 미동기화 항목의 개수를 반환
  ///
  /// Returns: Map of table names to count of unsynced records
  /// - key: 테이블명 (fragments, drafts, posts)
  /// - value: 미동기화 레코드 개수 (deleted 항목 포함)
  ///
  /// 논리:
  /// - synced=false인 모든 항목 (deleted 포함)
  /// - deleted 항목도 서버 동기화가 필요하므로 count에 포함
  Future<Map<String, int>> getUnsyncedItemsCounts() async {
    try {
      logger.d('Getting unsynced item counts...');

      final isar = DatabaseService.instance.isar;
      final counts = <String, int>{};

      // Fragments - 동기화되지 않은 조각들의 개수 (deleted 포함)
      final unsyncedFragments = await isar.fragments
          .filter()
          .syncedEqualTo(false)
          .findAll();
      counts['fragments'] = unsyncedFragments.length;

      // Drafts - 동기화되지 않은 초안들의 개수 (deleted 포함)
      final unsyncedDrafts = await isar.drafts
          .filter()
          .syncedEqualTo(false)
          .findAll();
      counts['drafts'] = unsyncedDrafts.length;

      // Posts - 동기화되지 않은 포스트들의 개수 (deleted 포함)
      final unsyncedPosts = await isar.posts
          .filter()
          .syncedEqualTo(false)
          .findAll();
      counts['posts'] = unsyncedPosts.length;

      final totalUnsynced = counts.values.fold(0, (sum, count) => sum + count);
      logger.i('Total unsynced items: $totalUnsynced (fragments: ${counts['fragments']}, drafts: ${counts['drafts']}, posts: ${counts['posts']})');

      return counts;
    } catch (e, stack) {
      logger.e('Failed to get unsynced item counts', e, stack);
      return {};
    }
  }
}
