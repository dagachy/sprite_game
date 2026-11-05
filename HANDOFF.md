# HANDOFF (2026-11-05, 6)

## Goal
Godot 4 모바일 2D 로그라이트 프로토타입(P0)을 출시 검증 가능하게 만든다. 이번 단위는 인트로·도입 컷·판 밖 흐름(타이틀, 설정, 일시정지, 결과, 포기)을 구현하는 것이었다. 구현과 헤드리스 검증은 끝났고, 실기기 확인과 밸런스 판정이 남았다.

## Decisions (재논의 금지)
- 엔진 Godot 4.7.2 GDScript, 2D 전용. 루트 `game/`. 논리 해상도 216x384.
- 결정 규칙: 사용자에게 물을 결정은 TD(technical-director)가 정하고, 실행은 전문가 팀이 한다. 메인은 구현 파일을 직접 고치지 않는다.
- 커밋·푸시는 사용자가 요청할 때만, main에 직접.
- 밸런스 값 변경은 사람 플레이 기록 후에만. 봇 결과는 판정 근거로 쓰지 않는다.
- 디버그 코드는 `scripts/debug/`, 릴리스에서는 `OS.is_debug_build()` 가드 안 `load()`로만 참조 (AC-43).
- 새 `class_name` 추가 시 `godot --headless --path game --import` 먼저.
- 디버그 부여 런과 프리셋 판은 세이브·메타·runs·events를 건드리지 않는다 (decision4).
- 인트로·흐름 결정은 `_workspace/td_decision/decision5.md` (E1~E7). 주요 내용:
  - 도입 컷 3장과 클리어 컷 2장은 `CutPlayer`로 재생, 1탭 넘김·스킵, 컷당 최소 1.2초.
  - 첫 실행 판별은 `user://settings.cfg`의 `first_run_done`. 메타 세이브 스키마는 건드리지 않음.
  - UI는 코드로 빌드. 새 `.tscn` 없음.
  - 포기는 확인 후 PAUSE→RESULT로 가서 60% 정산, runs.jsonl에 `result:"died"`, `quit_midrun:true`로 기록 (E6).
  - 포기 로그는 집계에서 걸러낸다 (E7). `battle.gd`는 건드리지 않는다.
  - `boss.intro`는 접근 구간 배너(`ui.zone.boss`)에 연결 유지 (E2).

## Done
- 커밋 `cb7874c` (main, origin 동기화): CAP-01~06, 캡처 판정 결정 4, 디버그 부여 가드, AC-43 수정.
- 미커밋 (main 위, 전부 작업 트리에 있음):
  - 흐름: `game/scripts/game/flow.gd`(TITLE/INTRO/RUN/PAUSE/RESULT/SETTINGS), `settings_store.gd`, `cut_player.gd`, `run_settle.gd`(정산·runs 기록).
  - UI: `game/scripts/ui/flow_ui.gd`(타이틀, 컷, 결과, 설정, 일시정지, 포기 확인, 뒤로 가기 차단, 백그라운드 자동 일시정지).
  - 데이터: `game/scripts/data/strings.gd`(문구 테이블, 금지어 스캔).
  - `game/scripts/game/main.gd`: `_boot_flow()`, `quit_run()` 래퍼, `boss.intro` 연결, `flow_ui_ready=true`.
  - 테스트: `game/tests/unit/test_game_flow.gd`, `test_flow_ui.gd` (+uid).
- 헤드리스: 88 tests, 2568 checks, 0 failures (재실행 확인). 부팅 에러 없음.
- 문구: 클리어 컷(`cut.clear1~2`)과 표기 교체(쓰러졌다·각인)는 `_workspace/p_story/storyteller/lines.md`. game-reviewer 검토 전 가정 상태.
- 보고서: `_workspace/p_impl_flow/gameplay-programmer/report*.md`, `_workspace/p_impl_ui/ui-implementer/report*.md`.

## Next
1. 릴리스 export로 실기기 확인. 에디터와 디버그 빌드는 타이틀·인트로를 건너뛰므로 새 화면이 보이지 않는다. 체크 항목: 90초 실측, 로딩 1.5초, 컷 1.2초 전 탭 무시, 뒤로 가기(판 중 앱 종료 안 되는지), 전화·홈 이동 후 자동 일시정지, 노치 레이아웃, 한글 글리프, 3택·리롤 버튼(44px 미달, 기존 화면), 포기 정산과 재실행 후 유지, 컷 도중 강제 종료 후 재실행.
2. 최고 항목 표시 문구를 storyteller에게 받아 `strings.gd` TABLE과 `SCAN_PREFIXES`("item.")에 추가. 지금은 결과 화면에서 전부 숨김.
3. 클리어 컷·표기 문구 game-reviewer 검토 후 확정.
4. 포기 집계 규칙(E7)을 AC-20·23·25 문서에 반영 (편집 담당 지정 필요).
5. 밸런스 판정 (AC-20, 23, 25): 사람 플레이 기록 필요.
6. 공개 `Battle.abandon()`과 `run_quit` 이벤트: `battle.gd` 변경이라 승인 후, 밸런스 판정 뒤에.
7. 커밋·푸시: 사용자 요청 대기.
8. 스토어 제출 전: `com.example` 패키지명, `use_gradle_build=false`(AAB 불가), 서명 설정.

## Key files
- `game/scripts/game/flow.gd`: 상태 전이와 진입 메서드. 흐름의 기준.
- `game/scripts/game/main.gd`: `_boot_flow`, `quit_run`, `boss.intro`. 디버그 패널과 AC-43 경로가 얽혀 있음.
- `game/scripts/ui/flow_ui.gd`: 화면 5종과 포기 확인. 뒤로 가기 설정은 `_ready`.
- `game/scripts/game/run_settle.gd`: 정산과 runs.jsonl 기록, 집계 규칙 주석.
- `game/scripts/data/strings.gd`: 문구 테이블. 새 문구는 여기에만.
- `_workspace/td_decision/decision5.md`: 이번 단위 결정 전체.
- `game/scripts/core/battle.gd`: 무변경 원칙. `_end_run`은 private.

## Open questions (사용자 확인이 남는 것만)
- 커밋·푸시를 지금 할지.
- 실기기 확인을 누가, 언제 할지 (릴리스 export 필요).
- `battle.gd` 공개 포기 API 추가 승인 여부 (밸런스 판정 뒤로 미룸).
- 실결제 광고비 집행: 재판정 통과 후에도 결제 직전 확인 1회.
