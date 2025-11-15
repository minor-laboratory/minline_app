# 컴포넌트 상세 스펙

> 웹 버전과 일관된 UI/UX를 위한 컴포넌트별 상세 규격

**언제 읽어야 하는가:**
- 컴포넌트 구현 시 (필수)
- UI 디테일 확인 시

## 📐 공통 규칙

### UI 라이브러리

**shadcn_ui 사용 (기본 원칙)**

```dart
import 'package:shadcn_ui/shadcn_ui.dart';

// ✅ shadcn_ui 컴포넌트 사용 (기본)
ShadButton(onPressed: _save, child: Text('common.save'.tr()))
ShadButton.outline(onPressed: _cancel, child: Text('common.cancel'.tr()))
ShadInput(placeholder: Text('snap.input_placeholder'.tr()))
ShadCard(title: Text('Title'), child: ...)
showShadDialog(context: context, builder: (context) => ShadDialog(...))

// ⚠️ Material 기본 위젯은 계속 사용 (Scaffold, AppBar, Column 등)
```

**상세 가이드:** [docs/MIGRATION_SHADCN.md](MIGRATION_SHADCN.md) 참조

### 색상 시스템

**테마 사용 필수** (하드코딩 금지):
```dart
// ❌ 하드코딩
Color(0xFF2563EB)
Colors.blue

// ✅ 테마 사용 (shadcn_ui가 자동 감지)
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
Icon(Icons.add)
Icon(LucideIcons.sparkles)

// ✅ AppIcons 사용
Icon(AppIcons.timeline)
Icon(AppIcons.sparkles)
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
      top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
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
// 단일 줄 입력 (자동 확장, 최대 3줄)
ShadInput(
  controller: _contentController,
  enabled: !_isLoading,
  placeholder: Text('snap.input_placeholder'.tr()),
  minLines: 1,
  maxLines: 3,
  keyboardType: TextInputType.multiline,
  onChanged: (value) {
    // 300자 제한
    if (value.length > _maxLength) {
      _contentController.text = value.substring(0, _maxLength);
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _maxLength),
      );
    }
    setState(() {});
  },
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

### SafeArea 처리 (필수)

**문제:** bottomNavigationBar에서 하단 시스템 바 (홈 인디케이터) 영역 침범

**❌ 잘못된 패딩 (고정값):**
```dart
Container(
  padding: EdgeInsets.all(16),  // 시스템 바 영역 침범
  child: FragmentInput(),
)
```

**✅ 올바른 패딩 (MediaQuery 사용):**
```dart
final bottomPadding = MediaQuery.of(context).padding.bottom;

Container(
  padding: EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: 16 + bottomPadding,  // 시스템 바 높이만큼 추가
  ),
  child: FragmentInput(),
)
```

**SafeArea 처리 (권장):**
```dart
// ✅ SafeArea: 시스템 바 영역 자동 처리
return SafeArea(
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      border: Border(
        top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 입력 UI
      ],
    ),
  ),
);
```

**이유:** SafeArea가 시스템 바, 노치 등을 자동으로 처리하므로 더 안전하고 간단합니다.

**iOS vs Android:**
- iOS: 홈 인디케이터 영역 약 34dp
- Android (제스처 네비게이션): 약 16-20dp
- Android (버튼 네비게이션): 0dp (시스템이 자동 처리)

**네이티브 설정 (Android):**
- **파일**: `android/app/src/main/kotlin/com/minorlab/miniline/MainActivity.kt`
- **내용**: Edge-to-edge 설정으로 시스템 바 투명화 (북랩 앱 패턴 참조)
```kotlin
// Edge-to-edge 설정 (시스템 바 투명화)
WindowCompat.setDecorFitsSystemWindows(window, false)
window.statusBarColor = android.graphics.Color.TRANSPARENT
window.navigationBarColor = android.graphics.Color.TRANSPARENT
```

**적용 위치:**
- bottomNavigationBar
- 하단 고정 버튼
- 바텀시트 하단
- 스크롤 가능 리스트의 마지막 항목 (padding: EdgeInsets.only(bottom: bottomPadding))

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
        color: Colors.black.withValues(alpha: 0.05),
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
    color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
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
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
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

**드롭다운 메뉴** (ShadSheet 사용):
```dart
// ❌ 잘못: ListTile 직접 사용 (Material ancestor 없음)
showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    child: ListTile(onTap: () {}),  // 에러!
  ),
);

// ✅ 올바름: Material + InkWell 또는 GestureDetector
showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    title: Text('common.more'.tr()),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              _handleEdit();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(AppIcons.edit, size: 20),
                  const SizedBox(width: 12),
                  Text('common.edit'.tr()),
                ],
              ),
            ),
          ),
        ),
        // 구분선
        const Divider(height: 1),
        // 삭제 (빨강)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteDialog();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(AppIcons.delete, size: 20, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text('common.delete'.tr(), style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
```

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
        color: getStatusColor(draft.status).withValues(alpha: 0.1),
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
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
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

> 검색, 태그 필터, 정렬 기능을 제공하는 Timeline 필터 바

**언제 읽어야 하는가:**
- Timeline 검색/필터 기능 구현 시
- ShadInput 기반 검색 UI 참조 시
- 태그 필터링 UI 확인 시

### 기본 정보

- **파일**: `lib/features/timeline/presentation/widgets/filter_bar.dart`
- **웹 참조**: `miniline/src/lib/components/FilterBar.svelte`

### 레이아웃

```
┌────────────────────────────────────────────────────┐
│ [#태그1 ✕] [#태그2 ✕] 검색...  [정렬▼] [↕]      │
└────────────────────────────────────────────────────┘
```

### 구조

```dart
Row(
  children: [
    // 검색 입력 (태그 Pills 포함)
    Expanded(
      child: Focus(
        onKeyEvent: (node, event) {
          // Backspace로 마지막 태그 삭제
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
          focusNode: _focusNode,
          placeholder: filter.selectedTags.isEmpty
              ? Text('filter.search_placeholder'.tr())
              : null,
          onChanged: (value) {
            ref.read(fragmentFilterProvider.notifier).setQuery(value);
          },
          style: const TextStyle(fontSize: 14),
          leading: filter.selectedTags.isNotEmpty
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filter.selectedTags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            Text(tag, style: TextStyle(fontSize: 12)),
                            SizedBox(width: 2),
                            GestureDetector(
                              onTap: () => removeTag(tag),
                              child: Icon(AppIcons.close, size: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : null,
        ),
      ),
    ),
    SizedBox(width: 8),

    // 정렬 버튼
    PopupMenuButton<String>(
      icon: Icon(AppIcons.sort),
      tooltip: 'filter.sort'.tr(),
      onSelected: (value) {
        ref.read(fragmentFilterProvider.notifier).setSortBy(value);
      },
      itemBuilder: (context) => [
        _buildSortMenuItem('event', 'filter.sort_event'.tr()),
        _buildSortMenuItem('created', 'filter.sort_created'.tr()),
        _buildSortMenuItem('updated', 'filter.sort_updated'.tr()),
      ],
    ),

    // 정렬 방향 토글
    ShadIconButton.ghost(
      icon: Icon(
        filter.sortOrder == 'desc' ? AppIcons.arrowDown : AppIcons.arrowUp,
        size: 20,
      ),
      onPressed: () {
        ref.read(fragmentFilterProvider.notifier).toggleSortOrder();
      },
    ),
  ],
)
```

### 핵심 기능

#### 1. 태그 Pills (인라인 태그 표시)

선택된 태그를 검색창 내부 왼쪽에 pill 형태로 표시:

```dart
leading: filter.selectedTags.isNotEmpty
    ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filter.selectedTags.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9999), // rounded-full
              ),
              child: Row(
                children: [
                  Text(tag, style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                  SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => ref.read(fragmentFilterProvider.notifier).removeTag(tag),
                    child: Icon(AppIcons.close, size: 12, color: colorScheme.primary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      )
    : null,
```

#### 2. 키보드 단축키

- **Backspace** (빈 입력창): 마지막 태그 삭제
- **일반 입력**: 실시간 검색

```dart
Focus(
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
  child: ShadInput(...),
)
```

#### 3. 정렬 메뉴

선택된 항목 표시:

```dart
PopupMenuItem<String> _buildSortMenuItem(String value, String label, bool isSelected) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Text(label),
        if (isSelected) ...[
          Spacer(),
          Icon(AppIcons.checkCircle, size: 16, color: colorScheme.primary),
        ],
      ],
    ),
  );
}
```

### 웹과의 차이점

| 항목 | 웹 (miniline) | 앱 (miniline_app) |
|------|--------------|------------------|
| 검색 입력 | 일반 `<input>` | ShadInput |
| 태그 Pills | bg-primary/10 | colorScheme.primary.withValues(alpha: 0.1) |
| 정렬 UI | `<select>` 태그 | PopupMenuButton |
| Border | rounded-md (6px) | 테마 radius (12px) |

---

## 6. TagEditPage (태그 추가 페이지)

> 모바일 텍스트 입력 원칙 준수: Dialog/Sheet 대신 페이지 사용

**언제 읽어야 하는가:**
- Fragment 태그 관리 구현 시
- 사용자 태그 추가/편집 UI 확인 시
- 모바일 텍스트 입력 패턴 참조 시

### 기본 정보

- **파일**: `lib/features/timeline/presentation/pages/tag_edit_page.dart`
- **라우트**: `/tag/edit/:fragmentId`
- **참조**: [MOBILE_DIALOG_SHEET_RULES.md](MOBILE_DIALOG_SHEET_RULES.md) - 텍스트 입력은 페이지로

### 레이아웃

```
┌─────────────────────────────────────────┐
│ ✕ 태그 추가                    [저장]   │ ← AppBar
├─────────────────────────────────────────┤
│ 이 스냅에 추가할 태그를 입력하세요       │ ← 설명
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ 태그 입력...                        ││ ← ShadInput (autofocus)
│ └─────────────────────────────────────┘│
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ ℹ 태그는 스냅을 분류하고 필터링하는 ││ ← 힌트
│ │   데 사용됩니다                     ││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### 상세 스펙

#### AppBar

```dart
AppBar(
  title: Text('tag.add_tag'.tr()),
  leading: IconButton(
    icon: Icon(AppIcons.close),
    onPressed: () => context.pop(),
  ),
  actions: [
    ShadButton(
      enabled: _tagController.text.trim().isNotEmpty,
      onPressed: _save,
      child: Text('common.save'.tr()),
    ),
    SizedBox(width: 8),
  ],
)
```

#### 입력 필드

```dart
ShadInput(
  controller: _tagController,
  focusNode: _focusNode,
  placeholder: Text('tag.add_tag_placeholder'.tr()),
  onChanged: (value) => setState(() {}), // 저장 버튼 활성화 상태 업데이트
  onSubmitted: (value) => _save(),
)
```

#### 자동 포커스

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _focusNode.requestFocus();
  });
}
```

#### 저장 및 반환

```dart
void _save() {
  final tag = _tagController.text.trim();
  if (tag.isEmpty) return;
  context.pop(tag);  // 결과 반환
}
```

### FragmentCard 통합

#### 태그 추가 페이지 열기

```dart
Future<void> _showAddTagPage() async {
  logger.d('태그 추가 페이지 이동: ${widget.fragment.remoteID}');

  final tag = await context.push<String>('/tag/edit/${widget.fragment.remoteID}');

  logger.d('입력한 태그: $tag');
  if (tag == null || tag.isEmpty) {
    logger.d('태그 입력 취소됨');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final isar = DatabaseService.instance.isar;
    logger.d('Isar 트랜잭션 시작 - Fragment ID: ${widget.fragment.id}');

    await isar.writeTxn(() async {
      // ⚠️ 중요: 트랜잭션 내부에서 다시 읽기 (Isar 필수)
      final fragment = await isar.fragments.get(widget.fragment.id);
      if (fragment == null) {
        logger.e('Fragment를 찾을 수 없음: ${widget.fragment.id}');
        return;
      }

      logger.d('현재 userTags: ${fragment.userTags}');

      if (!fragment.userTags.contains(tag)) {
        fragment.userTags.add(tag);
        fragment.synced = false;
        fragment.refreshAt = DateTime.now();
        await isar.fragments.put(fragment);
        logger.i('✅ 태그 추가 완료: $tag, 전체 태그: ${fragment.userTags}');
      } else {
        logger.d('이미 존재하는 태그: $tag');
      }
    });

    logger.d('onUpdate 호출');
    widget.onUpdate?.call();
  } catch (e, stack) {
    logger.e('태그 추가 실패', e, stack);
  } finally {
    setState(() => _isLoading = false);
  }
}
```

#### 태그 삭제

```dart
Future<void> _handleRemoveUserTag(String tag) async {
  setState(() => _isLoading = true);

  try {
    final isar = DatabaseService.instance.isar;
    await isar.writeTxn(() async {
      // 트랜잭션 내부에서 다시 읽기 (Isar 필수)
      final fragment = await isar.fragments.get(widget.fragment.id);
      if (fragment == null) return;

      fragment.userTags.removeWhere((t) => t == tag);
      fragment.synced = false;
      fragment.refreshAt = DateTime.now();
      await isar.fragments.put(fragment);
    });

    widget.onUpdate?.call();
  } catch (e, stack) {
    logger.e('태그 삭제 실패', e, stack);
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Isar 트랜잭션 주의사항

⚠️ **중요**: Isar에서 객체를 수정할 때는 **트랜잭션 내부에서 다시 읽어야** 합니다.

**❌ 잘못된 방법**:
```dart
await isar.writeTxn(() async {
  widget.fragment.userTags.add(tag); // Widget 객체 직접 수정
  await isar.fragments.put(widget.fragment);
});
```

**✅ 올바른 방법**:
```dart
await isar.writeTxn(() async {
  final fragment = await isar.fragments.get(widget.fragment.id);
  if (fragment == null) return;

  fragment.userTags.add(tag);
  fragment.synced = false;
  fragment.refreshAt = DateTime.now();
  await isar.fragments.put(fragment);
});
```

### 웹과의 차이점

| 항목 | 웹 (miniline) | 앱 (miniline_app) |
|------|--------------|------------------|
| 태그 추가 UI | 인라인 입력 (Sheet) | 전용 페이지 (TagEditPage) |
| 키보드 처리 | 자동 | 자동 포커스 + Enter 저장 |
| 태그 삭제 | Hover → X 버튼 | GestureDetector → X 버튼 |
| 페이지 이동 | N/A | context.push('/tag/edit/:id') |

### 모바일 원칙

**❌ Dialog/Sheet 사용 금지**:
```dart
// 절대 금지!
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    child: ShadInput(),  // 텍스트 입력 금지
  ),
);
```

**✅ 페이지 사용**:
```dart
// 올바른 방법
final tag = await context.push<String>('/tag/edit/:fragmentId');
```

**이유**: [MOBILE_DIALOG_SHEET_RULES.md](MOBILE_DIALOG_SHEET_RULES.md) 참조 - 텍스트 입력은 키보드 관리와 UX 문제로 페이지로만 구현

---

## 7. PostCreatePage (글 생성 화면)

### 기본 정보

- **파일**: `lib/features/posts/presentation/pages/post_create_page.dart`
- **패키지**: `supabase_flutter` (SSE), `shadcn_ui` (버튼, 카드)
- **웹 참조**: 웹 버전과 UI 차이 (드롭다운 → 그리드 카드)

### 레이아웃

```
┌─────────────────────────────────────────┐
│ ← 글 만들기              [생성하기 ✨]  │ ← AppBar
├─────────────────────────────────────────┤
│ 📄 제안                                 │
│ AI가 관련있는 스냅들을 묶어 제안했어요  │
│                                         │
│ 템플릿 선택                              │
│ ┌────────────┐ ┌────────────┐          │
│ │ 📝 생각정리 │ │ ⏱️ 시간순  │          │ ← 그리드 (2열)
│ └────────────┘ └────────────┘          │
│ ┌────────────┐ ┌────────────┐          │
│ │ 📦 제품사용│ │ ✈️ 여행기  │          │
│ └────────────┘ └────────────┘          │
│ ┌────────────┐                          │
│ │ 🚀 프로젝트│                          │
│ └────────────┘                          │
│                                         │
│ 미리보기                                │
│ ━━━━━━━━━━━━━━━━ 65% ━━━━━━━━━━━━━━━━│ ← Progress bar
│ ┌─────────────────────────────────────┐│
│ │ # 제목이 여기에 나타납니다_         ││ ← 실시간 타이핑
│ │                                     ││
│ │ 본문 내용이 스트리밍으로 추가됩니다 ││
│ │                                     ││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### 상세 스펙

**템플릿 카드** (`_buildTemplateCard`):
```dart
Card(
  color: isSelected ? primaryContainer : null,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: isSelected
        ? BorderSide(color: primary, width: 2)
        : BorderSide.none,
  ),
  child: Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? primary : surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(template.icon),
      ),
      Column(
        children: [
          Text(template.nameKey.tr()), // 예: "생각 정리"
          Text(template.descKey.tr()), // 예: "자유로운 형식으로..."
        ],
      ),
      if (isSelected) Icon(AppIcons.checkCircle),
    ],
  ),
)
```

**5개 템플릿** (`lib/core/constants/post_templates.dart`):
1. **Essay** (생각 정리): 자유로운 형식
2. **Timeline** (시간순 스토리): 시간 순서대로
3. **Product Review** (제품 사용기): 제품 경험 상세히
4. **Travel** (여행기): 여행 경험 생생하게
5. **Project** (프로젝트 기록): 프로젝트 과정 체계적으로

**AI 생성 상태**:
```dart
// Progress bar
LinearProgressIndicator(
  value: _progress / 100, // 0.0 ~ 1.0
  minHeight: 6,
)
Text('${_progress.toInt()}%')

// 실시간 타이핑
Row(
  children: [
    Expanded(child: Text(_generatingContent)),
    if (_isGenerating) _CursorBlinker(), // 깜빡이는 커서
  ],
)

// 커서 애니메이션
class _CursorBlinker extends StatefulWidget {
  // FadeTransition으로 500ms 반복
  AnimationController(duration: 500ms)..repeat(reverse: true);
}
```

**에러 처리**:
```dart
if (_errorMessage != null)
  Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(AppIcons.error, color: error),
        Text(_errorMessage!),
      ],
    ),
  )
```

- Fragment 2개 미만: `post.not_enough_fragments`
- 무료 한도 초과: `post.free_limit_exceeded`

**재생성 지원**:
- `previousVersionId` 쿼리 파라미터로 전달
- Edge Function에서 이전 버전 참고하여 새 버전 생성
- 라우트: `/posts/create/:draftId?previousVersionId=:postId`

### Edge Function 연동 (SSE)

**함수 이름**: `generate-post`

**요청**:
```json
{
  "draftId": "uuid",
  "fragmentIds": ["uuid1", "uuid2", ...],
  "template": "essay",
  "previousVersionId": "uuid" // 재생성 시만
}
```

**응답 (Server-Sent Events)**:
```
data: {"type": "title", "content": "제목"}

data: {"type": "content", "content": "본문 일부"}
data: {"type": "content", "content": "더 많은 본문"}
...

data: {"type": "done", "postId": "uuid"}
```

또는 에러:
```
data: {"type": "error", "message": "free_limit_exceeded"}
```

### 검증 사항

- [x] 템플릿 선택 시 border + primaryContainer 색상 변경
- [x] AI 생성 중 progress bar 0-100% 진행
- [x] 타이핑 애니메이션 (한 글자씩 추가)
- [x] 커서 깜빡임 (500ms 반복)
- [x] 생성 완료 후 Post 상세 페이지로 이동 (`/posts/:postId`)
- [x] Fragment 2개 미만 시 에러 메시지
- [x] 재생성 시 previousVersionId 전달

---

## 7. PostDetailPage (공개글 상세)

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
| Preview/Source 모드 | 없음 | 토글 버튼 |
| Markdown 내보내기 | 브라우저 다운로드 | share_plus (공유 시트) |
| Fragment 목록 표시 | 항상 표시 | 토글 버튼 (접기/펼치기) |
| 재생성 | 별도 페이지 | 더보기 메뉴 |
| 피드백 신고 | 모달 | 더보기 메뉴 → FeedbackDialog |

### 신규 기능 (앱 전용)

#### Fragment 목록 토글

**위치**: Post 하단

**UI**:
```dart
ShadButton.ghost(
  onPressed: () => setState(() => _showFragments = !_showFragments),
  child: Row(
    children: [
      Icon(_showFragments ? AppIcons.chevronDown : AppIcons.chevronRight),
      Text('draft.snap_count'.tr(namedArgs: {'count': fragments.length})),
    ],
  ),
)

if (_showFragments) ...fragments.map((f) =>
  Card(
    child: Column(
      children: [
        Text(f.content),
        Text(DateFormat('MMM d, HH:mm').format(f.eventTime)),
        // AI 태그 (최대 3개)
        Wrap(children: f.tags.take(3).map((tag) => Chip(tag))),
      ],
    ),
  ),
)
```

#### Markdown 내보내기

**위치**: AppBar 우측

**동작**:
```dart
Future<void> _handleExport() async {
  final markdown = '# ${_post.title}\n\n${_post.content}';
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/${_post.title}.md');
  await file.writeAsString(markdown);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: _post.title,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('post.export_success'.tr())),
  );
}
```

#### 재생성 기능

**위치**: 더보기 메뉴

**조건**: `_post.draftId != null` 일 때만 표시

**동작**:
```dart
Future<void> _handleRegenerate() async {
  final confirmed = await showShadDialog<bool>(
    context: context,
    builder: (context) => ShadDialog(
      title: Text('post.regenerate'.tr()),
      description: Text('post.regenerate_confirm'.tr()),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(false),
          child: Text('common.cancel'.tr()),
        ),
        ShadButton(
          onPressed: () => Navigator.pop(true),
          child: Text('post.regenerate'.tr()),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    context.push(
      '/posts/create/${_post.draftId}?previousVersionId=${_post.remoteID}',
    );
  }
}
```

#### 피드백 신고

**위치**: 더보기 메뉴

**동작**:
```dart
Future<void> _handleFeedback() async {
  // 중복 제출 체크
  final hasExisting = await FeedbackService.instance.checkExistingFeedback(
    targetType: 'post',
    targetId: _post.remoteID,
  );

  if (hasExisting) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('feedback.error_already_submitted'.tr())),
    );
    return;
  }

  await showShadDialog<bool>(
    context: context,
    builder: (context) => FeedbackDialog(
      targetType: 'post',
      targetId: _post.remoteID,
    ),
  );
}
```

**신고 사유** (`FeedbackTemplates.post`):
1. **inaccurate**: 부정확한 내용
2. **poor_writing**: 글쓰기 품질 낮음
3. **wrong_tone**: 톤앤매너 잘못됨
4. **too_short**: 너무 짧음

#### Preview/Source 모드 토글

**위치**: Post 내용 상단

**UI**:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    _viewMode == 'preview'
        ? ShadButton(onPressed: null, child: Text('post.show_preview'.tr()))
        : ShadButton.outline(
            onPressed: () => setState(() => _viewMode = 'preview'),
            child: Text('post.show_preview'.tr()),
          ),
    _viewMode == 'source'
        ? ShadButton(onPressed: null, child: Text('post.show_source'.tr()))
        : ShadButton.outline(
            onPressed: () => setState(() => _viewMode = 'source'),
            child: Text('post.show_source'.tr()),
          ),
  ],
)
```

**렌더링**:
```dart
if (_viewMode == 'preview')
  MarkdownBody(
    data: _post.content,
    styleSheet: MarkdownStyleSheet(...),
  )
else
  Text(
    _post.content,
    style: textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
  )
```

### 언제 읽어야 하는가

- Posts 상세 화면 구현 시
- Markdown 렌더링 방법 확인 시
- Post 메타 정보 표시 방법 확인 시
- 웹 버전과 차이점 확인 시

---

## 7. ShadTabs (탭 버튼 패턴)

> 북랩 앱과 동일한 탭 패턴 (ShadTabs 사용, 컨텐츠는 수동 관리)

**언제 읽어야 하는가:**
- Drafts/Posts 탭 구현 시
- 필터링된 리스트 표시 시
- 북랩 앱과 동일한 패턴 적용 시

### 기본 정보

**파일**: `lib/features/drafts/presentation/pages/drafts_page.dart`
**참조**: 북랩 `minorlab_book/lib/features/library/presentation/pages/library_page.dart`

### 패턴 설명

**핵심**: ShadTabs는 **탭 버튼만** 제공. 컨텐츠는 직접 관리.

**❌ 잘못된 패턴 (웹 방식):**
```dart
// 웹: ShadTabs가 컨텐츠도 관리
ShadTabs(
  value: currentTab,
  tabs: [
    ShadTab(value: 'all', child: Text('All')),
    ShadTab(value: 'pending', child: Text('Pending')),
  ],
  tabContents: [
    TabContent(value: 'all', child: AllDraftsList()),
    TabContent(value: 'pending', child: PendingDraftsList()),
  ],
)
```

**✅ 올바른 패턴 (북랩 방식):**
```dart
// 앱: ShadTabs는 탭 버튼만, 컨텐츠는 수동 관리
Column(
  children: [
    // 1. 탭 버튼만 표시
    ShadTabs<String>(
      value: filter.status,
      onChanged: (value) {
        ref.read(draftFilterProvider.notifier).setStatus(value);
      },
      scrollable: true,
      tabs: [
        ShadTab(value: 'all', child: Text('draft.filter_all'.tr())),
        ShadTab(value: 'pending', child: Text('draft.filter_pending'.tr())),
        ShadTab(value: 'accepted', child: Text('draft.filter_accepted'.tr())),
        ShadTab(value: 'rejected', child: Text('draft.filter_rejected'.tr())),
      ],
    ),

    // 2. 탭 컨텐츠는 별도 위젯으로 관리
    Expanded(
      child: _DraftTabContent(
        status: filter.status,
        draftsStream: draftsStream,
      ),
    ),
  ],
)
```

### 탭 컨텐츠 위젯

```dart
class _DraftTabContent extends StatelessWidget {
  final String status;
  final AsyncValue<List<Draft>> draftsStream;

  @override
  Widget build(BuildContext context) {
    return draftsStream.when(
      data: (allDrafts) {
        // 필터링
        final filteredDrafts = status == 'all'
            ? allDrafts
            : allDrafts.where((d) => d.status == status).toList();

        if (filteredDrafts.isEmpty) {
          return Center(child: Text('draft.empty_filter'.tr()));
        }

        return ListView.builder(
          itemCount: filteredDrafts.length,
          itemBuilder: (context, index) {
            return DraftCard(draft: filteredDrafts[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}
```

### 주의사항

1. **탭 버튼만**: ShadTabs는 UI만 제공, 컨텐츠는 직접 관리
2. **scrollable**: 다국어 텍스트 길이 차이 대응
3. **onChanged**: 필터 상태 업데이트
4. **별도 위젯**: 탭 컨텐츠는 별도 위젯으로 분리
5. **maxLines**: 탭 텍스트가 길어질 수 있으므로 ellipsis 처리

---

## 8. StandardBottomSheet (공통 바텀시트 패턴)

> 북랩 앱과 동일한 바텀시트 패턴 (Wolt Modal Sheet 기반)

**언제 읽어야 하는가:**
- Settings 시트 구현 시
- 바텀시트 UI 구현 시
- 북랩 앱과 동일한 패턴 적용 시

### 기본 정보

**파일:**
- `lib/shared/widgets/standard_bottom_sheet.dart`
- `lib/shared/widgets/responsive_modal_sheet.dart`

**패키지:** `wolt_modal_sheet: ^0.11.0`

**참조:**
- 북랩: `minorlab_book/lib/shared/widgets/standard_bottom_sheet.dart`
- 북랩: `minorlab_book/lib/shared/widgets/responsive_modal_sheet.dart`

### 구조

**ResponsiveModalSheet**: WoltModalSheet 래퍼
- 모바일: 바텀시트
- 태블릿 (600dp 이상): 다이얼로그
- 드래그/탭으로 닫기 제어

**StandardBottomSheet**: 표준화된 바텀시트
- Material widget context 제공 (InkWell 등 Material 위젯 사용 가능)
- 타이틀 헤더 자동 제공
- 일관된 패딩 및 스타일

### 사용 방법

**❌ ShadSheet 사용 (이전 방식):**
```dart
void _showSettings() {
  showShadSheet(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (context) => ThemeSettingsSheet(),
  );
}
```

**✅ StandardBottomSheet 사용 (북랩 패턴):**
```dart
void _showThemeSettings() {
  StandardBottomSheet.show(
    context: context,
    title: 'settings.theme'.tr(),
    content: const ThemeSettingsSheet(),
    isDraggable: true,
    isDismissible: true,
  );
}
```

### 시트 내부 구조

**❌ 자체 헤더 포함 (중복):**
```dart
class ThemeSettingsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // ❌ StandardBottomSheet가 이미 제공하는 헤더
        Row(
          children: [
            Text('settings.theme'.tr()),
            IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        // 실제 컨텐츠
        ...
      ],
    );
  }
}
```

**✅ 컨텐츠만 포함:**
```dart
class ThemeSettingsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // StandardBottomSheet.show()의 title로 헤더 제공됨
        // 바로 컨텐츠 시작
        ...
      ],
    );
  }
}
```

### Material Widget 문제 해결

**문제:** InkWell, InkResponse 등 Material 위젯이 Material ancestor를 요구

**❌ GestureDetector로만 대체 (터치 피드백 없음):**
```dart
GestureDetector(
  onTap: onTap,
  child: Container(...),
)
```

**✅ StandardBottomSheet 사용 (Material 제공):**
```dart
// StandardBottomSheet가 Material widget을 제공하므로
// InkWell 사용 가능
InkWell(
  onTap: onTap,
  child: Container(...),
)

// 또는 GestureDetector 사용 (더 간단)
GestureDetector(
  onTap: onTap,
  child: Container(...),
)
```

### 적용 예시

**ThemeSettingsSheet:**
```dart
// settings_page.dart
void _showThemeSettings() {
  StandardBottomSheet.show(
    context: context,
    title: 'settings.theme'.tr(),
    content: const ThemeSettingsSheet(),
  );
}

// theme_settings_sheet.dart
class ThemeSettingsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(common.Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 테마 모드 선택 (시스템/라이트/다크)
          Row(
            children: [
              _ThemeModeCard(...),
              _ThemeModeCard(...),
              _ThemeModeCard(...),
            ],
          ),
          // 배경색 선택
          // 컬러 스킴 선택
        ],
      ),
    );
  }
}
```

**LanguageSettingsSheet:**
```dart
// settings_page.dart
void _showLanguageSettings() {
  StandardBottomSheet.show(
    context: context,
    title: 'settings.language'.tr(),
    content: const LanguageSettingsSheet(),
  );
}

// language_settings_sheet.dart
class LanguageSettingsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 시스템 언어 사용 스위치
        ShadCard(
          child: SwitchListTile(...),
        ),
        // 언어 목록 (한국어, English)
        ShadCard(child: ListTile(...)),
        ShadCard(child: ListTile(...)),
      ],
    );
  }
}
```

### 주의사항

1. **헤더 중복 방지**: StandardBottomSheet.show()의 title로 제공되므로 시트 내부에 헤더 불필요
2. **Material 제공**: StandardBottomSheet가 Material widget을 제공하므로 InkWell 등 사용 가능
3. **mainAxisSize**: Column의 mainAxisSize는 MainAxisSize.min 사용 (자동 높이)
4. **SingleChildScrollView**: 컨텐츠가 길 경우 스크롤 가능하도록 감싸기

---

## 8. 알림 설정 (Notification Settings)

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

## 9. Isar Stream Provider 패턴 (watchLazy)

> Riverpod Stream Provider에서 Isar watchLazy() 사용 패턴

**언제 읽어야 하는가:**
- Provider에서 Isar 데이터 스트림 구현 시
- 빈 DB에서 무한 로딩 문제 해결 시
- 실시간 UI 갱신 구현 시

### 패턴 변경: Isar 직접 읽기 (2025-11-15)

**이전 패턴** (Stream 의존):
```dart
@riverpod
Stream<List<Draft>> filteredDrafts(Ref ref) async* {
  final draftsAsync = ref.watch(draftsStreamProvider);
  final filter = ref.watch(draftFilterProvider);

  await for (final drafts in draftsAsync) {
    final filtered = filterDrafts(drafts, filter);
    yield filtered;
  }
}
```

**새 패턴** (Isar 직접 읽기):
```dart
@riverpod
Stream<List<Draft>> filteredDrafts(Ref ref) async* {
  final isar = DatabaseService.instance.isar;
  final filter = ref.watch(draftFilterProvider);

  // 초기값 먼저 방출
  final initialDrafts = await isar.drafts
      .filter()
      .deletedEqualTo(false)
      .findAll();

  initialDrafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  yield filterDrafts(initialDrafts, filter);

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.drafts.watchLazy()) {
    final drafts = await isar.drafts
        .filter()
        .deletedEqualTo(false)
        .findAll();

    drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield filterDrafts(drafts, filter);
  }
}
```

**이유:**
- ✅ **필터 변경 즉시 반영**: filter 변경 시 바로 Isar 쿼리 재실행
- ✅ **불필요한 의존성 제거**: 다른 Stream Provider 의존 없음
- ✅ **명확한 로직**: Isar 쿼리 → 정렬 → 필터링 한눈에 파악
- ✅ **메모리 효율**: watchLazy로 변경 이벤트만 감지

**참조:**
- `lib/features/drafts/providers/drafts_provider.dart`
- `lib/features/timeline/providers/fragments_provider.dart`

### 문제: watchLazy()는 초기값을 emit하지 않음

**❌ 잘못된 패턴 (무한 로딩):**
```dart
@riverpod
Stream<List<Fragment>> fragmentsStream(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // watchLazy()는 변경 이벤트만 emit (초기값 없음)
  await for (final _ in isar.fragments.watchLazy()) {
    final fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    yield fragments;
  }
}
// 문제: DB가 비어있으면 watchLazy()가 emit하지 않음 → 무한 로딩
```

**✅ 올바른 패턴 (초기값 먼저 emit):**
```dart
@riverpod
Stream<List<Fragment>> fragmentsStream(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 1. 초기값 먼저 방출
  final initialFragments = await isar.fragments
      .filter()
      .deletedEqualTo(false)
      .findAll();

  initialFragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
      .compareTo(a.refreshAt ?? DateTime.now()));

  yield initialFragments;

  // 2. watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.fragments.watchLazy()) {
    final fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    fragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
        .compareTo(a.refreshAt ?? DateTime.now()));

    yield fragments;
  }
}
// 해결: 초기값을 먼저 emit하므로 빈 DB에서도 정상 동작
```

### 패턴 상세 설명

**1단계: 초기값 로드 및 emit**
```dart
// await으로 초기 데이터 로드
final initialFragments = await isar.fragments.filter().deletedEqualTo(false).findAll();

// yield로 초기값 즉시 방출 (UI가 데이터를 받음)
yield initialFragments;
```

**2단계: watchLazy()로 변경 감지**
```dart
// await for로 변경 이벤트를 계속 감지
await for (final _ in isar.fragments.watchLazy()) {
  // 변경 발생 시에만 데이터 다시 로드
  final fragments = await isar.fragments.filter().deletedEqualTo(false).findAll();
  yield fragments;
}
```

### 왜 watchLazy()를 사용하는가?

**watch() vs watchLazy():**

```dart
// ❌ watch(): 전체 데이터를 매번 emit (메모리 비효율적)
await for (final fragments in isar.fragments.watch()) {
  yield fragments;  // 변경 시마다 전체 리스트 emit
}

// ✅ watchLazy(): 변경 이벤트만 emit (메모리 효율적)
await for (final _ in isar.fragments.watchLazy()) {
  final fragments = await isar.fragments.findAll();  // 명시적으로 로드
  yield fragments;
}
```

**장점:**
- 메모리 효율적 (데이터를 중복 전송하지 않음)
- 필요한 시점에만 데이터 로드
- 대용량 데이터에서도 성능 유지

### 실제 예제

**fragmentsProvider (타임라인):**
```dart
@riverpod
Stream<List<Fragment>> fragmentsStream(Ref ref) async* {
  final isar = DatabaseService.instance.isar;

  // 초기값 먼저 방출
  final initialFragments = await isar.fragments
      .filter()
      .deletedEqualTo(false)
      .findAll();

  initialFragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
      .compareTo(a.refreshAt ?? DateTime.now()));

  yield initialFragments;

  // watchLazy로 변경 이벤트만 감지
  await for (final _ in isar.fragments.watchLazy()) {
    final fragments = await isar.fragments
        .filter()
        .deletedEqualTo(false)
        .findAll();

    fragments.sort((a, b) => (b.refreshAt ?? DateTime.now())
        .compareTo(a.refreshAt ?? DateTime.now()));

    yield fragments;
  }
}
```

**filteredFragments (검색/정렬 적용):**
```dart
@riverpod
Stream<List<Fragment>> filteredFragments(Ref ref) async* {
  final fragmentsAsync = ref.watch(fragmentsStreamProvider);
  final filterState = ref.watch(fragmentFilterProvider);

  // 초기값 먼저 방출
  await for (final fragments in fragmentsAsync) {
    final filtered = filterAndSort(fragments, filterState);
    yield filtered;
    break;  // 초기값만 방출하고 중단
  }

  // watchLazy로 변경 감지
  await for (final fragmentsValue in fragmentsAsync) {
    final filtered = filterAndSort(fragmentsValue, filterState);
    yield filtered;
  }
}

List<Fragment> filterAndSort(List<Fragment> fragments, FragmentFilterState filterState) {
  var result = fragments;

  // 검색어 필터링
  if (filterState.query.trim().isNotEmpty) {
    result = result.where((f) =>
      f.content.toLowerCase().contains(filterState.query.toLowerCase())
    ).toList();
  }

  // 정렬
  result.sort((a, b) {
    final aTime = filterState.sortBy == 'created' ? a.createdAt : a.refreshAt ?? DateTime.now();
    final bTime = filterState.sortBy == 'created' ? b.createdAt : b.refreshAt ?? DateTime.now();
    return filterState.sortOrder == 'desc'
      ? bTime.compareTo(aTime)
      : aTime.compareTo(bTime);
  });

  return result;
}
```

### 주의사항

1. **반드시 초기값 먼저 emit**: 빈 DB에서 무한 로딩 방지
2. **정렬은 emit 전에**: yield 전에 sort 완료
3. **필터 로직은 별도 함수로**: 재사용성 향상
4. **Stream Provider 사용**: FutureProvider가 아닌 StreamProvider 사용

### 참조

- 구현 파일:
  - `lib/features/timeline/providers/fragments_provider.dart`
  - `lib/features/drafts/providers/drafts_provider.dart`
  - `lib/features/posts/providers/posts_provider.dart`
- 패턴 출처: [북랩 Stream Provider 패턴](../../minorlab_book/lib/features/library/providers/)

---

## 10. Empty State (빈 상태 화면)

> Fragment 목록이 비어있을 때 표시되는 화면

**언제 읽어야 하는가:**
- Empty State UI 구현 시
- 빈 목록 화면 디자인 시

### 기본 정보

**파일**: `lib/features/timeline/presentation/widgets/fragment_list.dart`
**웹 참조**: 웹 버전도 유사한 Empty State 사용

### 레이아웃

```
┌─────────────────────────────────────────┐
│                                         │
│          [원형 아이콘 배경]              │  ← 64x64, sparkles
│                                         │
│          빈 상태 제목                    │
│          설명 텍스트                     │
│                                         │
│        [입력 힌트 칩]                    │  ← 화살표 + 플레이스홀더
│                                         │
└─────────────────────────────────────────┘
```

### 상세 스펙

**컨테이너**:
```dart
Container(
  margin: const EdgeInsets.all(16),
  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        colorScheme.surfaceContainerHighest,
      ],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
)
```

**원형 아이콘 배경**:
```dart
Container(
  width: 64,
  height: 64,
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerHighest,
    shape: BoxShape.circle,
  ),
  child: Icon(
    AppIcons.sparkles,
    size: 32,
    color: colorScheme.onSurface,
  ),
)
```

**텍스트**:
```dart
// 제목
Text(
  'snap.empty'.tr(),
  style: theme.textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.w600,
    color: colorScheme.onSurface,
  ),
)

// 설명
Text(
  'snap.empty_hint'.tr(),
  style: theme.textTheme.bodyMedium?.copyWith(
    color: colorScheme.onSurfaceVariant,
  ),
)
```

**입력 힌트 칩**:
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: colorScheme.surface.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        AppIcons.arrowUp,
        size: 12,
        color: colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 8),
      Text(
        'snap.input_placeholder'.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  ),
)
```

### 색상 사용 원칙

**❌ 메인 컬러 남용:**
```dart
// 모든 요소에 primary 사용 (과도한 강조)
Container(
  decoration: BoxDecoration(
    color: colorScheme.primary.withValues(alpha: 0.1),
  ),
  child: Icon(AppIcons.sparkles, color: colorScheme.primary),
)
```

**✅ 중립 색상 + 최소 강조:**
```dart
// 배경은 중립, 아이콘만 강조
Container(
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerHighest,  // 중립
  ),
  child: Icon(
    AppIcons.sparkles,
    color: colorScheme.onSurface,  // 중립
  ),
)
```

**색상 선택 가이드:**
- **배경**: `surfaceContainerHighest` (중립)
- **아이콘 배경**: `surfaceContainerHighest` (중립)
- **아이콘**: `onSurface` (중립)
- **텍스트 제목**: `onSurface` (중립)
- **텍스트 설명**: `onSurfaceVariant` (중립)
- **입력 힌트**: `surface` + `onSurfaceVariant` (중립)

**이유**: Empty State는 정보 제공이 목적이므로 중립적인 색상 사용. 메인 컬러는 CTA 버튼에만 사용.

### 주의사항

1. **메인 컬러 사용 금지**: Empty State에서 primary 색상 사용 최소화
2. **그라데이션 사용**: 배경에 subtle한 그라데이션으로 깊이감 추가
3. **원형 배경**: 아이콘을 원형 배경에 배치하여 시각적 안정감 제공
4. **입력 힌트**: 사용자에게 다음 액션을 명확히 안내

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
