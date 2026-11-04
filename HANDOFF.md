# HANDOFF

## Goal
`sprite_game`을 유니티(C#) 기반 2D 모바일 게임 제작사 작업 공간으로 세팅한다. 하네스·토큰 가드·전문가 팀을 이 폴더 전용으로 구성하고, 유니티 프로젝트와 Sprite Fusion·Unity MCP를 연결하는 것이 목표다.

## Decisions
- 모든 설정은 프로젝트 범위(`sprite_game/.claude/`, `sprite_game/.mcp.json`)에 둔다. 전역 `~/.claude`는 아직 건드리지 않았다.
- 전문가 에이전트는 역할별로 나눈다. 분석·기획·제작·출시 에이전트는 읽기 전용(Read, Grep, Glob, WebFetch, WebSearch)이다. 구현 에이전트 6명만 Edit, Write, Bash를 가진다.
- 엔진은 Unity(C#), 2D 기준이다. Sprite Fusion이 2D 타일맵 도구이기 때문이다.
- 구현 에이전트는 파일 삭제, 대량 에셋·프리팹 수정, `.meta` 편집, 스토어 프로덕션 업로드, 비밀 값 취급 전에 승인을 받는다.
- Sprite Fusion MCP는 HTTP 방식(`https://www.spritefusion.com/mcp`)으로 등록했다. 생성 도구 1회당 15 크레딧이 든다.
- 상용 게임 분석은 공개 정보와 플레이 관찰만 쓴다. 코드·에셋 역분석이나 복제는 제안하지 않는다.

## Done
- 하네스 스킬 13개 복사: `.claude/skills/` (harness, harness-evolve, harness-structure, agent-frontmatter, agent-tools-contract, antipattern-detector, dag-validator, menu-pattern, prose-pruner, retry-safety, separation-signals, team-size-governor, with-without)
- 하네스 에이전트 12개 복사: `.claude/agents/` (auditor 9종, with-without-runner, with-without-grader, retry-safety-executor)
- token-guard 설치: `.claude/token-guard/` (scripts 9개, config.json, state/), `.claude/settings.json`에 훅 4종과 statusLine 연결, `.claude/skills/handoff`, `.claude/skills/token-report`, `.claude/agents/token-auditor.md`
- 단위 테스트 19개 통과(token-guard, 격리 실행). 세션 훅과 statusline 스크립트 스모크 테스트 통과.
- 전문가 에이전트 17명 추가(`.claude/agents/`):
  - 상용 분석: commercial-game-analyst, mechanics-analyst, economy-balance-analyst, ux-onboarding-analyst, art-audio-analyst, market-review-analyst
  - 설계·기획: spritefusion-expert, level-designer, bm-expert
  - 모바일 제작·출시: mobile-producer, mobile-performance-engineer, store-compliance-specialist, user-acquisition-marketer, mobile-qa-lead, live-ops-analytics
  - 구현(유니티): gameplay-programmer, level-pipeline-engineer, ui-implementer, backend-engineer, technical-artist, build-release-engineer
- MCP: `.mcp.json`에 `spritefusion` 등록. 상태는 "승인 대기"다.

## Next
1. 사용자가 `sprite_game`에서 `claude`를 실행해 spritefusion MCP를 승인하고, `/mcp`에서 OAuth 인증을 완료한다.
2. 유니티 프로젝트를 만든다(Unity 6.x 권장, 2D 템플릿). 경로를 전달받으면 `ProjectSettings/ProjectVersion.txt`로 버전을 확인한다.
3. `brew install uv`로 uv를 설치한다.
4. Unity 프로젝트에 CoplayDev MCP for Unity를 추가한다: Package Manager → Add from git URL `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main`. 이후 `Window → MCP for Unity → Configure All Detected Clients`를 실행한다.
5. Unity MCP가 `claude mcp list`에 나타나는지 확인한다. 안 나오면 https://coplaydev.github.io/unity-mcp/ 에서 Claude Code 등록 명령을 확인한다.
6. 새 에이전트 목록을 보려면 세션을 재시작한다.

## Key files
- `.mcp.json` — 프로젝트 MCP 서버 목록. spritefusion 등록 상태.
- `.claude/settings.json` — token-guard 훅 4종과 statusLine 설정. 프로젝트 범위.
- `.claude/token-guard/config.json` — 임계치(컨텍스트 200K 경고, 캐시 만료 차단 150K 등).
- `.claude/agents/gameplay-programmer.md` — 구현 에이전트 작업 절차와 승인 기준의 기준 문서. 나머지 구현 에이전트도 같은 원칙을 따른다.
- `.claude/agents/level-pipeline-engineer.md` — Sprite Fusion 출력 임포트 규칙. 샘플 맵 없이 임포터를 만들지 않는다.
- `.claude/agents/spritefusion-expert.md` — Sprite Fusion 참조 출처(제품·docs URL)와 MCP 크레딧 비용 요약.

## Open questions
- 전역 `~/.claude`에 남아 있는 token-guard 훅, `handoff`·`token-report` 스킬, `token-auditor` 에이전트, 하네스 스킬·에이전트를 지울지 결정이 필요하다. 지우지 않으면 이 폴더에서 훅이 두 번씩 실행된다.
- 유니티 프로젝트 경로(또는 새로 만들 버전·템플릿)를 알려줘야 한다.
- Sprite Fusion 신규 체험 크레딧(50, 30일)은 검색 요약에서만 확인했다. 가입 시 실제 지급 여부를 확인해야 한다.
- 이 폴더는 git 저장소가 아니다. `.claude/`, `.mcp.json`, `HANDOFF.md`를 버전 관리에 넣을지, `.gitignore`에 넣을지 정해야 한다. 특히 `.claude/token-guard/state/`는 제외 대상이다.
