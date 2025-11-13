# 컴포넌트 상세 스펙

> 웹 버전과 일관된 UI/UX를 위한 컴포넌트별 상세 규격

**언제 읽어야 하는가:**
- 컴포넌트 구현 시 (필수)
- UI 디테일 확인 시

## 📐 공통 규칙

### 색상 시스템

**테마 사용 필수** (하드코딩 금지):
```dart
// ❌ 하드코딩
Color(0xFF2563EB)
Colors.blue

// ✅ 테마 사용
theme.colorScheme.primary
theme.colorScheme.surface
theme.colorScheme.onSurface
```

### 크기 시스템

**spacing 단위**:
```dart
// 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64
const spacing2 = 2.0;
const spacing4 = 4.0;
const spacing8 = 8.0;
const spacing12 = 12.0;
const spacing16 = 16.0;
// ...
```

### 아이콘

**AppIcons 사용 필수**:
```dart
// ❌ 직접 사용
Icon(LucideIcons.sparkles)

// ✅ AppIcons 사용
Icon(AppIcons.timeline)
```

---

## 1. FragmentInputBar (하단 고정)

### 기본 정보

- **파일**: `lib/features/timeline/presentation/widgets/fragment_input_bar.dart`
- **웹 참조**: `miniline/src/lib/components/FragmentInput.svelte`
- **위치**: Scaffold의 `bottomNavigationBar` 또는 `persistentFooter`

### 레이아웃

```
┌─────────────────────────────────────────┐
│ [이미지 프리뷰 영역] (있을 때만)          │  ← 80x80 rounded-lg, X 버튼
├─────────────────────────────────────────┤
│                                         │
│  텍스트 입력 영역 (자동 높이)            │  ← min 80px, max 200px
│                                         │
├─────────────────────────────────────────┤
│ [이미지+] [0/3]  [100/300]      [저장]  │  ← 액션 영역
└─────────────────────────────────────────┘
```

### 상세 스펙

**컨테이너**:
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border(
      top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
    ),
  ),
)
```

**이미지 프리뷰**:
- 크기: 80x80 (웹: h-20 w-20 = 5rem = 80px)
- 모서리: 8px 둥글게 (rounded-lg)
- 삭제 버튼: 우상단 (-8, -8), 빨강 배경, X 아이콘 (12x12)
- 최대 3개 (MEDIA_LIMITS.MAX_FILES_PER_FRAGMENT)

**텍스트 입력**:
```dart
TextField(
  maxLines: null,  // 자동 확장
  minLines: 2,
  maxLength: 300,  // MAX_LENGTH
  decoration: InputDecoration(
    hintText: 'snap.input_placeholder'.tr(),
    border: InputBorder.none,
    counterText: '',  // 기본 카운터 숨김 (커스텀 사용)
  ),
)
```

**액션 영역** (하단):
```
┌──────────────────────────────────────────┐
│ [이미지+] [1/3]  [글자수]       [저장]    │
│  chip     chip    chip          button  │
└──────────────────────────────────────────┘
```

**Chip 스타일**:
```dart
// 이미지 추가 버튼
Container(
  height: 32,  // h-8
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),  // px-2.5
  decoration: BoxDecoration(
    color: theme.colorScheme.secondary,  // bg-secondary
    borderRadius: BorderRadius.circular(16),  // rounded-full
  ),
  child: Row(
    children: [
      Icon(AppIcons.imagePlus, size: 16),
      if (imageCount > 0) ...[
        SizedBox(width: 6),
        Text('$imageCount/$maxImages', style: TextStyle(fontSize: 12)),
      ],
    ],
  ),
)

// 글자수
Container(
  height: 32,
  padding: EdgeInsets.symmetric(horizontal: 10),
  decoration: BoxDecoration(
    color: theme.colorScheme.surfaceVariant,  // bg-muted
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    '$charCount / 300',
    style: TextStyle(fontSize: 14, fontFeatureSettings: ['tnum']),  // tabular-nums
  ),
)
```

**저장 버튼**:
```dart
ElevatedButton(
  onPressed: isValid ? handleSave : null,
  child: isLoading
    ? Row(children: [
        SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text(hasImages ? 'media.uploading'.tr() : 'common.saving'.tr()),
      ])
    : Text('common.save'.tr()),
)
```

### 키보드 동작

```dart
// Enter: 저장
// Shift+Enter: 줄바꿈 (자동 처리됨)

TextField(
  onSubmitted: (value) {
    if (value.trim().isNotEmpty || images.isNotEmpty) {
      handleSave();
    }
  },
)
```

### 유효성 검증

**저장 가능 조건**:
```dart
bool get isValid => content.trim().isNotEmpty || images.isNotEmpty;

// ❌ 잘못된 검증
if (content.isEmpty) {
  showError('내용을 입력하세요');  // 하드코딩
}

// ✅ 올바른 검증
if (content.trim().isEmpty && images.isEmpty) {
  toastStore.error('snap.content_or_media_required'.tr());
  return;
}
```

### 엣지 케이스

1. **이미지만 있고 텍스트 없음** → 저장 가능
2. **텍스트만 있고 이미지 없음** → 저장 가능
3. **둘 다 없음** → 저장 불가 (버튼 비활성화)
4. **300자 초과** → 입력 차단 (maxLength)
5. **4개 이미지 선택 시도** → Toast 경고, 3개만 허용

---

## 2. FragmentCard (타임라인 카드)

### 기본 정보

- **파일**: `lib/features/timeline/presentation/widgets/fragment_card.dart`
- **웹 참조**: `miniline/src/lib/components/FragmentCard.svelte`

### 레이아웃

```
┌─────────────────────────────────────────┐
│ 텍스트 내용                              │
│                                         │
├─────────────────────────────────────────┤
│ [이미지] [이미지] [이미지]               │  ← 128x128
├─────────────────────────────────────────┤
│ ⭐ 2025년 1월 13일 오후 3:45            │  ← 이벤트 시간
│ #AI태그 #사용자태그 [+태그추가]         │  ← 태그
│ 📄 "초안 제목" 연결됨                   │  ← Draft 연결 (있을 때만)
├─────────────────────────────────────────┤
│ 📝 2시간 전             [⋮]             │  ← 작성시간 & 메뉴
└─────────────────────────────────────────┘
```

### 상세 스펙

**카드 컨테이너**:
```dart
Container(
  padding: EdgeInsets.all(16),  // p-4
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border.all(color: theme.colorScheme.outline),
    borderRadius: BorderRadius.circular(8),  // rounded-lg
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
)
```

**텍스트 내용**:
```dart
Text(
  fragment.content,
  style: TextStyle(
    fontSize: 16,
    height: 1.6,  // leading-relaxed
    color: theme.colorScheme.onSurface,
  ),
)
```

**이미지**:
- 크기: 128x128 (웹: h-32 w-32 = 8rem = 128px)
- 모서리: 8px 둥글게
- Border: outline 색상
- 클릭 → 전체 화면 뷰어
- Hover 효과: opacity 0.8

```dart
GestureDetector(
  onTap: () => openImageViewer(url),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      url,
      width: 128,
      height: 128,
      fit: BoxFit.cover,
    ),
  ),
)
```

**이벤트 시간**:
```dart
Row(
  children: [
    Icon(
      fragment.eventTimeSource.startsWith('ai')
        ? AppIcons.sparkles      // AI 추론 시간
        : fragment.eventTimeSource.startsWith('user')
        ? AppIcons.calendar      // 사용자 설정 시간
        : AppIcons.clock,        // 자동 (작성 시간)
      size: 14,
      color: theme.colorScheme.primary,
    ),
    SizedBox(width: 6),
    Text(
      formatDate(fragment.eventTime, fragment.eventTimeSource),
      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    ),
  ],
)
```

**formatDate 로직**:
```dart
String formatDate(DateTime date, String source) {
  final includeTime = source.contains('time') || source == 'auto';
  final now = DateTime.now();
  final diff = now.difference(date);

  // 상대 시간 (time variant만, 7일 이내)
  if (includeTime) {
    if (diff.inMinutes < 1) return 'time.just_now'.tr();
    if (diff.inMinutes < 60) return 'time.minutes_ago'.tr(args: [diff.inMinutes]);
    if (diff.inHours < 24) return 'time.hours_ago'.tr(args: [diff.inHours]);
    if (diff.inDays < 7) return 'time.days_ago'.tr(args: [diff.inDays]);
  }

  // 절대 시간
  return DateFormat(
    includeTime ? 'yyyy년 M월 d일 a h:mm' : 'yyyy년 M월 d일',
    Localizations.localeOf(context).languageCode,
  ).format(date);
}
```

**태그**:

AI 태그:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),  // px-2 py-1
  decoration: BoxDecoration(
    color: theme.colorScheme.surfaceVariant,  // bg-muted
    borderRadius: BorderRadius.circular(6),  // rounded-md
  ),
  child: Row(
    children: [
      Icon(AppIcons.sparkles, size: 12),
      SizedBox(width: 4),
      Text(tag, style: TextStyle(fontSize: 12)),
      // Hover 시 X 버튼 표시 (GestureDetector로 구현)
    ],
  ),
)
```

사용자 태그:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: theme.colorScheme.primary,  // bg-primary
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(
    children: [
      Icon(AppIcons.edit, size: 12, color: theme.colorScheme.onPrimary),
      SizedBox(width: 4),
      Text(
        tag,
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary),
      ),
    ],
  ),
)
```

태그 추가 버튼:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(
    children: [
      Icon(AppIcons.add, size: 12),
      SizedBox(width: 4),
      Text('tag.add_tag'.tr(), style: TextStyle(fontSize: 12)),
    ],
  ),
)
```

**Draft 연결 정보**:
```dart
GestureDetector(
  onTap: () => context.go('/drafts'),
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Icon(AppIcons.drafts, size: 12, color: theme.colorScheme.primary),
        SizedBox(width: 4),
        Text(
          'draft.linked_to'.tr(args: [draftTitle]),
          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
        ),
      ],
    ),
  ),
)
```

**하단 영역** (작성시간 & 메뉴):
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // 작성시간
    Row(
      children: [
        Icon(AppIcons.drafts, size: 14, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: 4),
        Text(
          formatDate(fragment.timestamp, 'auto'),
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        if (!fragment.synced) ...[
          SizedBox(width: 4),
          Tooltip(
            message: 'sync.waiting'.tr(),
            child: Icon(AppIcons.clock, size: 14, color: Colors.blue),
          ),
        ],
      ],
    ),
    // 메뉴
    IconButton(
      icon: Icon(AppIcons.moreVert),
      iconSize: 16,
      onPressed: () => showMenu(),
    ),
  ],
)
```

**드롭다운 메뉴**:
- 편집 (Edit 아이콘)
- 임베딩 생성/재생성 (Sparkles 아이콘)
- --- (구분선)
- 삭제 (Trash 아이콘, 빨강)

---

## 3. DraftCard (초안 카드)

### 기본 정보

- **파일**: `lib/features/drafts/presentation/widgets/draft_card.dart`
- **웹 참조**: `miniline/src/lib/components/DraftCard.svelte`

### 레이아웃

```
┌─────────────────────────────────────────┐
│ 초안 제목                      [pending]  │
│ 초안 생성 이유 설명                       │
├─────────────────────────────────────────┤
│ 📄 3개 조각 • 유사도 87%                 │
│ [> Fragment 목록 보기]                   │  ← 토글
│   ├ Fragment 1 내용...                  │  (열렸을 때)
│   ├ Fragment 2 내용...                  │
│   └ Fragment 3 내용...                  │
├─────────────────────────────────────────┤
│              [✓ 수락] [✗ 거절] [⋮]       │  ← 액션
└─────────────────────────────────────────┘
```

### 상세 스펙

**카드 컨테이너**:
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border.all(color: theme.colorScheme.outline),
    borderRadius: BorderRadius.circular(8),
  ),
)
```

**헤더** (제목 & 상태):
```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (draft.reason != null)
            Text(
              draft.reason!,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    ),
    Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(draft.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'draft.status_${draft.status}'.tr(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  ],
)
```

**상태 색상**:
```dart
Color getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return theme.colorScheme.primary;
    case 'accepted':
      return Colors.green;  // accent (없으면 green)
    case 'rejected':
      return theme.colorScheme.onSurfaceVariant;
    default:
      return theme.colorScheme.onSurface;
  }
}
```

**메타 정보**:
```dart
Row(
  children: [
    Icon(AppIcons.drafts, size: 14),
    SizedBox(width: 4),
    Text(
      'draft.snap_count'.tr(args: [fragmentCount]),
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
    ),
    if (draft.similarityScore != null) ...[
      Text(' • ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      Text(
        'draft.similarity'.tr() + ' ${(draft.similarityScore! * 100).round()}%',
        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
      ),
    ],
  ],
)
```

**Fragment 목록 토글**:
```dart
TextButton.icon(
  onPressed: () => setState(() => showFragments = !showFragments),
  icon: Icon(showFragments ? AppIcons.chevronDown : AppIcons.chevronRight),
  label: Text(
    showFragments
      ? 'draft.toggle_snaps_hide'.tr()
      : 'draft.toggle_snaps_show'.tr(),
  ),
  style: TextButton.styleFrom(
    foregroundColor: theme.colorScheme.onSurfaceVariant,
  ),
)
```

**Fragment 리스트** (토글 시):
```dart
Container(
  margin: EdgeInsets.only(left: 16),
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(
        color: theme.colorScheme.outline,
        width: 2,
      ),
    ),
  ),
  child: Column(
    children: fragments.map((fragment) =>
      Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fragment.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('M월 d일 a h:mm').format(fragment.timestamp),
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ).toList(),
  ),
)
```

**액션 버튼** (상태별):

Pending:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton.icon(
      onPressed: handleAccept,
      icon: Icon(AppIcons.check, size: 16),
      label: Text('draft.accept_action'.tr()),
    ),
    SizedBox(width: 8),
    OutlinedButton.icon(
      onPressed: handleReject,
      icon: Icon(AppIcons.close, size: 16),
      label: Text('draft.reject_action'.tr()),
    ),
    IconButton(
      icon: Icon(AppIcons.moreVert),
      onPressed: showMenu,
    ),
  ],
)
```

Accepted:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton.icon(
      onPressed: () => context.go('/posts/new?draftId=${draft.id}'),
      icon: Icon(AppIcons.posts, size: 16),
      label: Text('draft.create_post'.tr()),
    ),
    // ... Reject, Menu
  ],
)
```

Rejected:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton.icon(
      onPressed: handleAccept,
      icon: Icon(AppIcons.check, size: 16),
      label: Text('draft.reaccept_action'.tr()),
    ),
    IconButton(
      icon: Icon(AppIcons.moreVert),
      onPressed: showMenu,
    ),
  ],
)
```

---

## 4. PostCard (공개글 카드)

### 기본 정보

- **파일**: `lib/features/posts/presentation/widgets/post_card.dart`
- **웹 참조**: 웹에는 상세 페이지만 있음 (PostCard 컴포넌트 없음)

### 레이아웃

```
┌─────────────────────────────────────────┐
│ 글 제목                        [공개/비공개]│
│                                         │
│ 본문 미리보기 (최대 3줄)...             │
│                                         │
├─────────────────────────────────────────┤
│ 2025년 1월 13일               [⋮]       │
└─────────────────────────────────────────┘
```

### 상세 스펙

**카드 컨테이너**:
```dart
GestureDetector(
  onTap: () => context.go('/posts/${post.id}'),
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border.all(color: theme.colorScheme.outline),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
)
```

**헤더**:
```dart
Row(
  children: [
    Expanded(
      child: Text(
        post.title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: post.isPublic
          ? theme.colorScheme.primary.withOpacity(0.1)
          : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        post.isPublic ? 'post.public'.tr() : 'post.private'.tr(),
        style: TextStyle(
          fontSize: 12,
          color: post.isPublic
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  ],
)
```

**본문 미리보기**:
```dart
Text(
  post.content,
  style: TextStyle(fontSize: 14, height: 1.5),
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
)
```

**하단**:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      DateFormat('yyyy년 M월 d일').format(post.createdAt),
      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    ),
    IconButton(
      icon: Icon(AppIcons.moreVert, size: 16),
      onPressed: showMenu,
    ),
  ],
)
```

---

## 5. FilterBar (필터/정렬)

### 기본 정보

- **파일**: `lib/features/timeline/presentation/widgets/filter_bar.dart`
- **웹 참조**: `miniline/src/lib/components/FilterBar.svelte`

### 레이아웃

```
[🔍 검색] [🏷️ 태그] [📅 날짜] [↕ 정렬] [⟳]
```

### 상세 스펙

```dart
Row(
  children: [
    Expanded(
      child: TextField(
        decoration: InputDecoration(
          hintText: 'filter.search_placeholder'.tr(),
          prefixIcon: Icon(AppIcons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    SizedBox(width: 8),
    IconButton(
      icon: Icon(AppIcons.filter),
      onPressed: showFilterDialog,
    ),
    IconButton(
      icon: Icon(AppIcons.calendar),
      onPressed: showDatePicker,
    ),
    IconButton(
      icon: Icon(AppIcons.sort),
      onPressed: showSortMenu,
    ),
    IconButton(
      icon: Icon(AppIcons.refresh),
      onPressed: refresh,
    ),
  ],
)
```

---

## 6. PostDetailPage (공개글 상세)

### 기본 정보

- **파일**: `lib/features/posts/presentation/pages/post_detail_page.dart`
- **패키지**: `flutter_markdown: ^0.7.4+1`
- **웹 참조**: 웹 버전과 유사하나 Markdown 렌더링 라이브러리 차이

### 레이아웃

```
┌─────────────────────────────────────────┐
│ ← Posts                        [⋮]      │ ← AppBar
├─────────────────────────────────────────┤
│ 제목 (headlineSmall, bold)              │
│ [템플릿 타입] 2025-01-13   [공개/비공개]│ ← 메타 정보
├─────────────────────────────────────────┤
│                                         │
│ Markdown 본문 렌더링                    │
│ # 제목 (headlineMedium, bold)          │
│ ## 부제목 (titleLarge, bold)           │
│ 본문 내용... (bodyLarge)                │
│                                         │
├─────────────────────────────────────────┤
│ 공개글로 전환           [toggle]         │ ← SwitchListTile (Card)
│ 공개 시 다른 사용자도 볼 수 있습니다      │
├─────────────────────────────────────────┤
│ ⭐ 버전                                 │ (version > 1일 때만)
│ 버전 2                                  │
├─────────────────────────────────────────┤
│ 🔗 내보낸 플랫폼                         │ (exportedTo가 있을 때만)
│ Medium, Notion                          │
├─────────────────────────────────────────┤
│ 📄 사용된 Fragment                      │
│ 5개의 Fragment로 작성되었습니다          │
└─────────────────────────────────────────┘
```

### 상세 스펙

#### Markdown 렌더링

**패키지:** flutter_markdown ^0.7.4+1

**❌ 웹 버전처럼 HTML 사용:**
```dart
// 웹: marked 라이브러리 사용
const htmlContent = marked(post.content);
```

**✅ Flutter에서 Markdown 직접 렌더링:**
```dart
MarkdownBody(
  data: post.content,
  styleSheet: MarkdownStyleSheet(
    p: textTheme.bodyLarge,
    h1: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
    h2: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    h3: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  ),
)
```

**이유:**
- Flutter는 HTML 렌더링보다 Markdown 직접 렌더링이 효율적
- flutter_markdown이 Material Design과 잘 통합됨
- 웹 버전 (marked)보다 가볍고 빠름

#### 공개 여부 토글

**크기:** Card 내부 SwitchListTile
**상태:** post.isPublic (true/false)

**❌ 단순 Switch만 사용:**
```dart
Switch(
  value: post.isPublic,
  onChanged: (_) => _togglePublic(),
)
```

**✅ Card + SwitchListTile로 명확한 설명:**
```dart
Card(
  child: SwitchListTile(
    title: Text('posts.make_public'.tr()),
    subtitle: Text('posts.make_public_description'.tr()),
    value: post.isPublic,
    onChanged: (_) => _togglePublic(),
  ),
)
```

**동작:**
1. 토글 시 Isar 로컬 업데이트
2. synced = false 설정 (동기화 큐 추가)
3. setState()로 UI 즉시 갱신
4. SnackBar로 변경 알림

#### viewed 플래그 자동 업데이트

**시점:** 화면 진입 시 (initState)

**로직:**
```dart
// viewed = false → true 업데이트
if (post != null && !post.viewed) {
  post.viewed = true;
  await isar.writeTxn(() => isar.posts.put(post));
}
```

**이유:**
- 사용자가 Post를 확인했음을 표시
- 헤더 뱃지 업데이트에 사용 (미확인 Post 개수)
- 웹과 동기화되어 한 기기에서 확인하면 모든 기기에서 뱃지 제거

#### 메타 정보 표시

**템플릿 타입:** primaryContainer 배경
- product_review: 제품 사용기
- timeline: 시간순 스토리
- essay: 생각 정리
- travel: 여행기
- project: 프로젝트 기록

**작성일:** yyyy-MM-dd 형식

**공개 여부 아이콘:**
- 공개: `AppIcons.language` (지구본)
- 비공개: `AppIcons.password` (자물쇠)

#### 선택사항 카드들

**1. 버전 정보 (version > 1):**
```dart
if (_post!.version > 1) ...[
  Card(
    child: ListTile(
      leading: Icon(AppIcons.star),
      title: Text('posts.version'.tr()),
      subtitle: Text('posts.version_info'.tr(args: [version.toString()])),
    ),
  ),
]
```

**2. 내보내기 정보 (exportedTo.isNotEmpty):**
```dart
if (_post!.exportedTo.isNotEmpty) ...[
  Card(
    child: ListTile(
      leading: Icon(AppIcons.share),
      title: Text('posts.exported_to'.tr()),
      subtitle: Text(_post!.exportedTo.join(', ')),
    ),
  ),
]
```

**3. Fragment 개수 (항상 표시):**
```dart
Card(
  child: ListTile(
    leading: Icon(AppIcons.fileText),
    title: Text('posts.fragments_used'.tr()),
    subtitle: Text('posts.fragments_count'.tr(
      args: [_post!.fragmentIds.length.toString()],
    )),
  ),
)
```

#### 삭제 기능

**진입:** AppBar 우측 더보기 메뉴 (`AppIcons.moreVert`)

**플로우:**
1. 더보기 메뉴 표시 (ModalBottomSheet)
2. 삭제 항목 선택
3. 확인 다이얼로그 (`AlertDialog`)
4. 확인 시 `post.deleted = true` 설정
5. Isar에 저장 (동기화 큐 추가)
6. SnackBar 표시 후 pop()

### 웹 버전과의 차이점

| 항목 | 웹 (miniline) | 앱 (miniline_app) |
|------|--------------|------------------|
| Markdown 렌더링 | marked (HTML 변환) | flutter_markdown (직접 렌더링) |
| 공개 토글 | 버튼 클릭 | SwitchListTile |
| 삭제 | 인라인 버튼 | 더보기 메뉴 |
| 메타 정보 | 상단 고정 | 스크롤 가능 |

### 언제 읽어야 하는가

- Posts 상세 화면 구현 시
- Markdown 렌더링 방법 확인 시
- Post 메타 정보 표시 방법 확인 시
- 웹 버전과 차이점 확인 시

---

## 7. 알림 설정 (Notification Settings)

> 앱 전용 기능 (웹 버전 없음)

**언제 읽어야 하는가:**
- Settings 알림 UI 구현 시
- 알림 설정 저장/로드 구현 시

### 7.1 DailyReminderSheet (일일 리마인더 설정)

**파일:** `lib/features/settings/presentation/widgets/daily_reminder_sheet.dart`

**구조:**
- 바텀시트 (showModalBottomSheet)
- 헤더 (아이콘 + 제목 + 닫기 버튼)
- 설명 텍스트
- ON/OFF 스위치
- 시간 선택 (TimePicker)

**데이터 저장:**
```dart
// SharedPreferences 사용
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('daily_reminder_enabled', enabled);
await prefs.setInt('daily_reminder_hour', hour);
await prefs.setInt('daily_reminder_minute', minute);
```

**LocalNotificationService 연동:**
```dart
if (enabled) {
  await LocalNotificationService().scheduleDailyReminder(
    hour: hour,
    minute: minute,
    title: 'timeline.title'.tr(),
    body: 'common.input_placeholder'.tr(),
  );
} else {
  await LocalNotificationService().cancelDailyReminder();
}
```

**UI 요소:**
- 헤더 높이: 56dp
- 아이콘 크기: 24dp
- Padding: 16dp
- SwitchListTile (Material Design)
- TimeOfDay 선택 → TimePicker

### 7.2 DraftNotificationSheet (Draft 완성 알림 설정)

**파일:** `lib/features/settings/presentation/widgets/draft_notification_sheet.dart`

**구조:**
- 바텀시트 (showModalBottomSheet)
- 헤더 (아이콘 + 제목 + 닫기 버튼)
- 설명 텍스트
- ON/OFF 스위치

**데이터 저장:**
```dart
// SharedPreferences 사용
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('draft_notification_enabled', enabled);
```

**기본값:**
- 기본: true (켜짐)
- Draft 생성 시 FCM 푸시 수신 여부 제어

**UI 요소:**
- 헤더 높이: 56dp
- 아이콘 크기: 24dp
- Padding: 16dp
- SwitchListTile (Material Design)
- subtitle: "알림 켜짐" / "알림 꺼짐"

### 번역 키

**settings:**
```
settings.notifications: "알림"
settings.daily_reminder: "일일 리마인더"
settings.daily_reminder_description: "매일 정해진 시간에 알림"
settings.draft_notifications: "초안 완성 알림"
settings.draft_notifications_description: "AI가 초안을 생성하면 알림"
settings.select_time: "시간 선택"
settings.notification_time: "알림 시간"
```

**common:**
```
common.enable: "사용"
common.notifications_on: "알림 켜짐"
common.notifications_off: "알림 꺼짐"
```

---

## 📋 체크리스트

**컴포넌트 구현 시 필수 확인:**
- [ ] 웹 버전과 동일한 크기 사용 (px to dp 1:1)
- [ ] 테마 색상 사용 (하드코딩 금지)
- [ ] AppIcons 사용 (직접 아이콘 사용 금지)
- [ ] 다국어 키 사용 (`.tr()`, 하드코딩 금지)
- [ ] 웹 버전과 동일한 동작 (키보드, 제스처)
- [ ] 엣지 케이스 처리 (빈 값, 최대값 초과 등)

---

**작성 후 확인:**
- [x] ❌/✅ 패턴 사용했는가?
- [x] "언제 읽어야 하는지" 명시했는가?
- [x] 전체 코드 복사하지 않았는가?
- [x] 웹 버전 참조 명시했는가?
