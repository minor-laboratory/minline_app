fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

App Store Connect에 앱 생성 (최초 1회만, App-specific password 필요)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

MiniLine iOS 앱 TestFlight 배포 (완전 자동화: flutter clean → build_runner → icon/splash → build → upload)

### ios upload_only

```sh
[bundle exec] fastlane ios upload_only
```

IPA 파일만 TestFlight에 업로드 (빌드 제외)

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

MiniLine iOS 앱 App Store 배포

### ios test_api_key

```sh
[bundle exec] fastlane ios test_api_key
```

API 키 테스트

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

메타데이터만 업로드 (앱 정보, 스크린샷)

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

스크린샷만 업로드

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
