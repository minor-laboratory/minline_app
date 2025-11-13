# 미니라인 인증 및 프로필 기능 작업 계획

**작성일**: 2025-01-13
**담당**: Claude Code + Danny
**예상 작업 시간**: 4-6시간

## 작업 전 정리 완료 ✅

1. ✅ **ProfileEditPage 삭제 확인** - 북랩에서 미사용 코드 확인
2. ✅ **북랩 패턴 분석** - 복사 후 수정 방식으로 진행
3. ✅ **minorlab_common 이동 검토** - Phase 2로 보류, 당장은 복사
4. ✅ **지연 로그인 전략 문서** - 저장 시점에 로그인 유도

## 핵심 요구사항 정리

### 1. ProfileEditPage 삭제 (북랩)
- 미사용 코드 제거
- 라우터에서도 제거

### 2. 북랩 코드 복사 후 수정
- AuthRepository → 익명 로그인 로직 제거
- ProfileDetailPage → 미니라인용 단순화
- PasswordChangePage → 그대로 복사
- AccountWithdrawalPage → 구독 체크 제거
- 간단한 로그아웃 다이얼로그 → 미동기화 체크 없음

### 3. minorlab_common 이동
- **당장은 하지 않음**
- Phase 2 (웹 작업 시) 검토

### 4. 지연 로그인 전략
- 홈 화면 입력은 자유
- 저장 버튼 클릭 시 로그인 체크
- 비로그인 상태면 로그인 유도 다이얼로그
- 웹도 동일 적용 (나중에)

## 작업 순서

### Phase 0: 북랩 정리

1. **ProfileEditPage 삭제**
   - 파일 삭제: `minorlab_book/lib/features/settings/presentation/pages/profile_edit_page.dart`
   - 라우터에서 제거: `app_router.dart`

### Phase 1: 인증 기반 구조

2. **AuthRepository 구현**
   - 북랩 코드 복사
   - 익명 로그인 관련 코드 제거
   - 로그아웃 시 익명 전환 제거
   - 지연 로그인 패턴 적용

3. **AuthProvider 구현**
   - minorlab_common provider 재사용
   - currentUserProvider, authStateProvider 등

### Phase 2: 프로필 UI

4. **UserProfileSection (설정 페이지 상단)**
   - 북랩 코드 복사
   - 비로그인 시 게스트 표시 + 로그인 유도
   - 로그인 시 프로필 정보 + 프로필 페이지 이동

5. **ProfileDetailPage (프로필 상세/편집 통합)**
   - 북랩 profile_detail_page.dart 복사
   - 이미지 업로드/삭제
   - 이름 편집 (자동 저장)
   - 로그인 정보 표시
   - 비밀번호 변경 버튼
   - 로그아웃 버튼
   - 회원탈퇴 (팝업 메뉴)

6. **PasswordChangePage**
   - 북랩 코드 그대로 복사
   - 기존 비밀번호 확인
   - 새 비밀번호 설정

7. **AccountWithdrawalPage**
   - 북랩 코드 복사
   - 구독 체크 로직 제거 (미니라인은 무료)
   - 확인 텍스트 입력 후 탈퇴

8. **간단한 로그아웃 다이얼로그**
   - 미동기화 체크 없음
   - "로그아웃 하시겠습니까?" 단순 확인

### Phase 3: 지연 로그인 구현

9. **저장 시 로그인 체크**
   - TimelinePage (Fragment 저장) 수정
   - 비로그인 시 로그인 유도 다이얼로그
   - 임시 내용 보존
   - 로그인 성공 시 저장

10. **로그인 유도 다이얼로그**
    - "저장하려면 로그인이 필요해요"
    - [나중에] [로그인하기] 버튼

### Phase 4: 마무리

11. **다국어 키 추가**
    - auth.yaml
    - profile.yaml
    - settings.yaml

12. **라우터 설정**
    - /auth → AuthPage (common)
    - /profile → ProfileDetailPage
    - /profile/password → PasswordChangePage
    - /profile/withdrawal → AccountWithdrawalPage

13. **검증**
    - flutter analyze (No issues found!)
    - 실제 동작 확인
    - 로그인/로그아웃 플로우
    - 프로필 편집
    - 비밀번호 변경
    - 회원탈퇴

## 파일 구조

```
lib/features/
├── auth/
│   ├── data/
│   │   ├── auth_repository.dart          # 북랩 복사 (익명 제거)
│   │   └── auth_repository.g.dart
│   └── providers/
│       └── auth_provider.dart            # common provider 재사용
│
├── profile/
│   ├── pages/
│   │   ├── profile_page.dart             # 북랩 profile_detail_page.dart 복사
│   │   ├── password_change_page.dart     # 북랩 복사
│   │   └── account_withdrawal_page.dart  # 북랩 복사 (구독 제거)
│   └── widgets/
│       ├── user_profile_section.dart     # 설정 상단 카드
│       └── logout_dialog.dart            # 간단 버전
│
└── settings/
    └── pages/
        └── settings_page.dart            # 프로필 섹션 추가
```

## 복사할 북랩 파일 목록

### 그대로 복사 (수정 최소)
- ✅ `password_change_page.dart` (350줄)
- ✅ `user_profile_section.dart` (260줄) - 라우트만 수정

### 복사 후 수정 (중간)
- ⚠️ `auth_repository.dart` (580줄) - 익명 로그인 제거
- ⚠️ `profile_detail_page.dart` (612줄) - 미니라인 단순화
- ⚠️ `account_withdrawal_page.dart` (250줄) - 구독 체크 제거

### 새로 작성 (간단)
- 🆕 `logout_dialog.dart` (50줄) - 단순 확인 다이얼로그
- 🆕 로그인 유도 다이얼로그 (50줄)

## 예상 작업 시간

| 작업 | 예상 시간 |
|------|----------|
| ProfileEditPage 삭제 | 10분 |
| AuthRepository 구현 | 30분 |
| AuthProvider 구현 | 20분 |
| UserProfileSection | 30분 |
| ProfileDetailPage | 1시간 |
| PasswordChangePage | 20분 |
| AccountWithdrawalPage | 30분 |
| 로그아웃 다이얼로그 | 20분 |
| 지연 로그인 구현 | 1시간 |
| 다국어 키 추가 | 30분 |
| 라우터 설정 | 20분 |
| 검증 및 테스트 | 1시간 |
| **총 예상 시간** | **6시간** |

## 주의사항

1. **하드코딩 금지**
   - 모든 텍스트 `.tr()` 사용
   - 모든 아이콘 `AppIcons.xxx` 사용
   - 모든 색상 테마 시스템 사용

2. **익명 로그인 제거**
   - `signInAnonymously()` 호출 모두 제거
   - `isAnonymous` 체크 → `currentUser == null`로 변경

3. **로그아웃 동작 변경**
   - 익명 전환 없음
   - 홈 화면(`/`)으로 이동

4. **지연 로그인 패턴**
   - 입력은 자유
   - 저장 시 로그인 체크

5. **RLS 정책 확인**
   - 서버에서 비로그인 INSERT 차단

## 참고 문서

- [지연 로그인 전략](GUIDE_DELAYED_LOGIN_STRATEGY.md)
- [minorlab_common 이동 계획](PLAN_COMMON_MIGRATION.md)
- [북랩 AuthRepository](../minorlab_book/lib/features/auth/data/auth_repository.dart)
- [미니라인 DB 스키마](../miniline/docs/SPEC_DATABASE_SCHEMA.md)

## 다음 단계 (완료 후)

1. 웹 버전 동일 패턴 적용
2. 지연 로그인 UX 테스트
3. minorlab_common 이동 검토 (Phase 2)

---

**준비 완료! 작업 시작합니다.**
