import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';

/// Draft 카드 액션 버튼 위젯 (웹 버전과 동일한 구조)
class DraftCardActions extends StatelessWidget {
  final String status;
  final bool isLoading;
  final bool hasSubmittedFeedback;
  final String draftRemoteID;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onFeedback;

  const DraftCardActions({
    super.key,
    required this.status,
    required this.isLoading,
    required this.hasSubmittedFeedback,
    required this.draftRemoteID,
    required this.onAccept,
    required this.onReject,
    required this.onDelete,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Accept 버튼 (왼쪽)
          ShadButton(
            onPressed: isLoading ? null : onAccept,
            size: ShadButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(AppIcons.checkCircle, size: 16),
                const SizedBox(width: 6),
                Text(
                  isLoading ? 'common.loading'.tr() : 'draft.accept_action'.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Reject 버튼 (오른쪽)
          ShadButton.outline(
            onPressed: isLoading ? null : onReject,
            size: ShadButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.error, size: 16),
                const SizedBox(width: 6),
                Text('draft.reject_action'.tr()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // More 버튼
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 28,
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  AppIcons.moreVert,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'feedback':
                      onFeedback();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'feedback',
                    enabled: !hasSubmittedFeedback,
                    child: Row(
                      children: [
                        Icon(
                          hasSubmittedFeedback ? AppIcons.checkCircle : AppIcons.flag,
                          size: 16,
                          color: hasSubmittedFeedback
                              ? theme.colorScheme.border
                              : theme.colorScheme.foreground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasSubmittedFeedback
                              ? 'feedback.submitted'.tr()
                              : 'feedback.report_issue'.tr(),
                          style: TextStyle(
                            color: hasSubmittedFeedback
                                ? theme.colorScheme.border
                                : theme.colorScheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(AppIcons.delete, size: 16, color: theme.colorScheme.destructive),
                        const SizedBox(width: 8),
                        Text(
                          'common.delete'.tr(),
                          style: TextStyle(color: theme.colorScheme.destructive),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Create Post 버튼 (왼쪽)
          ShadButton(
            onPressed: isLoading
                ? null
                : () => context.push('/posts/create/$draftRemoteID'),
            size: ShadButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.fileText, size: 16),
                const SizedBox(width: 6),
                Text('draft.create_post'.tr()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Reject 버튼 (오른쪽)
          ShadButton.outline(
            onPressed: isLoading ? null : onReject,
            size: ShadButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.error, size: 16),
                const SizedBox(width: 6),
                Text('draft.reject_action'.tr()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // More 버튼
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 28,
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  AppIcons.moreVert,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'feedback':
                      onFeedback();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'feedback',
                    enabled: !hasSubmittedFeedback,
                    child: Row(
                      children: [
                        Icon(
                          hasSubmittedFeedback ? AppIcons.checkCircle : AppIcons.flag,
                          size: 16,
                          color: hasSubmittedFeedback
                              ? theme.colorScheme.border
                              : theme.colorScheme.foreground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasSubmittedFeedback
                              ? 'feedback.submitted'.tr()
                              : 'feedback.report_issue'.tr(),
                          style: TextStyle(
                            color: hasSubmittedFeedback
                                ? theme.colorScheme.border
                                : theme.colorScheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(AppIcons.delete, size: 16, color: theme.colorScheme.destructive),
                        const SizedBox(width: 8),
                        Text(
                          'common.delete'.tr(),
                          style: TextStyle(color: theme.colorScheme.destructive),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (status == 'rejected') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Reaccept 버튼 (왼쪽)
          ShadButton(
            onPressed: isLoading ? null : onAccept,
            size: ShadButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.checkCircle, size: 16),
                const SizedBox(width: 6),
                Text('draft.reaccept_action'.tr()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // More 버튼
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 28,
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  AppIcons.moreVert,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'feedback':
                      onFeedback();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'feedback',
                    enabled: !hasSubmittedFeedback,
                    child: Row(
                      children: [
                        Icon(
                          hasSubmittedFeedback ? AppIcons.checkCircle : AppIcons.flag,
                          size: 16,
                          color: hasSubmittedFeedback
                              ? theme.colorScheme.border
                              : theme.colorScheme.foreground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasSubmittedFeedback
                              ? 'feedback.submitted'.tr()
                              : 'feedback.report_issue'.tr(),
                          style: TextStyle(
                            color: hasSubmittedFeedback
                                ? theme.colorScheme.border
                                : theme.colorScheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(AppIcons.delete, size: 16, color: theme.colorScheme.destructive),
                        const SizedBox(width: 8),
                        Text(
                          'common.delete'.tr(),
                          style: TextStyle(color: theme.colorScheme.destructive),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
