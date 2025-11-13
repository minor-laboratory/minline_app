import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../../../../core/utils/app_icons.dart';
import '../../providers/settings_provider.dart';

/// 테마 설정 시트
class ThemeSettingsSheet extends ConsumerWidget {
  const ThemeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final colorThemeAsync = ref.watch(colorThemeProvider);
    final backgroundColorAsync = ref.watch(backgroundColorProvider);

    return themeModeAsync.when(
      data: (themeMode) => colorThemeAsync.when(
        data: (colorTheme) => backgroundColorAsync.when(
          data: (backgroundOption) => SingleChildScrollView(
            padding: const EdgeInsets.all(common.Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 테마 모드 섹션
                Text(
                  'theme.mode'.tr(),
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: common.Spacing.md),

                // 테마 모드 버튼들 (3개 나란히)
                Row(
                  children: [
                    _ThemeModeCard(
                      icon: AppIcons.monitor,
                      label: 'settings.system_mode'.tr(),
                      isSelected: themeMode == ThemeMode.system,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                      },
                    ),
                    const SizedBox(width: common.Spacing.sm),
                    _ThemeModeCard(
                      icon: AppIcons.sun,
                      label: 'settings.light_mode'.tr(),
                      isSelected: themeMode == ThemeMode.light,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                      },
                    ),
                    const SizedBox(width: common.Spacing.sm),
                    _ThemeModeCard(
                      icon: AppIcons.moon,
                      label: 'settings.dark_mode'.tr(),
                      isSelected: themeMode == ThemeMode.dark,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: common.Spacing.xl),

                // 배경색 섹션
                Text(
                  'theme.background_color'.tr(),
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: common.Spacing.sm),
                Text(
                  'theme.background_color_desc'.tr(),
                  style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 12),
                ),
                const SizedBox(height: common.Spacing.md),

                // 배경색 옵션 버튼들 (3개 나란히)
                Row(
                  children: [
                    _BackgroundColorCard(
                      label: 'theme.bg_default'.tr(),
                      subtitle: 'theme.bg_default_desc'.tr(),
                      isSelected: backgroundOption == common.BackgroundColorOption.defaultColor,
                      onTap: () {
                        ref.read(backgroundColorProvider.notifier).setBackgroundOption(
                              common.BackgroundColorOption.defaultColor,
                            );
                      },
                    ),
                    const SizedBox(width: common.Spacing.sm),
                    _BackgroundColorCard(
                      label: 'theme.bg_warm'.tr(),
                      subtitle: 'theme.bg_warm_desc'.tr(),
                      isSelected: backgroundOption == common.BackgroundColorOption.warm,
                      onTap: () {
                        ref.read(backgroundColorProvider.notifier).setBackgroundOption(
                              common.BackgroundColorOption.warm,
                            );
                      },
                    ),
                    const SizedBox(width: common.Spacing.sm),
                    _BackgroundColorCard(
                      label: 'theme.bg_neutral'.tr(),
                      subtitle: 'theme.bg_neutral_desc'.tr(),
                      isSelected: backgroundOption == common.BackgroundColorOption.neutral,
                      onTap: () {
                        ref.read(backgroundColorProvider.notifier).setBackgroundOption(
                              common.BackgroundColorOption.neutral,
                            );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: common.Spacing.xl),

                // 컬러 스킴 섹션
                Text(
                  'theme.color_scheme'.tr(),
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: common.Spacing.md),

                // 컬러 스킴 그리드 (3 columns x 4 rows = 12 Shadcn UI colors)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: common.Spacing.sm,
                  crossAxisSpacing: common.Spacing.sm,
                  childAspectRatio: 1.0,
                  children: _buildColorCards(context, ref, colorTheme),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('common.error'.tr()),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('common.error'.tr()),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('common.error'.tr()),
      ),
    );
  }

  List<Widget> _buildColorCards(
    BuildContext context,
    WidgetRef ref,
    String currentPaletteId,
  ) {
    // Shadcn UI 12가지 표준 컬러 스킴
    final colors = [
      {'id': 'blue', 'name': 'Blue', 'color': const Color(0xFF3B82F6)},
      {'id': 'slate', 'name': 'Slate', 'color': const Color(0xFF64748B)},
      {'id': 'gray', 'name': 'Gray', 'color': const Color(0xFF6B7280)},
      {'id': 'zinc', 'name': 'Zinc', 'color': const Color(0xFF71717A)},
      {'id': 'neutral', 'name': 'Neutral', 'color': const Color(0xFF737373)},
      {'id': 'stone', 'name': 'Stone', 'color': const Color(0xFF78716C)},
      {'id': 'red', 'name': 'Red', 'color': const Color(0xFFEF4444)},
      {'id': 'orange', 'name': 'Orange', 'color': const Color(0xFFF97316)},
      {'id': 'yellow', 'name': 'Yellow', 'color': const Color(0xFFEAB308)},
      {'id': 'green', 'name': 'Green', 'color': const Color(0xFF22C55E)},
      {'id': 'violet', 'name': 'Violet', 'color': const Color(0xFF8B5CF6)},
      {'id': 'rose', 'name': 'Rose', 'color': const Color(0xFFF43F5E)},
    ];

    return colors.map((scheme) {
      final isSelected = scheme['id'] == currentPaletteId;
      return _ColorCard(
        color: scheme['color'] as Color,
        label: scheme['name'] as String,
        isSelected: isSelected,
        onTap: () {
          ref.read(colorThemeProvider.notifier).setColorTheme(scheme['id'] as String);
        },
      );
    }).toList();
  }
}

/// 배경색 옵션 카드
class _BackgroundColorCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackgroundColorCard({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(common.Spacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? ShadTheme.of(context).colorScheme.accent
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? ShadTheme.of(context).colorScheme.ring
                  : ShadTheme.of(context).colorScheme.border,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ShadTheme.of(context).textTheme.small.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: common.Spacing.xs),
              Text(
                subtitle,
                style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 테마 모드 카드
class _ThemeModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: common.Spacing.md,
            horizontal: common.Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? ShadTheme.of(context).colorScheme.accent
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? ShadTheme.of(context).colorScheme.ring
                  : ShadTheme.of(context).colorScheme.border,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: common.Spacing.xs),
              Text(
                label,
                style: ShadTheme.of(context).textTheme.small,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 컬러 카드
class _ColorCard extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCard({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? ShadTheme.of(context).colorScheme.accent.withValues(alpha: 0.3)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? ShadTheme.of(context).colorScheme.ring
                : ShadTheme.of(context).colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      AppIcons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: common.Spacing.sm),
            Text(
              label,
              style: ShadTheme.of(context).textTheme.small.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
