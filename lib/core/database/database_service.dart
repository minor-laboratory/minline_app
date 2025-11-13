import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/draft.dart';
import '../../models/fragment.dart';
import '../../models/post.dart';

part 'database_service.g.dart';

/// Isar 기반 데이터베이스 서비스
/// minorlab_book의 DatabaseService 패턴을 따름
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  Isar? _isar;

  /// Isar 인스턴스 접근
  Isar get isar {
    if (_isar == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _isar!;
  }

  /// 데이터베이스 초기화
  Future<void> init({Isar? testIsar}) async {
    if (_isar != null) return;

    // 테스트용 Isar 인스턴스가 제공된 경우 사용
    if (testIsar != null) {
      _isar = testIsar;
      return;
    }

    final directory = await getApplicationSupportDirectory();

    _isar = await Isar.open(
      [
        FragmentSchema,
        DraftSchema,
        PostSchema,
      ],
      directory: directory.path,
      inspector: true, // 개발 중 Isar Inspector 활성화
    );
  }

  /// 데이터베이스 종료
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// 로컬에 사용자 데이터가 있는지 확인
  ///
  /// 로그인/회원가입 시 로컬 데이터 병합/삭제 선택을 위해 사용
  ///
  /// Returns: 하나 이상의 데이터가 존재하면 true
  Future<bool> hasLocalData() async {
    final fragmentCount = await isar.fragments.count();
    final draftCount = await isar.drafts.count();
    final postCount = await isar.posts.count();

    return fragmentCount > 0 || draftCount > 0 || postCount > 0;
  }

  /// 데이터베이스 리셋 (모든 데이터 삭제)
  Future<void> reset() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }

  /// 테스트용 Isar 인스턴스 설정
  static void setTestInstance(Isar testIsar) {
    _instance ??= DatabaseService._();
    _instance!._isar = testIsar;
  }

  /// 테스트용 인스턴스 초기화
  static void resetInstance() {
    _instance = null;
  }
}

// Isar Provider
@riverpod
Future<Isar> database(Ref ref) async {
  final service = DatabaseService.instance;
  await service.init();
  return service.isar;
}
