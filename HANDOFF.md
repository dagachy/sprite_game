# HANDOFF (2026-11-05)

## Goal
Godot 4 모바일 2D 로그라이트 프로토타입(P0)을 출시 검증 가능한 수준으로 올린다. 한 판이 끝까지 돌고, 3택·로그·디버그 가드·캡처 도구가 들어가 있다. 밸런스는 사람 플레이 기록을 기다리는 중이다.

## Decisions (재논의 금지)
- 엔진 Godot 4.7.2 GDScript, 2D 전용. 루트 `game/`. 논리 해상도 216x384.
- 문서 우선순위: p4 요약 > p3 > p2 > p1 > 원본. 기준본 `_workspace/impl_spec/<phase>/_summary.md`.
- 밸런스 값 변경은 사람 플레이 기록 후에만 (TD D1). 봇 0/100 측정은 휴리스틱 한계라 판정 근거로 쓰지 않는다.
- plaza_01 모서리 `###` 유지, `chunk_lint.gd`의 L4B_EXCEPT (TD D2).
- 로그: 평면 봉투, 문자열 enum, 이벤트 `pick`, `pick_log` 키 통일 (TD D4).
- 이벤트: P0 필수 중 `run_start`, `zone_enter`, `pick`, `run_death`, `run_end` 구현. `run_restart`, `debug_toggle`은 P1. 확장 `hint_shown`, `b1_stun_pillar`, `levelup_ms`는 승인, 구현은 P1 (TD D3, D6).
- 디버그 코드는 `scripts/debug/`, `scenes/debug/`에 두고 export 제외. 참조는 `OS.is_debug_build()` 가드 안의 `load()`만 (AC-43).
- 커밋·푸시는 사용자 요청 시에만, main에 직접.
- TD 결정 재확인(2026-11-05): 대기 중인 technical-director 에이전트 결과는 없었다. 기록된 결정은 `_workspace/impl_spec/p3_bm_ops/_summary.md` 끝 "TD 결정 추가" 블록뿐이며, 코드와 대조해 이미 반영돼 있음을 확인했다(P0 이벤트 5종 emit, `run_restart`·`debug_toggle` 미구현=P1, `pick_log` 통일).
- 사용자 결정 대기 8건(유상 젬, 광고 2배 각인 제외, SDK·분석 백엔드, UA 예산 약 31,000달러, `WalletState` 세이브 포맷, `Battle.hurt()` killer_kind 인자, 디버그 API 코어 수정, 캡처 200장 상한)은 `_summary.md` "사용자 결정 대기"에 있다. 이번에는 적용하지 않았다.
- 새 `class_name` 스크립트를 추가하면 `godot --headless --path game --import`로 클래스 캐시를 먼저 갱신한다. 안 하면 테스트가 Parse Error로 실패한다.
- StringName은 사전순 정렬이 안 된다. 정렬이 필요하면 String으로 바꿔서 정렬한다.

## Done
- 3택 입력 잠금 0.5s: `game/scripts/core/offer_lock.gd`, `game/scripts/game/main.gd` (AC-35).
- 3택 규칙: T-01 1000시드×12상태 통과 (AC-14, 15).
- 로그 runs.jsonl 필드를 P3 §2.3에 정렬, `pick_log` 통일. 이벤트 run_start/zone_enter/run_death/run_end 추가 (`battle.gd`, `main.gd`).
- 릴리스 가드: 디버그 HUD 미생성, F1~F9 가드 (AC-43 정적 검사).
- 결과·사망 화면 딤 레이어 (`main.gd`).
- 캡처 C1/C2/C5: F6 PNG 저장, F7 월드 정지, F8 한 프레임, F9 HUD 숨김. `game/scripts/debug/capture_rig.gd`, 200장 상한.
- C3 시드 프리셋 데이터 (이번 세션):
  - `game/scripts/debug/capture_presets.gd`: CAP-01~06 `PRESETS`, `ids()`, `make_battle()`, `advance()`, `state_digest()`.
  - `game/tests/unit/test_capture_presets.gd`: 목록, god 오버라이드, CAP-04 무기·패시브, 결정성, CAP-04 3택 정지.
  - CAP-04만 실제로 검증됨. CAP-01~03, 05, 06의 도달 조건과 오버라이드(위험 바닥 강조, 스폰 수 12, 진화 강제)는 **[추정] 미구현**이다. 파일 주석과 `note` 필드에 표시해 뒀다.
- 봇 100판 측정: `game/tools/bot_batch.gd`. 단축판 1판차 클리어 0/100, 사망은 전부 구역 A. 판정 FAIL, 밸런스 보류.
- 테스트: `godot --headless --path game --script res://tests/run_tests.gd` 52 tests, 2262 checks 전부 통과.
- QA 상태표: `_workspace/impl_spec/p4_quality/mobile-qa-lead.md`.

## Next
1. C3 메뉴 연결은 완료. 디버그 하단 패널(`main.gd` `_build_preset_panel`)에서 프리셋을 골라 시작하고 정지 후 F6로 저장한다. 파일명은 `cap_<ms>_<seq>_<프리셋ID>.png`. P3 C5 전체 형식(날짜·res·seed·t·git)은 아직 아니다. 실제 화면 캡처는 헤드리스로 확인 못 했다(GPU 렌더 필요).
2. CAP-01~03, 05, 06의 도달 조건을 실측한다. `stage_recipe.gd`의 슬롯과 `cover_01`, `choke_01` 청크 위치를 보고 `forward_steps`를 확정한다. 필요하면 `balance`나 청크 값은 건드리지 않는다(밸런스는 보류 상태).
3. 디버그 패널 UI에서 `battle.debug_set_weapon`, `debug_give_passive` 호출 연결 (OS.is_debug_build 가드).
4. 사람 플레이 기록 수집 후 밸런스 판정(AC-20, 23, 25) 재검토.
5. Android SDK·익스포트 템플릿 설치 결정 후 릴리스 export 실행 검사(AC-43 실행 검사), Android 빌드(T19 전 필수).
6. P5: `docs/specs/` 통합.

## Key files
- `_workspace/impl_spec/p3_bm_ops/user-acquisition-marketer.md` §5: CAP-01~06 스펙, 결정성 규칙 D1~D6, 수용 기준.
- `_workspace/impl_spec/p4_quality/mobile-qa-lead.md`: AC 상태표. 다음 작업 체크리스트.
- `_workspace/impl_spec/p4_quality/_summary.md`: 사용자 결정 1~10, 충돌 Z1~Z11.
- `game/scripts/debug/capture_presets.gd`: 이번 세션 신규. CAP-01~06 데이터와 빌더.
- `game/scripts/debug/capture_rig.gd`: C5 PNG 저장, 상한 정리.
- `game/scripts/game/main.gd`: 씬 루트, 입력, 3택·결과 UI, 디버그 가드. C3 메뉴 연결 지점.
- `game/scripts/core/battle.gd`: 전투 상태, 시그널, 디버그 API(`debug_set_weapon`, `debug_give_passive`, 약 L920).
- `game/scripts/core/stage_recipe.gd`: 슬롯 구성, 시드 기반 청크 선택.
- `game/tests/run_tests.gd`: 헤드리스 테스트 러너. 검사 0건 테스트는 실패 처리.

## Open questions
- 사람 플레이 기록을 누가, 언제 줄지 (밸런스 판정 블로커).
- Android SDK·익스포트 템플릿 설치를 이 환경에서 진행할지 (대용량, 라이선스 동의 필요).
- `TD`는 technical-director로 해석해 사용 중. 다른 뜻이었는지 확인 필요.
