import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/keyboard_animation_builder.dart';
import '../../../../shared/widgets/user_avatar_button.dart';
import '../../../drafts/presentation/widgets/drafts_view.dart';
import '../../../drafts/providers/drafts_provider.dart';
import '../../../posts/presentation/widgets/posts_view.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../timeline/presentation/widgets/fragment_input_bar.dart';
import '../../../timeline/presentation/widgets/timeline_view.dart';
import '../../../timeline/providers/fragments_provider.dart';

/// 메인 화면 (PageView + Tabs)
///
/// Timeline/Drafts/Posts 페이지를 PageView로 관리
class MainPage extends ConsumerStatefulWidget {
  final int? initialTab;

  /// Notification에서 탭 변경 요청 시 사용하는 callback
  static void Function(int)? onTabChangeRequested;

  const MainPage({super.key, this.initialTab});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late int _currentPageIndex;

  // Timeline 상태
  String _viewMode = 'timeline'; // 'timeline' | 'calendar'
  bool _isSearchMode = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Timeline 포커스 트리거 콜백
  VoidCallback? _timelineFocusTrigger;

  // Draft 상태
  bool _isAnalyzing = false;
  String _analyzeMessage = '';

  @override
  void initState() {
    super.initState();

    // 탭 인덱스 초기화: initialTab이 있으면 사용, 없으면 기본값 0
    _currentPageIndex = widget.initialTab ?? 0;
    _pageController = PageController(initialPage: _currentPageIndex);

    WidgetsBinding.instance.addObserver(this);

    // Notification에서 탭 변경 요청 시 사용할 callback 설정
    MainPage.onTabChangeRequested = (index) async {
      logger.d('[MainPage] Callback called: index=$index, mounted=$mounted');
      if (!mounted || index < 0 || index > 2) {
        logger.w('[MainPage] Early return: mounted=$mounted, index=$index');
        return;
      }

      // index 0 (타임라인) 요청 시
      if (index == 0) {
        // 입력 방식 확인
        final inputModeAsync = await ref.read(fragmentInputModeProvider.future);
        final inputMode = inputModeAsync;

        if (!mounted) return;

        if (inputMode == 'inline') {
          // inline 모드: 입력창 포커스
          if (_timelineFocusTrigger != null) {
            logger.i('MainPage: Inline mode, focusing input');
            _timelineFocusTrigger!.call();
          }
        } else {
          // fab 모드: 모달 표시
          logger.i('MainPage: FAB mode, showing fragment input modal');
          showFragmentInputModal(context);
        }
      } else {
        // 다른 탭으로 이동
        setState(() {
          _currentPageIndex = index;
        });
        _pageController.jumpToPage(index);
        logger.i('MainPage tab changed by notification: $index');
      }
    };

    // 저장된 탭 인덱스 로드 및 Auto focus 처리
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // initialTab이 없을 때만 저장된 값 로드
      if (widget.initialTab == null) {
        final savedIndex = await ref.read(lastTabIndexProvider.future);

        if (mounted &&
            savedIndex != _currentPageIndex &&
            savedIndex >= 0 &&
            savedIndex <= 2) {
          setState(() {
            _currentPageIndex = savedIndex;
          });
          _pageController.jumpToPage(savedIndex);
          logger.i('MainPage restored to saved tab: $savedIndex');
        }
      }

      // 앱 시작 시에도 자동 포커스 체크
      _handleAppResumed();
    });
  }

  @override
  void didUpdateWidget(MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab &&
        widget.initialTab != null) {
      logger.i(
        'MainPage tab changed: ${oldWidget.initialTab} -> ${widget.initialTab}',
      );
      setState(() {
        _currentPageIndex = widget.initialTab!;
      });
      _pageController.jumpToPage(widget.initialTab!);
    }
  }

  @override
  void dispose() {
    MainPage.onTabChangeRequested = null;
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      logger.d('[MainPage] App resumed');
      _handleAppResumed();
    }
  }

  /// 앱 포그라운드 진입 시 처리
  void _handleAppResumed() async {
    logger.d(
      '[MainPage] _handleAppResumed - pageIndex: $_currentPageIndex, searchMode: $_isSearchMode',
    );

    // 타임라인 탭이 아니면 무시
    if (_currentPageIndex != 0) {
      logger.d('[MainPage] Not timeline tab, skipping');
      return;
    }

    // 검색 모드이면 무시
    if (_isSearchMode) {
      logger.d('[MainPage] Search mode active, skipping');
      return;
    }

    // 설정 확인 (비동기 - Provider 로드 완료까지 대기)
    try {
      final enabled = await ref.read(autoFocusInputProvider.future);
      logger.d(
        '[MainPage] Auto-focus enabled: $enabled, trigger: ${_timelineFocusTrigger != null}',
      );

      if (enabled && _timelineFocusTrigger != null) {
        logger.d('[MainPage] Triggering focus');
        _timelineFocusTrigger!.call();
      }
    } catch (e) {
      logger.e('[MainPage] Failed to read auto-focus setting: $e');
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      // 탭 변경 시 검색 모드 종료
      if (_isSearchMode) {
        _exitSearchMode();
      }
    });
    _pageController.jumpToPage(index);

    // 탭 위치 저장
    ref.read(lastTabIndexProvider.notifier).setLastTabIndex(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      // 페이지 변경 시 검색 모드 종료
      if (_isSearchMode) {
        _exitSearchMode();
      }
    });

    // 탭 위치 저장
    ref.read(lastTabIndexProvider.notifier).setLastTabIndex(index);
  }

  // Timeline: 검색 모드
  void _enterSearchMode() {
    setState(() => _isSearchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _exitSearchMode() {
    setState(() => _isSearchMode = false);
    _searchController.clear();
    ref.read(fragmentFilterProvider.notifier).clearSearch();
    _searchFocusNode.unfocus();
  }

  void _toggleViewMode() {
    setState(() {
      final newMode = _viewMode == 'timeline' ? 'calendar' : 'timeline';
      _viewMode = newMode;

      // Calendar 모드로 전환 시 trigger 초기화
      // (FragmentInputBar가 dispose되므로 이전 trigger는 무효)
      if (newMode == 'calendar') {
        _timelineFocusTrigger = null;
        logger.d('MainPage: Switched to calendar mode, cleared focus trigger');
      }
      // Timeline 모드로 전환 시 trigger는 FragmentInputBar의 initState에서 자동 재등록됨
    });
  }

  // Draft: 분석 실행
  Future<void> _handleAnalyzeNow() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analyzeMessage = '';
    });

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) {
        setState(() {
          _analyzeMessage = 'auth.login_required'.tr();
        });
        return;
      }

      final response = await supabase.functions.invoke('analyze-fragments');

      if (response.status != 200) {
        logger.e('❌ analyze-fragments 실패: ${response.data}');
        setState(() {
          _analyzeMessage = 'draft.analyze_failed'.tr();
        });
        return;
      }

      final result = response.data as Map<String, dynamic>;
      logger.i('✅ Draft 분석 완료: $result');

      final draftsCreated = result['drafts_created'] as int? ?? 0;
      setState(() {
        if (draftsCreated > 0) {
          _analyzeMessage = 'draft.analyze_success'.tr(
            namedArgs: {'count': draftsCreated.toString()},
          );
        } else {
          _analyzeMessage = 'draft.analyze_no_results'.tr();
        }
      });

      ref.invalidate(draftsStreamProvider);
    } catch (error) {
      logger.e('❌ Draft 분석 오류:', error);
      setState(() {
        _analyzeMessage = 'draft.analyze_failed'.tr();
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputModeAsync = ref.watch(fragmentInputModeProvider);
    final inputMode = inputModeAsync.asData?.value ?? 'inline';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _isSearchMode ? _buildSearchAppBar() : _buildDefaultAppBar(),
      body: Stack(
        children: [
          // 페이지 뷰
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: [
              TimelineView(
                viewMode: _viewMode,
                onEnterSearchMode: _enterSearchMode,
              ),
              DraftsView(analyzeMessage: _analyzeMessage),
              const PostsView(),
            ],
          ),
          // inline 모드일 때 하단 입력창 표시 (모든 탭)
          if (inputMode == 'inline')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: KeyboardAnimationBuilder(
                builder: (context, keyboardHeight) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: keyboardHeight),
                    child: FragmentInputBar(
                      onRegisterFocusTrigger: (trigger) {
                        _timelineFocusTrigger = trigger;
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      // fab 모드일 때 FAB 표시 (모든 탭)
      floatingActionButton: inputMode == 'fab'
          ? FloatingActionButton(
              onPressed: () => showFragmentInputModal(context),
              child: Icon(AppIcons.add),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      leading: _buildLeading(),

      title: Padding(
        padding: const EdgeInsets.only(top: common.Spacing.sm),

        child: ShadTabs<int>(
          value: _currentPageIndex,
          onChanged: _onTabChanged,
          scrollable: true,
          tabs: [
            // Timeline 탭 (텍스트 + 뷰 토글 아이콘)
            ShadTab(
              value: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _viewMode == 'timeline'
                        ? 'timeline.title'.tr()
                        : 'timeline.calendar'.tr(),
                  ),
                  const SizedBox(width: common.Spacing.sm),
                  GestureDetector(
                    onTap: _currentPageIndex == 0 ? _toggleViewMode : null,
                    child: Icon(
                      _viewMode == 'timeline'
                          ? AppIcons.calendar
                          : AppIcons.sparkles,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            ShadTab(
              value: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(AppIcons.drafts, size: 20)],
              ),
            ),
            ShadTab(
              value: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(AppIcons.posts, size: 20)],
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(
            right: common.Spacing.sm + common.Spacing.xs,
          ),
          child: Center(child: UserAvatarButton()),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    final filterAsync = ref.watch(fragmentFilterProvider);
    final filter = filterAsync.asData?.value ?? const FragmentFilterState();
    final theme = ShadTheme.of(context);

    return AppBar(
      leading: IconButton(
        icon: Icon(AppIcons.arrowBack),
        onPressed: _exitSearchMode,
      ),
      title: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _searchController.text.isEmpty &&
              filter.selectedTags.isNotEmpty) {
            final lastTag = filter.selectedTags.last;
            ref.read(fragmentFilterProvider.notifier).removeTag(lastTag);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ShadInput(
          controller: _searchController,
          focusNode: _searchFocusNode,
          placeholder: filter.selectedTags.isEmpty
              ? Text('filter.search_placeholder'.tr())
              : null,
          onChanged: (value) {
            ref.read(fragmentFilterProvider.notifier).setQuery(value);
          },
          leading: filter.selectedTags.isNotEmpty
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filter.selectedTags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: common.Spacing.xs,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: common.Spacing.sm - common.Spacing.xs,
                            vertical: common.Spacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              common.BorderRadii.full,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: theme.textTheme.small.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: common.Spacing.xs / 2),
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(fragmentFilterProvider.notifier)
                                      .removeTag(tag);
                                },
                                child: Icon(
                                  AppIcons.close,
                                  size: common.Spacing.sm + common.Spacing.xs,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : null,
          trailing: (filter.query.isNotEmpty || filter.selectedTags.isNotEmpty)
              ? ShadButton.ghost(
                  width: common.Spacing.lg,
                  height: common.Spacing.lg,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _searchController.clear();
                    ref.read(fragmentFilterProvider.notifier).clearSearch();
                  },
                  child: Icon(
                    AppIcons.close,
                    size: common.Spacing.md,
                    color: theme.colorScheme.mutedForeground,
                  ),
                )
              : null,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(AppIcons.sort, color: theme.colorScheme.mutedForeground),
          tooltip: 'filter.sort'.tr(),
          onSelected: (value) {
            ref.read(fragmentFilterProvider.notifier).setSortBy(value);
          },
          itemBuilder: (context) => [
            _buildSortMenuItem(
              'event',
              'filter.sort_event'.tr(),
              filter.sortBy == 'event',
            ),
            _buildSortMenuItem(
              'created',
              'filter.sort_created'.tr(),
              filter.sortBy == 'created',
            ),
            _buildSortMenuItem(
              'updated',
              'filter.sort_updated'.tr(),
              filter.sortBy == 'updated',
            ),
          ],
        ),
        ShadIconButton.ghost(
          padding: const EdgeInsets.all(common.Spacing.sm),
          icon: Icon(
            filter.sortOrder == 'desc' ? AppIcons.arrowDown : AppIcons.arrowUp,
            size: 20,
            color: theme.colorScheme.mutedForeground,
          ),
          onPressed: () {
            ref.read(fragmentFilterProvider.notifier).toggleSortOrder();
          },
        ),
        const SizedBox(width: common.Spacing.xs),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              AppIcons.checkCircle,
              size: common.Spacing.md,
              color: ShadTheme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildLeading() {
    // Timeline: 검색 아이콘
    if (_currentPageIndex == 0) {
      return Center(
        child: ShadIconButton.ghost(
          icon: Icon(
            AppIcons.search,
            color: ShadTheme.of(context).colorScheme.mutedForeground,
          ),
          onPressed: _enterSearchMode,
        ),
      );
    }

    // Drafts: 분석 아이콘 (debug mode만)
    if (_currentPageIndex == 1 && kDebugMode) {
      return Center(
        child: ShadIconButton.ghost(
          icon: _isAnalyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(AppIcons.sparkles, size: 20),
          onPressed: _isAnalyzing ? null : _handleAnalyzeNow,
        ),
      );
    }

    // Posts: leading 없음
    return null;
  }
}
