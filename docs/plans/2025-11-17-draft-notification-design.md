# Draft 완성 알림 시스템 설계

> 작성: 2025-11-17
> 목적: 서버 기반 Draft 완성 알림 및 확장 가능한 알림 설정 시스템

## 개요

### 문제점

현재 Draft 완성 알림 설정:
- ❌ SharedPreferences에만 저장 (서버 확인 불가)
- ❌ ON/OFF만 가능 (시간 설정 없음)
- ❌ 새벽 알림 발생 가능
- ❌ 디바이스 간 동기화 불가

### 목표

1. **서버 기반 알림 설정**: Supabase DB에 저장하여 서버가 사용자 설정 확인
2. **시간대 제어**: 허용 시간 범위 설정 (예: 09:00-21:00)
3. **확장 가능한 구조**: 여러 앱에서 공통 사용 가능 (`user_feedback` 테이블 참고)
4. **디바이스 동기화**: 설정 변경 시 모든 디바이스에 반영

## 알림 타입별 특성

| 알림 타입 | 발송 방식 | 설정 저장소 | 시간 제어 |
|----------|----------|------------|----------|
| Daily Reminder | 로컬 알림 (flutter_local_notifications) | SharedPreferences | 특정 시간 지정 |
| Draft 완성 | FCM 푸시 (서버 발송) | Supabase DB | 허용 시간대 범위 |
| Post 생성 | FCM 푸시 (서버 발송) | 불필요 (앱 상태로 판단) | - |

**Draft 완성 알림 특성:**
- 배치 작업이 하루 1회 생성 (무료 사용자 기준)
- 생성 시간은 `batch_slot`에 의해 결정 (사용자가 선택 불가)
- 허용 시간 내 생성 → 즉시 알림
- 허용 시간 밖 생성 → 다음 허용 시작 시간에 알림

## DB 테이블 설계

### user_notification_settings 테이블

```sql
-- ===== 알림 설정 테이블 (확장 가능) =====
-- 작성: 2025-11-17
-- 목적: 모든 앱에서 공통 사용 가능한 알림 설정
-- 프로젝트: MiniLine (다른 앱 확장 가능)

CREATE TABLE public.user_notification_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- 앱 및 알림 타입 구분
    app_name text NOT NULL DEFAULT 'miniline',
    notification_type text NOT NULL,  -- 'draft_completion', 'post_creation' 등

    -- 기본 설정
    enabled boolean NOT NULL DEFAULT true,

    -- 타입별 추가 설정 (JSONB)
    settings jsonb DEFAULT '{}',

    -- 메타데이터
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- 중복 방지: 사용자당 앱당 알림타입당 1개
    CONSTRAINT user_notification_settings_unique
      UNIQUE (user_id, app_name, notification_type)
);

-- 인덱스: 배치 발송 시 효율적 조회
CREATE INDEX idx_user_notification_settings_lookup
  ON public.user_notification_settings(app_name, notification_type, enabled);

CREATE INDEX idx_user_notification_settings_user
  ON public.user_notification_settings(user_id, app_name);

-- RLS (Row Level Security)
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 사용자는 본인 설정만 조회/수정 가능
CREATE POLICY "Users can view their own notification settings"
    ON public.user_notification_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification settings"
    ON public.user_notification_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification settings"
    ON public.user_notification_settings FOR UPDATE
    USING (auth.uid() = user_id);

-- Trigger: updated_at 자동 업데이트
CREATE TRIGGER handle_updated_at_user_notification_settings
    BEFORE UPDATE ON public.user_notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- 코멘트
COMMENT ON TABLE public.user_notification_settings IS '통합 알림 설정 시스템 (모든 앱 공통)';
COMMENT ON COLUMN public.user_notification_settings.notification_type IS '알림 타입 (draft_completion, post_creation 등)';
COMMENT ON COLUMN public.user_notification_settings.settings IS '알림 타입별 추가 설정 (JSONB)';
```

### 데이터 예시

**Draft 완성 알림:**
```json
{
  "id": "...",
  "user_id": "...",
  "app_name": "miniline",
  "notification_type": "draft_completion",
  "enabled": true,
  "settings": {
    "allowed_start": "09:00",
    "allowed_end": "21:00"
  }
}
```

**Post 생성 알림 (미래 확장):**
```json
{
  "id": "...",
  "user_id": "...",
  "app_name": "miniline",
  "notification_type": "post_creation",
  "enabled": true,
  "settings": {}
}
```

### 행 분리 방식 선택 이유

1. **쿼리 효율성:**
```sql
-- 배치 발송 시: enabled로 직접 필터링 (JSONB 파싱 불필요)
SELECT user_id, settings
FROM user_notification_settings
WHERE app_name = 'miniline'
  AND notification_type = 'draft_completion'
  AND enabled = true;
```

2. **명확성:** enabled 컬럼으로 즉시 활성화 여부 판단

3. **일관성:** `user_feedback` 테이블과 동일한 패턴 (행 분리)

4. **확장성:** 새 알림 타입 추가 시 row만 INSERT

## Edge Function 설계

### 1. Draft 생성 배치 함수 수정

**파일:** `supabase/functions/generate-drafts/index.ts`

**추가 로직:**

```typescript
// Draft 생성 후 알림 발송
async function sendDraftCompletionNotification(
  userId: string,
  draft: Draft
) {
  // 1. 알림 설정 조회
  const { data: settings, error } = await supabase
    .from('user_notification_settings')
    .select('enabled, settings')
    .eq('user_id', userId)
    .eq('app_name', 'miniline')
    .eq('notification_type', 'draft_completion')
    .maybeSingle();

  // 설정 없으면 기본값으로 즉시 발송 (첫 사용자)
  if (!settings) {
    await sendFCM(userId, draft);
    return;
  }

  // 알림 꺼짐
  if (!settings.enabled) {
    return;
  }

  // 2. 현재 시간 확인
  const now = new Date();
  const userTimezone = await getUserTimezone(userId); // user_metadata에서 조회
  const currentTime = now.toLocaleString('en-US', {
    timeZone: userTimezone,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }); // "HH:MM"

  const { allowed_start, allowed_end } = settings.settings;

  // 3. 허용 시간 내 → 즉시 발송
  if (currentTime >= allowed_start && currentTime <= allowed_end) {
    await sendFCM(userId, draft);
  }
  // 4. 허용 시간 밖 → 예약 발송
  else {
    await schedulePendingNotification(userId, draft, allowed_start, userTimezone);
  }
}

async function sendFCM(userId: string, draft: Draft) {
  // FCM 토큰 조회 (user_devices 테이블 등)
  const tokens = await getFCMTokens(userId);

  for (const token of tokens) {
    await admin.messaging().send({
      token,
      notification: {
        title: '새로운 초안이 완성되었습니다',
        body: draft.title,
      },
      data: {
        type: 'draft_completion',
        draftId: draft.id,
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });
  }
}

async function schedulePendingNotification(
  userId: string,
  draft: Draft,
  allowedStart: string,
  timezone: string
) {
  // pending_notifications 테이블에 저장
  await supabase.from('pending_notifications').insert({
    user_id: userId,
    app_name: 'miniline',
    notification_type: 'draft_completion',
    payload: {
      title: '새로운 초안이 완성되었습니다',
      body: draft.title,
      data: { draftId: draft.id },
    },
    scheduled_time: calculateNextAllowedTime(allowedStart, timezone),
  });
}
```

### 2. pending_notifications 테이블

```sql
CREATE TABLE public.pending_notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    app_name text NOT NULL,
    notification_type text NOT NULL,
    payload jsonb NOT NULL,  -- FCM payload
    scheduled_time timestamptz NOT NULL,
    sent boolean DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pending_notifications_schedule
  ON public.pending_notifications(scheduled_time)
  WHERE sent = false;
```

### 3. Cron 함수 (예약 알림 발송)

**파일:** `supabase/functions/send-pending-notifications/index.ts`

**Cron 설정:** 매 시간마다 실행 (`0 * * * *`)

```typescript
// 발송 시간이 된 예약 알림 조회 및 발송
const { data: pendingNotifications } = await supabase
  .from('pending_notifications')
  .select('*')
  .lte('scheduled_time', new Date().toISOString())
  .eq('sent', false);

for (const notification of pendingNotifications) {
  const tokens = await getFCMTokens(notification.user_id);

  for (const token of tokens) {
    await admin.messaging().send({
      token,
      ...notification.payload,
    });
  }

  // 발송 완료 표시
  await supabase
    .from('pending_notifications')
    .update({ sent: true })
    .eq('id', notification.id);
}
```

## 클라이언트 구현

### 1. UI 수정

**파일:** `lib/features/settings/presentation/widgets/draft_notification_sheet.dart`

```dart
class _DraftNotificationSheetState extends ConsumerState<DraftNotificationSheet> {
  bool _enabled = true;
  TimeOfDay _allowedStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _allowedEnd = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    final response = await supabase
        .from('user_notification_settings')
        .select()
        .eq('user_id', userId)
        .eq('app_name', 'miniline')
        .eq('notification_type', 'draft_completion')
        .maybeSingle();

    if (response != null && mounted) {
      final settings = response['settings'] as Map<String, dynamic>;
      setState(() {
        _enabled = response['enabled'] as bool;
        _allowedStart = _parseTime(settings['allowed_start'] as String);
        _allowedEnd = _parseTime(settings['allowed_end'] as String);
      });
    }
  }

  Future<void> _saveSettings() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    await supabase.from('user_notification_settings').upsert({
      'user_id': userId,
      'app_name': 'miniline',
      'notification_type': 'draft_completion',
      'enabled': _enabled,
      'settings': {
        'allowed_start': _formatTime(_allowedStart),
        'allowed_end': _formatTime(_allowedEnd),
      },
    });
  }

  // UI: enabled 스위치 + 시간 범위 선택
}
```

### 2. 로컬 캐싱 + 서버 동기화

**현재:** SharedPreferences만 사용 (서버 동기화 없음)
**변경:** 로컬 캐시 + 서버 동기화 (깜빡임 방지)

**읽기 순서:**
1. 로컬 캐시 먼저 읽기 (즉시 UI 표시)
2. 백그라운드에서 서버 데이터 가져오기
3. 서버 데이터로 UI 업데이트 (변경 있을 경우)

**쓰기 순서:**
1. 로컬 캐시 즉시 업데이트 (UI 반영)
2. 서버로 전송
3. 성공 시 완료, 실패 시 재시도

**Provider 구현 (PolicyLatestPage 패턴 적용):**

```dart
/// 알림 설정 상태
enum NotificationSettingsState {
  initial,     // 초기 상태
  loading,     // 로딩 중 (캐시 없음)
  refreshing,  // 백그라운드 새로고침 (캐시 있음)
  loaded,      // 로드 완료
  error,       // 에러
}

@riverpod
class DraftNotificationSettings extends _$DraftNotificationSettings {
  static const String _keyEnabled = 'draft_notification_enabled';
  static const String _keyStart = 'draft_notification_start';
  static const String _keyEnd = 'draft_notification_end';

  NotificationSettingsState _pageState = NotificationSettingsState.initial;

  NotificationSettingsState get pageState => _pageState;

  @override
  Future<NotificationSettingsData> build() async {
    return await loadWithCache();
  }

  /// 캐시 우선 로드 (PolicyLatestPage 패턴)
  Future<NotificationSettingsData> loadWithCache() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);

      // 1. 캐시 먼저 읽기
      final cachedEnabled = prefs.getBool(_keyEnabled);
      final cachedStart = prefs.getString(_keyStart);
      final cachedEnd = prefs.getString(_keyEnd);

      // 캐시가 있으면 즉시 반환
      if (cachedEnabled != null && cachedStart != null && cachedEnd != null) {
        final cached = NotificationSettingsData(
          enabled: cachedEnabled,
          allowedStart: cachedStart,
          allowedEnd: cachedEnd,
        );

        // 상태를 loaded로 설정
        _pageState = NotificationSettingsState.loaded;

        // 2. 백그라운드에서 서버 확인 (Cache-First with Always-Check)
        _checkForUpdates();

        return cached;
      }

      // 캐시 없으면 로딩 표시
      _pageState = NotificationSettingsState.loading;
      return await _fetchFromServer();
    } catch (e) {
      // 캐시 로드 실패시 서버에서 로드
      _pageState = NotificationSettingsState.loading;
      return await _fetchFromServer();
    }
  }

  /// 서버에서 데이터 가져오기
  Future<NotificationSettingsData> _fetchFromServer() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        // 로그인 안됨 → 기본값 + 캐시 저장
        final defaultSettings = NotificationSettingsData(
          enabled: true,
          allowedStart: '09:00',
          allowedEnd: '21:00',
        );
        await _saveToCache(defaultSettings);
        _pageState = NotificationSettingsState.loaded;
        return defaultSettings;
      }

      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('app_name', 'miniline')
          .eq('notification_type', 'draft_completion')
          .maybeSingle();

      if (response == null) {
        // 서버에 데이터 없음 → 기본값 + 캐시 저장
        final defaultSettings = NotificationSettingsData(
          enabled: true,
          allowedStart: '09:00',
          allowedEnd: '21:00',
        );
        await _saveToCache(defaultSettings);
        _pageState = NotificationSettingsState.loaded;
        return defaultSettings;
      }

      final settings = NotificationSettingsData(
        enabled: response['enabled'] as bool,
        allowedStart: response['settings']['allowed_start'] as String,
        allowedEnd: response['settings']['allowed_end'] as String,
      );

      await _saveToCache(settings);
      _pageState = NotificationSettingsState.loaded;
      return settings;
    } catch (e) {
      _pageState = NotificationSettingsState.error;
      logger.e('Failed to fetch notification settings', e);
      rethrow;
    }
  }

  /// 백그라운드 업데이트 확인 (PolicyLatestPage 패턴)
  Future<void> _checkForUpdates() async {
    _pageState = NotificationSettingsState.refreshing;

    try {
      final serverData = await _fetchFromServer();

      // 데이터 변경 확인
      final currentData = state.value;
      if (currentData != null && _hasDataChanged(currentData, serverData)) {
        // 변경사항 있으면 업데이트
        state = AsyncValue.data(serverData);
      }

      _pageState = NotificationSettingsState.loaded;
    } catch (e) {
      // 서버 에러는 조용히 실패 (캐시 데이터 유지)
      _pageState = NotificationSettingsState.loaded;
      logger.e('Background sync failed (ignored)', e);
    }
  }

  /// 데이터 변경 여부 확인
  bool _hasDataChanged(NotificationSettingsData current, NotificationSettingsData server) {
    return current.enabled != server.enabled ||
           current.allowedStart != server.allowedStart ||
           current.allowedEnd != server.allowedEnd;
  }

  /// 캐시 저장
  Future<void> _saveToCache(NotificationSettingsData settings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setString(_keyStart, settings.allowedStart);
    await prefs.setString(_keyEnd, settings.allowedEnd);
  }

  /// 설정 업데이트 (사용자 액션)
  Future<void> updateSettings(NotificationSettingsData settings) async {
    // 1. 즉시 UI 업데이트
    state = AsyncValue.data(settings);

    // 2. 로컬 캐시 저장
    await _saveToCache(settings);

    // 3. 서버로 전송
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase.from('user_notification_settings').upsert({
        'user_id': userId,
        'app_name': 'miniline',
        'notification_type': 'draft_completion',
        'enabled': settings.enabled,
        'settings': {
          'allowed_start': settings.allowedStart,
          'allowed_end': settings.allowedEnd,
        },
      });
    } catch (e) {
      logger.e('Failed to save notification settings to server', e);
      // 서버 저장 실패해도 캐시는 이미 저장됨 (다음 동기화에서 재시도)
    }
  }
}

class NotificationSettingsData {
  final bool enabled;
  final String allowedStart;  // "HH:MM"
  final String allowedEnd;    // "HH:MM"

  NotificationSettingsData({
    required this.enabled,
    required this.allowedStart,
    required this.allowedEnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsData &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          allowedStart == other.allowedStart &&
          allowedEnd == other.allowedEnd;

  @override
  int get hashCode =>
      enabled.hashCode ^ allowedStart.hashCode ^ allowedEnd.hashCode;
}
```

**settings_page.dart에서 사용:**

```dart
// ListTile에 설정값 표시 (캐시에서 즉시 로드)
Consumer(
  builder: (context, ref, child) {
    final settingsAsync = ref.watch(draftNotificationSettingsProvider);

    return settingsAsync.when(
      data: (settings) => ListTile(
        leading: Icon(AppIcons.notification),
        title: Text('settings.draft_notifications'.tr()),
        subtitle: Text(
          settings.enabled
              ? '${settings.allowedStart} - ${settings.allowedEnd}'
              : 'settings.draft_notifications_description'.tr(),
        ),
        trailing: Icon(AppIcons.chevronRight, size: 20),
        onTap: _showDraftNotificationSettings,
      ),
      loading: () => ListTile(
        leading: Icon(AppIcons.notification),
        title: Text('settings.draft_notifications'.tr()),
        subtitle: Text('common.loading'.tr()),
        trailing: Icon(AppIcons.chevronRight, size: 20),
      ),
      error: (_, __) => ListTile(
        leading: Icon(AppIcons.notification),
        title: Text('settings.draft_notifications'.tr()),
        subtitle: Text('settings.draft_notifications_description'.tr()),
        trailing: Icon(AppIcons.chevronRight, size: 20),
        onTap: _showDraftNotificationSettings,
      ),
    );
  },
),
```

**장점:**
- 로컬 캐시로 즉시 표시 (깜빡임 없음)
- 백그라운드 동기화로 최신 데이터 유지
- 오프라인에서도 캐시 데이터 사용 가능

### 3. FCM 핸들러

**파일:** `lib/core/services/fcm_service.dart`

```dart
void _handleForegroundMessage(RemoteMessage message) {
  final type = message.data['type'];

  if (type == 'draft_completion') {
    // Draft 상세 화면으로 이동 (딥링크)
    final draftId = message.data['draftId'];
    // GoRouter로 네비게이션
  }
}
```

## 엣지 케이스

### 1. 타임존 처리

- 사용자 타임존은 `auth.users.raw_user_meta_data->>'timezone'`에 저장
- 저장되지 않은 경우 기기 타임존 사용 (클라이언트가 첫 로그인 시 저장)

### 2. 허용 시간 범위 검증

- `allowed_start < allowed_end` 검증 (클라이언트 + 서버)
- 자정 걸치는 설정 불가 (예: 22:00-02:00) → Phase 2

### 3. FCM 토큰 관리

- `user_devices` 테이블에 디바이스별 FCM 토큰 저장
- 앱 설치 제거 시 토큰 삭제 (FCM 에러 핸들링)

### 4. 배치 슬롯과 허용 시간 충돌

**시나리오:**
- 사용자 배치 슬롯: 새벽 2시
- 허용 시간: 09:00-21:00

**처리:**
- Draft는 새벽 2시에 생성
- 알림은 09:00에 예약 발송
- 사용자는 09:00에 확인 가능

### 5. 설정 변경 시 pending_notifications 처리

**시나리오:**
- 예약된 알림이 있는 상태에서 사용자가 설정 변경 (예: 허용 시간 변경)

**처리:**
- 설정 변경 시 해당 사용자의 pending_notifications 재계산
- 새 허용 시간으로 scheduled_time 업데이트

## 마이그레이션 계획

### Phase 1: DB 테이블 생성

1. 마이그레이션 파일 생성: `20251117_001_miniline_notification_settings.sql`
2. Supabase Dashboard에서 실행
3. RLS 정책 확인

### Phase 2: Edge Function 수정

1. `generate-drafts` 함수에 알림 로직 추가
2. `send-pending-notifications` Cron 함수 생성
3. FCM Admin SDK 설정 확인

### Phase 3: 클라이언트 구현

1. UI 수정 (시간 범위 선택)
2. Supabase 연동
3. SharedPreferences 제거

### Phase 4: 테스트

1. 허용 시간 내 Draft 생성 → 즉시 알림 확인
2. 허용 시간 밖 Draft 생성 → 예약 알림 확인
3. 설정 변경 → 동기화 확인
4. 디바이스 간 동기화 확인

## 참고

- `user_feedback` 테이블: [/minorlab_schema/20251111_005_weaver_user_feedback.sql](../../../minorlab_schema/20251111_005_weaver_user_feedback.sql)
- Firebase FCM: [lib/core/services/fcm_service.dart](../../lib/core/services/fcm_service.dart)
- Daily reminder (로컬 알림): [lib/features/settings/presentation/widgets/daily_reminder_sheet.dart](../../lib/features/settings/presentation/widgets/daily_reminder_sheet.dart)

---

**다음 단계:**
- [ ] 마이그레이션 파일 작성
- [ ] Edge Function 구현
- [ ] 클라이언트 UI 수정
- [ ] 테스트 및 검증
