import 'package:isar_community/isar.dart';
import 'package:miniline_app/models/base.dart';

/// Isar Stream 헬퍼
///
/// Provider에서 공통으로 사용하는 Stream 패턴을 추출
class IsarStreamHelpers {
  /// 기본 Stream 패턴 (초기값 방출 → watchLazy로 변경 감지)
  ///
  /// 사용 예시:
  /// ```dart
  /// @riverpod
  /// Stream<List<Fragment>> fragmentsStream(Ref ref) {
  ///   return IsarStreamHelpers.watchCollection<Fragment>(
  ///     collection: DatabaseService.instance.isar.fragments,
  ///     filter: (query) => query.filter().deletedEqualTo(false),
  ///     sort: (a, b) => (b.refreshAt ?? DateTime.now())
  ///         .compareTo(a.refreshAt ?? DateTime.now()),
  ///   );
  /// }
  /// ```
  static Stream<List<T>> watchCollection<T extends Base>({
    required IsarCollection<T> collection,
    required QueryBuilder<T, T, QAfterFilterCondition> Function(
      IsarCollection<T>,
    ) filter,
    required int Function(T, T) sort,
  }) async* {
    // 초기값 먼저 방출
    final initialData = await filter(collection).findAll();
    initialData.sort(sort);
    yield initialData;

    // watchLazy로 변경 이벤트만 감지
    await for (final _ in collection.watchLazy()) {
      final data = await filter(collection).findAll();
      data.sort(sort);
      yield data;
    }
  }
}
