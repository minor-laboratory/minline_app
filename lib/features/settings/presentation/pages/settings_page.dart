import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_icons.dart';
import '../widgets/daily_reminder_sheet.dart';
import '../widgets/draft_notification_sheet.dart';
import '../widgets/language_settings_sheet.dart';
import '../widgets/theme_settings_sheet.dart';

/// Settings 화면
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.logout'.tr()),
        content: Text('settings.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('settings.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('settings.logout'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('common.error'.tr())),
          );
        }
      }
    }
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ThemeSettingsSheet(),
    );
  }

  void _showLanguageSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LanguageSettingsSheet(),
    );
  }

  void _showDailyReminderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DailyReminderSheet(),
    );
  }

  void _showDraftNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DraftNotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null && !(user.isAnonymous);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
      ),
      body: ListView(
        children: [
          // UX 설정 섹션
          _buildSectionHeader(context, 'settings.ux'.tr()),

          ListTile(
            leading: Icon(AppIcons.palette),
            title: Text('settings.theme'.tr()),
            subtitle: Text('settings.theme_description'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: _showThemeSettings,
          ),

          ListTile(
            leading: Icon(AppIcons.language),
            title: Text('settings.language'.tr()),
            subtitle: Text('settings.language_description'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: _showLanguageSettings,
          ),

          const Divider(),

          // 알림 설정 섹션
          _buildSectionHeader(context, 'settings.notifications'.tr()),

          ListTile(
            leading: Icon(AppIcons.notification),
            title: Text('settings.daily_reminder'.tr()),
            subtitle: Text('settings.daily_reminder_description'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: _showDailyReminderSettings,
          ),

          ListTile(
            leading: Icon(AppIcons.notification),
            title: Text('settings.draft_notifications'.tr()),
            subtitle: Text('settings.draft_notifications_description'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: _showDraftNotificationSettings,
          ),

          const Divider(),

          // 앱 정보 섹션
          _buildSectionHeader(context, 'settings.app_info'.tr()),

          ListTile(
            leading: Icon(AppIcons.info),
            title: Text('settings.app_version'.tr()),
            subtitle: Text(_appVersion),
          ),

          const Divider(),

          // 법적 정보 섹션
          _buildSectionHeader(context, 'settings.legal'.tr()),

          ListTile(
            leading: Icon(AppIcons.fileText),
            title: Text('settings.terms_of_service'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: () => context.push('/settings/terms'),
          ),

          ListTile(
            leading: Icon(AppIcons.fileText),
            title: Text('settings.privacy_policy'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: () => context.push('/settings/privacy'),
          ),

          // 로그아웃 (로그인 상태일 때만)
          if (isLoggedIn) ...[
            const Divider(),
            ListTile(
              leading: Icon(AppIcons.logout, color: colorScheme.error),
              title: Text(
                'settings.logout'.tr(),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              onTap: _handleLogout,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
