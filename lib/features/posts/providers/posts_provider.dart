import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../models/post.dart';

part 'posts_provider.g.dart';

/// Post 리스트 Stream Provider
@riverpod
Stream<List<Post>> postsStream(Ref ref) {
  final isar = DatabaseService.instance.isar;

  return isar.posts.watchLazy().asyncMap((_) async {
    final posts = await isar.posts
        .filter()
        .deletedEqualTo(false)
        .findAll();

    // 생성일 역순 정렬
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return posts;
  });
}

/// 공개된 Post 리스트
@riverpod
Stream<List<Post>> publicPostsStream(Ref ref) {
  final isar = DatabaseService.instance.isar;

  return isar.posts.watchLazy().asyncMap((_) async {
    final posts = await isar.posts
        .filter()
        .deletedEqualTo(false)
        .isPublicEqualTo(true)
        .findAll();

    // 생성일 역순 정렬
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return posts;
  });
}

/// 전체 Post 개수
@riverpod
Stream<int> postsCount(Ref ref) {
  final isar = DatabaseService.instance.isar;

  return isar.posts.watchLazy().asyncMap((_) async {
    return await isar.posts
        .filter()
        .deletedEqualTo(false)
        .count();
  });
}
