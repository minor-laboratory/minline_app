import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/feedback_templates.dart';
import '../../../../core/services/feedback_service.dart';

/// 피드백 신고 페이지
///
/// Draft/Post 피드백 신고 UI (페이지 형식)
class FeedbackPage extends StatefulWidget {
  final String targetType; // 'draft' | 'post'
  final String targetId;

  const FeedbackPage({
    required this.targetType,
    required this.targetId,
    super.key,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _selectedReasons = <String>{};
  final _customReasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  List<FeedbackReason> get _reasons {
    switch (widget.targetType) {
      case 'draft':
        return FeedbackTemplates.draft;
      case 'post':
        return FeedbackTemplates.post;
      default:
        return [];
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await FeedbackService.instance.submitFeedback(
        targetType: widget.targetType,
        targetId: widget.targetId,
        feedbackType: 'issue',
        selectedReasons: _selectedReasons.toList(),
        customReason: _customReasonController.text,
      );

      if (!mounted) return;

      if (result.success) {
        final messenger = ScaffoldMessenger.of(context);
        context.pop(true);
        messenger.showSnackBar(
          SnackBar(content: Text('feedback.submit_success'.tr())),
        );
      } else {
        setState(() {
          _errorMessage = 'feedback.error_${result.error}'.tr();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('feedback.what_went_wrong'.tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShadButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('feedback.submit'.tr()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명
            Text(
              'feedback.select_or_describe'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 사유 선택 (체크박스)
            ..._reasons.map((reason) {
              final isSelected = _selectedReasons.contains(reason.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ShadCheckbox(
                      value: isSelected,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedReasons.add(reason.id);
                                } else {
                                  _selectedReasons.remove(reason.id);
                                }
                                _errorMessage = null;
                              });
                            },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedReasons.remove(reason.id);
                                  } else {
                                    _selectedReasons.add(reason.id);
                                  }
                                  _errorMessage = null;
                                });
                              },
                        child: Text(reason.labelKey.tr()),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 자유 입력
            ShadTextarea(
              controller: _customReasonController,
              placeholder: Text('feedback.additional_optional'.tr()),
              minHeight: 100,
              maxHeight: 200,
              enabled: !_isSubmitting,
              onChanged: (_) {
                setState(() => _errorMessage = null);
              },
            ),

            const SizedBox(height: 16),

            // 에러 메시지
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShadTheme.of(context).colorScheme.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: ShadTheme.of(context).colorScheme.destructiveForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
