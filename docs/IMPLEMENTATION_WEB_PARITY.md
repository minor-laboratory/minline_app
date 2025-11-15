# 웹 버전 기능 동등성 구현 계획

> **작성일**: 2025-11-13
> **목적**: 미니라인 앱을 웹 버전과 동등한 수준으로 기능 구현
> **참조**: 웹 버전 (miniline), 북랩 앱 (minorlab_book)

## 언제 읽어야 하는가

- 미니라인 앱 기능 구현 전
- 웹과 앱의 차이점 확인 시
- 누락된 기능 파악 시

---

## 개요

### 발견된 문제점

웹 버전과 앱 버전을 비교한 결과, **핵심 기능이 여러 개 누락**되었습니다:

1. **Timeline**: 검색/정렬/필터 기능 없음
2. **Drafts**: 상태 필터, AI 분석 버튼 없음
3. **Settings**: 컬러 테마 선택 없음 (테마 모드만 있음)

### 구현 원칙

- ✅ **웹 UI를 앱에 맞게 변환** (Bottom Sheet, Material 3 스타일)
- ✅ **북랩 패턴 재사용** (테마, Bottom Sheet 등)
- ✅ **로컬 퍼스트** (Isar 우선, 동기화는 백그라운드)
- ❌ **웹 코드 직접 복사 금지** (Flutter로 재구현)

---

## 웹 vs 앱 기능 비교 요약

| 화면 | 기능 | 웹 | 앱 | 우선순위 |
|------|------|-----|-----|---------|
| **Timeline** | 검색 | ✅ | ❌ | P1 |
| | 정렬 (created/updated/event) | ✅ | ❌ | P1 |
| | 정렬 방향 (desc/asc) | ✅ | ❌ | P1 |
| | 태그 필터링 | ✅ | ❌ | P1 |
| | 무한 스크롤 | ✅ (30개) | ❌ | P2 |
| **Drafts** | 상태 필터 (all/pending/accepted/rejected) | ✅ | ❌ | P1 |
| | 상태별 카운트 | ✅ | ❌ | P1 |
| | AI 분석 실행 버튼 | ✅ | ❌ | P1 |
| | 무한 스크롤 | ✅ (20개) | ❌ | P2 |
| **Settings** | 컬러 테마 (12가지) | ✅ | ❌ | P1 |
| | 데이터 내보내기 (Markdown/JSON) | ✅ | ❌ | P2 |
| | 계정 삭제 | ✅ | ❌ | P2 |

---

## 구현 순서

### Phase 1: 핵심 기능 (필수)

1. [Settings] 컬러 테마 선택
2. [Timeline] 검색/정렬/필터
3. [Drafts] 상태 필터 + AI 분석

### Phase 2: 개선 기능 (선택)

4. [Timeline/Drafts] 무한 스크롤
5. [Settings] 데이터 내보내기
6. [Settings] 계정 삭제

---

## Phase 1-1: Settings 컬러 테마 선택

### 현재 상태

**❌ 문제**:
- `settings_provider.dart`: `ThemeModeNotifier`만 있음 (system/light/dark)
- `theme_settings_sheet.dart`: 테마 모드 3개만 표시

**참조 파일**:
- 북랩: `minorlab_book/lib/features/profile/presentation/widgets/theme_settings_sheet.dart`
- 북랩: `minorlab_common`의 `themeConfigProvider`

### 목표 상태

**✅ 구현**:
```dart
// settings_provider.dart
@riverpod
class ColorThemeNotifier extends _$ColorThemeNotifier {
  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString('color_theme') ?? 'zinc';
  }

  Future<void> setColorTheme(String colorId) async {
    state = AsyncValue.data(colorId);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('color_theme', colorId);
  }
}

// 12가지 컬러: blue, slate, gray, zinc, neutral, stone, red, orange, yellow, green, violet, rose
```

**UI 구조** (북랩 참조):
```
ThemeSettingsSheet (Column)
├─ 테마 모드 (Row - 3개 카드)
│  ├─ System
│  ├─ Light
│  └─ Dark
├─ Divider
├─ 배경색 (Column - 3개 RadioListTile)
│  ├─ 기본 (defaultColor): 순수한 흰색/검정
│  ├─ 따뜻함 (warm): 세피아/차콜 톤
│  └─ 중립 (neutral): 연한 회색 톤
├─ Divider
└─ 컬러 스킴 (GridView 3x4)
   ├─ Blue, Slate, Gray, Zinc
   ├─ Neutral, Stone, Red, Orange
   └─ Yellow, Green, Violet, Rose
```

### 구현 단계

#### 1. Provider 추가

**파일**: `lib/features/settings/providers/settings_provider.dart`

```dart
/// 컬러 테마 Provider (12가지 Shadcn UI 컬러)
@riverpod
class ColorThemeNotifier extends _$ColorThemeNotifier {
  static const String _key = 'color_theme';

  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString(_key) ?? 'zinc';
  }

  Future<void> setColorTheme(String colorId) async {
    state = AsyncValue.data(colorId);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, colorId);
  }
}
```

#### 2. UI 업데이트

**파일**: `lib/features/settings/presentation/widgets/theme_settings_sheet.dart`

**추가 내용**:
- 컬러 스킴 섹션 헤더
- `GridView.count` (3 columns, 12 items)
- `_ColorCard` 위젯 (원형 컬러 + 라벨 + 선택 표시)

**참조**: 북랩 `theme_settings_sheet.dart:116-171`

#### 3. 테마 적용

**파일**: `lib/app/app.dart` (MaterialApp)

```dart
final colorTheme = ref.watch(colorThemeProvider);

return colorTheme.when(
  data: (colorId) => MaterialApp.router(
    theme: _buildTheme(colorId, Brightness.light),
    darkTheme: _buildTheme(colorId, Brightness.dark),
    // ...
  ),
  loading: () => CircularProgressIndicator(),
  error: (_, __) => MaterialApp.router(...), // 기본 테마
);
```

#### 4. 배경색 Provider 추가

**파일**: `lib/features/settings/providers/settings_provider.dart`

```dart
/// 배경색 Provider (defaultColor/warm/neutral)
@riverpod
class BackgroundColorNotifier extends _$BackgroundColorNotifier {
  static const String _key = 'background_color';

  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString(_key) ?? 'defaultColor';
  }

  Future<void> setBackgroundColor(String bgColor) async {
    state = AsyncValue.data(bgColor);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, bgColor);
  }
}
```

**테마 적용**:
```dart
// main.dart에서 minorlab_common의 BackgroundColorOption 사용
final bgColor = ref.watch(backgroundColorProvider);

theme: AppTheme.light(
  colorId: colorId,
  bgColor: bgColor == 'warm' ? BackgroundColorOption.warm
         : bgColor == 'neutral' ? BackgroundColorOption.neutral
         : BackgroundColorOption.defaultColor,
),
```

#### 5. 다국어 키 추가

**파일**: `assets/translations/ko.json`, `en.json`

```json
{
  "theme.mode": "테마 모드",
  "theme.color_scheme": "컬러 테마",
  "theme.background_color": "배경색",
  "theme.background_color_desc": "읽기 편한 배경색을 선택하세요",
  "theme.bg_default": "기본",
  "theme.bg_default_desc": "순수한 흰색/검정",
  "theme.bg_warm": "따뜻함",
  "theme.bg_warm_desc": "세피아/차콜 톤",
  "theme.bg_neutral": "중립",
  "theme.bg_neutral_desc": "연한 회색 톤",
  "theme.color_blue": "블루",
  "theme.color_slate": "슬레이트",
  "theme.color_gray": "그레이",
  "theme.color_zinc": "징크",
  "theme.color_neutral": "뉴트럴",
  "theme.color_stone": "스톤",
  "theme.color_red": "레드",
  "theme.color_orange": "오렌지",
  "theme.color_yellow": "옐로우",
  "theme.color_green": "그린",
  "theme.color_violet": "바이올렛",
  "theme.color_rose": "로즈"
}
```

### 주의사항

- ❌ **북랩 코드 직접 복사 금지** (minorlab_common 의존성 있음)
- ✅ **컬러 정의는 북랩과 동일하게** (일관성 유지)
- ✅ **SharedPreferences 사용** (북랩과 동일)

---

## Phase 1-2: Timeline 검색/정렬/필터

### 현재 상태

**❌ 문제**:
- `fragment_list.dart`: `ListView.builder`만 있음
- 검색, 정렬, 태그 필터 없음

**웹 구현**: `miniline/src/lib/components/Timeline.svelte:23-70`
- `query` (검색어)
- `sortBy` (created/updated/event)
- `sortOrder` (desc/asc)
- `selectedTags` (배열)
- 필터링/정렬 로직

**웹 UI**: `miniline/src/lib/components/FilterBar.svelte`
- 검색 입력창
- 정렬 드롭다운
- 선택된 태그 칩 (제거 가능)

### 목표 상태

**✅ 구현**:

```dart
// providers/fragments_provider.dart
@riverpod
class FilteredFragments extends _$FilteredFragments {
  String query = '';
  String sortBy = 'event'; // created, updated, event
  String sortOrder = 'desc'; // desc, asc
  List<String> selectedTags = [];

  void setQuery(String value) {
    query = value;
    ref.invalidateSelf();
  }

  void setSortBy(String value) {
    sortBy = value;
    ref.invalidateSelf();
  }

  void toggleSortOrder() {
    sortOrder = sortOrder == 'desc' ? 'asc' : 'desc';
    ref.invalidateSelf();
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    ref.invalidateSelf();
  }

  @override
  Stream<List<Fragment>> build() async* {
    // fragmentsStreamProvider를 구독
    final stream = ref.watch(fragmentsStreamProvider);

    await for (final fragments in stream) {
      var result = fragments;

      // 검색 필터
      if (query.isNotEmpty) {
        result = result.where((f) =>
          f.content.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }

      // 태그 필터
      if (selectedTags.isNotEmpty) {
        result = result.where((f) {
          final allTags = [...f.tags, ...f.userTags];
          return selectedTags.any((tag) => allTags.contains(tag));
        }).toList();
      }

      // 정렬
      result.sort((a, b) {
        DateTime aTime, bTime;
        if (sortBy == 'created') {
          aTime = a.createdAt;
          bTime = b.createdAt;
        } else if (sortBy == 'updated') {
          aTime = a.updatedAt;
          bTime = b.updatedAt;
        } else {
          aTime = a.eventTime;
          bTime = b.eventTime;
        }

        final diff = aTime.compareTo(bTime);
        return sortOrder == 'desc' ? -diff : diff;
      });

      yield result;
    }
  }
}
```

### 구현 단계

#### 1. Provider 추가

**파일**: `lib/features/timeline/providers/fragments_provider.dart`

위의 `FilteredFragmentsProvider` 추가

#### 2. FilterBar 위젯 생성

**파일**: `lib/features/timeline/presentation/widgets/filter_bar.dart`

**구조**:
```
Column
├─ Row
│  ├─ SearchBar (검색 입력)
│  └─ PopupMenuButton (정렬 선택)
└─ Wrap (선택된 태그 칩들)
```

**참조**: 웹 `FilterBar.svelte`

#### 3. FragmentList 수정

**파일**: `lib/features/timeline/presentation/widgets/fragment_list.dart`

**변경**:
```dart
// Before
final fragmentsAsync = ref.watch(fragmentsStreamProvider);

// After
final fragmentsAsync = ref.watch(filteredFragmentsProvider);
```

#### 4. MainPage의 TimelineView에 FilterBar 추가

**파일**: `lib/features/main/presentation/pages/main_page.dart` (Timeline/Drafts/Posts 통합)
**참조**: `lib/features/timeline/presentation/widgets/timeline_view.dart`

```dart
body: Column(
  children: [
    if (_viewMode == 'timeline') const FilterBar(),
    Expanded(
      child: _viewMode == 'timeline'
          ? const FragmentList()
          : CalendarView(...),
    ),
  ],
),
```

#### 5. localStorage에 상태 저장

**SharedPreferences**:
- `timeline_sort_by`
- `timeline_sort_order`
- `timeline_view_mode` (이미 있음)

### 주의사항

- ✅ **Provider 기반** (웹의 `$state`와 동일한 역할)
- ✅ **Stream 구독** (Isar 자동 갱신)
- ❌ **UI 스레드 블로킹 금지** (필터링/정렬은 async)

---

## Phase 1-3: Drafts 상태 필터 + AI 분석 ✅ 완료

### 현재 상태

**✅ 구현 완료** (2025-11-13):
- `DraftFilterState` 및 `DraftFilter` Provider
- `filteredDraftsProvider` (필터링 로직)
- `draftCountsProvider` (상태별 카운트)
- DraftsPage UI (필터 버튼, AI 분석 버튼)
- 다국어 키 (웹과 100% 일치)

**파일**:
- `lib/features/drafts/providers/drafts_provider.dart` ✅
- `lib/features/drafts/presentation/widgets/drafts_view.dart` ✅ (PageView 통합으로 이동)
- `lib/features/main/presentation/pages/main_page.dart` ✅ (Timeline/Drafts/Posts 통합)
- `assets/translations/ko.json`, `en.json` ✅

**웹 참조**: `miniline/src/lib/components/DraftList.svelte` (120-172, 196-225라인)

### 구현 내용

#### 1. Provider 추가

**파일**: `lib/features/drafts/providers/drafts_provider.dart`

**완료된 구현**:

```dart
/// Draft 필터 상태
class DraftFilterState {
  final String status; // 'all', 'pending', 'accepted', 'rejected'

  const DraftFilterState({this.status = 'all'});

  DraftFilterState copyWith({String? status}) {
    return DraftFilterState(status: status ?? this.status);
  }
}

/// Draft 필터 Notifier
@riverpod
class DraftFilter extends _$DraftFilter {
  @override
  DraftFilterState build() => const DraftFilterState();

  void setStatus(String value) {
    state = state.copyWith(status: value);
  }

  void reset() {
    state = const DraftFilterState();
  }
}

/// 필터링된 Draft 리스트
@riverpod
Stream<List<Draft>> filteredDrafts(Ref ref) async* {
  final filter = ref.watch(draftFilterProvider);
  final draftsAsync = ref.watch(draftsStreamProvider);

  await for (final drafts in draftsAsync.when(
    data: (data) => Stream.value(data),
    loading: () => const Stream<List<Draft>>.empty(),
    error: (_, __) => const Stream<List<Draft>>.empty(),
  )) {
    if (filter.status == 'all') {
      yield drafts;
    } else {
      yield drafts.where((d) => d.status == filter.status).toList();
    }
  }
}

/// 상태별 Draft 개수
@riverpod
Stream<Map<String, int>> draftCounts(Ref ref) async* {
  final draftsAsync = ref.watch(draftsStreamProvider);

  await for (final drafts in draftsAsync.when(
    data: (data) => Stream.value(data),
    loading: () => const Stream<List<Draft>>.empty(),
    error: (_, __) => const Stream<List<Draft>>.empty(),
  )) {
    yield {
      'all': drafts.length,
      'pending': drafts.where((d) => d.status == 'pending').length,
      'accepted': drafts.where((d) => d.status == 'accepted').length,
      'rejected': drafts.where((d) => d.status == 'rejected').length,
    };
  }
}
```

#### 2. DraftsView UI 수정

**파일**: `lib/features/drafts/presentation/widgets/drafts_view.dart` (PageView 통합)
**호출**: `lib/features/main/presentation/pages/main_page.dart`

**완료된 구현**:

- **AppBar 액션**: AI 분석 버튼 (TextButton.icon, 우측 상단)
- **분석 결과 메시지**: Container (margin: 16, padding: 16, surfaceContainerHighest)
- **필터 버튼**: Wrap 레이아웃 (4개 FilterChip)
- **FilterChip**: Material FilterChip 위젯 사용
- **Empty State**: 필터별 다른 메시지 (`draft.empty_message` / `draft.empty_filter`)

**핵심 코드**:
```dart
AppBar(
  title: Text('drafts.title'.tr()),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: _isAnalyzing ? null : _handleAnalyzeNow,
        icon: _isAnalyzing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(AppIcons.sparkles),
        label: Text(_isAnalyzing
            ? 'draft.analyzing'.tr()
            : 'draft.analyze_now'.tr()),
      ),
    ),
  ],
),
body: Column(
  children: [
    // 분석 결과 메시지
    if (_analyzeMessage.isNotEmpty)
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(_analyzeMessage, textAlign: TextAlign.center),
      ),

    // 필터 칩 (all/pending/accepted/rejected)
    countsStream.when(
      data: (counts) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'draft.filter_all'.tr(),
              count: counts['all'] ?? 0,
              isSelected: filter.status == 'all',
              onTap: () => ref.read(draftFilterProvider.notifier).setStatus('all'),
            ),
            // ... pending, accepted, rejected
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    ),

    // Draft 리스트
    Expanded(
      child: filteredDraftsStream.when(
        data: (drafts) => /* ... */,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => /* ... */,
      ),
    ),
  ],
),
```

**_FilterChip 위젯**:
```dart
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }
}
```

#### 3. AI 분석 함수 추가

**파일**: `lib/features/main/presentation/pages/main_page.dart` (Drafts 탭 로직)

**완료된 구현**:
```dart
Future<void> _handleAnalyzeNow() async {
  if (_isAnalyzing) return;

  setState(() {
    _isAnalyzing = true;
    _analyzeMessage = '';
  });

  try {
    final supabase = Supabase.instance.client;

    // 세션 확인
    final session = supabase.auth.currentSession;
    if (session == null) {
      setState(() {
        _analyzeMessage = 'auth.login_required'.tr();
      });
      return;
    }

    // analyze-fragments Edge Function 호출
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

    // 성공 메시지 표시
    final draftsCreated = result['drafts_created'] as int? ?? 0;
    setState(() {
      if (draftsCreated > 0) {
        _analyzeMessage =
            'draft.analyze_success'.tr(namedArgs: {'count': draftsCreated.toString()});
      } else {
        _analyzeMessage = 'draft.analyze_no_results'.tr();
      }
    });

    // Provider 무효화로 자동 갱신
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
```

**웹 버전과 차이점**:
- 웹: `fetch()` → 앱: `supabase.functions.invoke()`
- 웹: `syncService.syncAll(true)` → 앱: `ref.invalidate(draftsStreamProvider)` (Stream 자동 갱신)

#### 4. 다국어 키 추가

**파일**: `assets/translations/ko.json`, `en.json`

**완료된 키** (웹 버전과 100% 일치):
```json
{
  "draft.title": "제안" / "Drafts",
  "draft.ai_suggestions": "AI 제안" / "AI Suggestions",
  "draft.subtitle": "관련된 스냅을 묶어 글로 만들어보세요" / "Group related snaps into posts",
  "draft.filter_all": "전체" / "All",
  "draft.filter_pending": "확인 대기" / "Pending",
  "draft.filter_accepted": "수락됨" / "Accepted",
  "draft.filter_rejected": "거부됨" / "Rejected",
  "draft.analyze_now": "지금 분석" / "Analyze Now",
  "draft.analyzing": "분석 중..." / "Analyzing...",
  "draft.analyze_success": "{count}개의 제안이 생성되었습니다" / "{count} draft(s) created",
  "draft.analyze_no_results": "새로운 제안이 없습니다" / "No new drafts found",
  "draft.analyze_failed": "분석 실패" / "Analysis failed",
  "draft.load_failed": "Draft 로딩 실패" / "Failed to load drafts",
  "draft.empty_message": "아직 AI 제안이 없습니다" / "No AI suggestions yet",
  "draft.empty_hint": "스냅을 작성하면 AI가 자동으로 관련된 내용을 묶어 제안합니다" / "AI will automatically group related snaps as you write",
  "draft.empty_filter": "해당 상태의 Draft가 없습니다" / "No drafts with this status"
}
```

**주요 변경사항**:
- "초안" → "제안" (웹과 일치)
- "확인 대기" (웹과 일치, 기존 "대기 중"에서 변경)
- "{count}개의 제안" (웹과 일치, 기존 "초안"에서 변경)

### 검증 완료 ✅

- [x] `flutter analyze` 통과
- [x] 모든 텍스트 `.tr()` 형식 (하드코딩 없음)
- [x] 모든 아이콘 `AppIcons.xxx` 사용
- [x] Provider 기반 상태 관리 (Stream 자동 갱신)
- [x] 웹과 동일한 UX (필터, 분석, 메시지)
- [x] 다국어 키 웹과 100% 일치

---

## Phase 2: 선택 기능 (추후 구현)

### 무한 스크롤

**웹**: Intersection Observer (Timeline 30개, Drafts 20개)

**앱 구현 방법**:
- `ScrollController` + `addListener`
- 또는 `lazy_load_scrollview` 패키지

### 데이터 내보내기

**웹**: Markdown/JSON 파일 다운로드

**앱 구현 방법**:
- `share_plus` 패키지로 공유
- 또는 `file_picker`로 저장 위치 선택

### 계정 삭제

**웹**: 로컬 DB 삭제 + 로그아웃

**앱 구현 방법**:
- Isar DB 전체 삭제
- SharedPreferences 초기화
- Supabase signOut

---

## 검증 체크리스트

각 Phase 완료 후 확인:

- [ ] `flutter analyze` 통과 (No issues found!)
- [ ] 모든 텍스트 `.tr()` 형식 (하드코딩 없음)
- [ ] 모든 아이콘 `AppIcons.xxx` 사용
- [ ] Isar 데이터 저장 확인 (Isar Inspector)
- [ ] 실제 동작 확인 (에뮬레이터/실기기)
- [ ] 웹과 동일한 UX (기능 동등성)

---

## 참조 파일 목록

### 웹 버전 (miniline)

- Timeline: `src/lib/components/Timeline.svelte`
- FilterBar: `src/lib/components/FilterBar.svelte`
- DraftList: `src/lib/components/DraftList.svelte`
- Settings: `src/routes/settings/+page.svelte`
- Theme Store: `src/lib/stores/theme.svelte.ts`

### 북랩 앱 (minorlab_book)

- Theme Settings: `lib/features/profile/presentation/widgets/theme_settings_sheet.dart`
- Profile Page: `lib/features/profile/presentation/pages/profile_main_page.dart`
- Standard Bottom Sheet: `lib/shared/widgets/standard_bottom_sheet.dart`

### 미니라인 앱 (현재)

- Timeline: `lib/features/timeline/presentation/widgets/timeline_view.dart` (MainPage에서 호출)
- Drafts: `lib/features/drafts/presentation/widgets/drafts_view.dart` (MainPage에서 호출)
- Posts: `lib/features/posts/presentation/widgets/posts_view.dart` (MainPage에서 호출)
- **통합 페이지**: `lib/features/main/presentation/pages/main_page.dart` (PageView + Tabs)
- Settings: `lib/features/settings/presentation/pages/settings_page.dart`

---

## 작업 진행 방법

1. **Phase별 순차 진행** (1-1 → 1-2 → 1-3)
2. **각 단계마다 검증** (체크리스트 확인)
3. **Git 커밋**: 각 Phase 완료 후
4. **이슈 발생 시**: 이 문서 참조하여 진행 상황 파악

---

**문서 관리**:
- 구현 완료 시 체크박스 업데이트
- 새로운 이슈 발견 시 문서에 추가
- 구현 방법 변경 시 문서 동기화
