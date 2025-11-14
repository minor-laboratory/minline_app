import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../shared/widgets/standard_bottom_sheet.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/widgets/user_profile_section.dart';
import '../../providers/settings_provider.dart';
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
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.logout'.tr()),
        description: Text('settings.logout_confirm'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('settings.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // AuthRepository를 통해 로그아웃 (로컬 데이터 정리 포함)
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('settings.logout'.tr())),
          );
          // 타임라인으로 이동 (로컬 퍼스트: 로그아웃 후에도 사용 가능)
          context.go('/');
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
    StandardBottomSheet.show(
      context: context,
      title: 'settings.theme'.tr(),
      content: const ThemeSettingsSheet(),
      isDraggable: true,
      isDismissible: true,
    );
  }

  void _showLanguageSettings() {
    StandardBottomSheet.show(
      context: context,
      title: 'settings.language'.tr(),
      content: const LanguageSettingsSheet(),
      isDraggable: true,
      isDismissible: true,
    );
  }

  void _showDailyReminderSettings() {
    StandardBottomSheet.show(
      context: context,
      title: 'settings.daily_reminder'.tr(),
      content: const DailyReminderSheet(),
      isDraggable: true,
      isDismissible: true,
    );
  }

  void _showDraftNotificationSettings() {
    StandardBottomSheet.show(
      context: context,
      title: 'settings.draft_notifications'.tr(),
      content: const DraftNotificationSheet(),
      isDraggable: true,
      isDismissible: true,
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
          // 프로필 섹션
          const UserProfileSection(),
          const SizedBox(height: 16),

          const ShadSeparator.horizontal(
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),

          // UX 설정 섹션
          _buildSectionHeader(context, 'settings.ux'.tr()),

          Consumer(
            builder: (context, ref, child) {
              final themeModeAsync = ref.watch(themeModeProvider);
              return themeModeAsync.when(
                data: (themeMode) => ListTile(
                  leading: Icon(AppIcons.palette),
                  title: Text('settings.theme'.tr()),
                  subtitle: Text(_getThemeModeLabel(themeMode)),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                  onTap: _showThemeSettings,
                ),
                loading: () => ListTile(
                  leading: Icon(AppIcons.palette),
                  title: Text('settings.theme'.tr()),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                  onTap: _showThemeSettings,
                ),
                error: (_, __) => ListTile(
                  leading: Icon(AppIcons.palette),
                  title: Text('settings.theme'.tr()),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                  onTap: _showThemeSettings,
                ),
              );
            },
          ),

          Consumer(
            builder: (context, ref, child) {
              final localeAsync = ref.watch(localeProvider);
              return localeAsync.when(
                data: (locale) {
                  final currentLocale = locale ?? context.locale;
                  return ListTile(
                    leading: Icon(AppIcons.language),
                    title: Text('settings.language'.tr()),
                    subtitle: Text(_getLanguageLabel(currentLocale)),
                    trailing: Icon(AppIcons.chevronRight, size: 20),
                    onTap: _showLanguageSettings,
                  );
                },
                loading: () => ListTile(
                  leading: Icon(AppIcons.language),
                  title: Text('settings.language'.tr()),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                  onTap: _showLanguageSettings,
                ),
                error: (_, __) => ListTile(
                  leading: Icon(AppIcons.language),
                  title: Text('settings.language'.tr()),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                  onTap: _showLanguageSettings,
                ),
              );
            },
          ),

          ShadSeparator.horizontal(
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

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

          ShadSeparator.horizontal(
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // 앱 정보 섹션
          _buildSectionHeader(context, 'settings.app_info'.tr()),

          ListTile(
            leading: Icon(AppIcons.info),
            title: Text('settings.app_version'.tr()),
            subtitle: Text(_appVersion),
          ),

          ShadSeparator.horizontal(
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ShadSeparator.horizontal(),
            ),
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

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'settings.system_mode'.tr();
      case ThemeMode.light:
        return 'settings.light_mode'.tr();
      case ThemeMode.dark:
        return 'settings.dark_mode'.tr();
    }
  }

  String _getLanguageLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return 'settings.language_korean'.tr();
      case 'en':
        return 'settings.language_english'.tr();
      default:
        return locale.languageCode;
    }
  }
}
