import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../core/providers/isar_stream_helpers.dart';
import '../../../models/post.dart';

part 'posts_provider.g.dart';

/// Post 리스트 Stream Provider
@riverpod
Stream<List<Post>> postsStream(Ref ref) {
  return IsarStreamHelpers.watchCollection<Post>(
    collection: DatabaseService.instance.isar.posts,
    filter: (collection) => collection.filter().deletedEqualTo(false),
    sort: (a, b) => b.createdAt.compareTo(a.createdAt),
  );
}

/// 공개된 Post 리스트
@riverpod
Stream<List<Post>> publicPostsStream(Ref ref) {
  return IsarStreamHelpers.watchCollection<Post>(
    collection: DatabaseService.instance.isar.posts,
    filter: (collection) => collection
        .filter()
        .deletedEqualTo(false)
        .isPublicEqualTo(true),
    sort: (a, b) => b.createdAt.compareTo(a.createdAt),
  );
}

/// 전체 Post 개수
@riverpod
Stream<int> postsCount(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 방출
  final initialCount = await isar.posts
      .filter()
      .deletedEqualTo(false)
      .count();
  yield initialCount;

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.posts.watchLazy()) {
    final count = await isar.posts
        .filter()
        .deletedEqualTo(false)
        .count();
    yield count;
  }
}
