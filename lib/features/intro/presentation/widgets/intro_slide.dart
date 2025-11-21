import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 인트로 슬라이드 위젯
class IntroSlide extends StatelessWidget {
  const IntroSlide({
    super.key,
    required this.title,
    required this.description,
    this.imagePath,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // 일러스트 영역 (상단 60%)
          Expanded(
            flex: 6,
            child: Center(
              child: _buildIllustration(theme),
            ),
          ),

          // 텍스트 영역 (하단 40%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                const SizedBox(height: 24),

                // 제목
                Text(
                  title,
                  style: theme.textTheme.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // 설명
                Text(
                  description,
                  style: theme.textTheme.p.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(ShadThemeData theme) {
    // 이미지가 있으면 이미지 표시
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.contain,
      );
    }

    // 이미지가 없으면 placeholder 아이콘 표시
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        icon ?? Icons.image_outlined,
        size: 80,
        color: iconColor ?? theme.colorScheme.mutedForeground,
      ),
    );
  }
}
