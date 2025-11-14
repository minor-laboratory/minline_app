# Flutter 에러 체크 자동화 스크립트

## 개요

Flutter 앱 실행 중 발생하는 에러와 경고를 자동으로 감지하는 스크립트입니다.

## 스크립트

### 1. check-flutter-errors.sh (수동 체크)

tmux 세션의 최근 출력에서 에러/경고를 한 번 검색합니다.

```bash
# 기본 사용 (miniline_app 세션, 최근 200줄)
.claude/scripts/check-flutter-errors.sh

# 세션명과 줄수 지정
.claude/scripts/check-flutter-errors.sh miniline_app 300
```

**사용 시점**:
- Hot reload 후
- 앱 재시작 후
- 에러 발생 의심 시

### 2. watch-flutter-errors.sh (자동 모니터링)

Hot reload를 감지하여 자동으로 에러를 체크합니다.

```bash
# 백그라운드에서 실행
.claude/scripts/watch-flutter-errors.sh

# tmux 세션에서 실행 (권장)
tmux new-session -d -s flutter_watch ".claude/scripts/watch-flutter-errors.sh"
tmux attach -t flutter_watch

# 종료
Ctrl+C 또는 tmux kill-session -t flutter_watch
```

**동작 방식**:
- 5초마다 tmux 출력 체크
- "Reloaded" 메시지 감지 시 에러 검색
- 에러/경고 발견 시 즉시 출력

## Claude Code 명령어

```
/check-errors
```

Claude Code에서 위 명령어로 현재 에러 상태를 체크할 수 있습니다.

## 감지하는 패턴

- **에러**: Error, Exception, Failed, fatal, EXCEPTION
- **경고**: Warning, warning
- **네트워크**: Invalid statusCode

## 예시 출력

```
🔄 Hot Reload 감지됨 (14:32:15)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 에러 발견:
I/flutter: ❌ [SupabaseStreamService] Failed to start...

⚠️  경고 발견:
Warning: Unused variable 'foo'

✅ 에러/경고 없음
```
