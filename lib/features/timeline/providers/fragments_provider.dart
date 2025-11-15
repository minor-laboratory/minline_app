import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_service.dart';
import '../../../core/utils/logger.dart';
import '../../../models/fragment.dart';
import '../../settings/providers/settings_provider.dart';

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
Stream<List<Fragment>> fragmentsStream(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 방출
  final initialFragments = await isar.fragments
      .filter()
      .deletedEqualTo(false)
      .findAll();

  initialFragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
      .compareTo(a.refreshAt ?? DateTime.now()));

  yield initialFragments;

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.fragments.watchLazy()) {
    final fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    fragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
        .compareTo(a.refreshAt ?? DateTime.now()));

    yield fragments;
  }
}

/// Fragment 개수 Provider
@riverpod
Future<int> fragmentCount(Ref ref) async {
  final isar = DatabaseService.instance.isar;

  return await isar.fragments.filter().deletedEqualTo(false).count();
}

/// Fragment 필터 상태 Provider (정렬 설정 영구 저장)
@riverpod
class FragmentFilter extends _$FragmentFilter {
  static const String _sortByKey = 'fragment_sort_by';
  static const String _sortOrderKey = 'fragment_sort_order';

  SharedPreferences? _prefs; // SharedPreferences 캐싱

  @override
  Future<FragmentFilterState> build() async {
    _prefs = await ref.watch(sharedPreferencesProvider.future);

    final sortBy = _prefs!.getString(_sortByKey) ?? 'event';
    final sortOrder = _prefs!.getString(_sortOrderKey) ?? 'desc';

    return FragmentFilterState(
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  void setQuery(String value) {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(query: value));
  }

  Future<void> setSortBy(String value) async {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(sortBy: value));

    try {
      // 캐싱된 SharedPreferences 사용
      await _prefs?.setString(_sortByKey, value);
    } catch (e, stack) {
      logger.e('Failed to save sortBy', e, stack);
      // UI는 이미 업데이트되었으므로 다음 앱 시작 시 이전 값으로 복원됨
    }
  }

  Future<void> toggleSortOrder() async {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    final newOrder = currentState.sortOrder == 'desc' ? 'asc' : 'desc';
    state = AsyncValue.data(currentState.copyWith(sortOrder: newOrder));

    try {
      // 캐싱된 SharedPreferences 사용
      await _prefs?.setString(_sortOrderKey, newOrder);
    } catch (e, stack) {
      logger.e('Failed to save sortOrder', e, stack);
      // UI는 이미 업데이트되었으므로 다음 앱 시작 시 이전 값으로 복원됨
    }
  }

  void toggleTag(String tag) {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    final newTags = List<String>.from(currentState.selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    state = AsyncValue.data(currentState.copyWith(selectedTags: newTags));
  }

  void removeTag(String tag) {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    final newTags = List<String>.from(currentState.selectedTags);
    newTags.remove(tag);
    state = AsyncValue.data(currentState.copyWith(selectedTags: newTags));
  }

  Future<void> reset() async {
    state = const AsyncValue.data(FragmentFilterState());

    // 캐싱된 SharedPreferences 사용
    await _prefs?.remove(_sortByKey);
    await _prefs?.remove(_sortOrderKey);
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
Stream<List<Fragment>> filteredFragments(Ref ref) async* {
  final isar = DatabaseService.instance.isar;
  final filterAsync = ref.watch(fragmentFilterProvider);

  // AsyncValue가 로딩 중이면 기본값 사용 (UI 깜빡임 방지)
  final filter = filterAsync.asData?.value ?? const FragmentFilterState();

  // 필터링 및 정렬 로직을 함수로 추출
  List<Fragment> filterAndSort(List<Fragment> fragments) {
    var result = fragments;

    // 검색어 필터링
    if (filter.query.isNotEmpty) {
      final searchQuery = filter.query.toLowerCase();
      result = result.where((f) =>
        f.content.toLowerCase().contains(searchQuery)
      ).toList();
    }

    // 태그 필터링
    if (filter.selectedTags.isNotEmpty) {
      result = result.where((f) {
        final allTags = [...f.tags, ...f.userTags];
        return filter.selectedTags.any((tag) => allTags.contains(tag));
      }).toList();
    }

    // 정렬
    result.sort((a, b) {
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

    return result;
  }

  // 초기값 먼저 방출
  final initialFragments = await isar.fragments
      .filter()
      .deletedEqualTo(false)
      .findAll();

  yield filterAndSort(initialFragments);

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.fragments.watchLazy()) {
    final fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    yield filterAndSort(fragments);
  }
}
