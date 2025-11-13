import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../models/post.dart';

part 'posts_provider.g.dart';

/// Post 리스트 Stream Provider
@riverpod
Stream<List<Post>> postsStream(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 방출
  final initialPosts = await isar.posts
      .filter()
      .deletedEqualTo(false)
      .findAll();

  initialPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  yield initialPosts;

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.posts.watchLazy()) {
    final posts = await isar.posts
        .filter()
        .deletedEqualTo(false)
        .findAll();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield posts;
  }
}

/// 공개된 Post 리스트
@riverpod
Stream<List<Post>> publicPostsStream(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 방출
  final initialPosts = await isar.posts
      .filter()
      .deletedEqualTo(false)
      .isPublicEqualTo(true)
      .findAll();

  initialPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  yield initialPosts;

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.posts.watchLazy()) {
    final posts = await isar.posts
        .filter()
        .deletedEqualTo(false)
        .isPublicEqualTo(true)
        .findAll();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield posts;
  }
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
