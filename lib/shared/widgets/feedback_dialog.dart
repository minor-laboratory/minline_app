import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/constants/feedback_templates.dart';
import '../../core/services/feedback_service.dart';

/// 피드백 다이얼로그
///
/// Draft/Post 피드백 신고 UI
class FeedbackDialog extends StatefulWidget {
  final String targetType; // 'draft' | 'post'
  final String targetId;

  const FeedbackDialog({
    required this.targetType,
    required this.targetId,
    super.key,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
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
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
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
    return ShadDialog(
      title: Text('feedback.what_went_wrong'.tr()),
      description: Text('feedback.select_or_describe'.tr()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사유 선택 (체크박스)
            ..._reasons.map((reason) {
              final isSelected = _selectedReasons.contains(reason.id);
              return CheckboxListTile(
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
                title: Text(reason.labelKey.tr()),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),

            const SizedBox(height: 16),

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
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.outline(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text('common.cancel'.tr()),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('feedback.submit'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
