import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_service.dart';
import '../../../core/providers/isar_stream_helpers.dart';
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
  return IsarStreamHelpers.watchCollection<Draft>(
    collection: DatabaseService.instance.isar.drafts,
    filter: (collection) => collection.filter().deletedEqualTo(false),
    sort: (a, b) => b.createdAt.compareTo(a.createdAt),
  );
}

/// 필터링된 Draft 리스트
@riverpod
Stream<List<Draft>> filteredDrafts(Ref ref) async* {
  final isar = DatabaseService.instance.isar;
  final filter = ref.watch(draftFilterProvider);

  // 필터링 로직을 함수로 추출
  List<Draft> filterDrafts(List<Draft> drafts) {
    if (filter.status == 'all') {
      return drafts;
    } else {
      return drafts.where((d) => d.status == filter.status).toList();
    }
  }

  // 초기값 먼저 방출
  final initialDrafts = await isar.drafts
      .filter()
      .deletedEqualTo(false)
      .findAll();

  initialDrafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  yield filterDrafts(initialDrafts);

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.drafts.watchLazy()) {
    final drafts = await isar.drafts
        .filter()
        .deletedEqualTo(false)
        .findAll();

    drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield filterDrafts(drafts);
  }
}

/// 상태별 Draft 개수
@riverpod
Stream<Map<String, int>> draftCounts(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 계산
  final initialDrafts = await isar.drafts
      .filter()
      .deletedEqualTo(false)
      .findAll();

  yield {
    'all': initialDrafts.length,
    'pending': initialDrafts.where((d) => d.status == 'pending').length,
    'accepted': initialDrafts.where((d) => d.status == 'accepted').length,
    'rejected': initialDrafts.where((d) => d.status == 'rejected').length,
  };

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.drafts.watchLazy()) {
    final drafts = await isar.drafts
        .filter()
        .deletedEqualTo(false)
        .findAll();

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
Stream<int> unviewedDraftsCount(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 방출
  final initialCount = await isar.drafts
      .filter()
      .deletedEqualTo(false)
      .viewedEqualTo(false)
      .count();
  yield initialCount;

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.drafts.watchLazy()) {
    final count = await isar.drafts
        .filter()
        .deletedEqualTo(false)
        .viewedEqualTo(false)
        .count();
    yield count;
  }
}
