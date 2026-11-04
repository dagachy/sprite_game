# 다른 PC에서 이어 작업하기 (SETUP)

이 저장소를 clone하면 하네스(에이전트, 스킬, 세션 훅, phase 카탈로그)가 그대로 실행된다. 토큰 가드는 전역 설정을 쓴다. 아래는 새 PC에서 한 번만 하면 되는 준비 항목이다.

## 1. 필수 도구

| 도구 | 용도 | 확인 명령 |
|---|---|---|
| Claude Code | 하네스 실행 | `claude --version` |
| Git, SSH 키 | 원격 push | `git --version` |
| Python 3 | 전역 token-guard 훅과 statusLine | `python3 --version` (3.10 이상 권장) |
| Node.js, npm | Pixel Agents 설치(선택) | `npm --version` |
| Unity Hub, Unity 6.x | 프로젝트 생성 후 필요 | 나중에 설치 |
| uv | Unity MCP 서버 실행(나중에 설치) | `uv --version` |

## 2. 저장소 받기

```bash
git clone git@github-dagachy:dagachy/sprite_game.git
cd sprite_game
```

- 원격 주소는 회사 키 별칭 `github-dagachy`를 쓴다. 새 PC의 `~/.ssh/config`에 같은 별칭과 키가 있어야 한다. 없으면 push가 `Permission denied`로 실패한다.
- 실패하면 `GIT_SSH_COMMAND="ssh" git push`로 재시도한다(HANDOFF 기록).

## 3. 프로젝트 안에 이미 들어 있는 것

커밋되어 있으므로 따로 설치할 필요가 없다.

- `CLAUDE.md`: 프로젝트 지침(팀 규칙, 승인 기준, 커밋 규칙)
- `.claude/agents/`: 전문가 에이전트 37명
- `.claude/skills/`: 하네스 스킬(`harness`, `handoff`, `token-report` 등)
- `.claude/phases.json`: phase별 후보 풀과 동시 활성 상한(5명)
- `.claude/settings.json`: 세션 시작 훅(Pixel Agents)
- `.claude/hooks/pixel-office-open.sh`: 세션 시작 시 Pixel Agents 서버를 띄우고 관찰 URL을 여는 훅
- `.mcp.json`: spritefusion MCP 등록(HTTP)
- `HANDOFF.md`: 마지막 인수인계 문서
- `docs/`: 상용 게임 분석, 실무 브리핑, 제안서

커밋하지 않는 것(`.gitignore`): `_workspace/` 산출물(README 제외), `__pycache__/`, 토큰 가드 상태(전역 `~/.claude/token-guard/state/`).

## 4. 새 PC에서 한 번 해야 하는 설정

1. **Claude Code 로그인.** 저장소 폴더에서 `claude`를 실행하고 계정으로 로그인한다.
2. **spritefusion MCP 인증.** Claude Code 안에서 `/mcp`를 열고 spritefusion을 OAuth로 인증한다. 호출마다 크레딧이 들므로, 호출 전에 비용을 확인한다(프로젝트 지침).
3. **Pixel Agents(선택).** 팀 상황을 브라우저로 보려면 `npm install -g pixel-agents`를 한다. 없으면 훅은 안내만 출력하고 넘어간다. 작업에는 영향이 없다.
4. **전역 설정은 저장소에 없다.** `~/.claude/` 아래의 개인 설정(전역 훅, 개인 CLAUDE.md, 전역 에이전트·스킬)은 이 저장소 밖에 있다. 이 PC의 것을 옮기려면 직접 복사해야 한다.
   - 전역 `~/.claude/CLAUDE.md`의 토큰 절약 규칙은 새 PC에도 같은 내용으로 두는 것을 권한다.
   - 토큰 가드는 전역 설정만 쓴다. 프로젝트 사본은 제거됐다.

## 5. 동작 확인

새 PC에서 아래를 확인한다.

- `claude` 실행 시 SessionStart 훅 오류가 없다.
- `/agents`에서 프로젝트 에이전트가 보인다. `.claude/agents`의 파일 수는 37개다.
- `/mcp`에서 spritefusion 상태가 연결됨으로 보인다.
- 전역 token-guard가 동작한다. 상태줄에 토큰 정보가 보인다.
- 훅이 Pixel Agents를 띄우지 못하면 `.claude/hooks/pixel-office-open.sh`를 직접 실행해 메시지를 본다.

## 6. 작업 규칙 요약

- 기본 브랜치 `main`에 직접 커밋한다. 신규 브랜치는 사용자가 요청할 때만 만든다(HANDOFF 결정).
- 커밋과 push는 사용자가 요청할 때만 한다.
- 파일 삭제, 대량 에셋·`.meta` 편집, 스토어 업로드, 비밀 값 취급은 구현 전에 승인을 받는다(CLAUDE.md).
- 다음 작업으로 넘길 때는 `/handoff`로 `HANDOFF.md`를 갱신하고 `/clear`로 새 세션을 연다.
