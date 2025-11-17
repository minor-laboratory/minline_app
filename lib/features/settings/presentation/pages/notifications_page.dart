import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../shared/widgets/standard_bottom_sheet.dart';
import '../../providers/draft_notification_settings_provider.dart';
import '../../providers/post_notification_settings_provider.dart';
import '../../providers/quiet_hours_settings_provider.dart';
import '../widgets/daily_reminder_sheet.dart';
import '../widgets/quiet_hours_sheet.dart';

/// 알림 설정 페이지
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shadTheme = ShadTheme.of(context);
    final textTheme = theme.textTheme;

    final quietHoursAsync = ref.watch(quietHoursSettingsProvider);
    final draftAsync = ref.watch(draftNotificationSettingsProvider);
    final postAsync = ref.watch(postNotificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.notifications'.tr()),
      ),
      body: ListView(
        children: [
          // ========== 방해금지 시간 섹션 ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(
              common.Spacing.md,
              common.Spacing.md,
              common.Spacing.md,
              common.Spacing.sm,
            ),
            child: Text(
              'settings.quiet_hours'.tr(),
              style: textTheme.labelLarge?.copyWith(
                color: shadTheme.colorScheme.mutedForeground,
              ),
            ),
          ),

          quietHoursAsync.when(
            data: (quietHours) => ListTile(
              leading: Icon(AppIcons.moon),
              title: Text('settings.quiet_hours_time'.tr()),
              subtitle: Text(
                quietHours.enabled
                    ? '${quietHours.quietStart} - ${quietHours.quietEnd}'
                    : 'settings.quiet_hours_disabled'.tr(),
              ),
              trailing: Icon(AppIcons.chevronRight, size: 20),
              onTap: () => _showQuietHoursSheet(context),
            ),
            loading: () => ListTile(
              leading: Icon(AppIcons.moon),
              title: Text('settings.quiet_hours_time'.tr()),
              subtitle: Text('common.loading'.tr()),
            ),
            error: (_, __) => ListTile(
              leading: Icon(AppIcons.moon),
              title: Text('settings.quiet_hours_time'.tr()),
              subtitle: Text('settings.quiet_hours_error'.tr()),
              onTap: () => _showQuietHoursSheet(context),
            ),
          ),

          const Divider(height: common.Spacing.lg),

          // ========== 푸시 알림 섹션 ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(
              common.Spacing.md,
              common.Spacing.sm,
              common.Spacing.md,
              common.Spacing.sm,
            ),
            child: Text(
              'settings.push_notifications'.tr(),
              style: textTheme.labelLarge?.copyWith(
                color: shadTheme.colorScheme.mutedForeground,
              ),
            ),
          ),

          // Draft 완성 알림
          draftAsync.when(
            data: (draft) => SwitchListTile(
              secondary: Icon(AppIcons.checkCircle),
              title: Text('settings.draft_completion_notification'.tr()),
              subtitle: Text('settings.draft_completion_description'.tr()),
              value: draft.enabled,
              onChanged: (value) async {
                final updated = NotificationSettingsData(
                  enabled: value,
                  allowedStart: draft.allowedStart,
                  allowedEnd: draft.allowedEnd,
                );
                await ref
                    .read(draftNotificationSettingsProvider.notifier)
                    .updateSettings(updated);
              },
            ),
            loading: () => ListTile(
              leading: Icon(AppIcons.checkCircle),
              title: Text('settings.draft_completion_notification'.tr()),
              subtitle: Text('common.loading'.tr()),
            ),
            error: (_, __) => ListTile(
              leading: Icon(AppIcons.checkCircle),
              title: Text('settings.draft_completion_notification'.tr()),
              subtitle: Text('settings.error_loading'.tr()),
            ),
          ),

          // Post 알림
          postAsync.when(
            data: (post) => SwitchListTile(
              secondary: Icon(AppIcons.send),
              title: Text('settings.post_notification'.tr()),
              subtitle: Text('settings.post_notification_description'.tr()),
              value: post.enabled,
              onChanged: (value) async {
                final updated = PostNotificationData(
                  enabled: value,
                  allowedStart: post.allowedStart,
                  allowedEnd: post.allowedEnd,
                );
                await ref
                    .read(postNotificationSettingsProvider.notifier)
                    .updateSettings(updated);
              },
            ),
            loading: () => ListTile(
              leading: Icon(AppIcons.send),
              title: Text('settings.post_notification'.tr()),
              subtitle: Text('common.loading'.tr()),
            ),
            error: (_, __) => ListTile(
              leading: Icon(AppIcons.send),
              title: Text('settings.post_notification'.tr()),
              subtitle: Text('settings.error_loading'.tr()),
            ),
          ),

          const Divider(height: common.Spacing.lg),

          // ========== 로컬 알림 섹션 ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(
              common.Spacing.md,
              common.Spacing.sm,
              common.Spacing.md,
              common.Spacing.sm,
            ),
            child: Text(
              'settings.local_notifications'.tr(),
              style: textTheme.labelLarge?.copyWith(
                color: shadTheme.colorScheme.mutedForeground,
              ),
            ),
          ),

          // Daily Reminder
          ListTile(
            leading: Icon(AppIcons.notification),
            title: Text('settings.daily_reminder'.tr()),
            subtitle: Text('settings.daily_reminder_description'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: () => _showDailyReminderSheet(context),
          ),

          const SizedBox(height: common.Spacing.md),
        ],
      ),
    );
  }

  void _showQuietHoursSheet(BuildContext context) {
    StandardBottomSheet.show(
      context: context,
      title: 'settings.quiet_hours'.tr(),
      content: const QuietHoursSheet(),
    );
  }

  void _showDailyReminderSheet(BuildContext context) {
    StandardBottomSheet.show(
      context: context,
      title: 'settings.daily_reminder'.tr(),
      content: const DailyReminderSheet(),
    );
  }
}
