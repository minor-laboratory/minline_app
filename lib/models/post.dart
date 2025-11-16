import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'base.dart';

part 'post.g.dart';

/// Post (완성된 글)
/// AI가 생성한 완성된 글
@collection
class Post extends Base {
  /// 사용자 ID
  @Index()
  @Name('user_id')
  String? userId;

  /// 원본 Draft ID
  @Index()
  @Name('draft_id')
  String? draftId;

  /// 글 제목
  String title = '';

  /// 완성된 글 (Markdown)
  String content = '';

  /// 사용된 Fragment 배열
  @Name('fragment_ids')
  List<String> fragmentIds = [];

  /// 템플릿 타입
  /// - product_review: 제품 사용기
  /// - timeline: 시간순 스토리
  /// - essay: 생각 정리
  /// - travel: 여행기
  /// - project: 프로젝트 기록
  @Index()
  String template = 'essay';

  /// 버전 번호
  int version = 1;

  /// 이전 버전 ID
  @Name('previous_version_id')
  String? previousVersionId;

  /// 내보낸 플랫폼
  @Name('exported_to')
  List<String> exportedTo = [];

  /// 공개 여부
  @Index()
  @Name('is_public')
  bool isPublic = false;

  /// 확인 여부 (헤더 뱃지 표시용)
  @Index()
  bool viewed = false;

  /// 기본 생성자 - Isar requires
  Post();

  /// 새 Post 생성용 생성자
  Post.fromNew({
    super.synced,
    super.deleted,
    super.previousRemoteID,
    required this.userId,
    this.draftId,
    required this.title,
    required this.content,
    this.fragmentIds = const [],
    required this.template,
    this.version = 1,
    this.previousVersionId,
    this.exportedTo = const [],
    this.isPublic = false,
    this.viewed = false,
  }) : super.fromNew();

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();

    data['user_id'] = userId;
    if (draftId != null) data['draft_id'] = draftId;
    data['title'] = title;
    data['content'] = content;
    data['fragment_ids'] = fragmentIds;
    data['template'] = template;
    data['version'] = version;
    if (previousVersionId != null) {
      data['previous_version_id'] = previousVersionId;
    }
    data['exported_to'] = exportedTo;
    data['is_public'] = isPublic;
    data['viewed'] = viewed;

    return data;
  }

  /// JSON에서 생성
  Post.fromJson(Map<String, dynamic> json) {
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
    draftId = json['draft_id'];
    title = json['title'] ?? '';
    content = json['content'] ?? '';
    fragmentIds = (json['fragment_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    template = json['template'] ?? 'essay';
    version = json['version'] ?? 1;
    previousVersionId = json['previous_version_id'];
    exportedTo = (json['exported_to'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    isPublic = json['is_public'] ?? false;
    viewed = json['viewed'] ?? false;
  }

  @override
  Map<String, dynamic> toRemote() {
    final data = super.toRemote();

    data['user_id'] = userId;
    if (draftId != null) data['draft_id'] = draftId;
    data['title'] = title;
    data['content'] = content;
    data['fragment_ids'] = fragmentIds;
    data['template'] = template;
    data['version'] = version;
    if (previousVersionId != null) {
      data['previous_version_id'] = previousVersionId;
    }
    data['exported_to'] = exportedTo;
    data['is_public'] = isPublic;
    data['viewed'] = viewed;

    return data;
  }

  /// 미확인 Post인지 확인
  @ignore
  bool get isUnviewed => !viewed;

  /// 공개된 Post인지 확인
  @ignore
  bool get isPublicPost => isPublic;

  /// 내보낸 적이 있는지 확인
  @ignore
  bool get hasExported => exportedTo.isNotEmpty;
}
