import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/draft_notification_settings_provider.dart';

/// Draft 완성 알림 설정 바텀 시트
class DraftNotificationSheet extends ConsumerStatefulWidget {
  const DraftNotificationSheet({super.key});

  @override
  ConsumerState<DraftNotificationSheet> createState() =>
      _DraftNotificationSheetState();
}

class _DraftNotificationSheetState
    extends ConsumerState<DraftNotificationSheet> {
  bool _enabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsAsync = ref.read(draftNotificationSettingsProvider);

    settingsAsync.whenData((settings) {
      if (mounted) {
        setState(() {
          _enabled = settings.enabled;
          _startTime = _parseTime(settings.allowedStart);
          _endTime = _parseTime(settings.allowedEnd);
        });
      }
    });
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    final currentSettings = await ref.read(draftNotificationSettingsProvider.future);

    final settings = NotificationSettingsData(
      enabled: _enabled,
      allowedStart: _formatTime(_startTime),
      allowedEnd: _formatTime(_endTime),
      timezone: currentSettings.timezone, // 기존 timezone 유지
    );

    await ref
        .read(draftNotificationSettingsProvider.notifier)
        .updateSettings(settings);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null && mounted) {
      // 종료 시간보다 늦으면 안됨
      if (picked.hour > _endTime.hour ||
          (picked.hour == _endTime.hour && picked.minute >= _endTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.start_time_must_be_earlier'.tr()),
          ),
        );
        return;
      }

      setState(() => _startTime = picked);
      await _saveSettings();
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null && mounted) {
      // 시작 시간보다 빠르면 안됨
      if (picked.hour < _startTime.hour ||
          (picked.hour == _startTime.hour && picked.minute <= _startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.end_time_must_be_later'.tr()),
          ),
        );
        return;
      }

      setState(() => _endTime = picked);
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final shadTheme = ShadTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 설명
        Padding(
          padding: const EdgeInsets.all(common.Spacing.md),
          child: Text(
            'settings.draft_notifications_description'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: shadTheme.colorScheme.mutedForeground,
            ),
          ),
        ),

        // 알림 ON/OFF
        SwitchListTile(
          title: Text('common.enable'.tr()),
          value: _enabled,
          onChanged: (value) async {
            setState(() => _enabled = value);
            await _saveSettings();
          },
        ),

        // 허용 시간 범위
        if (_enabled) ...[
          const SizedBox(height: common.Spacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
            child: Text(
              'settings.draft_notification_time_range'.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: shadTheme.colorScheme.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: common.Spacing.sm),

          // 시작 시간
          ListTile(
            leading: Icon(AppIcons.clock),
            title: Text('settings.allowed_start_time'.tr()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _startTime.format(context),
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: common.Spacing.sm),
                Icon(AppIcons.chevronRight, size: 20),
              ],
            ),
            onTap: _selectStartTime,
          ),

          // 종료 시간
          ListTile(
            leading: Icon(AppIcons.clock),
            title: Text('settings.allowed_end_time'.tr()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _endTime.format(context),
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: common.Spacing.sm),
                Icon(AppIcons.chevronRight, size: 20),
              ],
            ),
            onTap: _selectEndTime,
          ),
        ],

        const SizedBox(height: common.Spacing.md),
      ],
    );
  }
}
