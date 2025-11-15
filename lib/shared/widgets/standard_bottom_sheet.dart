import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../../core/utils/app_icons.dart';
import 'responsive_modal_sheet.dart';

/// 📋 표준 Bottom Sheet 패턴 구현
///
/// 미니라인 앱 전체에서 일관된 Bottom Sheet UI 제공을 위한 통합 컴포넌트
///
/// 🎯 주요 기능:
/// - Wolt Modal Sheet 기반으로 반응형 지원 (모바일: Bottom Sheet, 태블릿: Dialog)
/// - 표준화된 헤더, 컨텐츠, 푸터 레이아웃
/// - 일관된 디자인 시스템 적용
/// - 다양한 사용 사례에 대한 프리셋 제공
class StandardBottomSheet {
  /// 🚀 표준 Bottom Sheet 표시 (Wolt Modal Sheet 기반)
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget content,

    // 헤더 설정
    String? title,
    BottomSheetTitleStyle titleStyle = BottomSheetTitleStyle.large,
    bool showCloseButton = false,

    // 푸터 설정
    List<BottomSheetAction>? actions,
    BottomSheetActionLayout actionLayout = BottomSheetActionLayout.horizontal,

    // 동작 설정 (Wolt Modal Sheet에서 자동으로 드래그 핸들 제공)
    bool isDismissible = true,
    bool isDraggable = true,
    EdgeInsetsGeometry? contentPadding,

    // 콜백
    VoidCallback? onClosed,
  }) {
    final shadTheme = ShadTheme.of(context);
    final materialTheme = Theme.of(context);
    final cardColor = shadTheme.colorScheme.card;

    return ResponsiveModalSheet.show<T>(
      context: context,
      barrierDismissible: isDismissible,
      enableDrag: isDraggable,
      onModalDismissedWithBarrierTap: onClosed,
      onModalDismissedWithDrag: onClosed,
      pages: [
        ResponsiveModalSheet.createPage(
          topBarTitle: title,
          topBarTitleStyle: materialTheme.textTheme.titleLarge,
          hasTopBarLayer: title != null,
          backgroundColor: cardColor,
          child: _StandardBottomSheetContent(
            content: content,
            actions: actions,
            actionLayout: actionLayout,
            titleStyle: titleStyle,
            showCloseButton: showCloseButton,
            contentPadding: contentPadding ?? const EdgeInsets.all(common.Spacing.md),
          ),
        ),
      ],
    );
  }

  /// 📝 텍스트 리스트 선택 Bottom Sheet (설정용)
  static Future<T?> showSelection<T>({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption<T>> options,
    T? selectedValue,
    bool isDraggable = true,
  }) {
    return show<T>(
      context: context,
      title: title,
      titleStyle: BottomSheetTitleStyle.medium,
      isDraggable: isDraggable,
      isDismissible: true,
      contentPadding: const EdgeInsets.all(0),
      content: _SelectionListContent<T>(
        options: options,
        selectedValue: selectedValue,
      ),
    );
  }

  /// 📷 액션 선택 Bottom Sheet (메뉴용)
  static Future<T?> showActions<T>({
    required BuildContext context,
    String? title,
    required List<BottomSheetAction<T>> actions,
    bool isDraggable = true,
  }) {
    return show<T>(
      context: context,
      title: title,
      titleStyle: BottomSheetTitleStyle.medium,
      isDraggable: isDraggable,
      isDismissible: true,
      contentPadding: const EdgeInsets.symmetric(vertical: common.Spacing.sm),
      content: _ActionListContent<T>(actions: actions),
    );
  }

  /// ⚠️ 확인 다이얼로그 스타일 Bottom Sheet
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      titleStyle: BottomSheetTitleStyle.medium,
      isDraggable: false,
      isDismissible: true,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: common.Spacing.sm),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      actions: [
        BottomSheetAction<bool>(
          text: cancelText ?? 'common.cancel'.tr(),
          value: false,
          style: BottomSheetActionStyle.outlined,
        ),
        BottomSheetAction<bool>(
          text: confirmText ?? 'common.confirm'.tr(),
          value: true,
          style: isDestructive
            ? BottomSheetActionStyle.destructive
            : BottomSheetActionStyle.elevated,
        ),
      ],
      actionLayout: BottomSheetActionLayout.horizontal,
    );
  }
}

/// 📋 Bottom Sheet 컨텐츠 구현
class _StandardBottomSheetContent extends StatelessWidget {
  final Widget content;
  final List<BottomSheetAction>? actions;
  final BottomSheetActionLayout actionLayout;
  final BottomSheetTitleStyle titleStyle;
  final bool showCloseButton;
  final EdgeInsetsGeometry contentPadding;

  const _StandardBottomSheetContent({
    required this.content,
    this.actions,
    required this.actionLayout,
    required this.titleStyle,
    required this.showCloseButton,
    required this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 컨텐츠 영역
        Padding(
          padding: contentPadding,
          child: content,
        ),

        // 액션 버튼 영역
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: common.Spacing.md),
          _buildActionButtons(context),
          const SizedBox(height: common.Spacing.md),
        ],
      ],
    );
  }


  Widget _buildActionButtons(BuildContext context) {
    if (actions == null || actions!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
      child: actionLayout == BottomSheetActionLayout.horizontal
        ? _buildHorizontalActions(context)
        : _buildVerticalActions(context),
    );
  }

  Widget _buildHorizontalActions(BuildContext context) {
    return Row(
      children: actions!.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return [
          if (index > 0) const SizedBox(width: common.Spacing.sm),
          Expanded(child: _buildActionButton(context, action)),
        ];
      }).expand((widgets) => widgets).toList(),
    );
  }

  Widget _buildVerticalActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions!.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return [
          if (index > 0) const SizedBox(height: common.Spacing.sm),
          _buildActionButton(context, action),
        ];
      }).expand((widgets) => widgets).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, BottomSheetAction action) {
    final shadTheme = ShadTheme.of(context);
    final materialTheme = Theme.of(context);

    switch (action.style) {
      case BottomSheetActionStyle.elevated:
        return ShadButton(
          onPressed: () => Navigator.of(context).pop(action.value),
          child: Text(action.text),
        );

      case BottomSheetActionStyle.outlined:
        return ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(action.value),
          foregroundColor: shadTheme.colorScheme.foreground,
          child: Text(action.text),
        );

      case BottomSheetActionStyle.text:
        return ShadButton.ghost(
          onPressed: () => Navigator.of(context).pop(action.value),
          child: Text(action.text),
        );

      case BottomSheetActionStyle.destructive:
        return ShadButton(
          onPressed: () => Navigator.of(context).pop(action.value),
          backgroundColor: materialTheme.colorScheme.error,
          foregroundColor: materialTheme.colorScheme.onError,
          child: Text(action.text),
        );
    }
  }
}

/// 📝 선택 리스트 컨텐츠
class _SelectionListContent<T> extends StatelessWidget {
  final List<BottomSheetOption<T>> options;
  final T? selectedValue;

  const _SelectionListContent({
    required this.options,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    final materialTheme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isSelected = option.value == selectedValue;

        return ListTile(
          leading: option.icon != null
            ? Icon(option.icon)
            : null,
          title: Text(
            option.text,
            style: materialTheme.textTheme.bodyLarge?.copyWith(
              color: isSelected ? shadTheme.colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
          subtitle: option.subtitle != null
            ? Text(option.subtitle!, style: materialTheme.textTheme.bodyMedium)
            : null,
          trailing: isSelected
            ? const Icon(AppIcons.check)
            : null,
          onTap: () => Navigator.of(context).pop(option.value),
        );
      }).toList(),
    );
  }
}

/// 📷 액션 리스트 컨텐츠
class _ActionListContent<T> extends StatelessWidget {
  final List<BottomSheetAction<T>> actions;

  const _ActionListContent({required this.actions});

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((action) {
        return ListTile(
          leading: action.icon != null
            ? Icon(
                action.icon,
                color: action.style == BottomSheetActionStyle.destructive
                  ? materialTheme.colorScheme.error
                  : null,
              )
            : null,
          title: Text(
            action.text,
            style: materialTheme.textTheme.bodyLarge?.copyWith(
              color: action.style == BottomSheetActionStyle.destructive
                ? materialTheme.colorScheme.error
                : null,
            ),
          ),
          onTap: () => Navigator.of(context).pop(action.value),
        );
      }).toList(),
    );
  }
}

/// 📋 Bottom Sheet 설정 타입들

enum BottomSheetTitleStyle {
  large,    // titleLarge (주요 기능)
  medium,   // titleMedium (보조 기능)
}

enum BottomSheetActionStyle {
  elevated,     // 주요 액션 (ElevatedButton)
  outlined,     // 보조 액션 (OutlinedButton)
  text,         // 텍스트 액션 (TextButton)
  destructive,  // 위험한 액션 (빨간 ElevatedButton)
}

enum BottomSheetActionLayout {
  horizontal,   // 가로 배치 (나란히)
  vertical,     // 세로 배치 (위아래)
}

/// 📋 Bottom Sheet 액션 정의
class BottomSheetAction<T> {
  final String text;
  final T value;
  final BottomSheetActionStyle style;
  final IconData? icon;

  const BottomSheetAction({
    required this.text,
    required this.value,
    this.style = BottomSheetActionStyle.elevated,
    this.icon,
  });
}

/// 📋 Bottom Sheet 선택 옵션 정의
class BottomSheetOption<T> {
  final String text;
  final String? subtitle;
  final T value;
  final IconData? icon;

  const BottomSheetOption({
    required this.text,
    required this.value,
    this.subtitle,
    this.icon,
  });
}
