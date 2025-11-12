# 개발 일정

> 미니라인 앱 개발 단계별 계획

**언제 읽어야 하는가:**
- 다음 작업 확인 시
- 우선순위 판단 시
- 진행 상황 체크 시

---

## 전체 단계

```
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

## Phase 1: 기반 구축 (MVP 준비)

### 1.1 데이터 모델 구현

**우선순위:** 최상 (다른 모든 작업의 기반)

**작업:**
- [ ] Base 모델 작성 (북랩 패턴)
- [ ] Fragment 모델 (Isar)
- [ ] Draft 모델 (Isar)
- [ ] Post 모델 (Isar)
- [ ] 코드 생성 (`build_runner`)

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

### 1.2 Isar 설정

**우선순위:** 최상

**작업:**
- [ ] Isar Provider 작성
- [ ] 초기화 로직 (`main.dart`)
- [ ] Collection 등록

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

### 1.3 Supabase 연결

**우선순위:** 최상

**작업:**
- [ ] Supabase Provider 작성
- [ ] 환경 변수 설정 (`.env`)
- [ ] 인증 플로우 (Google, Apple, Email)

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

### 1.4 동기화 서비스 (3-Service)

**우선순위:** 높음

**작업:**
- [ ] IsarWatchService (로컬 → 서버)
- [ ] SupabaseStreamService (서버 → 로컬)
- [ ] LifecycleService (앱 재시작 시)
- [ ] Sync Provider 통합

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

### 2.1 Timeline 화면

**우선순위:** 최상

**작업:**
- [ ] Timeline 페이지 (`timeline_page.dart`)
- [ ] Fragment 리스트 위젯
- [ ] Fragment 카드 위젯
- [ ] Empty State
- [ ] Loading State

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

### 2.2 Fragment 입력

**우선순위:** 최상

**작업:**
- [ ] FragmentInputBar 위젯
- [ ] 텍스트 입력 (300자 제한)
- [ ] 이미지 첨부 (최대 3개)
- [ ] 이미지 프리뷰
- [ ] 저장 로직

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

### 2.3 Drafts 화면

**우선순위:** 중간

**작업:**
- [ ] Drafts 페이지
- [ ] Draft 리스트
- [ ] Draft 카드
- [ ] Draft 상세 화면

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

### 2.4 Posts 화면

**우선순위:** 중간

**작업:**
- [ ] Posts 페이지
- [ ] Post 리스트
- [ ] Post 카드
- [ ] Post 상세 화면 (읽기 모드)

**파일:**
```
lib/features/posts/
├── presentation/
│   ├── pages/
│   │   ├── posts_page.dart
│   │   └── post_detail_page.dart
│   └── widgets/post_card.dart
└── providers/posts_provider.dart
```

**검증:**
- Post 리스트 표시
- Post 상세 화면 표시
- 공개/비공개 상태 확인

### 2.5 라우팅

**우선순위:** 높음

**작업:**
- [ ] GoRouter 설정
- [ ] 화면 전환 애니메이션
- [ ] 딥링크 (선택사항)

**파일:**
```
lib/router/app_router.dart
```

**검증:**
- 화면 간 이동 확인
- 뒤로가기 동작 확인

---

## Phase 3: 앱 특화 기능

### 3.1 공유 수신

**우선순위:** 높음 (앱의 차별점)

**작업:**
- [ ] ShareHandlerService 작성
- [ ] 텍스트 공유 수신
- [ ] 이미지 공유 수신
- [ ] Timeline으로 자동 이동
- [ ] 입력창에 자동 입력

**파일:**
```
lib/core/services/share_handler_service.dart
```

**참조:**
- [../minorlab_book/lib/core/services/share_handler_service.dart](../minorlab_book/lib/core/services/share_handler_service.dart)
- [docs/DIFFERENCES_FROM_WEB.md](DIFFERENCES_FROM_WEB.md) - 공유 수신 섹션

**검증:**
- Safari에서 URL 공유 → MiniLine 열림
- 갤러리에서 이미지 공유 → MiniLine 열림
- 입력창에 자동 입력 확인

### 3.2 로컬 알림

**우선순위:** 중간

**작업:**
- [ ] NotificationService 작성
- [ ] 알림 권한 요청
- [ ] 로컬 알림 스케줄링
- [ ] 알림 탭 시 Timeline 이동

**파일:**
```
lib/core/services/notification_service.dart
```

**참조:**
- [docs/DIFFERENCES_FROM_WEB.md](DIFFERENCES_FROM_WEB.md) - 로컬 알림 섹션

**검증:**
- Settings에서 시간 설정
- 설정 시간에 알림 발생
- 알림 탭 → Timeline 이동

### 3.3 푸시 알림 (FCM)

**우선순위:** 중간

**작업:**
- [ ] Firebase 설정 (iOS/Android)
- [ ] FCM 토큰 저장
- [ ] 디바이스 등록
- [ ] 알림 수신 처리

**파일:**
```
lib/core/services/fcm_service.dart
lib/core/services/device_info_service.dart
```

**참조:**
- [../minorlab_book/lib/core/services/device_info_service.dart](../minorlab_book/lib/core/services/device_info_service.dart)
- [docs/DIFFERENCES_FROM_WEB.md](DIFFERENCES_FROM_WEB.md) - 푸시 알림 섹션

**검증:**
- Draft 생성 완료 → 푸시 알림 수신
- 알림 탭 → Draft 상세 화면

### 3.4 디바이스 관리

**우선순위:** 낮음 (동기화에 포함)

**작업:**
- [ ] 디바이스 자동 등록
- [ ] FCM 토큰 저장
- [ ] 마지막 동기화 시간 추적

**파일:**
```
lib/core/services/device_info_service.dart
```

**검증:**
- 앱 설치 → 디바이스 자동 등록
- Supabase devices 테이블 확인

---

## Phase 4: 완성도

### 4.1 Settings 화면

**우선순위:** 중간

**작업:**
- [ ] Settings 페이지
- [ ] 언어 설정
- [ ] 테마 설정 (라이트/다크/시스템)
- [ ] 알림 설정
- [ ] 프로필
- [ ] 구독 관리 (RevenueCat)
- [ ] 로그아웃

**파일:**
```
lib/features/settings/
├── presentation/pages/settings_page.dart
└── providers/settings_provider.dart
```

**검증:**
- 모든 설정 저장/로드 확인
- 테마 전환 확인

### 4.2 다국어 (i18n)

**우선순위:** 중간

**작업:**
- [ ] 다국어 파일 작성 (en, ko)
- [ ] easy_localization 설정
- [ ] 모든 하드코딩 텍스트 `.tr()` 변환

**파일:**
```
assets/translations/
├── en.json
└── ko.json
```

**검증:**
- 언어 전환 시 모든 텍스트 변경 확인
- 하드코딩 텍스트 없음 확인

### 4.3 테마

**우선순위:** 중간

**작업:**
- [ ] AppTheme 작성 (minorlab_common 기반)
- [ ] 라이트/다크 모드
- [ ] 모든 하드코딩 색상 제거

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
1. 로컬 알림
2. 푸시 알림
3. Settings
4. 다국어
5. 테마

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

**명령:**
```bash
cd miniline_app
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

**작성 후 확인:**
- [x] 우선순위 명확한가?
- [x] 단계별 검증 기준 있는가?
- [x] 참조 문서 링크 있는가?
