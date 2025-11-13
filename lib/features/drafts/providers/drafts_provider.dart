import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../models/draft.dart';

part 'drafts_provider.g.dart';

/// Draft 리스트 Stream Provider
@riverpod
Stream<List<Draft>> draftsStream(Ref ref) {
  final isar = DatabaseService.instance.isar;

  return isar.drafts.watchLazy().asyncMap((_) async {
    final drafts = await isar.drafts
        .filter()
        .deletedEqualTo(false)
        .findAll();

    // 생성일 역순 정렬
    drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return drafts;
  });
}

/// 미확인 Draft 개수
@riverpod
Stream<int> unviewedDraftsCount(Ref ref) {
  final isar = DatabaseService.instance.isar;

  return isar.drafts.watchLazy().asyncMap((_) async {
    return await isar.drafts
        .filter()
        .deletedEqualTo(false)
        .viewedEqualTo(false)
        .count();
  });
}
