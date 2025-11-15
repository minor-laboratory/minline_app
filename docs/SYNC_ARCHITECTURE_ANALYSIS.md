# 동기화 아키텍처 분석

> Realtime Channel vs Database Stream 비교 분석 (2025년 기준)

## 두 가지 방식 비교

### 1. Realtime Channel (postgres_changes)
**사용 중**: MiniLine 웹 (miniline/)

```typescript
supabase
  .channel('db-changes')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'fragments' }, (payload) => {
    handleRealtimeChange('fragments', payload);
  })
  .subscribe();
```

**특징**:
- INSERT/UPDATE/DELETE 이벤트를 명확히 구분
- 변경된 레코드 전체를 수신
- 클라이언트 측에서 직접 구독

**장점**:
- ✅ 간단한 설정
- ✅ 이벤트 타입 명확 (INSERT/UPDATE/DELETE)
- ✅ 재연결 로직 구현 용이

**단점**:
- ❌ 성능: 단일 스레드 처리 (스케일링 제한)
- ❌ 비용: 100명 구독 시 1개 insert = 100 messages
- ❌ RLS 오버헤드: 매 변경마다 각 사용자에 대해 RLS 체크
- ❌ 컴퓨트 업그레이드 효과 제한적
- ❌ 초기 데이터 별도 fetch 필요

---

### 2. Database Stream (.stream())
**사용 중**: 북랩 앱 (minorlab_book/)

```dart
supabase
  .from('fragments')
  .stream(primaryKey: ['id'])
  .gt('updated_at', lastSyncTime)
  .listen((data) {
    handleUpdate(data);
  });
```

**특징**:
- 초기 데이터 + 실시간 업데이트 통합
- 서버 사이드 타임스탬프 필터링
- 변경된 레코드만 증분 업데이트

**장점**:
- ✅ 초기 데이터 + 실시간 업데이트 한번에 해결
- ✅ 서버 사이드 필터링 (gt, lt, eq 등)
- ✅ RLS + 필터로 필요한 데이터만 전송
- ✅ 타임스탬프 기반 증분 업데이트 (대역폭 절약)
- ✅ Flutter/Dart Stream API와 통합

**단점**:
- ❌ postgres_changes 기반이므로 동일한 스케일링 제한
- ❌ 이벤트 타입 구분 불가 (INSERT/UPDATE 통합)
- ❌ 초기 데이터 포함 시 메시지 수 증가 가능

---

### 3. Broadcast (Supabase 권장)
**사용 중**: 없음

```typescript
// Database Trigger로 메시지 발행
CREATE TRIGGER broadcast_fragment_changes
AFTER INSERT OR UPDATE OR DELETE ON fragments
FOR EACH ROW EXECUTE FUNCTION broadcast_changes();

// 클라이언트 구독
supabase
  .channel('fragments')
  .on('broadcast', { event: 'fragment_changed' }, (payload) => {
    handleChange(payload);
  })
  .subscribe();
```

**특징**:
- Database Trigger + Broadcast 메시지
- 스케일링에 최적화
- 메시지 내용 커스터마이징 가능

**장점**:
- ✅ 최고의 스케일링 성능
- ✅ 타겟 액션 선택 가능 (INSERT/UPDATE/DELETE)
- ✅ 특정 컬럼만 전송 (대역폭 절약)
- ✅ RLS 오버헤드 없음

**단점**:
- ❌ 복잡한 설정 (Database Trigger 필요)
- ❌ 초기 데이터 별도 fetch 필요
- ❌ 메시지 구조 직접 설계 필요

---

## 비용 분석

### Realtime 메시지 요금 (2025년 기준)
- **$2.50 per 1M messages**
- 1 postgres_change = 1 message × 구독 클라이언트 수
- 예: 100명 구독 → 1개 insert → 100 messages

### 대역폭(Egress) 요금
- **$0.09 per GB** (uncached)
- **$0.03 per GB** (cached)

### 시나리오: 1,000명 사용자, 하루 100개 Fragment 생성
**Realtime Channel 방식**:
- 100 inserts × 1,000 users = 100,000 messages/day
- 월: 3M messages = $7.50/month
- 초기 데이터 fetch 별도 (Egress 비용)

**Database Stream 방식**:
- 서버 필터링으로 필요한 데이터만 전송
- RLS가 서버에서 필터링 → 메시지 수 감소
- 초기 데이터 포함 (추가 비용 없음)
- 추정: ~1.5M messages = $3.75/month

**Broadcast 방식**:
- 가장 효율적 (특정 컬럼만 전송)
- 추정: ~1M messages = $2.50/month

---

## 성능 벤치마크 (Supabase 공식)

### Postgres Changes
- 단일 스레드 처리
- RLS 체크 오버헤드
- 컴퓨트 업그레이드 효과 제한적

### Broadcast
- 멀티 스레드 가능
- RLS 오버헤드 없음
- 컴퓨트 업그레이드 효과 큼

> **Supabase 공식 권장**: "Postgres Changes are simple to use, but have some limitations as your application scales. We recommend using Broadcast for most use cases."

---

## MiniLine 앱 권장 방식

### 현재 상황
- 초기 버전 (사용자 수 < 1,000)
- Fragment, Draft, Post 3개 테이블
- 북랩과 동일한 데이터 모델
- 북랩에서 Database Stream 검증됨

### 권장: Database Stream 방식 (북랩 패턴)

**이유**:
1. **북랩 검증**: 이미 북랩에서 안정적으로 운영 중
2. **초기 데이터 + 실시간**: 한번에 해결 (코드 간결)
3. **서버 필터링**: 타임스탬프 기반 증분 업데이트 (비용 절약)
4. **Flutter 통합**: Stream API 네이티브 지원
5. **마이그레이션 용이**: 추후 Broadcast 전환 가능

**장기 계획**:
- **1단계** (현재): Database Stream (소규모~중규모)
- **2단계** (사용자 > 10,000): Broadcast 전환 검토

---

## 구현 패턴

### Database Stream 방식 (권장)

```dart
// 1. SupabaseStreamService (Riverpod keepAlive Provider)
class SupabaseStreamService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _fragmentStreamSubscription;
  bool _isListening = false;

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;

    // 마지막 동기화 시간 저장
    final lastSync = await SyncMetadataService.getLastSyncTime('fragments');

    // 서버 사이드 필터링 스트림 구독
    _fragmentStreamSubscription = _supabase
      .from('fragments')
      .stream(primaryKey: ['id'])
      .gt('updated_at', lastSync.toIso8601String())  // 서버 필터링
      .listen((List<Map<String, dynamic>> data) {
        // RLS가 user_id 필터링 자동 처리
        // 변경된 데이터만 수신 (증분 업데이트)
        _handleFragmentUpdate(data);
      });
  }

  Future<void> _handleFragmentUpdate(List<Map<String, dynamic>> data) async {
    // 로컬 DB 업데이트
    await isar.writeTxn(() async {
      await isar.fragments.putAll(fragments);
    });

    // 동기화 시간 업데이트
    await SyncMetadataService.setLastSyncTime('fragments', maxUpdatedAt);
  }
}

// 2. Riverpod Provider 정의 (keepAlive: true)
@Riverpod(keepAlive: true)
SupabaseStreamService supabaseStreamService(Ref ref) {
  final service = SupabaseStreamService();
  ref.onDispose(() => service.dispose());
  return service;
}

// 3. LifecycleService가 Provider를 통해 접근
class LifecycleService {
  WidgetRef? _ref;

  Future<void> initialize(WidgetRef ref) async {
    _ref = ref;
    // ... 초기화 로직
  }

  void _startAllServices() {
    if (_ref == null) return;

    // keepAlive Provider를 통해 접근 (인스턴스 재사용 보장)
    _ref!.read(supabaseStreamServiceProvider).startListening();
    _ref!.read(isarWatchSyncServiceProvider).start();
  }

  void _stopAllServices() {
    if (_ref == null) return;

    // 동일한 인스턴스 접근
    _ref!.read(supabaseStreamServiceProvider).stopListening();
    _ref!.read(isarWatchSyncServiceProvider).stop();
  }
}
```

**핵심 요소**:
1. **keepAlive Provider**: 앱 생명주기 동안 인스턴스 유지 (Singleton 대체)
2. **ref.read() 접근**: LifecycleService가 Provider를 통해 서비스 접근 (필드 저장 불필요)
3. **타임스탬프 필터링**: `gt('updated_at', lastSync)` → 증분 업데이트만
4. **RLS 자동 적용**: 서버에서 user_id 필터링
5. **메타데이터 관리**: 마지막 동기화 시간 저장
6. **에러 처리**: 재연결 + JWT 토큰 갱신

---

## 결론

**MiniLine 앱 동기화 방식**: **Database Stream (북랩 패턴)**

- ✅ 북랩에서 검증된 안정성
- ✅ 비용 효율적 (서버 필터링)
- ✅ 구현 간결 (초기 데이터 + 실시간 통합)
- ✅ 마이그레이션 용이 (추후 Broadcast 전환 가능)

**다음 단계**: Phase 1.4 동기화 서비스 구현 (북랩 3-서비스 패턴 재사용)
