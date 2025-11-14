import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../../../../core/utils/app_icons.dart';
import '../../providers/settings_provider.dart';

/// 언어 설정 시트
class LanguageSettingsSheet extends ConsumerWidget {
  const LanguageSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);

    return localeAsync.when(
      data: (currentLocale) {
        final useSystemLocale = currentLocale == null;
        final selectedCode = currentLocale?.languageCode ?? context.locale.languageCode;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 시스템 언어 사용 스위치
            ShadCard(
              child: SwitchListTile(
                title: Text('settings.use_system_language'.tr()),
                subtitle: Text('settings.use_system_language_description'.tr()),
                value: useSystemLocale,
                onChanged: (value) async {
                  if (value) {
                    // 시스템 언어 사용
                    await ref.read(localeProvider.notifier).setLocale(null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('settings.language_changed'.tr()),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } else {
                    // 현재 시스템 언어를 명시적으로 설정
                    final systemLocale = context.locale;
                    if (!context.mounted) return;
                    await context.setLocale(systemLocale);
                    await ref.read(localeProvider.notifier).setLocale(systemLocale);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('settings.language_changed'.tr()),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: common.Spacing.md),

            // 언어 목록 헤더
            Text(
              'settings.available_languages'.tr(),
              style: ShadTheme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: common.Spacing.sm),

            // 한국어
            Padding(
              padding: const EdgeInsets.symmetric(vertical: common.Spacing.xs),
              child: ShadCard(
                child: ListTile(
                  leading: const Text(
                    '🇰🇷',
                    style: TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    'settings.language_korean'.tr(),
                    style: ShadTheme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: (!useSystemLocale && selectedCode == 'ko') ||
                                  (useSystemLocale && selectedCode == 'ko')
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                  subtitle: Text('settings.language_korean_desc'.tr()),
                  trailing: ((!useSystemLocale && selectedCode == 'ko') ||
                          (useSystemLocale && selectedCode == 'ko'))
                      ? Icon(
                          AppIcons.checkCircle,
                          color: ShadTheme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: (!useSystemLocale && selectedCode == 'ko') ||
                      (useSystemLocale && selectedCode == 'ko'),
                  onTap: useSystemLocale
                      ? null
                      : () async {
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          await context.setLocale(const Locale('ko'));
                          await ref.read(localeProvider.notifier).setLocale(const Locale('ko'));
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('settings.language_changed'.tr()),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                ),
              ),
            ),

            // 영어
            Padding(
              padding: const EdgeInsets.symmetric(vertical: common.Spacing.xs),
              child: ShadCard(
                child: ListTile(
                  leading: const Text(
                    '🇺🇸',
                    style: TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    'settings.language_english'.tr(),
                    style: ShadTheme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: (!useSystemLocale && selectedCode == 'en') ||
                                  (useSystemLocale && selectedCode == 'en')
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                  subtitle: Text('settings.language_english_desc'.tr()),
                  trailing: ((!useSystemLocale && selectedCode == 'en') ||
                          (useSystemLocale && selectedCode == 'en'))
                      ? Icon(
                          AppIcons.checkCircle,
                          color: ShadTheme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: (!useSystemLocale && selectedCode == 'en') ||
                      (useSystemLocale && selectedCode == 'en'),
                  onTap: useSystemLocale
                      ? null
                      : () async {
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          await context.setLocale(const Locale('en'));
                          await ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('settings.language_changed'.tr()),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('common.error'.tr()),
      ),
    );
  }
}
