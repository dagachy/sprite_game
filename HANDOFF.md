# HANDOFF (2026-11-05, 8)

## Goal
Godot 4 모바일 2D 로그라이트 프로토타입을 출시 검증 가능하게 만든다. 이번 단위는 실행 오류 수정과 실제 플레이 테스트였다. 실기기 확인과 밸런스 판정이 남았다.

## Decisions (재논의 금지)
- 엔진 Godot 4.7.2 GDScript, 2D 전용. 루트 `game/`. 논리 해상도 216x384.
- 결정은 TD가 하고, 실행은 전문가 팀이 한다. 사용자에게 묻는 것은 승인 대기 항목뿐이다.
- 커밋·푸시는 사용자가 요청할 때만, main에 직접.
- 밸런스 값 변경과 판정은 사람 플레이 기록 후에만. 봇 결과는 근거로 쓰지 않는다.
- battle.gd, balance.gd는 무변경. 공개 `abandon()`, `run_quit`, killer 적 ID 필드는 R9 승인 요청 때 한 건으로 묶는다.
- 포기 확정은 `FlowUI._do_forfeit`이 `flow.abandon(no_record)`를 직접 호출한다. no_record는 프리셋 판 또는 부여 판이면 참. Flow에 forfeit() 래퍼는 두지 않는다 (`_workspace/p_playtest/technical-director/decision_forfeit.md`).
- 부팅 순서: `main.gd`에서 `fui.attach()`를 `add_child(fui)` 앞에 둔다 (`_workspace/p_playtest/technical-director/decision.md`).
- 디버그 코드는 `scripts/debug/`, 릴리스에서는 `OS.is_debug_build()` 가드 안 `load()`로만 참조 (AC-43).
- 새 `class_name` 추가 시 `godot --headless --path game --import` 먼저.
- 재화 표기는 "각인 +{n}". 존댓말은 UI 대화상자에만, 서사 컷은 존댓말 없음.
- 문구의 단일 출처는 `game/scripts/data/strings.gd`.

## Done
- 부팅 SCRIPT ERROR(`FlowUI._set_confirm`) 수정. 원인은 `_ready`가 `setup()`보다 먼저 불린 것. 안전망 가드 추가 (`flow_ui.gd` `_ready`, `_process`).
- 포기 확정 출시 차단 버그 수정. 기존에는 호출되지 않는 `forfeit()`을 불러 판이 안 끝났다. 죽은 경로(`forfeit_requested`, `has_method` 분기) 삭제.
- 재검증 완료(실행): 부팅 오류 0건, 일반 판 포기 → RESULT, 프리셋 판 포기 → TITLE, 취소 → PAUSE 유지, 레벨업, 사망 → RESULT, 다시 하기, 홈 → TITLE 모두 통과.
- 헤드리스 테스트: `godot --headless --path game --script res://tests/run_tests.gd` → 100 tests, 2686 checks, 0 failures.
- 이전 단위 작업(문구 item/death, 사유 줄, E7 집계 규칙, R3 릴리스 점검, R5 체크리스트, R8 설정 보고)은 이전 핸드오프와 동일하게 완료.
- 커밋 `51be7e2` 이후 변경은 아래 "Next 1"의 미커밋 상태다.

## Next
1. 커밋 여부 결정 (사용자 요청 대기). 미커밋 대상: `game/scripts/game/main.gd`, `game/scripts/ui/flow_ui.gd`, `game/tests/unit/test_flow_ui.gd`, `game/tests/run_tests.gd`, `game/scripts/data/strings.gd`, `game/project.godot`(이 단위와 무관한 변경일 수 있어 확인 필요), `HANDOFF.md`.
2. 설계 확인: 타이틀의 디버그 패널 "프리셋 시작"이 판을 뒤에서 돌리고 타이틀이 가린다. 디버그 전용이면 그대로 두고, 아니면 TD 판단.
3. 미확인 범위 QA: 실제 터치 입력(현재는 버튼 pressed 신호 직접 발화), 릴리스 빌드, 세이브·기록 파일 내용, 실기기 항목(노치, 인터럽트, 발열). 체크리스트는 `_workspace/p_remain_a/mobile-qa-lead/device_checklist.md`.
4. R6 실기기 확인: 서명된 릴리스 Android 빌드 필요. 승인 대기 1·2 선행.
5. R7 밸런스 판정 (economy-balance-analyst): 사람 플레이 기록(양식 B) 도착 후 E7 재집계. 최소 표본 일반 판 10판 이상, 플레이어 3명 이상(제안).
6. R9 `Battle.abandon()`, `run_quit`, killer 적 ID: 승인 요청 한 건으로 묶는다.
7. 스토어 제출 전: 패키지명 교체, use_gradle_build=false(AAB 불가) 재검토, 서명 설정, 버전 자동 증가 설계안.

## Key files
- `game/scripts/ui/flow_ui.gd`: 포기·부팅 안전망, 결과 화면, 사유 줄.
- `game/scripts/game/main.gd`: `_boot_flow`(부팅 순서), `_on_abandoned` → `quit_run`(정산).
- `game/scripts/game/flow.gd`: 상태 전이. `abandon(no_record)`는 77행 부근.
- `game/tests/unit/test_flow_ui.gd`: 포기 A~D 케이스와 부팅 회귀 테스트.
- `game/tests/run_tests.gd`: 러너가 첫 프레임에 실행하도록 변경됨(`_run`, test_tree meta).
- `game/scripts/core/battle.gd`: 무변경 원칙. R9 대기.
- `_workspace/p_playtest/technical-director/`: decision.md(부팅), decision_forfeit.md(포기).
- `_workspace/p_playtest/mobile-qa-lead/`: 실패 보고서 파일이 없음. 결과는 이 핸드오프 Done 항목 참조.

## Open questions (사용자 확인 필요)
- 커밋·푸시를 지금 할지, 대상 파일은 위 Next 1 목록 중 무엇인지.
- 타이틀 디버그 "프리셋 시작" 동작을 그대로 둘지.
- 실기기 확인 기기 모델과 OS 목록, 가로 모드 지원 여부.
- 승인 대기 1: Android 서명 빌드와 키스토어(비밀 값).
- 승인 대기 2: 패키지명 교체, use_gradle_build 전환, 서명 설정.
- 승인 대기 3: battle.gd 공개 abandon()과 killer 필드(R9). 밸런스 판정 뒤.
- 실결제 광고비 집행: 재판정 통과 후에도 결제 직전 확인 1회.
