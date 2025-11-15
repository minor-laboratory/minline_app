# CLAUDE.md - MiniLine App

AI 기반 자동 조합 저널 앱 (Flutter 버전)

> **컨셉**: 짧은 생각들(Fragments)을 시간에 걸쳐 입력하면, AI가 자동으로 연결하고 완성된 글(Draft)로 조합

## 필수 검증 체크리스트

- [ ] 모든 텍스트 `.tr()` 형식 사용 (하드코딩 금지)
- [ ] 모든 아이콘 `AppIcons.xxx` 사용 (Lucide)
- [ ] 모든 색상 테마 시스템 사용 (`minorlab_common`)
- [ ] `flutter analyze` 통과 (No issues found!)
- [ ] Isar 데이터 저장 확인 (Isar Inspector)
- [ ] 실제 동작 확인 (에뮬레이터/실기기)
- [ ] 동기화 확인 (웹↔앱 데이터 일치)

**자동화 도구**:
- `/check-errors` - Flutter 에러/경고 자동 체크 (Claude Code 명령어)
- `.claude/scripts/check-flutter-errors.sh` - 수동 에러 체크 스크립트
- `.claude/scripts/watch-flutter-errors.sh` - Hot reload 자동 모니터링

## 필수 참조 문서

**언제 읽어야 하는가:**

**프로젝트 공통**:
- [/CLAUDE.md](/CLAUDE.md) - 작업 시작 전 반드시
- [/TECH_STACK.md](/TECH_STACK.md) - 기술 선택 시
- [/docs/GUIDE_DOCUMENTATION_STANDARDS.md](/docs/GUIDE_DOCUMENTATION_STANDARDS.md) - 문서 작성 시

**미니라인 공통** (웹과 공유):
- [../miniline/docs/SPEC_DATABASE_SCHEMA.md](../miniline/docs/SPEC_DATABASE_SCHEMA.md) - **데이터 스키마 확인** 시
- [../miniline/docs/features/](../miniline/docs/features/) - **기능 이해** 시 (Fragment, Draft, Post)

**미니라인 앱 특화**:
- [docs/DIFFERENCES_FROM_WEB.md](docs/DIFFERENCES_FROM_WEB.md) - **웹과 다른 점** 확인 시 (공유, 알림, UI)
- [docs/DESIGN_UI.md](docs/DESIGN_UI.md) - **화면 구현** 시
- [docs/COMPONENT_SPECS.md](docs/COMPONENT_SPECS.md) - **컴포넌트 구현** 시 (필수)
- [docs/MOBILE_DIALOG_SHEET_RULES.md](docs/MOBILE_DIALOG_SHEET_RULES.md) - **Dialog/Sheet/Modal 구현** 시 (필수)
- [docs/PLAN.md](docs/PLAN.md) - **개발 일정 확인** 시

**북랩 (Flutter 패턴)**:
- [../minorlab_book/CLAUDE.md](../minorlab_book/CLAUDE.md) - **Flutter 전반** 참조 시
- [../minorlab_book/lib/core/database/models/base.dart](../minorlab_book/lib/core/database/models/base.dart) - **Isar 모델** 구현 시
- [../minorlab_book/lib/core/services/sync/](../minorlab_book/lib/core/services/sync/) - **동기화 서비스** 구현 시 (3-서비스 패턴)
- [../minorlab_book/lib/core/services/device_info_service.dart](../minorlab_book/lib/core/services/device_info_service.dart) - **디바이스 정보** 구현 시
- [../minorlab_book/lib/core/services/share_handler_service.dart](../minorlab_book/lib/core/services/share_handler_service.dart) - **공유 기능** 구현 시

**공통 가이드**:
- [/docs/flutter/FLUTTER_CODING_STYLE_GUIDE.md](/docs/flutter/FLUTTER_CODING_STYLE_GUIDE.md) - **Flutter 코딩** 시
- [/docs/flutter/GUIDE_ISAR_PATTERNS.md](/docs/flutter/GUIDE_ISAR_PATTERNS.md) - **Isar 사용** 시
- [/docs/common/GUIDE_STYLE_COMPONENTS.md](/docs/common/GUIDE_STYLE_COMPONENTS.md) - **컴포넌트/Modal/Dialog** 구현 시 (필수)
- [/docs/common/GUIDE_SUPABASE_PATTERNS.md](/docs/common/GUIDE_SUPABASE_PATTERNS.md) - **Supabase 에러** 시

## 핵심 원칙

### 1. 로컬 퍼스트 (북랩 패턴)

**❌ 서버 저장 실패 시 데이터 유실**
```dart
await supabase.from('fragments').insert({'content': content});
// 네트워크 끊김 → 저장 실패 → 데이터 유실!
```

**✅ 로컬 먼저 → 동기화는 백그라운드**
```dart
final fragment = Fragment()
  ..remoteID = uuid.v4()
  ..content = content
  ..synced = false
  ..refreshAt = DateTime.now();
await isar.writeTxn(() => isar.fragments.put(fragment));
// IsarWatchSyncService가 자동으로 업로드
```

### 2. 하드코딩 금지

**❌ 텍스트 하드코딩**
```dart
Text('저장되었습니다')
AppBar(title: Text('타임라인'))
```

**✅ 다국어 키 사용**
```dart
Text('common.saved'.tr())
AppBar(title: Text('timeline.title'.tr()))
```

**❌ 아이콘 하드코딩**
```dart
Icon(Icons.add)
Icon(Icons.settings)
```

**✅ AppIcons 사용**
```dart
Icon(AppIcons.add)
Icon(AppIcons.settings)
```

### 3. AI 비용 최소화

- 앱에서는 AI API 직접 호출 없음
- 모든 AI 처리는 서버 사이드 (Edge Functions)
- 프리미엄: 실시간 임베딩 생성
- 무료: 배치 처리 대기

### 4. 웹과 데이터 공유

- 동일한 Supabase 프로젝트 사용
- 웹 (Dexie) ↔ 앱 (Isar) ↔ 서버 (PostgreSQL)
- 실시간 동기화 (Realtime)

## 기술 스택

**상세**: [/TECH_STACK.md](/TECH_STACK.md) 참조

### 핵심

- **상태 관리**: flutter_riverpod ^3.0.3
- **라우팅**: go_router ^16.2.4
- **로컬 DB**: isar_community ^3.3.0-dev.1 (북랩 동일)
- **백엔드**: supabase_flutter ^2.10.3 (웹과 공유)
- **UI**: shadcn_ui ^0.39.3, flutter_lucide ^1.7.0
- **Markdown**: flutter_markdown ^0.7.4+1
- **알림**: firebase_messaging ^16.0.4, flutter_local_notifications ^19.4.2
- **공유**: share_handler ^0.0.25 (수신), share_plus ^10.1.4 (전송)
- **이미지**: cached_network_image ^3.4.1, image_picker ^1.1.2, easy_image_viewer ^1.5.1
- **다국어**: easy_localization ^3.0.7
- **공통**: minorlab_common (로컬 경로)

## 프로젝트 구조

```
lib/
├── app/
│   ├── app.dart                 # MaterialApp 설정
│   └── app_providers.dart       # 전역 Provider
│
├── core/
│   ├── constants/               # 상수
│   ├── utils/                   # 유틸리티
│   │   ├── app_icons.dart       # 아이콘 매핑
│   │   ├── logger.dart          # 로깅
│   │   ├── network_error_handler.dart  # 네트워크 에러 처리
│   │   └── storage_utils.dart   # 스토리지 유틸
│   └── services/                # 핵심 서비스
│       ├── device_info_service.dart
│       ├── device_info_provider.dart
│       ├── share_handler_service.dart
│       ├── share_handler_provider.dart
│       ├── local_notification_service.dart
│       ├── fcm_service.dart
│       ├── feedback_service.dart
│       ├── local_change_tracker.dart  # 로컬 변경사항 추적
│       └── sync/
│           ├── isar_watch_sync_service.dart
│           ├── supabase_stream_service.dart
│           ├── lifecycle_service.dart
│           └── sync_metadata_service.dart
│
├── models/                      # Isar 데이터 모델
│   ├── fragment.dart
│   ├── draft.dart
│   └── post.dart
│
├── features/
│   ├── timeline/                # 메인 화면
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   └── widgets/
│   │   └── providers/
│   ├── drafts/
│   ├── posts/
│   ├── auth/
│   └── settings/
│
├── providers/                   # 전역 Provider
│   ├── isar_provider.dart
│   └── supabase_provider.dart
│
├── router/
│   └── app_router.dart          # GoRouter 설정
│
└── shared/
    ├── widgets/                 # 공통 위젯
    └── theme/                   # 테마 설정
        └── app_theme.dart       # minorlab_common 기반
```

## 데이터 모델

**서버 스키마**: [../miniline/docs/SPEC_DATABASE_SCHEMA.md](../miniline/docs/SPEC_DATABASE_SCHEMA.md) 참조
**Isar 모델 패턴**: [../minorlab_book/lib/core/database/models/base.dart](../minorlab_book/lib/core/database/models/base.dart) 참조

**핵심**: 북랩 Base 패턴 재사용
```dart
// 모든 모델이 상속
class Base {
  Id id;                          // fastHash(remoteID)
  @Index(unique: true) String remoteID;  // UUID
  @Index() DateTime? refreshAt;   // UI 갱신 트리거
  @Index() bool synced = false;   // 동기화 상태
  @Index() bool deleted = false;  // 논리 삭제
  DateTime? deletedAt;            // 서버 관리 (클라이언트 설정 금지)
}
```

## 동기화 아키텍처

**패턴**: 북랩 3-서비스 구조 동일 ([참조](../minorlab_book/lib/core/services/sync/))
1. **IsarWatchSyncService**: 로컬 변경 감지 → 업로드 (lib/core/services/sync/isar_watch_sync_service.dart)
2. **SupabaseStreamService**: Realtime 구독 → 다운로드 (lib/core/services/sync/supabase_stream_service.dart)
3. **LifecycleService**: 앱 재시작 시 동기화 (lib/core/services/sync/lifecycle_service.dart)

**❌ 동기화 실패 시 저장 차단**
```dart
await isar.writeTxn(() => isar.fragments.put(fragment));
await supabase.from('fragments').insert(fragment.toJson());
// 네트워크 끊김 → 실패 → 데이터 유실
```

**✅ 로컬 우선 → 백그라운드 동기화**
```dart
await isar.writeTxn(() => isar.fragments.put(fragment));
// IsarWatchSyncService가 자동 업로드 (1초 디바운스)
```

## 앱 특화 기능

**상세**: [docs/DIFFERENCES_FROM_WEB.md](docs/DIFFERENCES_FROM_WEB.md) 참조

**웹에 없는 기능**:
- **공유 수신**: 다른 앱에서 텍스트/이미지 공유 → 자동 입력
- **로컬 알림**: 사용자 설정 시간에 입력 리마인더
- **푸시 알림**: Draft 생성 완료 시 FCM 알림
- **디바이스 관리**: 다중 기기 동기화

**UI 차이**:
- 하단 고정 입력창 (채팅 앱 스타일)
- 네이티브 네비게이션
- 상세: [docs/DESIGN_UI.md](docs/DESIGN_UI.md)

## 코딩 가이드

### Riverpod

**❌ StatefulWidget + Provider**
```dart
class MyWidget extends StatefulWidget {
  // Provider 상태 관리와 Widget 상태가 섞임
}
```

**✅ ConsumerWidget**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fragments = ref.watch(fragmentsProvider);
    return ListView(...);
  }
}
```

### Isar

**❌ 동기 쓰기**
```dart
isar.fragments.put(fragment); // 메인 스레드 블로킹
```

**✅ 비동기 트랜잭션**
```dart
await isar.writeTxn(() async {
  await isar.fragments.put(fragment);
});
```

**상세 패턴**: [/docs/flutter/GUIDE_ISAR_PATTERNS.md](/docs/flutter/GUIDE_ISAR_PATTERNS.md) 참조

### GoRouter

**❌ Navigator.push**
```dart
Navigator.push(context, MaterialPageRoute(...));
```

**✅ context.go / context.push**
```dart
context.go('/timeline');
context.push('/drafts');
```

### 에러 처리

**❌ 에러 무시**
```dart
try {
  await syncData();
} catch (e) {
  // 무시
}
```

**✅ 로깅 + UI 피드백**
```dart
try {
  await syncData();
} catch (e, stack) {
  logger.e('Sync failed', e, stack);
  toastStore.error('sync.failed'.tr());
}
```

## 개발 프로세스

**순서**:
1. [docs/PLAN.md](docs/PLAN.md) 확인 - 다음 작업
2. 관련 Feature 문서 읽기
3. 북랩 유사 기능 검색
4. 구현
5. 검증 체크리스트 확인
6. Commit

**Commit 형식**:
```
feat: Fragment 입력 화면 구현

- 하단 고정 입력창 (채팅 스타일)
- 이미지 첨부 (최대 3개)
- 실시간 글자수 카운트

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 자주 하는 실수

1. **동기화 실패로 저장 차단** → 로컬 우선, 동기화는 백그라운드
2. **텍스트 하드코딩** → `.tr()` 사용
3. **전체 코드 복사** → 핵심만 발췌
4. **테스트 없이 완료** → 실제 동작 확인 필수
5. **서버 스키마 무시** → 웹 DB 스키마와 일치 필수

---

**프로젝트 오너**: <danny@minorlab.com>
