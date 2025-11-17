import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

/// Wolt Modal Sheet를 활용한 반응형 모달 시트 헬퍼 유틸리티
///
/// 모바일에서는 Bottom Sheet로, 타블렛에서는 Dialog로 자동 표시
///
/// **일반 사용**: StandardBottomSheet.show() 사용 권장
/// **특수 케이스**: 동적 배경색이 필요한 경우 (테마 설정 모달)만 직접 사용
/// - 테마 설정 모달은 topBar와 child를 Consumer로 감싸서 실시간 배경색 반영
/// - 참조: `docs/COMPONENT_SPECS.md` - 특수 케이스: 테마 설정 모달
class ResponsiveModalSheet {
  /// 반응형 모달 시트 표시
  ///
  /// [context]: BuildContext
  /// [pages]: 모달 페이지 리스트
  /// [onModalDismissedWithBarrierTap]: 배경 탭으로 닫힐 때 콜백
  /// [onModalDismissedWithDrag]: 드래그로 닫힐 때 콜백
  static Future<T?> show<T>({
    required BuildContext context,
    required List<WoltModalSheetPage> pages,
    VoidCallback? onModalDismissedWithBarrierTap,
    VoidCallback? onModalDismissedWithDrag,
    bool? barrierDismissible,
    bool? enableDrag,
  }) {
    return WoltModalSheet.show<T>(
      context: context,
      pageListBuilder: (modalSheetContext) => pages,
      onModalDismissedWithBarrierTap: onModalDismissedWithBarrierTap,
      onModalDismissedWithDrag: onModalDismissedWithDrag,
      modalTypeBuilder: (context) {
        // 화면 너비에 따라 모달 타입 결정
        final screenWidth = MediaQuery.of(context).size.width;

        // 600dp 이상은 타블렛으로 간주하여 Dialog 표시
        if (screenWidth >= 600) {
          return WoltModalType.dialog();
        } else {
          return WoltModalType.bottomSheet();
        }
      },
      barrierDismissible: barrierDismissible ?? true,
      enableDrag: enableDrag ?? true,
    );
  }

  /// 단일 페이지 모달 시트 생성 헬퍼
  ///
  /// [backgroundColor]는 타이틀 영역과 컨텐츠 영역 모두에 적용
  static WoltModalSheetPage createPage({
    required Widget child,
    String? topBarTitle,
    TextStyle? topBarTitleStyle,
    Widget? topBar,
    bool? isTopBarLayerAlwaysVisible,
    bool? hasTopBarLayer,
    required Color backgroundColor,
    bool? resizeToAvoidBottomInset,
  }) {
    return WoltModalSheetPage(
      child: Container(color: backgroundColor, child: child),
      topBarTitle: topBarTitle != null
          ? Text(topBarTitle, style: topBarTitleStyle)
          : null,
      topBar: topBar,
      isTopBarLayerAlwaysVisible: isTopBarLayerAlwaysVisible ?? true,
      hasTopBarLayer: hasTopBarLayer ?? (topBarTitle != null || topBar != null),
      // surfaceTintColor를 transparent로 설정하여 테마 색상 영향 제거
      surfaceTintColor: Colors.transparent,
      // 타이틀 영역 배경색도 명시적으로 설정
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
    );
  }

  /// 간단한 컨텐츠 페이지 생성
  static WoltModalSheetPage simpleContentPage({
    required String title,
    required Widget content,
    required Color backgroundColor,
  }) {
    return createPage(
      topBarTitle: title,
      backgroundColor: backgroundColor,
      child: Padding(padding: const EdgeInsets.all(common.Spacing.md), child: content),
    );
  }
}
