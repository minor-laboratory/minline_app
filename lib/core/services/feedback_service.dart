import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

/// 피드백 서비스
///
/// Draft/Post 피드백 제출 및 조회
class FeedbackService {
  static final instance = FeedbackService._();
  FeedbackService._();

  final _supabase = Supabase.instance.client;

  /// 피드백 제출
  ///
  /// [targetType]: 'draft' | 'post'
  /// [targetId]: Draft/Post UUID
  /// [feedbackType]: 'issue' | 'suggestion'
  /// [selectedReasons]: 선택된 사유 목록
  /// [customReason]: 자유 입력 의견 (선택)
  Future<FeedbackResult> submitFeedback({
    required String targetType,
    required String targetId,
    required String feedbackType,
    required List<String> selectedReasons,
    String? customReason,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return FeedbackResult(
          success: false,
          error: 'auth_required',
        );
      }

      // 검증: 최소 1개 선택 필요
      final hasSelectedReasons = selectedReasons.isNotEmpty;
      final hasCustomReason = customReason?.trim().isNotEmpty ?? false;

      if (!hasSelectedReasons && !hasCustomReason) {
        return FeedbackResult(
          success: false,
          error: 'input_required',
        );
      }

      // customReason이 공백만 있으면 null로 처리
      final finalCustomReason = customReason?.trim().isEmpty ?? true
          ? null
          : customReason!.trim();

      // Supabase에 저장
      await _supabase.from('user_feedback').insert({
        'user_id': user.id,
        'target_type': targetType,
        'target_id': targetId,
        'feedback_type': feedbackType,
        'selected_reasons': selectedReasons,
        'custom_reason': finalCustomReason,
        'app_name': 'miniline',
      });

      logger.i('✅ 피드백 제출 완료: $targetType/$targetId');

      return FeedbackResult(success: true);
    } on PostgrestException catch (e) {
      // UNIQUE 제약조건 위반 (중복 제출)
      if (e.code == '23505') {
        logger.w('⚠️ 피드백 중복 제출: $targetType/$targetId');
        return FeedbackResult(
          success: false,
          error: 'already_submitted',
        );
      }

      logger.e('❌ 피드백 제출 실패:', e);
      return FeedbackResult(
        success: false,
        error: 'server_error',
      );
    } catch (e, stack) {
      logger.e('❌ 피드백 제출 오류:', e, stack);
      return FeedbackResult(
        success: false,
        error: 'server_error',
      );
    }
  }

  /// 기존 피드백 존재 확인
  ///
  /// [targetType]: 'draft' | 'post'
  /// [targetId]: Draft/Post UUID
  Future<bool> checkExistingFeedback({
    required String targetType,
    required String targetId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_feedback')
          .select('id')
          .eq('user_id', user.id)
          .eq('app_name', 'miniline')
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e, stack) {
      logger.e('❌ 피드백 조회 오류:', e, stack);
      return false;
    }
  }
}

/// 피드백 제출 결과
class FeedbackResult {
  final bool success;
  final String? error;

  FeedbackResult({
    required this.success,
    this.error,
  });
}
