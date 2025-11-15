import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/user_avatar_button.dart';
import '../../../drafts/presentation/widgets/drafts_view.dart';
import '../../../drafts/providers/drafts_provider.dart';
import '../../../posts/presentation/widgets/posts_view.dart';
import '../../../timeline/presentation/widgets/timeline_view.dart';
import '../../../timeline/providers/fragments_provider.dart';

/// 메인 화면 (PageView + Tabs)
///
/// Timeline/Drafts/Posts 페이지를 PageView로 관리
class MainPage extends ConsumerStatefulWidget {
  final int initialTab;

  const MainPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late final PageController _pageController;
  late int _currentPageIndex;

  // Timeline 상태
  String _viewMode = 'timeline'; // 'timeline' | 'calendar'
  bool _isSearchMode = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Draft 상태
  bool _isAnalyzing = false;
  String _analyzeMessage = '';

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialTab;
    _pageController = PageController(initialPage: widget.initialTab);
    logger.i('MainPage initialized with tab: ${widget.initialTab}');
  }

  @override
  void didUpdateWidget(MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      logger.i('MainPage tab changed: ${oldWidget.initialTab} -> ${widget.initialTab}');
      setState(() {
        _currentPageIndex = widget.initialTab;
      });
      _pageController.jumpToPage(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      // 페이지 변경 시 검색 모드 종료
      if (_isSearchMode) {
        _exitSearchMode();
      }
    });
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
      _viewMode = _viewMode == 'timeline' ? 'calendar' : 'timeline';
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _isSearchMode ? _buildSearchAppBar() : _buildDefaultAppBar(),
      body: PageView(
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
                  const SizedBox(width: common.Spacing.sm - common.Spacing.xs),
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
          padding: EdgeInsets.only(right: common.Spacing.sm + common.Spacing.xs),
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
                        padding: const EdgeInsets.only(right: common.Spacing.xs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: common.Spacing.sm - common.Spacing.xs,
                            vertical: common.Spacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
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

    // Drafts: 분석 아이콘
    if (_currentPageIndex == 1) {
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
