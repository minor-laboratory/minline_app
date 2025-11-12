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
