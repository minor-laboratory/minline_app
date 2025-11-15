import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/app_icons.dart';

/// 일일 리마인더 시간 설정 바텀 시트
class DailyReminderSheet extends ConsumerStatefulWidget {
  const DailyReminderSheet({super.key});

  @override
  ConsumerState<DailyReminderSheet> createState() =>
      _DailyReminderSheetState();
}

class _DailyReminderSheetState extends ConsumerState<DailyReminderSheet> {
  bool _enabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_reminder_enabled') ?? false;
    final hour = prefs.getInt('daily_reminder_hour') ?? 20;
    final minute = prefs.getInt('daily_reminder_minute') ?? 0;

    if (mounted) {
      setState(() {
        _enabled = enabled;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', _enabled);
    await prefs.setInt('daily_reminder_hour', _selectedTime.hour);
    await prefs.setInt('daily_reminder_minute', _selectedTime.minute);

    if (_enabled) {
      await LocalNotificationService().scheduleDailyReminder(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        title: 'timeline.title'.tr(),
        body: 'common.input_placeholder'.tr(),
      );
    } else {
      await LocalNotificationService().cancelDailyReminder();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 설명
          Padding(
            padding: const EdgeInsets.all(common.Spacing.md),
            child: Text(
              'settings.daily_reminder_description'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // 알림 ON/OFF
          SwitchListTile(
            title: Text('common.enable'.tr()),
            value: _enabled,
            onChanged: (value) async {
              setState(() {
                _enabled = value;
              });
              await _saveSettings();
            },
          ),

          // 시간 선택
          if (_enabled) ...[
            ListTile(
              leading: Icon(AppIcons.clock),
              title: Text('settings.notification_time'.tr()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedTime.format(context),
                    style: textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: common.Spacing.sm),
                  Icon(AppIcons.chevronRight, size: 20),
                ],
              ),
              onTap: _selectTime,
            ),
        ],

        const SizedBox(height: common.Spacing.md),
      ],
    );
  }
}
