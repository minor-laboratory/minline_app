# MiniLine App

AI 기반 자동 조합 저널 앱 (Flutter)

> 짧은 생각들(Fragments)을 시간에 걸쳐 입력하면, AI가 자동으로 연결하고 완성된 글(Draft)로 조합

## 개발 환경 설정

### 1. Firebase 설정 (필수)

**중요**: Firebase 설정 파일은 보안상 git에 포함되지 않습니다.

각 개발자는 다음 명령어로 Firebase 설정을 생성해야 합니다:

```bash
flutterfire configure \
  --project=minor-lab \
  --out=lib/firebase_options.dart \
  --ios-bundle-id=com.minorlab.miniline \
  --android-package-name=com.minorlab.miniline \
  --platforms=ios,android
```

생성되는 파일:
- `android/app/google-services.json` (gitignore)
- `ios/Runner/GoogleService-Info.plist` (gitignore)
- `lib/firebase_options.dart` (git 포함)

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 코드 생성

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. 앱 실행

```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── core/
│   └── database/          # Isar 데이터베이스
├── models/                # 데이터 모델 (Fragment, Draft, Post)
├── firebase_options.dart  # Firebase 설정
└── main.dart
```

## 기술 스택

- Flutter (Dart)
- Isar Community (로컬 DB)
- Firebase (인증, FCM, Crashlytics)
- Supabase (백엔드)
- Riverpod (상태 관리)

## 문서

자세한 내용은 [docs/](docs/) 폴더 참조
