# HANDOFF

## Goal
sprite_game은 Unity(C#) 2D 모바일 게임 작업 공간이다. 하네스로 전문가 에이전트 37명을 운영한다. 기준 문서는 `docs/proposals/game_proposal_v5.md`(「새벽 레일: 환생 열차」, 가제)다. 이번 세션에서는 v5 기준으로 예상 모바일 화면 목업 이미지를 만들었다. 직전에 요청받은 "기획팀 18명 phase별 상세 기획 문서" 작업은 사용자가 중단시켜서 아직 시작하지 않았다.

## Decisions
- v1~v3 제안서는 참조하지 않는다. v5는 v4와 v5 토론 산출물만 근거로 삼는다.
- 커밋·푸시는 `main`에 직접 하고 다른 브랜치는 만들지 않는다(메모리 `feedback-main-branch-only`).
- 장르는 세로 지형 전진 서바이버다. 던전 1층 = 판 1개 = 구역 A/B/C + 층 보스(약 7분 30초)다. 세계관은 「환생 열차」, 직업은 검사·궁수·마법사(+성직자), 원소 2종, 몬스터 2계열(실루엣 + 머리 위 1px 마크)이다. 상세는 v5 본문을 따른다.
- 목업 이미지는 Sprite Fusion을 직접 쓰지 않고(크레딧·MCP 미연결), **SF 공개 갤러리(`/pixel-art-gallery`) 스타일만 참고해** Python(PIL)으로 새로 그린다. 갤러리 이미지는 복사하거나 쓰지 않는다(사용자 정정).
- SF 갤러리 스타일 요약: 32~64px, 1px 어두운 외곽선, 3~4단 색조 이동 음영, 2.5등신 정면 치비, 발광 눈, 디테일 많은 석재·목재.
- 기획 문서 작업은 기획·분석 18명이 읽기 전용이라 파일을 못 쓴다. 메인이 결과를 받아 `_workspace/<task>/<phase>/<agent>.md`로 저장하고 phase마다 `_summary.md`를 만드는 방식(proposal_v5와 같은 방식)으로 한다. phase당 최대 5명이다.

## Done
- 목업 v1(단순 픽셀): 스크래치 폴더 `mock.py` → `mockup_sheet.png`, `screen_1~3.png`.
- 목업 v2(SF 갤러리 스타일): 스크래치 폴더 `mock_sf.py` → `sf_out/`(`sf_mockup_sheet.png`, `sf_screen_1~3.png`, `sf_assets.png`). 화면은 ① 판 안 플레이 ② 레벨업 3택 ③ 환생 결과이고, 에셋 시트도 있다.
  - `docs/mockups/`로 복사를 마쳤다(`v1_simple/`, `v2_sf_style/`, `scripts/`). 스크립트의 출력 경로는 자기 폴더 기준 상대 경로로 바꿨다. 아직 커밋하지 않았다.
- 확인 결과: `.mcp.json`에 `spritefusion`이 등록돼 있지만 `claude mcp list`에 나오지 않는다(미승인 또는 미인증).
- 이전부터 미커밋 상태인 파일: `game_proposal_v4.md`, `game_proposal_v5.md`, `isekai_proposal_v3.md`, `wuxia_isekai_proposal_v2.md`, `HANDOFF.md`(git status 기준으로는 clean으로 표시된다. 다음 세션에서 다시 확인).

## Next
1. 사용자가 요청하면 `docs/mockups/`를 커밋한다.
2. 기획팀 18명 상세 기획 작업(구현팀 인계 수준)을 phase로 진행한다. 제안 구성(동시 5명 이하):
   - P1 분석: commercial-game, mechanics, economy-balance, market-data, market-review
   - P2 핵심 설계: level-designer, ux-onboarding, art-audio, storyteller, spritefusion-expert
   - P3 BM·운영: bm-expert, live-ops-analytics, user-acquisition-marketer, store-compliance-specialist
   - P4 품질·일정·리뷰: mobile-qa-lead, mobile-performance-engineer, mobile-producer, game-reviewer
   - 산출물은 `_workspace/detail_spec/<phase>/`에 두고, 마지막에 `docs/specs/`로 구현팀 인계 문서를 통합한다.
   - 시작 전에 phase 구성과 인계 문서 목차를 사용자에게 보여 주고 확인받는다.
3. 남은 일(이전 세션): v5 §17.2의 결정 13개 확정, W1 SF 검증(크레딧 승인 필요), 경제 재계산, Unity 6 프로젝트 경로 받기.

## Key files
- `docs/proposals/game_proposal_v5.md`: 기준 제안서다. §5 메카닉, §6 레벨, §10 UI, §17 결정 항목이 있다.
- `docs/proposals/game_proposal_v4.md`: v5가 참조하는 세부 규칙이 있다.
- `_workspace/proposal_v5/*/_summary.md`: 이전 phase 진행 방식의 예시이자 근거다.
- `.claude/phases.json`, `docs/AGENTS.md`: phase 후보 풀과 에이전트 권한이 있다.
- `docs/mockups/scripts/mock_sf.py`: SF 스타일 목업 생성기다. 스프라이트 그리드, 램프 음영, 외곽선 파이프라인이 있다.

## Open questions
- 기획 18명 작업을 지금 시작할지, phase 구성안을 승인할지.
- Sprite Fusion MCP를 연결할지(`/mcp`에서 승인·로그인).
- v5 §17.2 결정 13개, v1~v3 파일 정리 여부.
