# HANDOFF

## Goal
sprite_game을 Unity(C#) 2D 모바일 게임 제작 작업 공간으로 세팅한다. 하네스 감사와 개선을 마치고, 작업마다 phase 단위로 팀을 짜는 운영 방식을 정착시킨다.

## Decisions
- 팀은 작업마다 새로 구성한다. 전체 에이전트 수에는 상한을 두지 않고, phase별 동시 활성 5명 이하로 제한한다.
- phase 산출물은 `_workspace/<phase>/<agent>/`에 쓰고, 다음 phase가 그 경로를 읽어 이어받는다.
- 분석·기획·QA·출시 에이전트는 읽기 전용이다. 구현 에이전트 6명만 Edit·Write·Bash를 가진다.
- 구현·실행 에이전트 본문에 "git commit/push 금지" 절을 넣었다. 커밋은 사용자가 요청할 때만 한다.
- `harness` 스킬은 메뉴판(라우터, 22줄) 구조다. 상세는 `references/`에 있다.
- 스킬별 "**왜:**" 줄은 규칙 아래에 추가했다. 임계값과 절차는 바꾸지 않았다.
- 상용 게임 분석은 공개 정보와 플레이 관찰만 쓴다. 역분석이나 복제는 하지 않는다.

## Done
- condition 감사 실행: 뼈대, frontmatter, tools, 안티패턴, 분리 신호, 메뉴판, 팀 규모 진단.
- 에이전트 34개: `color` 추가(역할별), 구현·실행 10개에 git 안전 절 추가.
- `.claude/phases.json`: phase 9개, 34명 중복 없이 배치, 최대 인원 5.
- `_workspace/README.md`와 `.gitignore`(`_workspace/*` 제외, README 추적).
- `CLAUDE.md` 재작성(팀 규칙, 작업 원칙, 토큰 관리, 커밋 규칙).
- `harness/SKILL.md` 405줄 → 22줄. `references/` 9개 → 20개. 교차 참조 제거.
- 스킬 14개에 "왜" 줄 추가. 검증: 각 스킬 7~20회.
- 워킹 트리 변경 58개 파일, 커밋 안 함.

## Next
1. `git diff`로 변경을 검토한다. 특히 `harness/references/`의 이동 내용과 `.claude/agents/`의 `color` 줄.
2. `harness/SKILL.md`에 "**왜:**" 줄이 없다(0개). 분리 작업 때 빠졌다. 라우터 본문 규칙마다 사유를 추가한다.
3. 추론으로 쓴 "왜" 세 곳을 검토한다: `menu-pattern`의 `MENU_MIN_LINKS`, `retry-safety`의 `RS_ESCALATE_MESSAGE`, `with-without`의 `WW_PARALLEL`.
4. 감사 에이전트를 다시 돌려 점수가 개선됐는지 확인한다(뼈대, 안티패턴, 메뉴판, 팀 규모).
5. 검토가 끝나면 커밋하고 푸시한다. 현재 브랜치는 `HEAD`(detached 상태 가능)이므로 `main` 기준으로 브랜치를 먼저 만든다.
6. Unity 프로젝트를 만든다(Unity 6.x, 2D 템플릿). 경로를 받으면 `ProjectSettings/ProjectVersion.txt`로 버전을 확인한다.
7. `brew install uv` 후 CoplayDev MCP for Unity를 추가하고, `claude mcp list`로 확인한다.
8. spritefusion MCP를 `/mcp`에서 OAuth 인증한다.

## Key files
- `CLAUDE.md`: 프로젝트 지침. 팀 규칙과 승인 기준이 여기 있다.
- `.claude/phases.json`: phase 카탈로그. 팀 구성 시 이 목록에서 고른다.
- `_workspace/README.md`: phase 산출물 규칙.
- `.claude/skills/harness/SKILL.md`: 메뉴판. 링크된 `references/`를 필요할 때만 읽는다.
- `.claude/agents/gameplay-programmer.md`: 구현 에이전트 기준 문서. 승인 기준과 git 절이 있다.
- `.claude/agents/level-pipeline-engineer.md`: Sprite Fusion 임포트 규칙. 샘플 맵 없이 임포터를 만들지 않는다.
- `.claude/settings.json`, `.claude/token-guard/config.json`: 토큰 가드 훅과 임계치.
- `.mcp.json`: spritefusion MCP 등록.

## Open questions
- 전역 `~/.claude`의 token-guard 훅, 스킬, 에이전트를 지울지. 지우지 않으면 이 폴더에서 훅이 두 번 실행된다.
- `.claude/token-guard/state/*.json`(세션 상태 파일 두 개)을 제외할지 커밋할지.
- Unity 프로젝트 경로와 버전.
- Sprite Fusion 신규 크레딧 지급 여부는 가입 시 확인이 필요하다.
- SSH 키(`id_ed25519_dagachy_company`)로 `ssh -T`는 거부되지만 `git push`는 성공했다. 원인 미확인.
