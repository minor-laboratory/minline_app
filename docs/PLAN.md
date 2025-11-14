# 개발 일정

> 미니라인 앱 개발 단계별 계획

**언제 읽어야 하는가:**
- 다음 작업 확인 시
- 우선순위 판단 시
- 진행 상황 체크 시

---

## 전체 단계

```
웹 동등성 구현: Phase 1-3 완료 ✅
  └─ Settings 컬러 테마, Timeline 검색/정렬, Drafts 필터/AI 분석

Phase 1: 기반 구축 (1-2주)
  └─ 데이터 모델, DB, 동기화

Phase 2: 핵심 기능 (2-3주)
  └─ Timeline, Fragment 입력, Drafts/Posts

Phase 3: 앱 특화 (1-2주)
  └─ 공유, 알림, 디바이스 관리

Phase 4: 완성도 (1주)
  └─ Settings, 테스트, 배포
```

---

## 웹 버전 동등성 구현 ✅

> **목적**: 웹 버전과 동일한 기능 제공
> **상세**: [IMPLEMENTATION_WEB_PARITY.md](IMPLEMENTATION_WEB_PARITY.md)

### Phase 1-1: Settings 컬러 테마 선택 ✅

**우선순위:** 최상 (사용자 경험)
**완료일:** 2025-11-13

**작업:**
- [x] ColorThemeNotifier Provider 추가
- [x] ThemeSettingsSheet UI 수정 (12색 GridView)
- [x] main.dart 테마 적용 로직
- [x] 다국어 키 추가 (theme.color_*)

**파일:**
```
lib/features/settings/
├── providers/settings_provider.dart ✅
├── presentation/widgets/theme_settings_sheet.dart ✅
lib/main.dart ✅
lib/core/constants/app_colors.dart ✅
assets/translations/ko.json, en.json ✅
```

**참조:**
- 구현 계획: [IMPLEMENTATION_WEB_PARITY.md](IMPLEMENTATION_WEB_PARITY.md) Phase 1-1
- 북랩 패턴: `minorlab_book/lib/features/profile/presentation/widgets/theme_settings_sheet.dart`

**검증:** ✅
- 12가지 컬러 선택 가능
- SharedPreferences 저장 확인
- 앱 재시작 시 테마 유지

### Phase 1-2: Timeline 검색/정렬/필터 ✅

**우선순위:** 최상 (핵심 기능)
**완료일:** 2025-11-13

**작업:**
- [x] FragmentFilterState 및 Provider 추가
- [x] filteredFragmentsProvider (필터링/정렬 로직)
- [x] FilterBar 위젯 생성
- [x] TimelinePage에 FilterBar 추가
- [x] 다국어 키 추가 (filter.*)

**파일:**
```
lib/features/timeline/
├── providers/fragments_provider.dart ✅
├── presentation/widgets/filter_bar.dart ✅
├── presentation/widgets/fragment_list.dart ✅
├── presentation/pages/timeline_page.dart ✅
lib/core/utils/app_icons.dart ✅
assets/translations/ko.json, en.json ✅
```

**참조:**
- 구현 계획: [IMPLEMENTATION_WEB_PARITY.md](IMPLEMENTATION_WEB_PARITY.md) Phase 1-2
- 웹 버전: `miniline/src/lib/components/Timeline.svelte`, `FilterBar.svelte`

**검증:** ✅
- 검색 입력 시 실시간 필터링
- 정렬 변경 (created/updated/event, desc/asc)
- Stream 기반 자동 갱신

### Phase 1-3: Drafts 상태 필터 + AI 분석 ✅

**우선순위:** 최상 (핵심 기능)
**완료일:** 2025-11-13

**작업:**
- [x] DraftFilterState 및 Provider 추가
- [x] filteredDraftsProvider (필터링 로직)
- [x] draftCountsProvider (상태별 카운트)
- [x] DraftsPage UI (필터 칩, AI 분석 버튼)
- [x] _handleAnalyzeNow 함수 (Edge Function 호출)
- [x] 다국어 키 추가 (웹과 100% 일치)

**파일:**
```
lib/features/drafts/
├── providers/drafts_provider.dart ✅
├── presentation/pages/drafts_page.dart ✅
assets/translations/ko.json, en.json ✅
```

**참조:**
- 구현 계획: [IMPLEMENTATION_WEB_PARITY.md](IMPLEMENTATION_WEB_PARITY.md) Phase 1-3
- 웹 버전: `miniline/src/lib/components/DraftList.svelte`

**검증:** ✅
- 상태별 필터 (all/pending/accepted/rejected)
- 각 상태별 개수 표시
- AI 분석 버튼 동작 확인
- 웹과 동일한 UX

---

## Phase 1: 기반 구축 (MVP 준비)

### 1.1 데이터 모델 구현 ✅ 완료

**우선순위:** 최상 (다른 모든 작업의 기반)

**작업:**
- [x] Base 모델 작성 (북랩 패턴)
- [x] Fragment 모델 (Isar)
- [x] Draft 모델 (Isar)
- [x] Post 모델 (Isar)
- [x] 코드 생성 (`build_runner`)

**파일:**
```
lib/models/
├── base.dart
├── fragment.dart
├── draft.dart
└── post.dart
```

**참조:**
- [../minorlab_book/lib/core/database/models/base.dart](../minorlab_book/lib/core/database/models/base.dart)
- [../miniline/docs/SPEC_DATABASE_SCHEMA.md](../miniline/docs/SPEC_DATABASE_SCHEMA.md)

**검증:**
- `flutter analyze` 통과
- Isar Inspector에서 스키마 확인

### 1.2 Isar 설정 ✅ 완료

**우선순위:** 최상

**작업:**
- [x] Isar Provider 작성
- [x] 초기화 로직 (`main.dart`)
- [x] Collection 등록

**파일:**
```
lib/providers/isar_provider.dart
lib/main.dart (초기화)
```

**참조:**
- [/docs/flutter/GUIDE_ISAR_PATTERNS.md](/docs/flutter/GUIDE_ISAR_PATTERNS.md)

**검증:**
- 앱 실행 시 Isar 초기화 성공
- 샘플 데이터 저장/조회 확인

### 1.3 Supabase 연결 ✅ 완료

**우선순위:** 최상

**작업:**
- [x] Supabase Provider 작성
- [x] 환경 변수 설정 (`.env`)
- [x] 인증 플로우 (Google, Apple, Email)

**파일:**
```
lib/providers/supabase_provider.dart
lib/features/auth/
.env (SUPABASE_URL, SUPABASE_ANON_KEY)
```

**참조:**
- [/docs/common/GUIDE_SUPABASE_PATTERNS.md](/docs/common/GUIDE_SUPABASE_PATTERNS.md)
- [../miniline/.env.example](../miniline/.env.example) (웹 버전 참조)

**검증:**
- 로그인/로그아웃 동작
- Supabase Dashboard에서 사용자 확인

### 1.4 동기화 서비스 (3-Service) ✅ 완료

**우선순위:** 높음

**작업:**
- [x] IsarWatchService (로컬 → 서버)
- [x] SupabaseStreamService (서버 → 로컬)
- [x] LifecycleService (앱 재시작 시)
- [x] Sync Provider 통합

**파일:**
```
lib/core/services/sync/
├── isar_watch_service.dart
├── supabase_stream_service.dart
├── lifecycle_service.dart
└── sync_provider.dart
```

**참조:**
- [../minorlab_book/lib/core/services/sync/](../minorlab_book/lib/core/services/sync/)

**검증:**
- Fragment 저장 → Supabase 자동 업로드
- 웹에서 저장 → 앱에서 자동 다운로드
- 앱 재시작 → 동기화 확인

---

## Phase 2: 핵심 기능 (MVP 완성)

### 2.1 Timeline 화면 ✅ 완료

**우선순위:** 최상

**작업:**
- [x] Timeline 페이지 (`timeline_page.dart`)
- [x] Fragment 리스트 위젯
- [x] Fragment 카드 위젯
- [x] Empty State
- [x] Loading State

**파일:**
```
lib/features/timeline/
├── presentation/
│   ├── pages/timeline_page.dart
│   └── widgets/
│       ├── fragment_card.dart
│       └── fragment_list.dart
└── providers/
    └── fragments_provider.dart
```

**참조:**
- [docs/DESIGN_UI.md](DESIGN_UI.md) - Timeline 섹션

**검증:**
- Fragment 리스트 표시
- 스크롤 동작
- Empty State 표시

### 2.2 Fragment 입력 ✅ 완료

**우선순위:** 최상

**작업:**
- [x] FragmentInputBar 위젯
- [x] 텍스트 입력 (300자 제한)
- [x] 이미지 첨부 (최대 3개)
- [x] 이미지 프리뷰
- [x] 저장 로직

**파일:**
```
lib/features/timeline/presentation/widgets/
└── fragment_input_bar.dart
```

**참조:**
- [../miniline/src/lib/components/FragmentInput.svelte](../miniline/src/lib/components/FragmentInput.svelte) (웹 참조)
- [docs/DESIGN_UI.md](DESIGN_UI.md) - FragmentInputBar 섹션

**검증:**
- 텍스트 입력 → 저장 → Timeline 표시
- 이미지 첨부 → 업로드 → Timeline 표시
- 글자수/이미지 개수 제한 확인
- 오프라인 저장 확인

### 2.3 Drafts 화면 ✅ 완료

**우선순위:** 중간

**작업:**
- [x] Drafts 페이지
- [x] Draft 리스트
- [x] Draft 카드
- [x] Draft 상세 화면

**파일:**
```
lib/features/drafts/
├── presentation/
│   ├── pages/
│   │   ├── drafts_page.dart
│   │   └── draft_detail_page.dart
│   └── widgets/draft_card.dart
└── providers/drafts_provider.dart
```

**검증:**
- Draft 리스트 표시
- Draft 상세 화면 표시
- AI 생성 초안 확인

### 2.4 Posts 화면 ✅ 완료

**우선순위:** 중간

**작업:**
- [x] Posts 페이지
- [x] Post 리스트
- [x] Post 카드
- [x] Post 상세 화면 (읽기 모드)
- [x] Markdown 렌더링 (flutter_markdown)
- [x] 공개/비공개 토글
- [x] 삭제 기능
- [x] 라우트 추가 (`/posts/:postId`)

**파일:**
```
lib/features/posts/
├── presentation/
│   ├── pages/
│   │   ├── posts_page.dart ✅
│   │   └── post_detail_page.dart ✅
│   └── widgets/post_card.dart
└── providers/posts_provider.dart ✅
lib/router/app_router.dart (라우트 추가) ✅
pubspec.yaml (flutter_markdown: ^0.7.4+1) ✅
```

**검증:** ✅
- Post 리스트 표시 확인
- Post 상세 화면 표시 확인
- Markdown 정상 렌더링 확인
- 공개/비공개 상태 토글 확인
- viewed 플래그 자동 업데이트 확인

### 2.4.1 Post 생성 화면 ✅ 완료

**우선순위:** 중간

**작업:**
- [x] PostCreatePage 구현
- [x] 5개 템플릿 선택 UI (Essay, Timeline, Product Review, Travel, Project)
- [x] AI 스트리밍 (SSE) 연동 (Edge Function 'generate-post')
- [x] 실시간 미리보기 (타이핑 애니메이션 + 커서)
- [x] Progress bar (0-100%)
- [x] 재생성 지원 (previousVersionId 쿼리 파라미터)
- [x] 에러 처리 (최소 Fragment 수, 무료 한도)
- [x] PostTemplates 상수 파일 생성
- [x] Fragment 목록 토글 (PostDetailPage)
- [x] Markdown 내보내기 (share_plus)
- [x] 피드백 신고 기능
- [x] Preview/Source 모드 토글

**파일:**
```
lib/features/posts/presentation/pages/post_create_page.dart ✅
lib/core/constants/post_templates.dart ✅
lib/features/posts/presentation/pages/post_detail_page.dart (신규 기능 추가) ✅
lib/router/app_router.dart (previousVersionId 쿼리 파라미터) ✅
assets/translations/ko.json, en.json (template.*, post.* 키 추가) ✅
pubspec.yaml (share_plus: ^10.1.4) ✅
```

**검증:** ✅
- 템플릿 선택 UI 확인 (그리드 2열)
- AI 스트리밍 동작 확인 (SSE, 실시간 타이핑)
- 미리보기 타이핑 애니메이션 확인
- Progress bar 0-100% 진행 확인
- 재생성 시 previousVersionId 전달 확인
- Fragment 2개 미만 시 에러 메시지 확인
- Fragment 목록 토글 확인 (내용, 시간, AI 태그)
- Markdown 내보내기 확인 (share_plus)
- 피드백 신고 확인 (FeedbackDialog)
- Preview/Source 모드 토글 확인

### 2.5 라우팅 ✅ 완료

**우선순위:** 높음

**작업:**
- [x] GoRouter 설정
- [x] 화면 전환 애니메이션
- [ ] 딥링크 (선택사항)

**파일:**
```
lib/router/app_router.dart
```

**검증:**
- 화면 간 이동 확인
- 뒤로가기 동작 확인

### 2.6 캘린더 뷰 ✅ 완료

**우선순위:** 중간

**작업:**
- [x] CalendarView 위젯 작성
- [x] 월간 캘린더 그리드 렌더링
- [x] 날짜별 Fragment 개수 점 표시 (1-3개: •••, 4개 이상: •••+)
- [x] 날짜 선택 시 하단 Fragment 리스트 표시
- [x] 년/월 변경 기능
- [x] Timeline ↔ Calendar 뷰 전환 버튼
- [x] 오늘 버튼

**파일:**
```
lib/features/timeline/presentation/widgets/
└── calendar_view.dart
lib/features/timeline/presentation/pages/
└── timeline_page.dart (뷰 토글 추가)
```

**참조:**
- [../miniline/docs/features/캘린더_뷰/FEATURE.md](../miniline/docs/features/캘린더_뷰/FEATURE.md) (웹 버전 참조)
- [../miniline/docs/features/캘린더_뷰/IMPLEMENTATION.md](../miniline/docs/features/캘린더_뷰/IMPLEMENTATION.md)
- Flutter table_calendar 패키지 사용 고려

**주의사항:**
- 필터는 Timeline 뷰에만 적용 (Calendar는 항상 전체 Fragment)
- 이전 월 날짜(회색)는 클릭 불가
- 오늘 날짜 border 표시
- 선택된 날짜 배경색 변경
- 로컬 데이터 우선 (오프라인 동작)

**검증:**
- Timeline ↔ Calendar 뷰 전환 확인
- 날짜 선택 → Fragment 리스트 표시
- Fragment 없는 날짜 → 안내 메시지
- 월 변경 → 캘린더 렌더링 확인
- 오늘 버튼 → 현재 월로 이동

---

## Phase 3: 앱 특화 기능 🟡 대부분 완료

### 3.1 공유 수신 ⏳ 보류

**우선순위:** 높음 (앱의 차별점)
**상태:** 서비스 파일 존재, 초기화 및 연동 미확인

**작업:**
- [x] ShareHandlerService 작성
- [ ] 텍스트 공유 수신 (테스트 필요)
- [ ] 이미지 공유 수신 (테스트 필요)
- [ ] Timeline으로 자동 이동 (코드 존재)
- [ ] 입력창에 자동 입력 (코드 존재)

**파일:**
```
lib/core/services/share_handler_service.dart ✅
lib/core/services/share_handler_provider.dart ✅
lib/router/app_router.dart (navigatorKey) ✅
```

**참조:**
- [../minorlab_book/lib/core/services/share_handler_service.dart](../minorlab_book/lib/core/services/share_handler_service.dart)
- [docs/DIFFERENCES_FROM_WEB.md](DIFFERENCES_FROM_WEB.md) - 공유 수신 섹션

**검증:** ⏳
- Safari에서 URL 공유 → MiniLine 열림 (테스트 필요)
- 갤러리에서 이미지 공유 → MiniLine 열림 (테스트 필요)
- 입력창에 자동 입력 확인 (테스트 필요)

### 3.2 로컬 알림 ✅ 완료

**우선순위:** 중간
**상태:** 완료

**작업:**
- [x] NotificationService 작성
- [x] 알림 권한 요청
- [x] 로컬 알림 스케줄링
- [x] 알림 탭 시 Timeline 이동
- [x] FCM 포그라운드 메시지 → 로컬 알림 변환
- [x] Settings 페이지에 알림 설정 UI 추가 (바텀시트)

**파일:**
```
lib/core/services/local_notification_service.dart ✅
lib/features/settings/presentation/widgets/daily_reminder_sheet.dart ✅
lib/features/settings/presentation/widgets/draft_notification_sheet.dart ✅
pubspec.yaml (timezone: ^0.10.0) ✅
```

**참조:**
- [docs/DIFFERENCES_FROM_WEB.md](DIFFERENCES_FROM_WEB.md) - 로컬 알림 섹션

**검증:** ✅
- 알림 권한 요청 확인 ✅
- 로컬 알림 스케줄링 확인 ✅
- 알림 탭 → Timeline 이동 ✅
- Settings UI (DailyReminderSheet, DraftNotificationSheet) ✅
- 시간 선택 TimePicker ✅
- SharedPreferences로 설정 저장 ✅

### 3.3 푸시 알림 (FCM) ✅ 완료

**우선순위:** 중간
**상태:** 완료

**작업:**
- [x] Firebase 설정 (iOS/Android)
- [x] FCM 토큰 저장
- [x] 디바이스 등록
- [x] 알림 수신 처리
- [x] 포그라운드 알림 → 로컬 알림 변환
- [x] 알림 탭 시 라우팅 (/drafts)

**파일:**
```
lib/core/services/fcm_service.dart ✅
lib/core/services/device_info_service.dart ✅
lib/router/app_router.dart (navigatorKey) ✅
```

**참조:**
- [../minorlab_book/lib/core/services/device_info_service.dart](../minorlab_book/lib/core/services/device_info_service.dart)
- [docs/DIFFERENCES_FROM_WEB.md](DIFFERENCES_FROM_WEB.md) - 푸시 알림 섹션

**검증:** ✅
- FCM 토큰 생성 확인 ✅
- 디바이스 등록 (Supabase devices 테이블 UPSERT) ✅
- Draft 생성 완료 → 푸시 알림 수신 (Edge Function 필요)
- 알림 탭 → Drafts 페이지 이동 ✅

### 3.4 디바이스 관리 ✅ 완료

**우선순위:** 낮음 (동기화에 포함)
**상태:** 완료

**작업:**
- [x] 디바이스 자동 등록
- [x] FCM 토큰 저장
- [x] APNS 토큰 저장 (iOS)
- [x] 마지막 동기화 시간 추적
- [x] 사용자별 디바이스 ID (secure_storage)

**파일:**
```
lib/core/services/device_info_service.dart ✅
lib/core/services/device_info_provider.dart ✅
```

**검증:** ✅
- 앱 설치 → 디바이스 자동 등록 ✅
- Supabase devices 테이블 확인 (실제 동작 시 확인 필요)

---

## Phase 4: 완성도

### 4.1 Settings 화면 ✅ 완료

**우선순위:** 중간
**상태:** 완료 (구독 제외)
**완료일:** 2025-11-13

**작업:**
- [x] Settings 페이지
- [x] 언어 설정 (LanguageSettingsSheet) - 북랩 패턴 적용
- [x] 테마 설정 (ThemeSettingsSheet) - 북랩 패턴 적용 (라이트/다크/시스템, 배경색, 컬러 테마)
- [x] 알림 설정 (DailyReminderSheet, DraftNotificationSheet)
- [x] StandardBottomSheet 패턴 적용 (Wolt Modal Sheet 기반)
- [x] 프로필 (사용자 정보 표시)
- [ ] 구독 관리 (RevenueCat) - 별도 세션에서 처리 예정
- [x] 로그아웃
- [x] 이용약관/개인정보처리방침 (minorlab_common PolicyLatestPage 사용)

**파일:**
```
lib/shared/widgets/
├── standard_bottom_sheet.dart ✅ (북랩 패턴)
└── responsive_modal_sheet.dart ✅ (북랩 패턴)
lib/features/settings/
├── presentation/
│   ├── pages/settings_page.dart ✅
│   └── widgets/
│       ├── theme_settings_sheet.dart ✅ (북랩 패턴 적용)
│       ├── language_settings_sheet.dart ✅ (북랩 패턴 적용)
│       ├── daily_reminder_sheet.dart ✅
│       └── draft_notification_sheet.dart ✅
lib/router/app_router.dart (정책 라우트) ✅
pubspec.yaml (wolt_modal_sheet: ^0.11.0) ✅
assets/translations/ko.json, en.json (theme.mode 키 추가) ✅
```

**참조:**
- 북랩 패턴: `minorlab_book/lib/shared/widgets/standard_bottom_sheet.dart`
- 문서: [docs/COMPONENT_SPECS.md](COMPONENT_SPECS.md) - StandardBottomSheet 섹션

**검증:** ✅
- 언어 전환 확인 ✅
- 시스템 언어 사용 스위치 동작 ✅
- 테마 전환 확인 (라이트/다크/시스템) ✅
- 배경색 선택 (기본/따뜻함/중립) ✅
- 컬러 테마 선택 (12색) ✅
- 알림 설정 UI (DailyReminderSheet, DraftNotificationSheet) ✅
- 정책 페이지 열림 확인 ✅
- 로그아웃 동작 확인 ✅
- InkWell/Material 위젯 에러 해결 ✅
- 북랩과 동일한 UI/UX ✅

### 4.2 다국어 (i18n) ✅ 완료

**우선순위:** 중간

**작업:**
- [x] 다국어 파일 작성 (en, ko)
- [x] easy_localization 설정
- [x] 모든 하드코딩 텍스트 `.tr()` 변환

**파일:**
```
assets/translations/
├── en.json
└── ko.json
```

**검증:**
- 언어 전환 시 모든 텍스트 변경 확인
- 하드코딩 텍스트 없음 확인

### 4.3 테마 ✅ 완료

**우선순위:** 중간

**작업:**
- [x] AppTheme 작성 (minorlab_common 기반)
- [x] 라이트/다크 모드
- [x] 모든 하드코딩 색상 제거

**파일:**
```
lib/shared/theme/app_theme.dart
```

**참조:**
- [../minorlab_book/lib/shared/theme/app_theme.dart](../minorlab_book/lib/shared/theme/app_theme.dart)

**검증:**
- 테마 전환 시 모든 색상 변경
- 하드코딩 색상 없음 확인

### 4.4 테스트

**우선순위:** 높음

**작업:**
- [ ] Widget 테스트 (주요 화면)
- [ ] Integration 테스트 (E2E)
- [ ] 실기기 테스트 (iOS/Android)

**검증:**
- 모든 핵심 플로우 동작 확인
- 오프라인 동작 확인
- 에러 처리 확인

### 4.5 배포 준비

**우선순위:** 높음

**작업:**
- [ ] 앱 아이콘
- [ ] 스플래시 스크린
- [ ] App Store 스크린샷
- [ ] 개인정보 처리방침
- [ ] 이용약관

**검증:**
- `flutter analyze` 통과
- 모든 경고 해결
- 실기기 동작 확인

---

## 우선순위 정리

### P0 (최상 - MVP 필수)
1. 데이터 모델
2. Isar 설정
3. Supabase 연결
4. Timeline 화면
5. Fragment 입력
6. 동기화 서비스

### P1 (높음 - 기본 기능)
1. Drafts/Posts 화면
2. 라우팅
3. 공유 수신
4. 테스트

### P2 (중간 - 완성도)
1. 캘린더 뷰
2. 로컬 알림
3. 푸시 알림
4. Settings
5. 다국어
6. 테마

### P3 (낮음 - 추가 기능)
1. 디바이스 관리
2. 구독 관리
3. 앱 내 튜토리얼

---

## 다음 작업

**지금 시작:**
- [ ] Phase 1.1: 데이터 모델 구현

**완료 기준:**
- `flutter analyze` 통과
- Isar Inspector에서 스키마 확인
- 샘플 데이터 저장/조회 성공

**자동화 도구:**
- `/check-errors` - Flutter 에러/경고 자동 체크 (Claude Code 명령어)
- `.claude/scripts/check-flutter-errors.sh` - 수동 에러 체크 스크립트
- `.claude/scripts/watch-flutter-errors.sh` - Hot reload 자동 모니터링

**명령:**
```bash
cd miniline_app
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
# 또는 자동 체크
.claude/scripts/check-flutter-errors.sh
```

---

**작성 후 확인:**
- [x] 우선순위 명확한가?
- [x] 단계별 검증 기준 있는가?
- [x] 참조 문서 링크 있는가?
