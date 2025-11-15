#!/bin/bash

# Flutter tmux 세션의 에러/경고 지속 모니터링 스크립트
# 사용법: .claude/scripts/watch-flutter-errors.sh [세션명] [체크간격(초)]

SESSION_NAME="${1:-miniline_app}"
INTERVAL="${2:-5}"

echo "👀 Flutter 에러 모니터링 시작 (세션: $SESSION_NAME, 간격: ${INTERVAL}초)"
echo "종료하려면 Ctrl+C를 누르세요"
echo ""

LAST_CHECK=""

while true; do
    # tmux 세션 존재 확인
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "❌ tmux 세션 '$SESSION_NAME'을 찾을 수 없습니다. 종료합니다."
        exit 1
    fi

    # 최근 50줄만 체크 (효율성)
    OUTPUT=$(tmux capture-pane -t "$SESSION_NAME" -p -S -50)

    # Hot reload/restart 감지
    RELOAD_TYPE=""
    if echo "$OUTPUT" | grep -q "Reloaded"; then
        RELOAD_TYPE="reload"
    elif echo "$OUTPUT" | grep -q "Restarted"; then
        RELOAD_TYPE="restart"
    fi

    if [ -n "$RELOAD_TYPE" ]; then
        CURRENT_TIME=$(date +%s)

        # 이전 체크로부터 최소 3초 경과 (중복 방지)
        if [ -z "$LAST_CHECK" ] || [ $((CURRENT_TIME - LAST_CHECK)) -gt 3 ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if [ "$RELOAD_TYPE" = "reload" ]; then
                echo "🔄 Hot Reload 감지됨 ($(date '+%H:%M:%S'))"
            else
                echo "♻️  Hot Restart 감지됨 ($(date '+%H:%M:%S'))"
            fi
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

            # 에러 체크 (최근 100줄)
            ERRORS=$(tmux capture-pane -t "$SESSION_NAME" -p -S -100 | grep -E "Error|Exception|Failed|fatal|EXCEPTION" | grep -v "No issues found" | grep -v "errorWidget")
            WARNINGS=$(tmux capture-pane -t "$SESSION_NAME" -p -S -100 | grep -E "Warning|warning" | grep -v "No issues found")

            if [ -n "$ERRORS" ]; then
                echo "🚨 에러 발견:"
                echo "$ERRORS"
                echo ""
            fi

            if [ -n "$WARNINGS" ]; then
                echo "⚠️  경고 발견:"
                echo "$WARNINGS"
                echo ""
            fi

            if [ -z "$ERRORS" ] && [ -z "$WARNINGS" ]; then
                echo "✅ 에러/경고 없음"
                echo ""
            fi

            LAST_CHECK=$CURRENT_TIME
        fi
    fi

    sleep $INTERVAL
done
