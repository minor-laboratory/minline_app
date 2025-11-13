import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/settings_provider.dart';

/// 테마 설정 Bottom Sheet
class ThemeSettingsSheet extends ConsumerWidget {
  const ThemeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final colorThemeAsync = ref.watch(colorThemeProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: themeModeAsync.when(
            data: (themeMode) => colorThemeAsync.when(
              data: (colorTheme) => ListView(
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
                    'settings.theme'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // 시스템 모드
                  _ThemeModeCard(
                    icon: AppIcons.monitor,
                    label: 'settings.system_mode'.tr(),
                    isSelected: themeMode == ThemeMode.system,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 라이트 모드
                  _ThemeModeCard(
                    icon: AppIcons.sun,
                    label: 'settings.light_mode'.tr(),
                    isSelected: themeMode == ThemeMode.light,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 다크 모드
                  _ThemeModeCard(
                    icon: AppIcons.moon,
                    label: 'settings.dark_mode'.tr(),
                    isSelected: themeMode == ThemeMode.dark,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // 컬러 스킴 섹션
                  Text(
                    'theme.color_scheme'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // 컬러 스킴 그리드 (3 columns x 4 rows = 12 colors)
                  _buildColorGrid(context, ref, colorTheme),
                ],
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
        );
      },
    );
  }

  Widget _buildColorGrid(BuildContext context, WidgetRef ref, String currentColorTheme) {
    // 12가지 Shadcn UI 컬러 스킴
    final colors = [
      {'id': 'blue', 'name': 'theme.color_blue'.tr(), 'color': const Color(0xFF3B82F6)},
      {'id': 'slate', 'name': 'theme.color_slate'.tr(), 'color': const Color(0xFF64748B)},
      {'id': 'gray', 'name': 'theme.color_gray'.tr(), 'color': const Color(0xFF6B7280)},
      {'id': 'zinc', 'name': 'theme.color_zinc'.tr(), 'color': const Color(0xFF71717A)},
      {'id': 'neutral', 'name': 'theme.color_neutral'.tr(), 'color': const Color(0xFF737373)},
      {'id': 'stone', 'name': 'theme.color_stone'.tr(), 'color': const Color(0xFF78716C)},
      {'id': 'red', 'name': 'theme.color_red'.tr(), 'color': const Color(0xFFEF4444)},
      {'id': 'orange', 'name': 'theme.color_orange'.tr(), 'color': const Color(0xFFF97316)},
      {'id': 'yellow', 'name': 'theme.color_yellow'.tr(), 'color': const Color(0xFFEAB308)},
      {'id': 'green', 'name': 'theme.color_green'.tr(), 'color': const Color(0xFF22C55E)},
      {'id': 'violet', 'name': 'theme.color_violet'.tr(), 'color': const Color(0xFF8B5CF6)},
      {'id': 'rose', 'name': 'theme.color_rose'.tr(), 'color': const Color(0xFFF43F5E)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final colorData = colors[index];
        final colorId = colorData['id'] as String;
        final colorName = colorData['name'] as String;
        final color = colorData['color'] as Color;

        return _ColorCard(
          color: color,
          label: colorName,
          isSelected: currentColorTheme == colorId,
          onTap: () {
            ref.read(colorThemeProvider.notifier).setColorTheme(colorId);
          },
        );
      },
    );
  }
}

/// 테마 모드 선택 카드
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
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
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
                      Icons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
