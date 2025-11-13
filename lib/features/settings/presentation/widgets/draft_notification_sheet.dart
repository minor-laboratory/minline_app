import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('draft_notification_enabled') ?? true;

    if (mounted) {
      setState(() {
        _enabled = enabled;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('draft_notification_enabled', _enabled);
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'settings.draft_notifications_description'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // 알림 ON/OFF
          SwitchListTile(
            title: Text('common.enable'.tr()),
            subtitle: Text(
              _enabled
                  ? 'common.notifications_on'.tr()
                  : 'common.notifications_off'.tr(),
            ),
            value: _enabled,
            onChanged: (value) async {
              setState(() {
                _enabled = value;
              });
              await _saveSettings();
            },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
