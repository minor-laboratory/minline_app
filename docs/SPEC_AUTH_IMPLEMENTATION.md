# 인증 기능 구현 사양

**작성일**: 2025-01-14
**목적**: minorlab_common 기반 새로운 인증 UI 구현 후 역이식

## 개요

기존 minorlab_common의 AuthPage는 Material + shadcn_ui 혼용으로 디자인이 일관되지 않음. 미니라인 앱에서 shadcn_ui 기반의 새로운 인증 UI를 구현하고, 완성 후 minorlab_common에 추가하여 북랩 등에서 재사용.

## 현황 분석

### minorlab_common 인증 기능

**장점**:
- ✅ 완전한 인증 로직 (Google, Apple, Email)
- ✅ 세밀한 에러 처리 (커스텀 예외 클래스)
- ✅ Riverpod Provider 구조
- ✅ AuthUser 모델 (Freezed)

**단점**:
- ❌ Material + shadcn_ui 혼용 (구버전 UI)
- ❌ Icons.xxx 직접 사용 (AppIcons 미사용)
- ❌ SnackBar 사용 (일관된 Toast 없음)
- ❌ Navigator.push 사용 (GoRouter 미사용)

### 북랩 인증 기능

**추가 기능**:
- ✅ 로컬 데이터 처리 (DatabaseService 재초기화)
- ✅ 비밀번호 관리 (hasExistingPassword, setPassword)
- ✅ 회원 탈퇴 (Edge Function 호출)
- ✅ OAuth 사용자 비밀번호 설정

**미니라인 불필요 기능**:
- ❌ 익명 로그인 (지연 로그인 전략 사용)
- ❌ 로컬 데이터 병합 다이얼로그

## 디자인 가이드 준수

### 필수 원칙

1. **shadcn_ui 컴포넌트 사용**
   ```dart
   // ✅ 필수
   ShadButton, ShadInput, ShadCard, ShadAvatar

   // ❌ 금지
   FilledButton, TextField, Card, CircleAvatar
   ```

2. **AppIcons 사용**
   ```dart
   // ✅ 필수
   Icon(AppIcons.email), Icon(AppIcons.password)

   // ❌ 금지
   Icon(Icons.email), Icon(Icons.lock)
   ```

3. **텍스트 입력 → 페이지로 구현**
   ```dart
   // ✅ 로그인/회원가입 페이지
   class AuthPage extends ConsumerStatefulWidget

   // ❌ 다이얼로그/BottomSheet 금지
   showDialog(...) // 절대 사용 금지
   ```

4. **ShadInput trailing 크기 고정**
   ```dart
   // ✅ 필수
   ShadInput(
     trailing: ShadButton.ghost(
       width: 24,
       height: 24,
       padding: EdgeInsets.zero,
       child: Icon(Icons.visibility, size: 16),
     ),
   )
   ```

## 구현 요구사항

### 1. 기본 인증 기능

- **Google 로그인**: google_sign_in 패키지 사용
- **Apple 로그인**: sign_in_with_apple 패키지 사용
- **Email 로그인**: Supabase signInWithPassword
- **Email 회원가입**: Supabase signUp
- **비밀번호 재설정**: resetPasswordForEmail
- **로그아웃**: signOut (익명 전환 없음)

### 2. UI 구성

#### AuthPage (로그인/회원가입 통합)

**레이아웃**:
```
┌─────────────────────────────────┐
│ ← 로그인                        │ AppBar
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ [로고]                  │   │ ShadCard
│  │                         │   │
│  │ 로그인                  │   │
│  │ MiniLine에 오신 것을... │   │
│  │                         │   │
│  │ [이메일 입력]          │   │ ShadInput
│  │ [비밀번호 입력]        │   │ ShadInput
│  │                         │   │
│  │ [로그인]               │   │ ShadButton
│  │ [회원가입으로 전환]    │   │ ShadButton.ghost
│  │ [비밀번호 찾기]        │   │ ShadButton.ghost
│  │                         │   │
│  │ ────── 또는 ──────     │   │
│  │                         │   │
│  │ [Google로 계속하기]    │   │ ShadButton.outline
│  │ [Apple로 계속하기]     │   │ ShadButton.outline
│  │                         │   │
│  │ 계속하면 이용약관에... │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

**컴포넌트**:
- `ShadCard`: 전체 폼 컨테이너
- `ShadInput`: 이메일, 비밀번호 입력
  - leading: 아이콘 (AppIcons 사용)
  - trailing: 비밀번호 표시/숨김 (크기 고정)
- `ShadButton`: 주요 액션 (로그인/회원가입)
- `ShadButton.outline`: 소셜 로그인
- `ShadButton.ghost`: 보조 액션 (모드 전환, 비밀번호 찾기)

#### PasswordResetPage (비밀번호 재설정)

**레이아웃**:
```
┌─────────────────────────────────┐
│ ← 비밀번호 재설정               │
├─────────────────────────────────┤
│                                 │
│  이메일 주소를 입력하시면      │
│  비밀번호 재설정 링크를 보내... │
│                                 │
│  [이메일 입력]                 │
│                                 │
│  [전송]                        │
└─────────────────────────────────┘
```

### 3. 에러 처리

**Toast 사용** (SnackBar 대신):
```dart
// minorlab_common AppToast 사용
AppToast.show(
  context: context,
  message: 'auth.error.invalid_credentials'.tr(),
  type: ToastType.error,
)
```

**에러 메시지 매핑**:
```dart
AuthInvalidCredentialsException → 'auth.error.invalid_credentials'
AuthEmailAlreadyInUseException → 'auth.error.email_already_in_use'
AuthWeakPasswordException → 'auth.error.weak_password'
AuthNetworkException → 'auth.error.network_error'
// 기타 AuthCustomException 하위 클래스들
```

### 4. 다국어 키 구조

```yaml
# auth.yaml
auth:
  login: "로그인"
  sign_up: "회원가입"
  email_hint: "이메일"
  password_hint: "비밀번호"
  password_confirm_hint: "비밀번호 확인"
  name_hint: "이름 (선택)"
  forgot_password: "비밀번호를 잊으셨나요?"
  continue_with_google: "Google로 계속하기"
  continue_with_apple: "Apple로 계속하기"
  already_have_account: "이미 계정이 있으신가요?"
  dont_have_account: "계정이 없으신가요?"
  by_continuing: "계속하면"
  agree_to_terms: "에 동의하는 것으로 간주됩니다"

  error:
    invalid_credentials: "이메일 또는 비밀번호가 올바르지 않습니다"
    email_already_in_use: "이미 사용 중인 이메일입니다"
    weak_password: "비밀번호는 최소 6자 이상이어야 합니다"
    network_error: "네트워크 연결을 확인해주세요"
    email_not_verified: "이메일 인증이 필요합니다"
    user_not_found: "존재하지 않는 사용자입니다"

  message:
    login_success: "로그인되었습니다"
    logout_success: "로그아웃되었습니다"
    sign_up_success: "회원가입되었습니다"
    password_reset_sent: "비밀번호 재설정 이메일을 전송했습니다"
```

## 구현 단계

### Phase 1: UI 개선 (미니라인 앱)

1. **AuthPage 재구현**
   - shadcn_ui 컴포넌트로 전체 재작성
   - AppIcons 사용
   - AppToast 사용
   - GoRouter 통합

2. **PasswordResetPage 구현**
   - 페이지 형식 (다이얼로그 금지)
   - shadcn_ui 컴포넌트 사용

3. **다국어 키 정리**
   - 명확한 구조
   - 에러 메시지 통일

4. **검증**
   - flutter analyze 통과
   - 실제 동작 확인
   - Google/Apple/Email 로그인 테스트

### Phase 2: minorlab_common 이동

1. **새 버전 추가**
   - `lib/src/pages/auth_page_v2.dart`
   - 기존 `auth_page.dart`와 공존
   - 점진적 마이그레이션 지원

2. **AppIcons 의존성 제거**
   - 아이콘을 파라미터로 받도록 수정
   - 또는 minorlab_common에 AppIcons 추가

3. **AppToast 통합**
   - minorlab_common에 이미 있음 (확인 필요)

4. **문서화**
   - 사용 예시
   - 마이그레이션 가이드

### Phase 3: 북랩 적용

1. **북랩 앱 업데이트**
   - AuthPage v2로 전환
   - AppIcons 적용
   - 다국어 키 통일

2. **검증**
   - 기존 기능 유지 확인
   - UI 개선 확인

## 파일 구조

```
lib/features/auth/
├── data/
│   ├── auth_repository.dart         # 북랩 패턴 기반 (익명 제거)
│   └── auth_repository.g.dart
├── presentation/
│   ├── pages/
│   │   ├── auth_page.dart           # 새 UI (shadcn_ui)
│   │   └── password_reset_page.dart # 새 UI
│   ├── providers/
│   │   └── auth_provider.dart       # minorlab_common 재사용
│   └── widgets/
│       ├── social_login_buttons.dart
│       └── auth_form_fields.dart
└── domain/
    └── auth_exceptions.dart         # minorlab_common에서 복사
```

## 체크리스트

### 디자인 가이드 준수
- [ ] shadcn_ui 컴포넌트만 사용 (Material 금지)
- [ ] AppIcons 사용 (Icons.xxx 금지)
- [ ] 텍스트 입력은 페이지로 구현 (다이얼로그 금지)
- [ ] ShadInput trailing 크기 고정
- [ ] AppToast 사용 (SnackBar 금지)

### 기능 구현
- [ ] Google 로그인
- [ ] Apple 로그인
- [ ] Email 로그인
- [ ] Email 회원가입
- [ ] 비밀번호 재설정
- [ ] 로그아웃
- [ ] 에러 처리 (모든 AuthCustomException)

### 코드 품질
- [ ] 모든 텍스트 `.tr()` 사용
- [ ] flutter analyze 통과
- [ ] 실제 동작 확인
- [ ] 다크 모드 테스트

### 문서화
- [ ] 다국어 키 정리
- [ ] 사용 예시 작성
- [ ] minorlab_common 마이그레이션 가이드

## 주의사항

1. **기존 UI는 참고만**
   - minorlab_common AuthPage는 레거시
   - 완전히 새로 작성

2. **익명 로그인 제거**
   - 미니라인은 지연 로그인 전략 사용
   - signInAnonymously 호출 없음

3. **로그아웃 동작**
   - 익명 전환 없음
   - 홈 화면(`/`)으로 이동

4. **다이얼로그 절대 금지**
   - showDialog, AlertDialog 사용 금지
   - showModalBottomSheet 사용 금지
   - 텍스트 입력은 무조건 페이지

5. **ShadInput trailing 크기 필수**
   - width: 24, height: 24 고정
   - 미지정 시 입력창 높이 변경됨

## 참고 문서

- [GUIDE_STYLE_COMPONENTS.md](/docs/common/GUIDE_STYLE_COMPONENTS.md) - 컴포넌트 가이드
- [minorlab_common AuthService](../minorlab_common/lib/src/auth/auth_service.dart) - 인증 로직
- [북랩 AuthRepository](../minorlab_book/lib/features/auth/data/auth_repository.dart) - 로컬 데이터 처리

---

**다음 단계**: Phase 1 시작 - AuthPage UI 재구현
