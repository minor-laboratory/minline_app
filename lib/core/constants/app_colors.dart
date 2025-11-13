import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 색상 상수
class AppColors {
  /// 브랜드 시드 컬러 (기본: Zinc)
  /// Material 3 테마 시스템의 기본 컬러로 사용
  static const Color seedColor = Color(0xFF71717A); // Zinc

  /// 12가지 Shadcn UI 컬러 스킴
  static const Map<String, Color> colorThemes = {
    'blue': Color(0xFF3B82F6),
    'slate': Color(0xFF64748B),
    'gray': Color(0xFF6B7280),
    'zinc': Color(0xFF71717A),
    'neutral': Color(0xFF737373),
    'stone': Color(0xFF78716C),
    'red': Color(0xFFEF4444),
    'orange': Color(0xFFF97316),
    'yellow': Color(0xFFEAB308),
    'green': Color(0xFF22C55E),
    'violet': Color(0xFF8B5CF6),
    'rose': Color(0xFFF43F5E),
  };

  /// 컬러 테마 ID로 Color 가져오기
  static Color getColorByTheme(String colorThemeId) {
    return colorThemes[colorThemeId] ?? colorThemes['zinc']!;
  }
}
