#!/usr/bin/env bash
# SessionStart 훅: Pixel Agents 서버가 꺼져 있으면 띄우고, 새 세션(startup)일 때 브라우저로 office를 연다.
# 관찰 전용 URL(토큰 없음)만 연다. 토큰이 필요한 작업(훅 설치 승인, 터미널 연결)은 브라우저에서 따로 한다.

PORT=3100
URL="http://127.0.0.1:${PORT}/"
LOG_DIR="$HOME/.pixel-agents"
LOG="$LOG_DIR/sprite_game-server.log"

mkdir -p "$LOG_DIR"

if ! curl -s -o /dev/null --max-time 1 "$URL"; then
  if command -v pixel-agents >/dev/null 2>&1; then
    cd "$CLAUDE_PROJECT_DIR" || exit 0
    nohup pixel-agents --port "$PORT" --host 127.0.0.1 --no-terminal >>"$LOG" 2>&1 &
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      sleep 0.5
      curl -s -o /dev/null --max-time 1 "$URL" && break
    done
  else
    echo "[pixel-office] pixel-agents 명령이 없습니다. 'npm install -g pixel-agents'를 실행하세요." >&2
    exit 0
  fi
fi

if [ "$(uname)" = "Darwin" ]; then
  open "$URL" >/dev/null 2>&1
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1
fi

exit 0
