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

/// Fragment 필터 상태 Provider
@riverpod
class FragmentFilter extends _$FragmentFilter {
  @override
  FragmentFilterState build() {
    return const FragmentFilterState();
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setSortBy(String value) {
    state = state.copyWith(sortBy: value);
  }

  void toggleSortOrder() {
    state = state.copyWith(
      sortOrder: state.sortOrder == 'desc' ? 'asc' : 'desc',
    );
  }

  void toggleTag(String tag) {
    final newTags = List<String>.from(state.selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    state = state.copyWith(selectedTags: newTags);
  }

  void removeTag(String tag) {
    final newTags = List<String>.from(state.selectedTags);
    newTags.remove(tag);
    state = state.copyWith(selectedTags: newTags);
  }

  void reset() {
    state = const FragmentFilterState();
  }
}

/// Fragment 필터 상태
class FragmentFilterState {
  final String query;
  final String sortBy; // created, updated, event
  final String sortOrder; // desc, asc
  final List<String> selectedTags;

  const FragmentFilterState({
    this.query = '',
    this.sortBy = 'event',
    this.sortOrder = 'desc',
    this.selectedTags = const [],
  });

  FragmentFilterState copyWith({
    String? query,
    String? sortBy,
    String? sortOrder,
    List<String>? selectedTags,
  }) {
    return FragmentFilterState(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }
}

/// 필터링된 Fragment 스트림 Provider
@riverpod
Stream<List<Fragment>> filteredFragments(Ref ref) {
  final isar = DatabaseService.instance.isar;
  final filter = ref.watch(fragmentFilterProvider);

  return isar.fragments.watchLazy().asyncMap((_) async {
    // 기본 필터 (deleted = false)
    var fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    // 검색어 필터링
    if (filter.query.isNotEmpty) {
      final searchQuery = filter.query.toLowerCase();
      fragments = fragments.where((f) =>
        f.content.toLowerCase().contains(searchQuery)
      ).toList();
    }

    // 태그 필터링
    if (filter.selectedTags.isNotEmpty) {
      fragments = fragments.where((f) {
        final allTags = [...f.tags, ...f.userTags];
        return filter.selectedTags.any((tag) => allTags.contains(tag));
      }).toList();
    }

    // 정렬
    fragments.sort((a, b) {
      DateTime aTime, bTime;

      if (filter.sortBy == 'created') {
        aTime = a.createdAt;
        bTime = b.createdAt;
      } else if (filter.sortBy == 'updated') {
        aTime = a.updatedAt;
        bTime = b.updatedAt;
      } else {
        // event (기본값)
        aTime = a.eventTime;
        bTime = b.eventTime;
      }

      final diff = aTime.compareTo(bTime);
      return filter.sortOrder == 'desc' ? -diff : diff;
    });

    return fragments;
  });
}
