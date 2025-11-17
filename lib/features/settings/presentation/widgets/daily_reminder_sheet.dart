import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../providers/quiet_hours_settings_provider.dart';

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
  Set<int> _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7}; // 월~일

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
    final weekdaysList = prefs.getStringList('daily_reminder_weekdays');
    final weekdays = weekdaysList?.map(int.parse).toSet() ?? {1, 2, 3, 4, 5, 6, 7};

    if (mounted) {
      setState(() {
        _enabled = enabled;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        _selectedWeekdays = weekdays;
      });
    }
  }

  Future<void> _saveSettings() async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', _enabled);
    await prefs.setInt('daily_reminder_hour', _selectedTime.hour);
    await prefs.setInt('daily_reminder_minute', _selectedTime.minute);
    await prefs.setStringList('daily_reminder_weekdays', _selectedWeekdays.map((e) => e.toString()).toList());

    if (_enabled) {

      try {
        // 1. 기본 알림 권한 확인
        final hasPermission = await LocalNotificationService().hasPermission();
        if (!hasPermission) {
          final granted = await LocalNotificationService().requestPermission();
          if (!granted) {
            // 권한 거부 시 처리
            if (!mounted) return;
            setState(() => _enabled = false);
            await prefs.setBool('daily_reminder_enabled', false);

            messenger.showSnackBar(
              SnackBar(
                content: Text('settings.notification_permission_required'.tr()),
                action: SnackBarAction(
                  label: 'common.ok'.tr(),
                  onPressed: () {},
                ),
              ),
            );
            return;
          }
        }

        // 2. 알림 스케줄링 (USE_EXACT_ALARM은 자동 부여되므로 권한 체크 불필요)
        await LocalNotificationService().scheduleDailyReminder(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          title: 'settings.daily_reminder_notification_title'.tr(),
          body: 'settings.daily_reminder_notification_body'.tr(),
          weekdays: _selectedWeekdays,
        );

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('settings.reminder_enabled'.tr()),
          ),
        );
      } catch (e, stack) {
        logger.e('[DailyReminder] Failed to schedule', e, stack);

        if (!mounted) return;
        setState(() => _enabled = false);
        await prefs.setBool('daily_reminder_enabled', false);

        messenger.showSnackBar(
          SnackBar(
            content: Text('settings.reminder_failed'.tr()),
            action: SnackBarAction(
              label: 'common.retry'.tr(),
              onPressed: () {
                setState(() => _enabled = true);
                _saveSettings();
              },
            ),
          ),
        );
      }
    } else {
      await LocalNotificationService().cancelDailyReminder();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('settings.reminder_disabled'.tr()),
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
      await _saveSettings();
    }
  }

  /// 선택한 시간이 방해금지 시간대에 포함되는지 확인
  bool _isInQuietHours(TimeOfDay time, QuietHoursData quietHours) {
    if (!quietHours.enabled) return false;

    final selectedMinutes = time.hour * 60 + time.minute;

    // 방해금지 시간 파싱
    final startParts = quietHours.quietStart.split(':');
    final endParts = quietHours.quietEnd.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // 자정을 넘어가는 경우 (예: 23:00 ~ 08:00)
    if (startMinutes > endMinutes) {
      return selectedMinutes >= startMinutes || selectedMinutes < endMinutes;
    } else {
      return selectedMinutes >= startMinutes && selectedMinutes < endMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadTheme = ShadTheme.of(context);
    final textTheme = theme.textTheme;

    // 방해금지 시간 확인
    final quietHoursAsync = ref.watch(quietHoursSettingsProvider);
    final hasQuietHoursConflict = quietHoursAsync.when(
      data: (quietHours) => _isInQuietHours(_selectedTime, quietHours),
      loading: () => false,
      error: (_, __) => false,
    );

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
                color: shadTheme.colorScheme.mutedForeground,
              ),
            ),
          ),

          // 알림 ON/OFF
          SwitchListTile(
            title: Text('common.enable'.tr()),
            value: _enabled,
            onChanged: (value) async {
              if (value) {
                // ON으로 변경 시: 이전 값 확인
                final prefs = await SharedPreferences.getInstance();
                final hasPreviousTime = prefs.containsKey('daily_reminder_hour');

                if (!hasPreviousTime) {
                  // 최초: 현재 시간 기준 5분 단위로 올림
                  final now = TimeOfDay.now();
                  final roundedMinute = ((now.minute ~/ 5) + 1) * 5;

                  if (roundedMinute >= 60) {
                    _selectedTime = TimeOfDay(
                      hour: (now.hour + 1) % 24,
                      minute: roundedMinute % 60,
                    );
                  } else {
                    _selectedTime = TimeOfDay(
                      hour: now.hour,
                      minute: roundedMinute,
                    );
                  }
                }
                // 이전 값이 있으면 _loadSettings()에서 로드된 값 사용
              }

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

            // 요일 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.repeat_on'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: shadTheme.colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: common.Spacing.sm),
                  Wrap(
                    spacing: common.Spacing.sm,
                    children: List.generate(7, (index) {
                      final weekday = index + 1;
                      final isSelected = _selectedWeekdays.contains(weekday);

                      return FilterChip(
                        label: Text('settings.weekday_$weekday'.tr()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(weekday);
                            } else {
                              if (_selectedWeekdays.length > 1) {
                                _selectedWeekdays.remove(weekday);
                              }
                            }
                          });
                          _saveSettings();
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),

            // 방해금지 시간 경고
            if (hasQuietHoursConflict) ...[
              const SizedBox(height: common.Spacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
                child: Container(
                  padding: const EdgeInsets.all(common.Spacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(common.BorderRadii.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.warning,
                        size: 16,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: common.Spacing.sm),
                      Expanded(
                        child: Text(
                          'settings.daily_reminder_quiet_hours_warning'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 테스트 버튼
            const SizedBox(height: common.Spacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
              child: ShadButton.outline(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await LocalNotificationService().showTestNotification();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('테스트 알림 전송됨')),
                  );
                },
                child: Text('테스트 알림 보내기'),
              ),
            ),
        ],

        const SizedBox(height: common.Spacing.md),
      ],
    );
  }
}
