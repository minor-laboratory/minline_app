import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/settings_provider.dart';

/// 언어 설정 Bottom Sheet
class LanguageSettingsSheet extends ConsumerWidget {
  const LanguageSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: localeAsync.when(
            data: (currentLocale) {
              final systemLocale = currentLocale == null;
              final selectedCode = currentLocale?.languageCode ?? context.locale.languageCode;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // 핸들바
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 타이틀
                  Text(
                    'settings.language'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // 시스템 언어 (null)
                  _LanguageCard(
                    label: 'settings.system_mode'.tr(),
                    isSelected: systemLocale,
                    onTap: () async {
                      await ref.read(localeProvider.notifier).setLocale(null);
                      if (context.mounted) {
                        await context.setLocale(context.deviceLocale);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 한국어
                  _LanguageCard(
                    label: '한국어',
                    isSelected: !systemLocale && selectedCode == 'ko',
                    onTap: () async {
                      await ref.read(localeProvider.notifier).setLocale(const Locale('ko'));
                      if (context.mounted) {
                        await context.setLocale(const Locale('ko'));
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // English
                  _LanguageCard(
                    label: 'English',
                    isSelected: !systemLocale && selectedCode == 'en',
                    onTap: () async {
                      await ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                      if (context.mounted) {
                        await context.setLocale(const Locale('en'));
                      }
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('common.error'.tr()),
            ),
          ),
        );
      },
    );
  }
}

/// 언어 선택 카드
class _LanguageCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : null,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                AppIcons.checkCircle,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
