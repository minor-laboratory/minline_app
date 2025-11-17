#!/bin/bash

# Flutter Hot Reload 트리거 후 런타임 에러 체크 스크립트
# 사용법: .claude/scripts/trigger-hot-reload-and-check.sh [세션명] [대기시간(초)]

SESSION_NAME="${1:-miniline_app}"
WAIT_TIME="${2:-3}"

# tmux 세션 존재 확인
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ tmux 세션 '$SESSION_NAME'을 찾을 수 없습니다."
    echo ""
    echo "실행 중인 세션:"
    tmux list-sessions 2>/dev/null || echo "  (없음)"
    echo ""
    echo "💡 앱을 먼저 실행하세요:"
    echo "   tmux new-session -d -s $SESSION_NAME"
    echo "   tmux send-keys -t $SESSION_NAME 'flutter run' C-m"
    exit 1
fi

echo "🔄 Hot Reload 트리거 중... (세션: $SESSION_NAME)"
echo ""

# Hot reload 트리거 (r 키 전송)
tmux send-keys -t "$SESSION_NAME" "r" C-m

# Hot reload 완료 대기
echo "⏳ Hot reload 완료 대기 중... (${WAIT_TIME}초)"
sleep $WAIT_TIME

echo ""
echo "🔍 런타임 에러 체크 중..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# tmux 출력 캡처 (최근 150줄)
OUTPUT=$(tmux capture-pane -t "$SESSION_NAME" -p -S -150)

# Hot reload 성공 확인
if echo "$OUTPUT" | grep -q "Reloaded"; then
    echo "✅ Hot Reload 성공"
    echo ""
else
    echo "⚠️  Hot Reload 확인 불가 (앱이 실행 중인지 확인하세요)"
    echo ""
fi

# 런타임 에러 패턴 검색
ERRORS=$(echo "$OUTPUT" | grep -E "Error|Exception|Failed|fatal|EXCEPTION|ERROR" | \
    grep -v "No issues found" | \
    grep -v "errorWidget" | \
    grep -v "flutter analyze" | \
    tail -20)

WARNINGS=$(echo "$OUTPUT" | grep -E "Warning|warning|WARNING" | \
    grep -v "No issues found" | \
    grep -v "flutter analyze" | \
    tail -20)

BUILD_ERRORS=$(echo "$OUTPUT" | grep -E "BUILD FAILED|Compilation failed|Could not build")

ASSERT_ERRORS=$(echo "$OUTPUT" | grep -E "Failed assertion|AssertionError")

NETWORK_ERRORS=$(echo "$OUTPUT" | grep -E "SocketException|TimeoutException|Connection refused")

# 결과 출력
HAS_ISSUES=0

if [ -n "$BUILD_ERRORS" ]; then
    echo "🚨 빌드 에러:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$BUILD_ERRORS"
    echo ""
    HAS_ISSUES=1
fi

if [ -n "$ASSERT_ERRORS" ]; then
    echo "🚨 Assertion 에러:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$ASSERT_ERRORS"
    echo ""
    HAS_ISSUES=1
fi

if [ -n "$ERRORS" ]; then
    echo "🚨 런타임 에러:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$ERRORS"
    echo ""
    HAS_ISSUES=1
fi

if [ -n "$NETWORK_ERRORS" ]; then
    echo "⚠️  네트워크 에러 (무시 가능):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NETWORK_ERRORS"
    echo ""
fi

if [ -n "$WARNINGS" ]; then
    echo "⚠️  경고:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$WARNINGS"
    echo ""
    HAS_ISSUES=1
fi

if [ $HAS_ISSUES -eq 0 ]; then
    echo "✅ 런타임 에러/경고 없음"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 전체 로그 보기: tmux attach -t $SESSION_NAME"
echo "💡 Hot Restart: tmux send-keys -t $SESSION_NAME 'R' C-m"

# Exit code (에러 있으면 1, 없으면 0)
exit $HAS_ISSUES
