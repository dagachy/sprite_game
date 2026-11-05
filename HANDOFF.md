# HANDOFF (2026-11-05, 5)

## Goal
Godot 4 모바일 2D 로그라이트 프로토타입(P0)을 출시 검증 가능한 수준으로 올린다. 한 판이 끝까지 돌고, 3택·로그·디버그 가드·캡처 도구가 들어가 있다. 밸런스는 사람 플레이 기록을 기다리는 중이다.

## Decisions (재논의 금지)
- 엔진 Godot 4.7.2 GDScript, 2D 전용. 루트 `game/`. 논리 해상도 216x384.
- 결정 규칙: 사용자에게 물을 결정은 technical-director(TD)가 정하고, 실행은 전문가 팀 에이전트가 한다. 메인이 구현 파일을 직접 고치지 않는다. 메모리 `feedback-td-decides-via-teams`. 실제 결제와 비밀 값 취급은 사용자 확인이 남는다.
- 커밋·푸시는 사용자가 요청할 때만, main에 직접.
- 밸런스 값 변경은 사람 플레이 기록 후에만. 봇 0/100은 판정 근거로 쓰지 않는다.
- 디버그 코드는 `scripts/debug/`에 두고 export 제외. 릴리스 경로에서 디버그 클래스는 `OS.is_debug_build()` 가드 안의 `load()`로만 참조한다 (AC-43).
- 새 `class_name` 추가 시 `godot --headless --path game --import` 먼저.
- step 1회 = 월드 시간 t 0.5s.
- 캡처 판정(TD, decision4): 파일명 `cap_{YYYYMMDD-HHMMSS}_{preset|FREE}_P{짧은변}_s{seed}_t{t}_{git}.png`. CAP-01~03은 3택 박스 숨김(상태 유지). CAP-04 도달 전 사망은 실패 표시, PNG 없음. 정지 캡처 중 흔들림 끔. CAP-06 초 단위 상한은 실측 후 확정(도달 상한은 MAX_STEPS 25200).
- 디버그 부여(무기·패시브) 런은 `runs.jsonl`·세이브 기록을 남기지 않는다 (TD 결정 2번). 상점 구매도 같은 조건으로 막음.
- 프리셋 판은 세이브·메타·runs.jsonl·events.jsonl을 건드리지 않는다.
- 수익화 판정(TD, `_workspace/td_decision/decision3.md`가 최종): 유상 젬 미도입, 광고 2배 각인 제외, P0 빌드 SDK 없음, 소프트런칭은 수동 로그 수집 먼저, UA 31,000달러 불승인, 0단계 지출 0원 클로즈드 테스트 채택, 1단계 2,000달러는 집행 금지, 세이브 포맷 보류.

## Done
- 커밋 `42bdaa5` (main 푸시 완료): CAP-01~06 프리셋, 위험 오버레이, 프리프 중 3택 지연.
- 미커밋 (위 결정 4, 세이브 가드, 부여 패널, AC-43 수정 모두 반영):
  - `game/scripts/game/main.gd`: 프리셋·부여 가드, 파일명 ctx, 흔들림 게이트, 3택 숨김, 디버그 패널(무기·패시브), AC-43용 load() 경로.
  - `game/scripts/debug/capture_rig.gd`: `snap(tree, ctx)`, `build_name`, `unique_name`, `git_short`.
  - `game/scripts/debug/capture_presets.gd`: `hide_offer`, `hides_offer`, `reach_failed`, `skips_record`.
  - `game/scripts/core/offer_lock.gd`: `accepts(locked, hidden)`.
  - `game/tests/unit/test_capture_presets.gd`, `game/tests/unit/test_capture_rig.gd`(+uid): 신규 단위 테스트.
- 헤드리스: 67 tests, 2316 checks, 0 failures. `battle.gd` 무변경.
- 스펙 `_workspace/impl_spec/p3_bm_ops/user-acquisition-marketer.md` §5.3 AC 2, 파일명 정규식 갱신 (`_workspace`는 git 제외).
- 결정 기록: `_workspace/td_decision/decision4.md`.

## Next
1. 커밋 승인 대기: 위 미커밋 변경 전체를 main에 커밋·푸시 (사용자 승인 필요).
2. 릴리스 파싱 검증: 실제 릴리스 export로 디버그 파일 제외 빌드가 파싱되는지 확인. 헤드리스 `-s` 단독 스크립트로는 autoload 때문에 검증 불가. Android SDK·템플릿 설치 필요(사람 작업, 항목 9).
3. 기기·에디터 확인(사람): 숨김 3택 박스와 "준비 중"/"도달 실패" 라벨, F6 PNG 파일명 육안 확인, UA-4 정지 PNG 2회 바이트 비교(shake 기본 on), CAP-06 도달 시간·프레임 시간 실측 → 초 단위 상한 확정, 부여 패널 동작과 부여 후 판 종료 시 `runs.jsonl` 줄 수 불변.
4. 사람 플레이 기록 수집 → 밸런스 판정(AC-20, 23, 25). 이후 2-3b 소프트런칭 수집 분석(live-ops-analyst, bm-expert).
5. 2-4 UA 1단계 재판정 조건: 0단계 통과, 밸런스 판정 완료, 2-3b 수집 경로 가동, AC-43 릴리스 export 검사 통과.
6. 스토어 제출 전 과제: `com.example` 패키지명, `use_gradle_build=false`(AAB 불가), Android 서명 설정. TD 확정 후 진행.
7. P5: `docs/specs/` 통합.

## Key files
- `game/scripts/game/main.gd`: 판 흐름, 가드, 디버그 패널, 3택 처리. 변경 집중 지점.
- `game/scripts/debug/capture_presets.gd`: CAP-01~06 데이터, `advance_chunk`, `skips_record`, `hides_offer`.
- `game/scripts/debug/capture_rig.gd`: 캡처 파일명·저장·prune.
- `game/scripts/core/battle.gd`: 코어 전투와 디버그 API. 무변경 원칙.
- `game/export_presets.cfg`: `scripts/debug/*` 릴리스 제외 설정.
- `_workspace/td_decision/decision4.md`: 이번 TD 결정(최신). 앞은 decision.md, decision2.md, decision3.md.
- `_workspace/impl_spec/p3_bm_ops/user-acquisition-marketer.md` §5: CAP 스펙과 AC.

## Open questions (사용자 확인이 남는 것만)
- 커밋·푸시 승인 여부 (Next 1).
- 실제 광고비 결제: 재판정 통과 후에도 결제 직전 사용자 확인 1회.
- 키스토어 등 비밀 값 생성·취급 (CLAUDE.md상 사용자 승인).
- (사람 행위, 블로커) 사람 플레이 기록을 누가 언제 줄지. 기기 확인을 누가 언제 할지.
- (외부 확인) 2-3b SDK 도입 시 Data Safety·ATT·동의 고지·_LICENSES.md, 부활 닫기 지연의 스토어·광고망 정책.
