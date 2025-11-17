# 웹 vs 앱 차이점

> 미니라인 웹과 앱의 기능, 구현, UI 차이점

**언제 읽어야 하는가:**
- 웹 기능을 앱에 이식하기 전
- 앱 전용 기능 구현 시
- 플랫폼별 제약사항 확인 시

---

## 추가 기능 (앱만 있음)

### 1. 공유 수신 (Share Handler)

**설명**: 다른 앱에서 텍스트/이미지 공유 시 MiniLine으로 수신

**패키지**: `share_handler: ^0.0.25`

**구현**: 북랩 패턴을 현대화
- **북랩**: Singleton + static GlobalKey
- **miniline_app**: `@Riverpod(keepAlive: true)` Provider + Ref 전달
- **추가**: `SharedMediaProvider`로 공유 데이터 상태 관리

**핵심 차이점**:
```dart
// 북랩 (Singleton)
class ShareHandlerService {
  static final ShareHandlerService _instance = ShareHandlerService._internal();
  factory ShareHandlerService() => _instance;
}

// miniline_app (keepAlive Provider)
@Riverpod(keepAlive: true)
ShareHandlerService shareHandlerService(Ref ref) {
  final service = ShareHandlerService(ref);
  ref.onDispose(() => service.dispose());
  return service;
}

// miniline_app 고유: 공유 데이터 Provider
@Riverpod(keepAlive: true)
class SharedMediaNotifier extends _$SharedMediaNotifier {
  @override
  SharedMedia? build() => null;
  void setMedia(SharedMedia media) { state = media; }
  void clear() { state = null; }
}
```

**참조**:
- 북랩 원본: [../minorlab_book/lib/core/services/share_handler_service.dart](../minorlab_book/lib/core/services/share_handler_service.dart)
- miniline_app: `lib/core/services/share_handler_service.dart`, `lib/core/providers/shared_media_provider.dart`

**iOS 구현 상세:**
- ShareExtension 타겟 추가
- ShareViewController.swift (share_handler_ios_models 상속)
- App Group 설정 (group.com.minorlab.miniline)
- MainInterface.storyboard 사용
- Info.plist: 텍스트, URL, 이미지, 파일 지원

**시나리오**:
1. Safari에서 URL 복사 → 공유 → MiniLine
2. MiniLine 앱 열림 → ShareInputPage로 이동
3. 공유된 데이터 표시 → Fragment로 저장

**상세**: [docs/SHARE_TESTING_GUIDE.md](SHARE_TESTING_GUIDE.md)

### 2. 로컬 알림 ✅

**설명**: 사용자 설정 시간에 입력 리마인더 알림

**패키지**: `flutter_local_notifications: ^19.4.2`, `timezone: ^0.10.0`

**구현 완료**:
- 사용자가 시간 선택 (DailyReminderSheet)
- 알림 내용: "스냅 작성 시간이에요" / "오늘 하루를 기록해보세요"
- 알림 탭 시:
  - Timeline 탭이면 입력창 포커스
  - 다른 탭이면 Fragment 입력 모달 표시
- FCM 포그라운드 메시지 → 로컬 알림 변환
- Exact alarm 권한 처리 (Android 12+)

**파일**:
- `lib/core/services/local_notification_service.dart`
- `lib/features/settings/presentation/widgets/daily_reminder_sheet.dart`
- `lib/features/main/presentation/pages/main_page.dart` (탭 콜백)

**상세**: [docs/PLAN.md](PLAN.md) Phase 3.2

### 3. 푸시 알림 (FCM) ✅

**설명**: Draft 생성 완료 시 서버에서 발송

**패키지**: `firebase_messaging: ^16.0.4`

**구현 완료**:
- FCM 토큰 저장 (디바이스 등록 시)
- 포그라운드 메시지 → 로컬 알림 변환
- 백그라운드 메시지 → 시스템 알림 표시
- 알림 탭 시 → Drafts 페이지 이동 (payload: 'draft:{id}')
- iOS는 Firebase가 자동으로 APNS 토큰 처리 (별도 저장 불필요)

**발송 조건** (Edge Function 필요):
1. Fragment 3개 이상 입력
2. AI가 Draft 생성 완료
3. 사용자 타임존 고려하여 발송

**파일**:
- `lib/core/services/fcm_service.dart`
- `lib/core/services/local_notification_service.dart` (포그라운드 처리)
- `lib/features/settings/presentation/widgets/draft_notification_sheet.dart`

**상세**: [docs/PLAN.md](PLAN.md) Phase 3.3

### 4. 디바이스 관리 ✅

**설명**: 다중 기기 동기화를 위한 디바이스 정보 관리

**패키지**: `device_info_plus: ^12.1.0`

**기능**:
- 디바이스 자동 등록 (앱 시작/포그라운드 진입 시)
- FCM 토큰 자동 캐싱 및 UPSERT 포함 (iOS APNS는 Firebase 자동 처리)
- 로그인 시 디바이스 정보 갱신

**구현 완료**:
- DeviceInfoService: 북랩 패턴 재사용 ([../minorlab_book/lib/core/services/device_info_service.dart](../minorlab_book/lib/core/services/device_info_service.dart))
- LifecycleService 통합: 자동 업데이트 로직

**자동 업데이트 시점**:
```dart
// lib/core/services/sync/lifecycle_service.dart

// 1. 앱 시작 시
await _deviceInfoService.initialize();

// 2. 로그인 시
_deviceInfoService.refreshOnAppStart();

// 3. 로그아웃 시
_deviceInfoService.markDeviceInactiveOnLogout(); // is_active = false

// 4. 포그라운드 진입 시 (resumed)
_deviceInfoService.refreshOnForeground();

// 5. dispose 시
_deviceInfoService.dispose();
```

**중요**: miniline_app은 익명 로그인을 사용하지 않음 (지연 로그인 전략)
- 상세: [docs/GUIDE_DELAYED_LOGIN_STRATEGY.md](GUIDE_DELAYED_LOGIN_STRATEGY.md)

**서버 테이블**: `devices`
```sql
id: UUID (디바이스 고유 ID)
user_id: UUID (사용자 ID)
target: TEXT ('miniline' - 앱 구분자)
platform: TEXT ('android', 'ios', 'web')
app_version: TEXT ('1.0.0+1')
notification_id: TEXT (FCM/APNS 토큰)
info: JSONB ({ device_name, os_version, package_name, is_active })
```

**파일**:
- `lib/core/services/device_info_service.dart`
- `lib/core/services/sync/lifecycle_service.dart`

---

## 다른 구현 (웹과 동일 기능, 다른 방식)

### 로컬 데이터베이스

**웹**: Dexie (IndexedDB)
```typescript
// miniline/src/lib/db/schema.ts
fragmentsTable = db.table('fragments')
  .version(1)
  .stores({ id: '++', remoteID: '&', synced: 'synced', ... });
```

**앱**: Isar Community (Native)
```dart
// miniline_app/lib/models/fragment.dart
@collection
class Fragment extends Base {
  @Index(unique: true) String remoteID;
  @Index() bool synced = false;
  // ...
}
```

**차이점**:
- Isar는 `bool` 타입 인덱스 지원 (Dexie는 `int` 0/1)
- Isar는 네이티브 성능
- 동일한 Supabase 테이블 공유

### 동기화 서비스

**웹**: Svelte 5 Runes + Service Workers
```typescript
// miniline/src/lib/services/sync/isar-watch.service.svelte.ts
let syncQueue = $state([]);
```

**앱**: Riverpod keepAlive Provider 통일
```dart
// miniline_app/lib/core/services/sync/supabase_stream_service_provider.dart
@Riverpod(keepAlive: true)
SupabaseStreamService supabaseStreamService(Ref ref) {
  final service = SupabaseStreamService();
  ref.onDispose(() => service.dispose());
  return service;
}

// miniline_app/lib/core/services/sync/isar_watch_sync_service_provider.dart
@Riverpod(keepAlive: true)
IsarWatchSyncService isarWatchSyncService(Ref ref) {
  final service = IsarWatchSyncService();
  ref.onDispose(() => service.stop());
  return service;
}

// miniline_app/lib/core/services/sync/lifecycle_service_provider.dart
// 북랩과 달리, miniline_app에서는 LifecycleService도 keepAlive Provider로 통일
@Riverpod(keepAlive: true)
LifecycleService lifecycleService(Ref ref) {
  return LifecycleService(ref);
}
```

**공통점**:
- 3-서비스 구조 동일 (IsarWatch, SupabaseStream, Lifecycle)
- 1초 디바운스
- 충돌 해결 (서버 우선)

**중요한 차이**:
- **웹**: Svelte 5 Runes로 반응형 상태 관리
- **앱**:
  - 모든 동기화 서비스를 Riverpod keepAlive Provider로 통일 관리
  - 북랩과 달리 LifecycleService도 Provider 패턴 (더 일관성 있음)

### 테마 시스템

**웹**: Tailwind v4 + CSS Variables
```typescript
// miniline/src/lib/styles/themes.ts
export const themes = {
  light: { primary: 'rgb(37, 99, 235)', ... },
  dark: { primary: 'rgb(59, 130, 246)', ... }
};
```

**앱**: shadcn_ui + minorlab_common
```dart
// miniline_app/lib/shared/theme/app_theme.dart
static ThemeData lightTheme = MinorLabTheme.minimal(
  paletteId: 'default',
  brightness: Brightness.light,
);
```

**공통점**:
- 동일한 색상 팔레트 사용
- 라이트/다크 모드 지원

### Post 생성 (PostCreatePage)

**웹**: 드롭다운 + 단순 로딩
```typescript
// miniline/src/routes/posts/new/+page.svelte
<select bind:value={selectedTemplate}>
  <option value="essay">생각 정리</option>
  <option value="timeline">시간순 스토리</option>
  ...
</select>

{#if isGenerating}
  <div class="spinner" /> <!-- 로딩 스피너 -->
{/if}
```

**앱**: 그리드 카드 + 실시간 미리보기
```dart
// miniline_app/lib/features/posts/presentation/pages/post_create_page.dart
GridView.builder(
  crossAxisCount: 2,
  children: PostTemplates.all.map((t) => _buildTemplateCard(t)).toList(),
)

// AI 생성 중
LinearProgressIndicator(value: _progress / 100) // 0-100% progress bar
MarkdownBody(data: _generatingContent + '_') // 타이핑 커서 애니메이션
```

**차이점**:
- 웹: 드롭다운 선택, 로딩 스피너
- 앱: 그리드 카드 UI (2열), Progress bar (0-100%), 타이핑 애니메이션 + 깜빡이는 커서

### Post 상세 (PostDetailPage)

#### Markdown 내보내기

**웹**: 브라우저 다운로드
```typescript
// miniline/src/routes/posts/[id]/+page.svelte
function exportMarkdown() {
  const blob = new Blob([`# ${post.title}\n\n${post.content}`], {
    type: 'text/markdown'
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${post.title}.md`;
  a.click();
  URL.revokeObjectURL(url);
}
```

**앱**: share_plus 패키지 (공유 시트)
```dart
// miniline_app/lib/features/posts/presentation/pages/post_detail_page.dart
Future<void> _handleExport() async {
  final markdown = '# ${_post.title}\n\n${_post.content}';
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/${_post.title}.md');
  await file.writeAsString(markdown);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: _post.title,
  );
}
```

**차이점**:
- 웹: 파일 시스템에 직접 다운로드
- 앱: 공유 시트로 다른 앱에 전송

#### Fragment 목록 토글

**웹**: 항상 표시 (접기/펼치기 없음)
```svelte
<!-- miniline/src/routes/posts/[id]/+page.svelte -->
{#if fragments.length > 0}
  <div class="fragments">
    {#each fragments as fragment}
      <FragmentCard {fragment} />
    {/each}
  </div>
{/if}
```

**앱**: 토글 버튼 (접기/펼치기)
```dart
// miniline_app/lib/features/posts/presentation/pages/post_detail_page.dart
ShadButton.ghost(
  onPressed: () => setState(() => _showFragments = !_showFragments),
  child: Row(
    children: [
      Icon(_showFragments ? AppIcons.chevronDown : AppIcons.chevronRight),
      Text('draft.snap_count'.tr(namedArgs: {'count': _fragments.length})),
    ],
  ),
)

if (_showFragments) ...fragments.map((f) => Card(...))
```

**차이점**:
- 웹: 항상 표시
- 앱: 토글 버튼으로 공간 절약 (모바일 화면 최적화)

#### Preview/Source 모드

**웹**: 없음 (Preview만 표시)

**앱**: 토글 버튼 (Preview ↔ Source)
```dart
// miniline_app/lib/features/posts/presentation/pages/post_detail_page.dart
Row(
  children: [
    ShadButton(
      onPressed: _viewMode == 'preview' ? null : () => setState(() => _viewMode = 'preview'),
      child: Text('post.show_preview'.tr()),
    ),
    ShadButton.outline(
      onPressed: _viewMode == 'source' ? null : () => setState(() => _viewMode = 'source'),
      child: Text('post.show_source'.tr()),
    ),
  ],
)

// Preview 모드
if (_viewMode == 'preview')
  MarkdownBody(data: _post.content, styleSheet: ...)

// Source 모드
else
  Text(_post.content, style: TextStyle(fontFamily: 'monospace'))
```

**차이점**:
- 웹: Preview만 표시
- 앱: Preview/Source 모드 전환 가능 (원본 Markdown 확인)

---

## UI 차이

### 입력 방식

**웹**: 페이지 상단 고정 카드
```svelte
<!-- miniline/src/routes/+page.svelte -->
<FragmentInput variant="page" />
<!-- border, padding, rounded -->
```

**앱**: 하단 고정 입력바 (채팅 스타일)
```dart
// miniline_app/lib/features/timeline/presentation/widgets/fragment_input_bar.dart
Column(
  children: [
    Expanded(child: FragmentList()),
    FragmentInputBar(), // 하단 고정
  ],
)
```

**이유**: 모바일에서 thumb zone 접근성

### 네비게이션

**웹**: 사이드바 + 모바일 하단 탭
```svelte
<!-- miniline/src/lib/components/Sidebar.svelte -->
<!-- 데스크톱: 좌측 사이드바 -->
<!-- 모바일: 하단 탭 바 -->
```

**앱**: MainPage + PageView + ShadTabs
```dart
// miniline_app/lib/features/main/presentation/pages/main_page.dart
// Timeline/Drafts/Posts를 PageView로 통합, ShadTabs로 탭 전환
MainPage(
  appBar: AppBar(
    title: ShadTabs(...), // Timeline/Drafts/Posts 탭
    actions: [UserAvatarButton()],
  ),
  body: PageView(
    children: [
      TimelineView(),  // lib/features/timeline/presentation/widgets/timeline_view.dart
      DraftsView(),    // lib/features/drafts/presentation/widgets/drafts_view.dart
      PostsView(),     // lib/features/posts/presentation/widgets/posts_view.dart
    ],
  ),
)
```

**이유**: 단일 화면 집중 (Timeline 중심)

### 이미지 첨부

**웹**: File input + Drag & Drop
```svelte
<!-- miniline/src/lib/components/FragmentInput.svelte -->
<input type="file" accept="image/*" multiple />
<div ondrop={handleDrop}>Drop images here</div>
```

**앱**: ImagePicker + 갤러리/카메라
```dart
// miniline_app/lib/features/timeline/presentation/widgets/fragment_input_bar.dart
final images = await ImagePicker().pickMultiImage();
// 또는
final photo = await ImagePicker().pickImage(source: ImageSource.camera);
```

**공통점**:
- 최대 3개 이미지
- 프리뷰 표시 (80x80)

---

## 배포 차이

### 웹
- Vercel 자동 배포
- `pnpm build` → Static 사이트
- PWA 지원 (Service Worker)

### 앱
- App Store + Google Play
- 수동 배포 (TestFlight, Internal Testing)
- 네이티브 앱 (Flutter AOT)

---

## 제약사항

### 웹
- 브라우저 제약: localStorage 용량 제한 (IndexedDB 사용으로 해결)
- 네이티브 알림 제한적
- 공유 수신 불가

### 앱
- 스토어 심사 필요
- 플랫폼별 설정 (iOS/Android)
- 빌드 시간 증가

---

## 자주 하는 실수

1. **웹 코드 그대로 복사** → 플랫폼별 API 확인 필요
2. **Dexie 패턴을 Isar에 적용** → bool vs int 차이 주의
3. **웹 UI를 앱에 그대로** → 모바일 thumb zone 고려 필요
4. **알림 구현 없이 배포** → 앱의 주요 장점 누락

---

**작성 후 확인:**
- [x] ❌/✅ 패턴 사용했는가?
- [x] "언제 읽어야 하는지" 명시했는가?
- [x] 전체 코드 복사하지 않았는가?
- [x] Feature 문서 참조 추가했는가?
