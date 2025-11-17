import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/quiet_hours_settings_provider.dart';

/// 방해금지 시간 설정 바텀 시트
class QuietHoursSheet extends ConsumerStatefulWidget {
  const QuietHoursSheet({super.key});

  @override
  ConsumerState<QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends ConsumerState<QuietHoursSheet> {
  bool _enabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsAsync = ref.read(quietHoursSettingsProvider);

    settingsAsync.whenData((settings) {
      if (mounted) {
        setState(() {
          _enabled = settings.enabled;
          _startTime = _parseTime(settings.quietStart);
          _endTime = _parseTime(settings.quietEnd);
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
    final settings = QuietHoursData(
      enabled: _enabled,
      quietStart: _formatTime(_startTime),
      quietEnd: _formatTime(_endTime),
    );

    await ref
        .read(quietHoursSettingsProvider.notifier)
        .updateSettings(settings);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null && mounted) {
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
            'settings.quiet_hours_description'.tr(),
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

        // 시간 범위
        if (_enabled) ...[
          const SizedBox(height: common.Spacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
            child: Text(
              'settings.quiet_hours_time_range'.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: shadTheme.colorScheme.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: common.Spacing.sm),

          // 시작 시간
          ListTile(
            leading: Icon(AppIcons.clock),
            title: Text('settings.quiet_hours_start'.tr()),
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
            title: Text('settings.quiet_hours_end'.tr()),
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

          // 안내 메시지
          Padding(
            padding: const EdgeInsets.all(common.Spacing.md),
            child: Container(
              padding: const EdgeInsets.all(common.Spacing.sm),
              decoration: BoxDecoration(
                color: shadTheme.colorScheme.muted,
                borderRadius: BorderRadius.circular(common.BorderRadii.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppIcons.info,
                    size: 16,
                    color: shadTheme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: common.Spacing.sm),
                  Expanded(
                    child: Text(
                      'settings.quiet_hours_info'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: shadTheme.colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: common.Spacing.md),
      ],
    );
  }
}
