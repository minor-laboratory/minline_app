import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/intro_provider.dart';
import '../widgets/intro_slide.dart';
import '../widgets/page_indicator.dart';

/// 인트로(온보딩) 페이지
class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _skipIntro() async {
    await ref.read(introCompletedProvider.notifier).complete();
    if (mounted) _navigateAfterIntro();
  }

  Future<void> _completeIntro() async {
    await ref.read(introCompletedProvider.notifier).complete();
    if (mounted) _navigateAfterIntro();
  }

  void _navigateAfterIntro() {
    // 로그인 상태에 따라 분기
    if (Supabase.instance.client.auth.currentUser != null) {
      context.go('/'); // 이미 로그인됨 → 메인
    } else {
      context.go('/auth'); // 미로그인 → 로그인 화면
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 건너뛰기 버튼
            _buildHeader(theme),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  // 화면 1: 문제 상황
                  IntroSlide(
                    title: 'intro.page1.title'.tr(),
                    description: 'intro.page1.description'.tr(),
                    icon: AppIcons.fileText,
                    iconColor: theme.colorScheme.mutedForeground,
                  ),
                  // 화면 2: 해결책
                  IntroSlide(
                    title: 'intro.page2.title'.tr(),
                    description: 'intro.page2.description'.tr(),
                    icon: AppIcons.edit,
                    iconColor: theme.colorScheme.primary,
                  ),
                  // 화면 3: 결과
                  IntroSlide(
                    title: 'intro.page3.title'.tr(),
                    description: 'intro.page3.description'.tr(),
                    icon: AppIcons.sparkles,
                    iconColor: const Color(0xFFFFB800),
                  ),
                ],
              ),
            ),

            // 하단: 인디케이터 + 버튼
            _buildBottom(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    // 마지막 페이지에서는 건너뛰기 버튼 숨김
    if (_currentPage >= _totalPages - 1) {
      return const SizedBox(height: 56);
    }

    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ShadButton.ghost(
            onPressed: _skipIntro,
            child: Text(
              'intro.skip'.tr(),
              style: TextStyle(color: theme.colorScheme.mutedForeground),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottom(ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          // 페이지 인디케이터
          PageIndicator(
            currentPage: _currentPage,
            totalPages: _totalPages,
          ),

          const SizedBox(height: 32),

          // 버튼
          SizedBox(
            width: double.infinity,
            child: _currentPage < _totalPages - 1
                ? ShadButton.outline(
                    onPressed: _nextPage,
                    child: Text('intro.next'.tr()),
                  )
                : ShadButton(
                    onPressed: _completeIntro,
                    child: Text('intro.start'.tr()),
                  ),
          ),
        ],
      ),
    );
  }
}
