# HANDOFF

## Goal
sprite_game을 Unity(C#) 2D 모바일 게임 제작 작업 공간으로 세팅한다. 하네스(에이전트 34명, phase 단위 팀 구성)를 정리하고, 상용 게임 분석을 개발 실무 참고용으로 쌓는다. 작업 중에는 Pixel Agents 브라우저 화면으로 팀과 진행을 본다.

## Decisions
- **신규 브랜치는 사용자가 요청하기 전까지 만들지 않는다.** 커밋과 푸시는 `main`에 직접 한다. 이 규칙은 `CLAUDE.md`의 "기본 브랜치에서 먼저 브랜치를 만든다"보다 우선한다.
- 원격은 `git@github-dagachy:dagachy/sprite_game.git`(회사 키 별칭)을 쓴다. 일반 `git push`가 `Permission denied`로 실패할 수 있으니 실패 시 `GIT_SSH_COMMAND="ssh"`로 재시도한다.
- `_workspace/*`는 `.gitignore`로 전부 제외된다. 커밋해야 하는 문서는 `_workspace/`가 아닌 추적 경로(예: `docs/`)에 둔다.
- 상용 게임 분석은 공개 정보와 플레이 관찰만 쓴다. 역분석, 에셋·수치·UI 재현은 하지 않는다.
- 상용 게임 조사·분석은 `commercial-game-analyst` 에이전트에 맡긴다. 메인이 직접 조사하지 않는다. 이 에이전트는 읽기 전용이라 파일을 쓰지 못하므로, 결과 저장은 메인이 맡는다.
- 팀은 작업마다 새로 구성한다. phase별 동시 활성 5명 이하(`.claude/phases.json`). phase 산출물은 `_workspace/<phase>/<agent>/`에 쓴다.
- 구현 에이전트 6명만 Edit·Write·Bash를 가진다. 나머지는 읽기 전용이다.
- Pixel Agents는 고정 포트 3100, `--no-terminal`, 토큰 없는 관찰 URL로만 연다.

## Done
- `main` 커밋: `6f4a9a7`(하네스 세팅), `aa82873`(Pixel Agents 훅, 스킬 references 분리), `007a61a`(HANDOFF 갱신), `585c50e`(token-guard state를 `.gitignore`에 추가), `b545aea`(상용 게임 분석 문서). `origin/main`과 `b545aea`가 같다.
- 분석 문서: `docs/analysis/commercial/tangtang_analysis.md`(탕탕특공대 / 탕탕에이스, 원리 10개 우선순위 포함). 원본 작성본은 `_workspace/analysis/commercial/tangtang_analysis.md`에 있다.
- Pixel Agents 점검: 서버(PID 4208, 포트 3100)는 실행 중이고 HTTP 200을 반환한다. 훅 스크립트는 실행 권한이 있고 수동 실행 시 브라우저를 연다. 로그에 에이전트 활동도 기록된다.
- pre-flight 점검 통과: 뼈대, agent frontmatter 34개, 팀 규모, 메뉴판.
- `handoff`, `token-report`, `harness-evolve`의 긴 본문을 `references/`로 옮겼다.

## Next
1. 브라우저에서 `http://127.0.0.1:3100/`을 열어 에이전트 캐릭터가 보이는지 확인한다. 캐릭터 표시는 Settings → Instant Detection (Hooks) 설치 후 완전히 동작한다. 이 설치는 전역 `~/.claude/settings.json`을 바꾸므로 사용자 승인이 필요하다.
2. SessionStart 훅 매처가 `startup`만 잡아 `/clear` 후에는 브라우저가 자동으로 열리지 않는다. `startup|clear`로 바꿀지 사용자 승인을 받는다.
3. 원격 `chore/harness-setup` 브랜치(`aa82873`)를 삭제할지 확인한다. `main`과 내용이 같다.
4. 원격·로컬 `docs/tangtang-analysis` 브랜치(`b780a8e`)를 삭제할지 확인한다. 요청 없이 만든 브랜치이므로 정리 대상이다.
5. Unity 프로젝트를 만든다(Unity 6.x, 2D 템플릿). 경로를 받으면 `ProjectSettings/ProjectVersion.txt`로 버전을 확인한다.
6. `brew install uv` 후 CoplayDev MCP for Unity를 추가하고 `claude mcp list`로 확인한다.
7. spritefusion MCP를 `/mcp`에서 OAuth 인증한다. 호출마다 크레딧이 드니 비용을 먼저 확인한다.

## Key files
- `CLAUDE.md`: 프로젝트 지침. 팀 규칙, 승인 기준, 커밋 규칙.
- `docs/analysis/commercial/tangtang_analysis.md`: 두 게임 분석 결과(추적 대상).
- `_workspace/README.md`: phase 산출물 규칙.
- `.claude/phases.json`: phase 카탈로그. 팀을 짤 때 이 목록에서 고른다.
- `.claude/hooks/pixel-office-open.sh`: 세션 시작 시 Pixel Agents 서버를 띄우고 브라우저를 여는 훅.
- `.claude/settings.json`: token-guard 훅과 pixel-office 훅 설정.
- `.claude/agents/commercial-game-analyst.md`: 상용 게임 분석 에이전트(읽기 전용).
- `.claude/skills/harness/SKILL.md`: 메뉴판. `references/`는 필요할 때만 읽는다.
- `.mcp.json`: spritefusion MCP 등록.

## Open questions
- 전역 `~/.claude`에 pre-flight 스킬·에이전트 9개씩과 token-guard 훅이 같은 이름으로 있다. 지울지 정한다. 지우지 않으면 이 프로젝트에서 훅이 두 번 실행될 수 있다.
- Unity 프로젝트 경로와 버전.
- Sprite Fusion 신규 크레딧 지급 여부는 가입 시 확인이 필요하다.
- 탕탕에이스의 과금 구조, 퍼블리셔, 정확한 출시일은 미확인이다. 스토어 페이지 확인이 필요하다.
- `chore/harness-setup`, `docs/tangtang-analysis` 원격 브랜치 삭제 여부.
