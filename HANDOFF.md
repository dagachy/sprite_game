# HANDOFF

## Goal
sprite_game은 Unity(C#) 2D 모바일 게임 작업 공간이다. 하네스(전문가 에이전트 37명, phase 단위 팀 구성)를 다른 PC에서도 실행하고, 탕탕특공대 분석을 바탕으로 중국 무협 + 이세계 요소의 신작 기획을 제안서 수준까지 다듬는다.

## Decisions
- 커밋과 푸시는 `main`에 직접 한다. 신규 브랜치는 사용자가 요청할 때만 만든다. 현재 원격 브랜치는 `main`만 있다.
- 원격은 `https://github.com/dagachy/sprite_game.git`이다. HTTPS 푸시는 인증 실패할 수 있으므로 `git@github-dagachy:dagachy/sprite_game.git`로 푸시한다.
- 토큰 가드는 전역(`~/.claude/token-guard/`, `~/.claude/settings.json`)만 쓴다. 프로젝트 사본은 두지 않는다.
- `_workspace/*`는 `.gitignore`로 제외한다. 커밋할 문서는 `docs/`에 둔다.
- 상용 게임 분석은 공개 정보와 플레이 관찰만 쓴다. 역분석, 에셋·수치·UI 재현은 하지 않는다.
- 구현 에이전트 6명만 Edit·Write·Bash 권한을 가진다. 나머지는 읽기 전용이다.
- 무협 신작은 뱀서라이크가 아니다. 한 손 경공 이동과 타이밍 판정이 중심이다. 수치와 BM은 전부 가정이다.
- 무협 신작 BM은 B안(premium + 외형·챕터 DLC)이 추천안이다. 귀환 엔딩의 핵심 인물은 유료로 막지 않는다.

## Done
- 커밋 `db0966a`: 스토리 텔러 에이전트, 이세계 포함 무협 제안서, 실무 브리핑 6종, `docs/SETUP.md`.
- 커밋 `6a14f54`: 전역 token-guard 전환, 시장 데이터 분석가 추가, HANDOFF 갱신.
- 원격 브랜치 `chore/harness-setup`, `docs/tangtang-analysis` 삭제. 둘 다 main에 포함된 내용이었다.
- 미커밋: `.claude/agents/game-reviewer.md` 추가(베테랑 게임 리뷰어, 읽기 전용). `.claude/phases.json`에 `review` phase 추가(game-reviewer, mechanics-analyst, ux-onboarding-analyst, level-designer). 에이전트 수 36→37 반영(`CLAUDE.md`, `docs/SETUP.md`, 이 파일).

## Next
1. 미커밋 변경 4개 파일과 신규 에이전트 파일을 커밋하고 `main`에 푸시한다(사용자 요청 시).
2. 다른 PC에서 `docs/SETUP.md`대로 설정하고, `/agents`에서 37개가 보이는지, 전역 token-guard 상태줄이 뜨는지 확인한다.
3. `market-data-analyst`로 무협 장르 시장 데이터를 조사한다. 제안서 §9 검증 3번이다. 조회 경로(모바일인덱스 또는 센서타워)를 먼저 정한다.
4. 제안서 §9 검증 1번: 경공 이동과 탭 판정의 입력 지연 프로토타입을 60Hz와 120Hz에서 측정한다.
5. `game-reviewer`로 무협 제안서를 플레이어 관점에서 검토한다.
6. 제안서 §10 결정 항목 5개를 사용자와 확정한다.
7. Unity 프로젝트를 만든다(Unity 6.x, 2D 템플릿). 경로를 받으면 `ProjectSettings/ProjectVersion.txt`로 버전을 확인한다.
8. spritefusion MCP를 `/mcp`에서 OAuth 인증한다. 호출 전 크레딧 비용을 확인한다.

## Key files
- `CLAUDE.md`: 프로젝트 지침. 팀 규칙, 승인 기준, 커밋 규칙.
- `docs/SETUP.md`: 다른 PC에서 하네스를 실행하는 절차.
- `docs/proposals/wuxia_action_proposal.md`: 무협 + 이세계 신작 제안서(§5 시나리오, §9 검증, §10 결정 항목).
- `.claude/phases.json`: phase 후보 풀(review phase 포함)과 동시 활성 상한 5명.
- `.claude/agents/game-reviewer.md`: 게임 리뷰어(읽기 전용, 미커밋).
- `.claude/agents/market-data-analyst.md`: 시장 데이터 분석가(읽기 전용).
- `.claude/agents/storyteller.md`: 스토리 텔러(읽기 전용).
- `.claude/settings.json`: 프로젝트 세션 시작 훅(Pixel Agents)만 남은 상태.
- `docs/analysis/commercial/tangtang_analysis.md`: 탕탕특공대 분석 원본.

## Open questions
- 전역 `~/.claude`의 pre-flight 스킬·에이전트 사본이 프로젝트와 중복될 수 있다. 제거할지 정해야 한다.
- 탕탕에이스의 과금 구조, 퍼블리셔, 출시일은 미확인이다.
- 무협 장르의 2026년 시장 데이터는 아직 없다. 조회 경로를 정해야 한다.
- 원격 URL을 HTTPS에서 SSH로 바꿀지 정해야 한다.
