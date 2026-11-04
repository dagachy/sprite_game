# sprite_game — 프로젝트 지침

2D 모바일 게임 제작 작업 공간이다. 엔진은 Unity(C#)이며, 레벨 타일맵은 Sprite Fusion으로 만든다.

## 구성

- `.mcp.json` — 프로젝트 MCP 서버. `spritefusion`(HTTP)이 등록돼 있다. Unity MCP는 Unity 프로젝트 준비 후 추가한다.
- `.claude/agents/` — 전문가 에이전트 34명. 분석·기획·QA·출시 계열은 읽기 전용이다. 구현 에이전트 6명만 Edit·Write·Bash를 가진다.
- `.claude/skills/` — 하네스 스킬. `harness`는 메뉴판(라우터)이고 상세는 `references/`에 있다.
- `.claude/phases.json` — 팀 phase 카탈로그. 작업마다 phase 단위로 팀을 짠다.
- `.claude/token-guard/` — 토큰 가드. 임계치는 `config.json`에 있다. 훅 4종과 statusLine은 `.claude/settings.json`에 연결돼 있다.
- `_workspace/` — phase 간 산출물 전달 공간. 규칙은 `_workspace/README.md`에 있다.
- `HANDOFF.md` — 작업 단위 종료 시 남기는 인수인계 문서. 추적한다.

## 팀 구성 규칙

- 팀은 작업마다 새로 정한다. 전체 에이전트 수는 상한이 없고, 상한은 phase별 동시 활성 수에 건다.
- 한 phase의 동시 활성 에이전트는 최대 5명이다(`phases.json`의 `max_concurrent`).
- phase 산출물은 `_workspace/<phase>/<agent>/`에 쓰고, 다음 phase 에이전트가 그 경로를 읽어 이어받는다.
- 같은 역할의 서브에이전트는 새로 띄우지 말고 `SendMessage`로 재사용한다.

## 작업 원칙

- 엔진은 Unity 2D다. 2D가 아닌 기능이나 3D 전제 설계는 하지 않는다.
- 상용 게임 분석은 공개 정보와 플레이 관찰만 쓴다. 역분석이나 복제는 하지 않는다.
- 아래 작업은 구현 전에 사용자 승인을 받는다.
  - 파일 삭제
  - 대량 에셋·프리팹 수정, `.meta` 파일 편집
  - 스토어 업로드
  - 비밀 값(키, 토큰, 계정 정보) 취급
- Sprite Fusion 출력 임포터는 실제 샘플 맵 없이 만들지 않는다(`level-pipeline-engineer` 기준).
- Sprite Fusion MCP 호출은 크레딧을 쓴다. 호출 전에 비용을 확인한다(`spritefusion-expert` 기준).

## 토큰 관리

- 작업 단위가 끝나면 `/handoff`로 `HANDOFF.md`를 갱신하고 `/clear`로 새 세션을 연다.
- 5분 넘게 쉬기 전에도 `/handoff`를 먼저 실행한다. 캐시가 만료되면 컨텍스트를 전부 다시 쓴다.
- 작은 작업은 직접 처리한다. 서브에이전트에는 큰 내용 대신 파일 경로를 넘긴다.
- 큰 파일은 전체 읽기 대신 `grep`과 `offset`/`limit`으로 읽는다.

## 커밋

- 사용자가 요청할 때만 커밋하고 푸시한다. 기본 브랜치에서는 먼저 브랜치를 만든다.
- `.gitignore`는 `__pycache__/`, `*.pyc`, `.DS_Store`, `_workspace/` 산출물(README 제외)을 제외한다.
