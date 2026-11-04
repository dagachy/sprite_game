# HANDOFF

## Goal
sprite_game을 Unity(C#) 2D 모바일 게임 제작 작업 공간으로 세팅한다. 하네스(에이전트 34명, phase 단위 팀 구성)를 정리하고, 작업 중에는 Pixel Agents 브라우저 화면으로 팀과 진행을 본다.

## Decisions
- 팀은 작업마다 새로 구성한다. 전체 인원 상한은 없고, phase별 동시 활성 5명 이하로 제한한다(`.claude/phases.json`).
- phase 산출물은 `_workspace/<phase>/<agent>/`에 쓴다. 다음 phase가 그 경로를 읽는다.
- 커밋과 푸시는 사용자가 요청할 때만 한다. 기본 브랜치에서는 먼저 브랜치를 만든다.
- 구현 에이전트 6명만 Edit·Write·Bash를 가진다. 나머지 분석·QA·출시 계열은 읽기 전용이다.
- pre-flight 점검 스킬과 감사 에이전트는 프로젝트 `.claude/`에 두고, 같은 이름의 전역 항목보다 프로젝트 쪽이 우선 적용된다.
- Pixel Agents는 고정 포트 3100, `--no-terminal`, 토큰 없는 관찰 URL로만 연다. 토큰이 필요한 작업은 브라우저에서 직접 한다.
- 상용 게임 분석은 공개 정보와 플레이 관찰만 쓴다. 역분석이나 복제는 하지 않는다.

## Done
- `main`에 push 완료: `aa82873`(Pixel Agents 자동 열기 훅, 스킬 references 분리). 그 앞 커밋 `6f4a9a7`(하네스 세팅).
- 원격 `chore/harness-setup` 브랜치는 아직 남아 있다. 필요 없으면 삭제한다.
- `.claude/hooks/pixel-office-open.sh`: SessionStart(`startup`)에서 서버를 띄우고 `http://127.0.0.1:3100/`을 연다. 수동 실행으로 동작을 확인했다.
- `npm install -g pixel-agents`(v1.5.0) 설치. 서버는 현재 떠 있다.
- pre-flight 점검: 뼈대, agent frontmatter 34개, 팀 규모(phase 9개 모두 5명 이하), 메뉴판은 통과했다.
- 개선: `handoff`, `token-report`, `harness-evolve`의 긴 본문을 `references/`로 옮겼다. `harness` 라우터에 "왜" 줄을 추가했다(24줄, R3 준수).
- 도구 권한 점검: `backend-engineer`는 "분석 이벤트" 단어 때문에 오탐이었다. 실제 문제는 없었다.

## Next
1. Pixel Agents 브라우저 화면에서 Settings → Instant Detection (Hooks)를 켜고 훅 설치를 승인한다. 이 승인은 `~/.claude/settings.json`(전역)을 수정한다.
2. 새 Claude 세션을 시작해 브라우저가 자동으로 열리는지 확인한다. 서브에이전트 호출 시 캐릭터가 나타나는지도 본다.
3. Unity 프로젝트를 만든다(Unity 6.x, 2D 템플릿). 경로를 받으면 `ProjectSettings/ProjectVersion.txt`로 버전을 확인한다.
4. `brew install uv` 후 CoplayDev MCP for Unity를 추가하고 `claude mcp list`로 확인한다.
5. spritefusion MCP를 `/mcp`에서 OAuth 인증한다. 호출마다 크레딧이 드니 비용을 먼저 확인한다.
6. `.claude/token-guard/state/*.json`(세션 상태 3개)을 `.gitignore`에 넣을지 정한다. 지금은 커밋되지 않은 채 남아 있다.

## Key files
- `CLAUDE.md`: 프로젝트 지침. 팀 규칙, 승인 기준, 커밋 규칙이 여기 있다.
- `.claude/phases.json`: phase 카탈로그. 팀을 짤 때 이 목록에서 고른다.
- `_workspace/README.md`: phase 산출물 규칙.
- `.claude/hooks/pixel-office-open.sh`: 세션 시작 시 Pixel Agents 서버를 띄우고 브라우저를 여는 훅.
- `.claude/settings.json`: token-guard 훅과 pixel-office 훅 설정.
- `.claude/skills/harness/SKILL.md`: 메뉴판. 링크된 `references/`는 필요할 때만 읽는다.
- `.claude/agents/gameplay-programmer.md`: 구현 에이전트 기준. 승인 기준과 git 절이 있다.
- `.claude/agents/level-pipeline-engineer.md`: Sprite Fusion 임포트 규칙. 샘플 맵 없이 임포터를 만들지 않는다.
- `.mcp.json`: spritefusion MCP 등록.

## Open questions
- 전역 `~/.claude`에 pre-flight 스킬·에이전트 9개씩과 token-guard 훅이 같은 이름으로 있다. 지울지 둘지 정한다. 지우지 않으면 이 프로젝트에서 훅이 두 번 실행될 수 있다.
- Unity 프로젝트 경로와 버전.
- Sprite Fusion 신규 크레딧 지급 여부는 가입 시 확인이 필요하다.
- SSH: `dagachy-company` 키로 push가 되다가 한 번 거부되고, 다시 시도하니 성공했다. 원인은 확인하지 못했다.
