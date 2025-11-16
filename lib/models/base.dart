import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

/// Isar에서 사용할 해시 함수
/// 북랩 base.dart의 fastHash 함수 참조
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

/// Isar 기반 모든 모델의 베이스 클래스
/// 북랩 패턴 + MiniLine 서버 스키마 호환
abstract class Base {
  /// Isar ID (remoteID의 해시값)
  Id get id => fastHash(remoteID);

  /// 원격 아이디 (UUID)
  @Index(unique: true)
  @Name('remote_id')
  late String remoteID;

  /// 생성 시간
  @Index()
  @Name('created_at')
  late DateTime createdAt;

  /// 수정 시간
  @Name('updated_at')
  late DateTime updatedAt;

  /// 로컬 업데이트 처리를 위한 변수 (UI 갱신 트리거)
  @Index()
  @Name('refresh_at')
  DateTime? refreshAt;

  /// 동기화 상태
  @Index()
  bool synced = false;

  /// 논리 삭제 플래그
  @Index()
  bool deleted = false;

  Base({
    String? remoteID,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? refreshAt,
    bool? synced,
    bool? deleted,
  })  : refreshAt = refreshAt ?? DateTime.now().toLocal(),
        updatedAt = updatedAt ?? DateTime.now().toLocal(),
        createdAt = createdAt ?? DateTime.now().toLocal(),
        synced = synced ?? false,
        deleted = deleted ?? false,
        remoteID = remoteID ?? const Uuid().v4();

  Base.fromNew({
    this.synced = false,
    this.deleted = false,
    String? previousRemoteID,
  })  : refreshAt = DateTime.now().toLocal(),
        updatedAt = DateTime.now().toLocal(),
        createdAt = DateTime.now().toLocal(),
        remoteID = previousRemoteID ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['remote_id'] = remoteID;
    data['created_at'] = createdAt.toUtc().toIso8601String();
    data['updated_at'] = updatedAt.toUtc().toIso8601String();
    data['synced'] = synced;
    data['deleted'] = deleted;

    return data;
  }

  Base.fromJson(Map<String, dynamic> json)
      : remoteID = json['remote_id'] ?? const Uuid().v4(),
        synced = json['synced'] ?? false,
        createdAt = DateTime.parse(json['created_at']).toLocal(),
        updatedAt = DateTime.parse(json['updated_at']).toLocal() {
    refreshAt = DateTime.now().toLocal();
    deleted = json['deleted'] ?? false;
  }

  Map<String, dynamic> toRemote() {
    final data = <String, dynamic>{};

    data['id'] = remoteID;
    data['deleted'] = deleted;

    return data;
  }

  /// 업데이트 여부 확인
  @ignore
  bool get updated {
    return createdAt.microsecondsSinceEpoch < updatedAt.microsecondsSinceEpoch;
  }

  /// 동기화가 필요한지 확인
  @ignore
  bool get needsSync => !synced;

  /// 삭제된 상태인지 확인
  @ignore
  bool get isDeleted => deleted;
}
