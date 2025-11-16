import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'base.dart';

part 'fragment.g.dart';

/// Fragment (토막글)
/// 사용자가 입력한 단편적인 생각/메모
@collection
class Fragment extends Base {
  /// 사용자 ID
  @Index()
  @Name('user_id')
  String? userId;

  /// 텍스트 콘텐츠
  String content = '';

  /// 미디어 URL 배열
  @Name('media_urls')
  List<String> mediaUrls = [];

  /// 입력 시간 (사용자가 글을 입력한 시간)
  @Index()
  DateTime timestamp = DateTime.now().toLocal();

  /// 실제 사건 발생 시간 (AI가 분석하여 업데이트)
  @Index()
  @Name('event_time')
  DateTime eventTime = DateTime.now().toLocal();

  /// 시간 출처 및 형식
  /// - auto: 자동 설정 (eventTime = timestamp)
  /// - ai_date: AI가 감지한 날짜
  /// - ai_time: AI가 감지한 날짜+시간
  /// - user_date: 사용자가 지정한 날짜
  /// - user_time: 사용자가 지정한 날짜+시간
  @Name('event_time_source')
  String eventTimeSource = 'auto';

  /// AI 태그 (AI가 자동 생성) - 인덱스로 빠른 필터링
  @Index(type: IndexType.value)
  List<String> tags = [];

  /// 사용자 태그 (사용자가 수동 추가) - 인덱스로 빠른 필터링
  @Index(type: IndexType.value)
  @Name('user_tags')
  List<String> userTags = [];

  /// 전체 텍스트 검색용 단어 인덱스 (Isar.splitWords 사용)
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get contentWords => Isar.splitWords(content);

  /// 기본 생성자 - Isar requires
  Fragment();

  /// 새 Fragment 생성용 생성자
  Fragment.fromNew({
    super.synced,
    super.deleted,
    super.previousRemoteID,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    DateTime? timestamp,
    DateTime? eventTime,
    this.eventTimeSource = 'auto',
    this.tags = const [],
    this.userTags = const [],
  })  : timestamp = timestamp ?? DateTime.now().toLocal(),
        eventTime = eventTime ?? (timestamp ?? DateTime.now().toLocal()),
        super.fromNew();

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();

    data['user_id'] = userId;
    data['content'] = content;
    data['media_urls'] = mediaUrls;
    data['timestamp'] = timestamp.toUtc().toIso8601String();
    data['event_time'] = eventTime.toUtc().toIso8601String();
    data['event_time_source'] = eventTimeSource;
    data['tags'] = tags;
    data['user_tags'] = userTags;

    return data;
  }

  /// JSON에서 생성
  Fragment.fromJson(Map<String, dynamic> json) {
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
    content = json['content'] ?? '';
    mediaUrls = (json['media_urls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    timestamp = json['timestamp'] != null
        ? DateTime.parse(json['timestamp']).toLocal()
        : DateTime.now().toLocal();
    eventTime = json['event_time'] != null
        ? DateTime.parse(json['event_time']).toLocal()
        : DateTime.now().toLocal();
    eventTimeSource = json['event_time_source'] ?? 'auto';
    tags =
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];
    userTags = (json['user_tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  @override
  Map<String, dynamic> toRemote() {
    final data = super.toRemote();

    data['user_id'] = userId;
    data['content'] = content;
    data['media_urls'] = mediaUrls;
    data['timestamp'] = timestamp.toUtc().toIso8601String();
    data['event_time'] = eventTime.toUtc().toIso8601String();
    data['event_time_source'] = eventTimeSource;
    data['tags'] = tags;
    data['user_tags'] = userTags;

    return data;
  }
}
