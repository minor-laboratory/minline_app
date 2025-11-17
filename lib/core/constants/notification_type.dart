/// 알림 타입 (DB 스키마와 일치)
///
/// TypeScript fcm-utils.ts의 NotificationType과 동일한 값
enum NotificationType {
  /// Draft 완성 알림
  draftCompletion('draft_completion'),

  /// Post 생성 알림
  postCreation('post_creation');

  const NotificationType(this.value);
  final String value;
}
