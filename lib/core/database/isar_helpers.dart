import 'package:isar_community/isar.dart';
import 'package:miniline_app/models/base.dart';

/// Isar write transaction 헬퍼
///
/// 공통 패턴을 추출하여 코드 중복을 줄이고 실수를 방지합니다.
extension IsarWriteHelper on Isar {
  /// synced = false, refreshAt = now()를 자동으로 설정하고 저장
  ///
  /// 사용 예시:
  /// ```dart
  /// await isar.putWithSync(isar.fragments, fragment);
  /// ```
  Future<Id> putWithSync<T extends Base>(
    IsarCollection<T> collection,
    T object,
  ) async {
    return await writeTxn(() async {
      object.synced = false;
      object.refreshAt = DateTime.now().toLocal();
      return await collection.put(object);
    });
  }

  /// 여러 객체를 한 번에 저장 (synced = false, refreshAt = now() 자동 설정)
  ///
  /// 사용 예시:
  /// ```dart
  /// await isar.putAllWithSync(isar.fragments, fragmentList);
  /// ```
  Future<List<Id>> putAllWithSync<T extends Base>(
    IsarCollection<T> collection,
    List<T> objects,
  ) async {
    return await writeTxn(() async {
      for (final object in objects) {
        object.synced = false;
        object.refreshAt = DateTime.now().toLocal();
      }
      return await collection.putAll(objects);
    });
  }

  /// 객체를 삭제 (논리 삭제: deleted = true)
  ///
  /// 사용 예시:
  /// ```dart
  /// await isar.deleteWithSync(isar.fragments, fragment);
  /// ```
  Future<Id> deleteWithSync<T extends Base>(
    IsarCollection<T> collection,
    T object,
  ) async {
    return await writeTxn(() async {
      object.deleted = true;
      object.synced = false;
      object.refreshAt = DateTime.now().toLocal();
      return await collection.put(object);
    });
  }
}
