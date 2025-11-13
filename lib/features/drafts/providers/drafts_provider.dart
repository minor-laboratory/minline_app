import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../models/draft.dart';

part 'drafts_provider.g.dart';

/// Draft 필터 상태
class DraftFilterState {
  final String status; // 'all', 'pending', 'accepted', 'rejected'

  const DraftFilterState({
    this.status = 'all',
  });

  DraftFilterState copyWith({
    String? status,
  }) {
    return DraftFilterState(
      status: status ?? this.status,
    );
  }
}

/// Draft 필터 Notifier
@riverpod
class DraftFilter extends _$DraftFilter {
  @override
  DraftFilterState build() {
    return const DraftFilterState();
  }

  void setStatus(String value) {
    state = state.copyWith(status: value);
  }

  void reset() {
    state = const DraftFilterState();
  }
}

/// Draft 리스트 Stream Provider (필터 적용 전)
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

/// 필터링된 Draft 리스트
@riverpod
Stream<List<Draft>> filteredDrafts(Ref ref) async* {
  final filter = ref.watch(draftFilterProvider);
  final draftsAsync = ref.watch(draftsStreamProvider);

  await for (final drafts in draftsAsync.when(
    data: (data) => Stream.value(data),
    loading: () => const Stream<List<Draft>>.empty(),
    error: (_, __) => const Stream<List<Draft>>.empty(),
  )) {
    if (filter.status == 'all') {
      yield drafts;
    } else {
      yield drafts.where((d) => d.status == filter.status).toList();
    }
  }
}

/// 상태별 Draft 개수
@riverpod
Stream<Map<String, int>> draftCounts(Ref ref) async* {
  final draftsAsync = ref.watch(draftsStreamProvider);

  await for (final drafts in draftsAsync.when(
    data: (data) => Stream.value(data),
    loading: () => const Stream<List<Draft>>.empty(),
    error: (_, __) => const Stream<List<Draft>>.empty(),
  )) {
    yield {
      'all': drafts.length,
      'pending': drafts.where((d) => d.status == 'pending').length,
      'accepted': drafts.where((d) => d.status == 'accepted').length,
      'rejected': drafts.where((d) => d.status == 'rejected').length,
    };
  }
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
