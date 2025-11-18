import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../shared/widgets/responsive_modal_sheet.dart';
import '../../../../shared/widgets/standard_bottom_sheet.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/widgets/user_profile_section.dart';
import '../../providers/settings_provider.dart';
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
    final confirmed = await StandardBottomSheet.showConfirmation(
      context: context,
      title: 'settings.logout'.tr(),
      message: 'settings.logout_confirm'.tr(),
      confirmText: 'settings.logout'.tr(),
      isDestructive: true,
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
    // 테마 설정 sheet는 특수 케이스: 동적 배경색 지원을 위해 직접 WoltModalSheet 사용
    // topBar와 child 모두 Consumer로 감싸서 테마 변경 시 실시간 배경색 반영
    final materialTheme = Theme.of(context);

    ResponsiveModalSheet.show(
      context: context,
      pages: [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          surfaceTintColor: Colors.transparent,
          // topBar: Consumer로 동적 배경색 적용
          topBar: Consumer(
            builder: (context, ref, child) {
              final themeModeAsync = ref.watch(themeModeProvider);
              final colorThemeAsync = ref.watch(colorThemeProvider);
              final backgroundColorAsync = ref.watch(backgroundColorProvider);

              return themeModeAsync.when(
                data: (themeMode) => colorThemeAsync.when(
                  data: (colorTheme) => backgroundColorAsync.when(
                    data: (backgroundOption) {
                      final shadLightTheme = common.MinorLabShadTheme.lightTheme(
                        paletteId: colorTheme,
                        backgroundOption: backgroundOption,
                      );
                      final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
                        paletteId: colorTheme,
                        backgroundOption: backgroundOption,
                      );

                      final brightness = MediaQuery.of(context).platformBrightness;
                      final currentShadTheme = themeMode == ThemeMode.dark
                          ? shadDarkTheme
                          : themeMode == ThemeMode.light
                              ? shadLightTheme
                              : (brightness == Brightness.dark ? shadDarkTheme : shadLightTheme);

                      final cardColor = currentShadTheme.colorScheme.card;

                      return Container(
                        width: double.infinity,
                        color: cardColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: common.Spacing.md,
                          vertical: common.Spacing.md,
                        ),
                        child: Text(
                          'settings.theme'.tr(),
                          style: materialTheme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    loading: () => Container(
                      padding: const EdgeInsets.all(common.Spacing.md),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => Container(
                      padding: const EdgeInsets.all(common.Spacing.md),
                      child: Center(child: Text('common.error'.tr())),
                    ),
                  ),
                  loading: () => Container(
                    padding: const EdgeInsets.all(common.Spacing.md),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(common.Spacing.md),
                    child: Center(child: Text('common.error'.tr())),
                  ),
                ),
                loading: () => Container(
                  padding: const EdgeInsets.all(common.Spacing.md),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(common.Spacing.md),
                  child: Center(child: Text('common.error'.tr())),
                ),
              );
            },
          ),
          // child: Consumer로 동적 배경색 적용
          child: Consumer(
            builder: (context, ref, child) {
              final themeModeAsync = ref.watch(themeModeProvider);
              final colorThemeAsync = ref.watch(colorThemeProvider);
              final backgroundColorAsync = ref.watch(backgroundColorProvider);

              return themeModeAsync.when(
                data: (themeMode) => colorThemeAsync.when(
                  data: (colorTheme) => backgroundColorAsync.when(
                    data: (backgroundOption) {
                      final shadLightTheme = common.MinorLabShadTheme.lightTheme(
                        paletteId: colorTheme,
                        backgroundOption: backgroundOption,
                      );
                      final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
                        paletteId: colorTheme,
                        backgroundOption: backgroundOption,
                      );

                      final brightness = MediaQuery.of(context).platformBrightness;
                      final currentShadTheme = themeMode == ThemeMode.dark
                          ? shadDarkTheme
                          : themeMode == ThemeMode.light
                              ? shadLightTheme
                              : (brightness == Brightness.dark ? shadDarkTheme : shadLightTheme);

                      final cardColor = currentShadTheme.colorScheme.card;

                      return Container(
                        color: cardColor,
                        child: const ThemeSettingsSheet(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(child: Text('common.error'.tr())),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(child: Text('common.error'.tr())),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text('common.error'.tr())),
              );
            },
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: common.Spacing.md),

          const ShadSeparator.horizontal(
            margin: EdgeInsets.symmetric(horizontal: common.Spacing.md),
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

          Consumer(
            builder: (context, ref, child) {
              final autoFocusAsync = ref.watch(autoFocusInputProvider);

              return autoFocusAsync.when(
                data: (enabled) => ListTile(
                  leading: Icon(AppIcons.edit),
                  title: Text('settings.auto_focus_input'.tr()),
                  subtitle: Text('settings.auto_focus_input_description'.tr()),
                  trailing: ShadSwitch(
                    value: enabled,
                    onChanged: (value) {
                      ref.read(autoFocusInputProvider.notifier).setAutoFocusInput(value);
                    },
                  ),
                  onTap: () {
                    ref.read(autoFocusInputProvider.notifier).setAutoFocusInput(!enabled);
                  },
                ),
                loading: () => ListTile(
                  leading: Icon(AppIcons.edit),
                  title: Text('settings.auto_focus_input'.tr()),
                  subtitle: Text('settings.auto_focus_input_description'.tr()),
                  trailing: ShadSwitch(
                    value: false,
                    onChanged: null,
                  ),
                ),
                error: (_, __) => ListTile(
                  leading: Icon(AppIcons.edit),
                  title: Text('settings.auto_focus_input'.tr()),
                  subtitle: Text('settings.auto_focus_input_description'.tr()),
                  trailing: ShadSwitch(
                    value: false,
                    onChanged: null,
                  ),
                ),
              );
            },
          ),

          Consumer(
            builder: (context, ref, child) {
              final inputModeAsync = ref.watch(fragmentInputModeProvider);

              return inputModeAsync.when(
                data: (mode) => ListTile(
                  leading: Icon(AppIcons.edit),
                  title: Text('settings.fragment_input_mode'.tr()),
                  subtitle: Text(_getInputModeLabel(mode)),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                  onTap: () => _showInputModeSettings(mode),
                ),
                loading: () => ListTile(
                  leading: Icon(AppIcons.edit),
                  title: Text('settings.fragment_input_mode'.tr()),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                ),
                error: (_, __) => ListTile(
                  leading: Icon(AppIcons.edit),
                  title: Text('settings.fragment_input_mode'.tr()),
                  trailing: Icon(AppIcons.chevronRight, size: 20),
                ),
              );
            },
          ),

          ShadSeparator.horizontal(
            margin: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
          ),

          // 알림 설정 섹션
          _buildSectionHeader(context, 'settings.notifications'.tr()),

          ListTile(
            leading: Icon(AppIcons.notification),
            title: Text('settings.notifications'.tr()),
            subtitle: Text('settings.notifications_description'.tr()),
            trailing: Icon(AppIcons.chevronRight, size: 20),
            onTap: () => context.push('/settings/notifications'),
          ),

          ShadSeparator.horizontal(
            margin: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
          ),

          // 앱 정보 섹션
          _buildSectionHeader(context, 'settings.app_info'.tr()),

          ListTile(
            leading: Icon(AppIcons.info),
            title: Text('settings.app_version'.tr()),
            subtitle: Text(_appVersion),
          ),

          ShadSeparator.horizontal(
            margin: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
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
            Builder(
              builder: (context) {
                final theme = ShadTheme.of(context);
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: common.Spacing.md),
                      child: ShadSeparator.horizontal(),
                    ),
                    ListTile(
                      leading: Icon(AppIcons.logout, color: theme.colorScheme.destructive),
                      title: Text(
                        'settings.logout'.tr(),
                        style: theme.textTheme.large.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                      onTap: _handleLogout,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        common.Spacing.md,
        common.Spacing.md,
        common.Spacing.md,
        common.Spacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.small.copyWith(
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

  String _getInputModeLabel(String mode) {
    switch (mode) {
      case 'inline':
        return 'settings.input_mode_inline'.tr();
      case 'fab':
        return 'settings.input_mode_fab'.tr();
      default:
        return 'settings.input_mode_inline'.tr();
    }
  }

  void _showInputModeSettings(String currentMode) {
    final theme = ShadTheme.of(context);

    StandardBottomSheet.show(
      context: context,
      title: 'settings.fragment_input_mode'.tr(),
      content: Consumer(
        builder: (context, ref, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(AppIcons.edit),
                title: Text('settings.input_mode_inline'.tr()),
                subtitle: Text('settings.input_mode_inline_description'.tr()),
                trailing: currentMode == 'inline'
                    ? Icon(AppIcons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(fragmentInputModeProvider.notifier).setInputMode('inline');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: common.Spacing.sm),
              ListTile(
                leading: Icon(AppIcons.add),
                title: Text('settings.input_mode_fab'.tr()),
                subtitle: Text('settings.input_mode_fab_description'.tr()),
                trailing: currentMode == 'fab'
                    ? Icon(AppIcons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(fragmentInputModeProvider.notifier).setInputMode('fab');
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
      isDraggable: true,
      isDismissible: true,
    );
  }
}
