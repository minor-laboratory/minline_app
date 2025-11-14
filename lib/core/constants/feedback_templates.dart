// 피드백 템플릿 정의
//
// 웹 버전과 동일한 구조
// 참조: miniline/src/lib/config/feedback-templates.ts

class FeedbackReason {
  final String id;
  final String labelKey;

  const FeedbackReason({
    required this.id,
    required this.labelKey,
  });
}

class FeedbackTemplates {
  /// Draft 피드백 사유
  static const List<FeedbackReason> draft = [
    FeedbackReason(
      id: 'irrelevant',
      labelKey: 'feedback.draft.irrelevant',
    ),
    FeedbackReason(
      id: 'poor_quality',
      labelKey: 'feedback.draft.poor_quality',
    ),
    FeedbackReason(
      id: 'wrong_grouping',
      labelKey: 'feedback.draft.wrong_grouping',
    ),
  ];

  /// Post 피드백 사유
  static const List<FeedbackReason> post = [
    FeedbackReason(
      id: 'inaccurate',
      labelKey: 'feedback.post.inaccurate',
    ),
    FeedbackReason(
      id: 'poor_writing',
      labelKey: 'feedback.post.poor_writing',
    ),
    FeedbackReason(
      id: 'wrong_tone',
      labelKey: 'feedback.post.wrong_tone',
    ),
    FeedbackReason(
      id: 'too_short',
      labelKey: 'feedback.post.too_short',
    ),
  ];
}
