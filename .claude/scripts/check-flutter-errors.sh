#!/bin/bash

# Flutter tmux 세션의 에러/경고 자동 체크 스크립트
# 사용법: .claude/scripts/check-flutter-errors.sh [세션명] [줄수]

SESSION_NAME="${1:-miniline_app}"
LINES="${2:-200}"

# tmux 세션 존재 확인
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ tmux 세션 '$SESSION_NAME'을 찾을 수 없습니다."
    echo "실행 중인 세션:"
    tmux list-sessions 2>/dev/null || echo "  (없음)"
    exit 1
fi

echo "🔍 Flutter 에러/경고 체크 중... (세션: $SESSION_NAME, 최근 ${LINES}줄)"
echo ""

# tmux 출력 캡처
OUTPUT=$(tmux capture-pane -t "$SESSION_NAME" -p -S -${LINES})

# 에러 패턴 검색
ERRORS=$(echo "$OUTPUT" | grep -E "Error|Exception|Failed|fatal|EXCEPTION" | grep -v "No issues found" | grep -v "errorWidget")
WARNINGS=$(echo "$OUTPUT" | grep -E "Warning|warning" | grep -v "No issues found")
INVALID_STATUS=$(echo "$OUTPUT" | grep -E "Invalid statusCode")

# 결과 출력
HAS_ISSUES=0

if [ -n "$ERRORS" ]; then
    echo "🚨 에러 발견:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$ERRORS"
    echo ""
    HAS_ISSUES=1
fi

if [ -n "$INVALID_STATUS" ]; then
    echo "⚠️  네트워크/스토리지 에러 발견:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$INVALID_STATUS"
    echo ""
    HAS_ISSUES=1
fi

if [ -n "$WARNINGS" ]; then
    echo "⚠️  경고 발견:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$WARNINGS"
    echo ""
    HAS_ISSUES=1
fi

if [ $HAS_ISSUES -eq 0 ]; then
    echo "✅ 에러/경고 없음"
fi

echo ""
echo "💡 전체 출력 보기: tmux attach -t $SESSION_NAME"
