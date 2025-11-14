import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';

/// 태그 추가/편집 페이지
///
/// Fragment에 사용자 태그를 추가하는 전용 페이지
class TagEditPage extends StatefulWidget {
  final String fragmentId;

  const TagEditPage({super.key, required this.fragmentId});

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  final _tagController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 태그 저장
  void _save() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    // 결과 반환하고 페이지 닫기
    context.pop(tag);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('tag.add_tag'.tr()),
        leading: IconButton(
          icon: Icon(AppIcons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          ShadButton(
            enabled: _tagController.text.trim().isNotEmpty,
            onPressed: _save,
            child: Text('common.save'.tr()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 설명 텍스트
            Text(
              'tag.add_tag_description'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // 태그 입력
            ShadInput(
              controller: _tagController,
              focusNode: _focusNode,
              placeholder: Text('tag.add_tag_placeholder'.tr()),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) => _save(),
            ),

            const SizedBox(height: 24),

            // 힌트
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.info,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'tag.hint'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
