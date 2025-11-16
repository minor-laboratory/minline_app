import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'base.dart';

part 'draft.g.dart';

/// Draft (AI 제안)
/// AI가 자동으로 생성한 글 제안 (관련 Fragment 그룹)
@collection
class Draft extends Base {
  /// 사용자 ID
  @Index()
  @Name('user_id')
  String? userId;

  /// AI 생성 제목
  String title = '';

  /// 묶은 이유
  String? reason;

  /// Fragment UUID 배열
  @Name('fragment_ids')
  List<String> fragmentIds = [];

  /// 평균 유사도
  @Name('similarity_score')
  double? similarityScore;

  /// 상태
  /// - pending: 사용자 확인 대기
  /// - accepted: 사용자 수락 (글 생성)
  /// - rejected: 사용자 거부
  @Index()
  String status = 'pending';

  /// 확인 여부 (헤더 뱃지 표시용)
  @Index()
  bool viewed = false;

  /// 기본 생성자 - Isar requires
  Draft();

  /// 새 Draft 생성용 생성자
  Draft.fromNew({
    super.synced,
    super.deleted,
    super.previousRemoteID,
    required this.userId,
    required this.title,
    this.reason,
    this.fragmentIds = const [],
    this.similarityScore,
    this.status = 'pending',
    this.viewed = false,
  }) : super.fromNew();

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();

    data['user_id'] = userId;
    data['title'] = title;
    if (reason != null) data['reason'] = reason;
    data['fragment_ids'] = fragmentIds;
    if (similarityScore != null) data['similarity_score'] = similarityScore;
    data['status'] = status;
    data['viewed'] = viewed;

    return data;
  }

  /// JSON에서 생성
  Draft.fromJson(Map<String, dynamic> json) {
    // Base 필드 초기화
    remoteID = json['id'] ?? json['remote_id'] ?? const Uuid().v4();
    synced = json['synced'] ?? false;
    createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at']).toLocal()
        : DateTime.now().toLocal();
    updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at']).toLocal()
        : DateTime.now().toLocal();
    refreshAt = DateTime.now().toLocal();
    deleted = json['deleted'] ?? false;

    // 필드 초기화
    userId = json['user_id'];
    title = json['title'] ?? '';
    reason = json['reason'];
    fragmentIds = (json['fragment_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    similarityScore = json['similarity_score'] != null
        ? (json['similarity_score'] as num).toDouble()
        : null;
    status = json['status'] ?? 'pending';
    viewed = json['viewed'] ?? false;
  }

  @override
  Map<String, dynamic> toRemote() {
    final data = super.toRemote();

    data['user_id'] = userId;
    data['title'] = title;
    if (reason != null) data['reason'] = reason;
    data['fragment_ids'] = fragmentIds;
    if (similarityScore != null) data['similarity_score'] = similarityScore;
    data['status'] = status;
    data['viewed'] = viewed;

    return data;
  }

  /// 미확인 Draft인지 확인
  @ignore
  bool get isUnviewed => !viewed;

  /// 대기 중인 Draft인지 확인
  @ignore
  bool get isPending => status == 'pending';

  /// 수락된 Draft인지 확인
  @ignore
  bool get isAccepted => status == 'accepted';

  /// 거부된 Draft인지 확인
  @ignore
  bool get isRejected => status == 'rejected';
}
