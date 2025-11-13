import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../models/fragment.dart';

part 'fragments_provider.g.dart';

/// Fragment 리스트 Provider (최신순)
///
/// refreshAt 기준 정렬 (UI 갱신 트리거)
/// deleted = false만 표시
@riverpod
Future<List<Fragment>> fragments(Ref ref) async {
  final isar = DatabaseService.instance.isar;

  // Isar에서 필터링 후 Dart에서 정렬
  final fragments = await isar.fragments
      .filter()
      .deletedEqualTo(false)
      .findAll();

  fragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
      .compareTo(a.refreshAt ?? DateTime.now()));

  return fragments;
}

/// Fragment 스트림 Provider (실시간 업데이트)
///
/// Isar watch로 실시간 변경 감지
@riverpod
Stream<List<Fragment>> fragmentsStream(Ref ref) {
  final isar = DatabaseService.instance.isar;

  return isar.fragments.watchLazy().asyncMap((_) async {
    final fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    fragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
        .compareTo(a.refreshAt ?? DateTime.now()));

    return fragments;
  });
}

/// Fragment 개수 Provider
@riverpod
Future<int> fragmentCount(Ref ref) async {
  final isar = DatabaseService.instance.isar;

  return await isar.fragments.filter().deletedEqualTo(false).count();
}
