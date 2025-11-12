# CLAUDE.md - MiniLine App

AI 기반 자동 조합 저널 앱 (Flutter 버전)

> **컨셉**: 짧은 생각들(Fragments)을 시간에 걸쳐 입력하면, AI가 자동으로 연결하고 완성된 글(Draft)로 조합

## 필수 검증 체크리스트

- [ ] 모든 텍스트 `.tr()` 형식 사용 (하드코딩 금지)
- [ ] 모든 아이콘 `AppIcons.xxx` 사용 (Lucide)
- [ ] 모든 색상 `ShadTheme.of(context).colorScheme.xxx` 사용
- [ ] `flutter analyze` 통과 (No issues found!)
- [ ] Isar 데이터 저장 확인 (Isar Inspector)
- [ ] 실제 동작 확인 (에뮬레이터/실기기)
- [ ] 동기화 확인 (웹↔앱 데이터 일치)
- [ ] 공유 기능 확인 (텍스트/이미지 공유 수신)

## 필수 참조 문서

**프로젝트 공통**:
- [/CLAUDE.md](/CLAUDE.md) - MinorLab 프로젝트 공통 가이드
- [/TECH_STACK.md](/TECH_STACK.md) - 기술 스택 통합 문서

**미니라인 웹 (참조용)**:
- [miniline/CLAUDE.md](miniline/CLAUDE.md) - 웹 버전 가이드
- [miniline/docs/SPEC_DATABASE_SCHEMA.md](miniline/docs/SPEC_DATABASE_SCHEMA.md) - 데이터베이스 스키마
- [miniline/docs/features/](miniline/docs/features/) - 기능별 상세 문서

**북랩 (참고 패턴)**:
- [minorlab_book/CLAUDE.md](minorlab_book/CLAUDE.md) - Flutter 앱 패턴
- [minorlab_book/lib/core/services/device_info_service.dart](minorlab_book/lib/core/services/device_info_service.dart) - 디바이스 정보 관리
- [minorlab_book/lib/core/services/share_handler_service.dart](minorlab_book/lib/core/services/share_handler_service.dart) - 공유 기능 패턴

## 핵심 원칙

### 1. 로컬 퍼스트 (북랩 패턴)

**❌ 서버 저장 실패 시 데이터 유실**
```dart
await supabase.from('fragments').insert({'content': content});
```

**✅ 로컬 먼저 → 동기화는 백그라운드**
```dart
final fragment = Fragment()
  ..remoteID = uuid.v4()
  ..content = content
  ..synced = false
  ..refreshAt = DateTime.now();
await isar.writeTxn(() => isar.fragments.put(fragment));
// SyncWatcher가 자동으로 업로드
```

### 2. AI 비용 최소화

- 앱에서는 AI API 직접 호출 없음
- 모든 AI 처리는 서버 사이드 (Edge Functions + Database Webhooks)
- 프리미엄: 실시간 임베딩 생성
- 무료: 배치 처리 대기

### 3. 웹과 데이터 공유

- 동일한 Supabase 프로젝트 사용
- 웹에서 작성한 Fragment를 앱에서도 볼 수 있음
- 실시간 동기화 (웹↔앱)

## 기술 스택

### 상태 관리
- `flutter_riverpod: ^3.0.3` - Riverpod 3.0

### 라우팅
- `go_router: ^16.2.4` - 선언적 라우팅

### 로컬 데이터베이스
- `isar_community: ^3.3.0-dev.1` - 로컬 DB (북랩과 동일)
- `isar_community_flutter_libs: ^3.3.0-dev.1` - Isar Core

### 백엔드
- `supabase_flutter: ^2.10.3` - Supabase (웹과 공유)
- `firebase_core: ^4.1.1` - Firebase 초기화
- `firebase_messaging: ^15.0.0` - FCM 푸시 알림

### UI 컴포넌트
- `shadcn_ui: ^0.39.3` - Shadcn UI (최신 버전)
- `flutter_lucide: ^latest` - Lucide 아이콘
- `toastification: ^3.0.3` - Toast 알림

### 알림
- `flutter_local_notifications: ^19.4.2` - 로컬 알림

### 공유 기능
- `share_handler: ^0.0.25` - 텍스트/이미지 공유 수신

### 다국어
- `easy_localization: ^3.0.7` - 다국어 지원

### 유틸리티
- `uuid: ^4.5.1` - UUID 생성
- `jiffy: ^6.3.1` - 날짜 처리
- `image_picker: ^1.1.2` - 이미지 선택
- `cached_network_image: ^3.4.1` - 이미지 캐싱

### 공통 라이브러리
- `minorlab_common` - MinorLab 공통 유틸리티, 테마

### 구독 및 결제
- `purchases_flutter: ^9.8.0` - RevenueCat

## 프로젝트 구조

```
miniline_app/
├── lib/
│   ├── app/
│   │   └── app.dart                    # ShadApp 설정
│   ├── core/
│   │   ├── constants/
│   │   ├── utils/
│   │   │   ├── app_icons.dart         # Lucide 아이콘 정의
│   │   │   └── logger.dart
│   │   └── services/
│   │       ├── device_info_service.dart  # 북랩 재사용
│   │       ├── notification_service.dart
│   │       └── share_handler_service.dart  # 공유 기능
│   ├── models/                         # Isar 모델
│   │   ├── fragment.dart               # @collection
│   │   ├── draft.dart
│   │   └── post.dart
│   ├── features/
│   │   ├── timeline/                   # Fragment 타임라인 (메인)
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   └── timeline_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── fragment_input_bar.dart  # 하단 고정 입력
│   │   │   │       └── fragment_card.dart
│   │   │   └── providers/
│   │   ├── drafts/                     # Draft 조회
│   │   ├── posts/                      # Post 조회/편집
│   │   ├── auth/                       # 인증
│   │   └── settings/                   # 설정 (구독 포함)
│   ├── providers/                      # Riverpod Providers
│   │   ├── isar_provider.dart
│   │   ├── supabase_provider.dart
│   │   ├── sync_provider.dart
│   │   └── auth_provider.dart
│   ├── router/
│   │   └── app_router.dart             # GoRouter 설정
│   └── shared/
│       ├── widgets/
│       └── theme/
└── assets/
    └── translations/
        ├── ko.json
        ├── en.json
        └── ja.json
```

## 데이터 모델

### Fragment (Isar)

```dart
@collection
class Fragment {
  /// Isar ID (remoteID의 해시값)
  Id get id => fastHash(remoteID);

  /// 원격 ID (UUID)
  @Index(unique: true)
  @Name('remote_id')
  late String remoteID;

  /// 사용자 ID
  @Index()
  @Name('user_id')
  late String userId;

  /// Fragment 내용
  late String content;

  /// 서버 타임스탬프 (생성 시간)
  late DateTime timestamp;

  /// 이벤트 발생 시간 (사용자가 실제 생각한 시간)
  @Index()
  @Name('event_time')
  late DateTime eventTime;

  /// 이벤트 시간 소스 ('auto' | 'manual' | 'ai_date' | 'ai_time')
  @Name('event_time_source')
  late String eventTimeSource;

  /// 미디어 URL 목록 (최대 3개)
  @Name('media_urls')
  List<String>? mediaUrls;

  /// 태그 목록 (AI 자동 생성, 서버에서 입력)
  List<String>? tags;

  /// 사용자 태그 (사용자가 수동 추가)
  @Name('user_tags')
  List<String>? userTags;

  /// 임베딩 벡터 (1536차원, 서버에서 생성)
  List<double>? embedding;

  /// 생성 시간
  @Index()
  @Name('created_at')
  late DateTime createdAt;

  /// 수정 시간
  @Name('updated_at')
  late DateTime updatedAt;

  /// 로컬 업데이트 처리를 위한 변수 (UI 갱신 트리거)
  @Index()
  @Name('refresh_at')
  DateTime? refreshAt;

  /// 동기화 상태
  @Index()
  bool synced = false;

  /// 논리 삭제 플래그
  @Index()
  bool deleted = false;

  /// 삭제 시간 (서버에서 관리)
  @Name('deleted_at')
  DateTime? deletedAt;
}
```

**Draft, Post 모델도 동일한 패턴 적용**

## 동기화 아키텍처 (북랩 패턴)

### 3-서비스 구조

1. **IsarWatchService**: 로컬 변경 감지 → 업로드
2. **SupabaseStreamService**: Realtime 구독 → 다운로드
3. **LifecycleService**: 앱 재시작 시 동기화

### Fragment 저장 플로우

```
1. 사용자 입력 → FragmentInputBar
   ↓
2. Isar 저장 (synced: false, refreshAt: now)
   ↓
3. IsarWatch 감지 (liveQuery)
   ↓
4. 1초 디바운스 → Supabase INSERT (embedding: null)
   ↓
5. Database Webhook → Edge Function /generate-embedding
   ↓
6. Edge Function → OpenAI API → embedding + tags 생성
   ↓
7. Edge Function → UPDATE fragments SET embedding, tags
   ↓
8. Realtime → Isar 자동 동기화 (refreshAt: now)
   ↓
9. UI 자동 갱신
```

### 웹↔앱 동기화

- 웹: Dexie (IndexedDB)
- 앱: Isar (Native)
- 서버: Supabase PostgreSQL

**데이터 일관성:**
- 동일한 Supabase 테이블 공유
- Realtime으로 실시간 동기화
- 충돌 해결: 서버 데이터 우선 (updated_at 비교)

## 화면 구조

### Timeline (메인 화면)

```
┌─────────────────────────────────┐
│ AppBar: [Drafts 뱃지] [Posts] [⋮]│
├─────────────────────────────────┤
│                                 │
│     Timeline (Fragments)        │
│     스크롤 가능                    │
│                                 │
│                                 │
├─────────────────────────────────┤
│ [이미지 프리뷰 (있을 경우)]          │
│ Textarea (동적 높이, 최대 300자)   │
│ [📷 0/3] [150/300]    [저장]    │ ← 하단 고정
└─────────────────────────────────┘
```

**특징:**
- Timeline이 유일한 메인 화면
- 하단 고정 입력창 (채팅 앱 스타일)
- Drafts/Posts/Settings는 AppBar에서 접근

### Fragment 입력창

**기능:**
- 최대 300자
- 최대 3개 이미지 (image_picker)
- 칩 스타일 버튼
- 동적 높이 조정
- 이미지 프리뷰 (80x80)

**구현 파일:** `features/timeline/presentation/widgets/fragment_input_bar.dart`

## 공유 기능 (share_handler)

### 북랩 패턴 재사용

**기능:**
- 다른 앱에서 텍스트/이미지 공유 시 MiniLine 앱으로 수신
- 수신 즉시 Fragment 입력 화면으로 이동
- 텍스트는 입력창에 자동 입력
- 이미지는 자동 첨부

### 구현

```dart
// lib/core/services/share_handler_service.dart
class ShareHandlerService {
  Future<void> initialize() async {
    final handler = ShareHandlerPlatform.instance;

    // 앱이 공유로 시작된 경우
    final initialMedia = await handler.getInitialSharedMedia();
    if (initialMedia != null) {
      _handleSharedMedia(initialMedia);
    }

    // 앱 실행 중 공유 수신
    handler.sharedMediaStream.listen((SharedMedia media) {
      _handleSharedMedia(media);
    });
  }

  void _handleSharedMedia(SharedMedia media) {
    // 이미지가 있는 경우
    if (media.attachments?.isNotEmpty == true) {
      _handleImageShare(context, media);
    }
    // 텍스트만 있는 경우
    else if (media.content != null && media.content!.isNotEmpty) {
      _handleTextShare(context, media.content!);
    }
  }

  void _handleTextShare(BuildContext context, String text) {
    // Timeline 화면으로 이동 + 입력창에 텍스트 자동 입력
    final router = GoRouter.of(context);
    router.go('/timeline', extra: {'sharedText': text});
  }

  void _handleImageShare(BuildContext context, SharedMedia media) {
    final imagePath = media.attachments!.first.path;
    // Timeline 화면으로 이동 + 이미지 자동 첨부
    final router = GoRouter.of(context);
    router.go('/timeline', extra: {
      'sharedImages': [imagePath],
      'sharedText': media.content ?? '',
    });
  }
}
```

### Timeline 화면에서 처리

```dart
// timeline_page.dart
class TimelinePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GoRouter extra 파라미터 확인
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final sharedText = extra?['sharedText'] as String?;
    final sharedImages = extra?['sharedImages'] as List<String>?;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: FragmentTimeline()),
          FragmentInputBar(
            initialText: sharedText,  // 공유된 텍스트 자동 입력
            initialImages: sharedImages,  // 공유된 이미지 자동 첨부
          ),
        ],
      ),
    );
  }
}
```

### Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application>
    <activity android:name=".MainActivity">
      <!-- 텍스트 공유 수신 -->
      <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
      </intent-filter>

      <!-- 이미지 공유 수신 -->
      <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="image/*" />
      </intent-filter>

      <!-- 여러 이미지 공유 수신 -->
      <intent-filter>
        <action android:name="android.intent.action.SEND_MULTIPLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="image/*" />
      </intent-filter>
    </activity>
  </application>
</manifest>
```

### iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key>
    <string>public.text</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.text</string>
      <string>public.plain-text</string>
    </array>
  </dict>
  <dict>
    <key>CFBundleTypeName</key>
    <string>public.image</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.image</string>
    </array>
  </dict>
</array>

<key>NSPhotoLibraryUsageDescription</key>
<string>이미지를 저장하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

## 알림 시스템

### 1. 로컬 알림 (flutter_local_notifications)

**Fragment 입력 리마인더:**
```dart
// 사용자가 설정에서 시간 선택 (기본: 09:00)
await NotificationSettings().setReminderTime(TimeOfDay(hour: 9, minute: 0));

// SharedPreferences에 저장 → 매일 반복 알림
await flutterLocalNotificationsPlugin.zonedSchedule(
  0,
  'fragment_reminder_title'.tr(),
  'fragment_reminder_body'.tr(),
  _nextInstanceOf(selectedTime),
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time,
);
```

### 2. FCM 푸시 알림 (firebase_messaging)

**디바이스 등록:**
```dart
// 앱 시작 시
await Firebase.initializeApp();
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null) {
  await DeviceInfoService().updateFcmToken(fcmToken);
}
```

**포그라운드 메시지 수신:**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // 로컬 알림으로 표시
  _showLocalNotification(message);
});
```

### 3. 사용자 알림 설정

**user_app_settings 테이블:**
```sql
CREATE TABLE user_app_settings (
  user_id uuid,
  app text, -- 'miniline'
  notification_enabled boolean,
  notification_start_time time, -- 알림 받을 시작 시간
  notification_end_time time,   -- 알림 받을 종료 시간
  notification_timezone text,   -- 사용자 시간대
  ...
);
```

**Edge Function에서 시간대 체크:**
- Draft 생성 완료 시 사용자 현지 시간 확인
- 시간대 내: 즉시 푸시 발송
- 시간대 밖: pending_notifications 테이블에 저장

**pg_cron 배치 발송:**
```sql
-- 매시간 pending_notifications 처리
SELECT cron.schedule(
  'send-pending-notifications',
  '0 * * * *',
  $$ ... $$
);
```

## UI 테마 시스템

### Shadcn UI + minorlab_common

```dart
// lib/app/app.dart
final shadLightTheme = common.MinorLabShadTheme.lightTheme(
  paletteId: 'miniline_indigo', // MiniLine 브랜드 컬러
  backgroundOption: themeConfig.backgroundOption,
);

final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
  paletteId: 'miniline_indigo',
  backgroundOption: themeConfig.backgroundOption,
);

return ShadApp.custom(
  themeMode: themeConfig.themeMode,
  theme: shadLightTheme,
  darkTheme: shadDarkTheme,
  appBuilder: (context) {
    final materialTheme = Theme.of(context);
    final shadTheme = ShadTheme.of(context);

    return MaterialApp.router(...);
  },
);
```

### 색상 사용

```dart
// ✅ Shadcn colorScheme 사용
final theme = ShadTheme.of(context);
Container(
  color: theme.colorScheme.primary,
  child: Text(
    'content'.tr(),
    style: TextStyle(color: theme.colorScheme.foreground),
  ),
)

// ❌ 하드코딩 금지
Container(color: Color(0xFF6366F1))
```

## 아이콘 시스템

### Lucide 아이콘 (flutter_lucide)

```dart
// lib/core/utils/app_icons.dart
import 'package:flutter_lucide/flutter_lucide.dart';

class AppIcons {
  // Fragment
  static const plus = LucideIcons.plus;
  static const pencil = LucideIcons.pencil;
  static const trash = LucideIcons.trash2;
  static const imagePlus = LucideIcons.image_plus;
  static const x = LucideIcons.x;

  // Draft/Post
  static const sparkles = LucideIcons.sparkles;
  static const fileText = LucideIcons.file_text;
  static const send = LucideIcons.send;

  // Navigation
  static const home = LucideIcons.home;
  static const settings = LucideIcons.settings;
  static const moreVertical = LucideIcons.more_vertical;
}
```

**사용법:**
```dart
Icon(AppIcons.plus, size: 20)
```

## 다국어 (easy_localization)

### 구조

```
assets/translations/
├── ko.json
├── en.json
└── ja.json
```

### 초기화

```dart
// main.dart
await EasyLocalization.ensureInitialized();

runApp(
  EasyLocalization(
    supportedLocales: [Locale('ko'), Locale('en'), Locale('ja')],
    path: 'assets/translations',
    fallbackLocale: Locale('ko'),
    child: MyApp(),
  ),
);
```

### 사용

```dart
// ✅
Text('input.placeholder'.tr())

// ❌ 하드코딩 금지
Text('무슨 생각을 하고 있나요?')
```

## 구독 시스템 (RevenueCat)

### 구독 플랜

- **무료**: 월 3개 Post 생성
- **프리미엄**: 무제한 Post 생성 + 즉시 임베딩

### 구현

```dart
// providers/subscription_provider.dart
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  Future<CustomerInfo> build() async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
    return await Purchases.getCustomerInfo();
  }

  Future<void> purchasePremium() async {
    final offerings = await Purchases.getOfferings();
    // 구매 로직
  }
}
```

### Supabase 테이블

- `user_subscriptions`: is_premium, free_posts_count
- RevenueCat Webhook → Supabase 동기화

## 개발 프로세스

### 1. 코딩 전

- [miniline/CLAUDE.md](miniline/CLAUDE.md) 확인
- 웹 버전 Feature 문서 참조
- 북랩 패턴 참고 (동기화, 알림, 공유)

### 2. 개발

**tmux 사용 필수 (Hot Reload 지원):**
```bash
# 세션 시작
tmux new-session -d -s miniline_app
tmux send-keys -t miniline_app "cd /Users/heyoom/Documents/Github/miniline_app && flutter run" C-m

# Hot Reload
tmux send-keys -t miniline_app "r" C-m
```

**코딩 규칙:**
- 모든 텍스트: `.tr()`
- 모든 아이콘: `AppIcons.xxx`
- 모든 색상: `ShadTheme.of(context).colorScheme.xxx`

### 3. 검증

```bash
flutter analyze  # No issues found!
flutter test     # 모든 테스트 통과
```

- [ ] Isar 데이터 저장 확인 (Isar Inspector)
- [ ] 동기화 확인 (웹↔앱 데이터 일치)
- [ ] 공유 기능 확인 (다른 앱 → MiniLine)
- [ ] 실제 동작 확인

### 4. 작업 완료

- "작업 마무리" 입력 → 자동 검증 실행
- 또는 `/finish` 실행

## 자주 하는 실수

### 1. 하드코딩

```dart
// ❌
Text('무슨 생각을 하고 있나요?')
Icon(Icons.add)
Container(color: Colors.blue)

// ✅
Text('input.placeholder'.tr())
Icon(AppIcons.plus)
Container(color: ShadTheme.of(context).colorScheme.primary)
```

### 2. 서버 저장 우선

```dart
// ❌ 서버 실패 시 데이터 유실
await supabase.from('fragments').insert({'content': content});

// ✅ 로컬 먼저
await isar.writeTxn(() => isar.fragments.put(fragment));
// SyncWatcher가 자동 업로드
```

### 3. AI API 직접 호출

```dart
// ❌ 앱에서 AI API 호출 금지
await openai.embeddings.create(...)

// ✅ 서버 사이드 처리
// Fragment INSERT → Database Webhook → Edge Function
```

### 4. 웹과 다른 스키마

- Supabase 테이블은 웹과 공유
- 필드명 변경 시 웹/앱 모두 영향
- 스키마 변경 전 미니라인 웹 팀과 협의

### 5. 공유 기능 테스트 누락

```bash
# Android: adb로 Intent 발송 테스트
adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "테스트 텍스트"

# iOS: 실기기에서 Safari → 공유 버튼 → MiniLine 선택
```

---

**프로젝트 오너**: <danny@minorlab.com>
**루트 가이드**: [/CLAUDE.md](/CLAUDE.md)
**웹 버전**: [miniline/CLAUDE.md](miniline/CLAUDE.md)
